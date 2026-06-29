const BudgetRequest = require('../models/budgetRequestModel');
const Notification = require('../models/notificationModel');
const Project = require('../models/projectModel')
const User = require('../models/usersModel')


exports.getColleagueProjects = async (req, res) => {
 try {
    const userId = req.user.userId;
    console.log("Current user ID:", userId);

    // 1. Trouver le RF du PM connecté
    const currentPm = await User.findById(userId).select('creepar');
    if (!currentPm || !currentPm.creepar) {
      return res.status(400).json({ message: "RF non trouvé pour ce PM" });
    }
    const rfId = currentPm.creepar;
    console.log("RF ID:", rfId);

    // 2. Trouver tous les PMs sous le même RF (excluant l'utilisateur actuel)
    const colleaguePms = await User.find({
      creepar: rfId,
      _id: { $ne: userId },
      role: 'PM'
    }).select('_id');

    const pmIds = colleaguePms.map(pm => pm._id);
    console.log("PM IDs for query:", pmIds);

    // 3. Récupérer les projets avec population du manager
    const projects = await Project.find({
      manager: { $in: pmIds }
    })
    .populate({
      path: 'manager',
      select: 'name email role'
    })
    .select('name status datedebut budget currency');

    console.log(`${projects.length} projets trouvés`);

    console.log("Projects found:", projects);

    res.status(200).json(projects);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      message: 'Erreur serveur',
      error: error.message
    });
  }
};

exports.createRequest = async (req, res) => {
  try {
    const { requestType, message, metadata } = req.body;
    const userId = req.user.userId;
    console.log(message);
    //console.log( requestType, message, metadata);
    // Récupérer les informations du PM son (RF)
    const projectManager = await User.findById(userId).select('creepar');
    
    if (!projectManager || !projectManager.creepar) {
      return res.status(400).json({ message: "Impossible de trouver le RF associé à ce PM" });
    }
    
    //const recipientId = projectManager.creepar;
    let recipientId = projectManager.creepar;
    let projectId;
    let finalMetadata = { ...metadata };

    // Gestion différente selon le type de requête
    if (requestType === 'PROJECT_CREATION') {
      // Création d'un nouveau projet
       // Vérifier si un projet avec le même nom existe déjà
  const existingProject = await Project.findOne({ name: metadata.projectName });
  if (existingProject) {
    return res.status(400).json({ 
      message: "Un projet avec ce nom existe déjà" 
    });
  }
      const project = await Project.create({
        name: metadata.projectName,
        status: 1,
        datedebut: new Date(metadata.startDate),
        manager: userId,
        budget: parseFloat(metadata.budget),
        currency: metadata.currency,
        second_currency: metadata.secondaryCurrency,
        pays: metadata.country
      });
      //console.log("projet",project);
      projectId = project._id;
      finalMetadata.projectId = projectId;
    } 
    else if (requestType === 'BUDGET_REQUEST') {
      // Augmentation de budget pour un projet existant
      projectId = metadata.projectId;
      if (!projectId) {
        return res.status(400).json({ message: "ID du projet manquant" });
      }
      
      // Vérifier que le projet appartient bien au PM
      const project = await Project.findOne({ 
        _id: projectId, 
        manager: userId 
      });
      
      if (!project) {
        return res.status(403).json({ message: "Vous n'êtes pas autorisé à modifier ce projet" });
      }
      
      finalMetadata.currentBudget = project.budget;
      finalMetadata.requestedAmount = parseFloat(metadata.amount);
       finalMetadata.currency = project.currency;
    }    else if (requestType === 'PROJECT_REVIEW') {
      // Demande de revue pour un projet existant
      projectId = metadata.projectId;
      if (!projectId) {
        return res.status(400).json({ message: "ID du projet manquant" });
      }
      
      // Récupérer le manager du projet (manager2)
      const project = await Project.findById(projectId).select('manager name');
      //onsole.log(project);
      if (!project) {
        return res.status(404).json({ message: "Projet non trouvé" });
      }
      
      // Vérifier que le demandeur (manager1) n'est pas le manager du projet
      if (project.manager.toString() === userId) {
        return res.status(400).json({ message: "Vous ne pouvez pas demander une view sur votre propre projet" });
      }
      
      recipientId = project.manager; // Le manager2 qui recevra la demande
      finalMetadata.projectId = projectId;
       // Ajouter des métadonnées supplémentaires
  finalMetadata = {
    ...finalMetadata,
    projectId: projectId,
    projectName: project.name, // Ajouter le nom du projet
    reviewNote: metadata.reviewNote || '', // Nouveau champ pour la note

  };
    }


    // Création de la notification
    const notification = await Notification.create({
      sender: userId,
      recipient: recipientId,
      type: requestType,
      message: message || `Nouvelle demande de type ${requestType}`,
      metadata: finalMetadata,
      status: 'pending'
    });

    // Envoi temps réel au destinataire (RF)
    const recipientSocket = req.userSockets.get(recipientId.toString());
    if (recipientSocket) {
      req.io.to(recipientSocket).emit('new_request', {
        ...notification.toObject(),
        sender: req.user
      });
    }

    res.status(201).json({ notification });
  } catch (error) {
    console.error('Erreur lors de la création de la demande:', error);
    res.status(500).json({ 
      message: 'Erreur lors de la création de la demande', 
      error: error.message 
    });
  }
};


// controllers/notificationController.js
//hethi la fonction responsable a la reponse 
/*exports.respondToRequest = async (req, res) => {
  try {
    const { id } = req.params; // Récupération depuis les paramètres d'URL
    const { response } = req.body;
    //const userId = req.user.userId;

    // 1. Vérifier que la notification existe et est en attente
    const notification = await Notification.findOne({
      _id: id,
      status: 'pending'
    }).populate('sender recipient');

    if (!notification) {
      return res.status(404).json({ 
        success: false,
        message: "Notification non trouvée ou déjà traitée" 
      });
    }

    // 2. Mettre à jour la notification
    notification.status = response ? 'approved' : 'rejected';
    notification.respondedAt = new Date();
    await notification.save();

    // 3. Exécuter l'action spécifique
    let actionResult = null;
    const metadata = notification.metadata || {};

    switch (notification.type) {
      case 'PROJECT_CREATION':
        if (response && metadata.projectId) {
          actionResult = await Project.findByIdAndUpdate(
            metadata.projectId,
            { 
              status: 2, // Statut actif
              datedebut: new Date() // Date d'acceptation
            },
            { new: true }
          );
        }
        break;

      case 'BUDGET_REQUEST':
        if (response && metadata.projectId && metadata.amount) {
          const amount = Number(metadata.amount);
          actionResult = await Project.findOneAndUpdate(
            { _id: metadata.projectId },
            { $inc: { budget: amount } },
            { new: true }
          );
        }
        break;

      case 'INVOICE_REVIEW':
        if (metadata.invoiceId) {
          actionResult = await Invoice.findByIdAndUpdate(
            metadata.invoiceId,
            { status: response ? 'approved' : 'rejected' },
            { new: true }
          );
        }
        break;
    }

    // 4. Envoyer la réponse
    res.json({
      success: true,
      notification: {
        id: notification._id,
        status: notification.status,
        respondedAt: notification.respondedAt,
        type: notification.type
      },
      ...(actionResult && { actionResult })
    });

  } catch (error) {
    console.error('Erreur traitement réponse:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};*/
exports.respondToRequest = async (req, res) => {
  try {
    const { id } = req.params; // Récupération depuis les paramètres d'URL
    const { response } = req.body;
    //const userId = req.user.userId;
    console.log(id,response);
    // 1. Vérifier que la notification existe et est en attente
    const notification = await Notification.findOne({
      _id: id,
      status: 'pending'
    }).populate('sender recipient');
    
    if (!notification) {
      return res.status(404).json({ 
        success: false,
        message: "Notification non trouvée ou déjà traitée" 
      });
    }
    
    // 2. Mettre à jour la notification
    notification.status = response ? 'approved' : 'rejected';
    notification.respondedAt = new Date();
    await notification.save();
    
    // 3. Exécuter l'action spécifique
    let actionResult = null;
    const metadata = notification.metadata || {};
    
    switch (notification.type) {
      case 'PROJECT_CREATION':
        if (response && metadata.projectId) {
          actionResult = await Project.findByIdAndUpdate(
            metadata.projectId,
            { 
              status: 2, // Statut actif
              datedebut: new Date() // Date d'acceptation
            },
            { new: true }
          );
        }
        break;
      
      case 'BUDGET_REQUEST':
        if (response && metadata.projectId && metadata.amount) {
          const amount = Number(metadata.amount);
          actionResult = await Project.findOneAndUpdate(
            { _id: metadata.projectId },
            { $inc: { budget: amount } },
            { new: true }
          );
        }
        break;
      
      case 'PROJECT_REVIEW':
        if (response && metadata.projectId) {
          // Si la demande est acceptée, ajouter le sender (PM demandeur) à la liste vupar
          const senderId = notification.sender._id || notification.sender;
          
          // Utiliser $addToSet pour éviter les doublons dans la liste
          actionResult = await Project.findByIdAndUpdate(
            metadata.projectId,
            { 
              $addToSet: { vupar: senderId }
            },
            { new: true }
          );
          
          // Log pour débogage
          console.log(`Project Review: Added user ${senderId} to vupar list of project ${metadata.projectId}`);
        }
        break;
      
      case 'INVOICE_REVIEW':
        if (metadata.invoiceId) {
          actionResult = await Invoice.findByIdAndUpdate(
            metadata.invoiceId,
            { status: response ? 'approved' : 'rejected' },
            { new: true }
          );
        }
        break;
    }
    
    // 4. Envoyer la réponse
    res.json({
      success: true,
      notification: {
        id: notification._id,
        status: notification.status,
        respondedAt: notification.respondedAt,
        type: notification.type
      },
      ...(actionResult && { actionResult })
    });
   
  } catch (error) {
    console.error('Erreur traitement réponse:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};

// Handlers spécifiques
async function handleProjectCreationResponse(notification, isAccepted) {
  if (!isAccepted) return null;
  
  const projectId = notification.metadata?.projectId;
  if (!projectId) throw new Error("Project ID manquant");

  const updatedProject = await Project.findByIdAndUpdate(
    projectId,
    { 
      status: 2, // Statut "actif"
      datedebut: new Date() // Date actuelle d'acceptation
    },
    { new: true }
  );

  return { 
    projectId: updatedProject._id,
    newStatus: updatedProject.status,
    startDate: updatedProject.datedebut 
  };
}

async function handleBudgetRequestResponse(notification, isAccepted) {
  if (!isAccepted) return null;
  
  const projectId = notification.metadata?.projectId;
  const amount = parseFloat(notification.metadata?.amount);
  
  if (!projectId || isNaN(amount)) {
    throw new Error("Données de budget invalides");
  }

  const project = await Project.findById(projectId);
  const newBudget = parseFloat(project.budget) + amount;
  
  const updatedProject = await Project.findByIdAndUpdate(
    projectId,
    { budget: newBudget },
    { new: true }
  );

  return {
    projectId: updatedProject._id,
    oldBudget: project.budget,
    newBudget: updatedProject.budget,
    addedAmount: amount
  };
}

async function handleInvoiceReviewResponse(notification, isAccepted) {
  const invoiceId = notification.metadata?.invoiceId;
  if (!invoiceId) throw new Error("Invoice ID manquant");

  const newStatus = isAccepted ? 'approved' : 'rejected';
  
  const updatedInvoice = await Invoice.findByIdAndUpdate(
    invoiceId,
    { status: newStatus },
    { new: true }
  );

  return {
    invoiceId: updatedInvoice._id,
    newStatus: updatedInvoice.status
  };
}