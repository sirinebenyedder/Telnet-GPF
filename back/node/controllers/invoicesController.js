const { createPostSchema } = require('../middlewares/validator');
const Invoice = require('../models/invoicesModel');
const Project = require('../models/projectModel');
const Imageinvoices = require('../models/imageinvoiceModel');
const User = require('../models/usersModel');
const axios = require('axios'); // Importer axios pour les requêtes HTTP
const path = require('path'); // Importer le module path
const multer = require('multer');
const fs = require('fs');
const http = require('http'); // Utiliser https si l'API externe est en HTTPS
const moment = require('moment');
const jwt = require('jsonwebtoken');
const {calculateProjectInvoiceTotal }=require('./projectController');
//const {getSpecificExchangeRate }=require('./projectController');
const { Console } = require('console');
const FormData = require('form-data');


// 1. Fonction Node.js uploadFactures modifiée
exports.uploadFactures = async (req, res) => {
  console.log('la fonction uploadFacture');
  try {
    const { oldTempImageId } = req.body;

    // Supprimer l'ancienne image temporaire si elle existe
    if (oldTempImageId) {
      const oldTempImagePath = path.join(__dirname, '../uploads2', `${oldTempImageId}_*`);
      const files = fs.readdirSync(path.join(__dirname, '../uploads2'));
      const fileToDelete = files.find((file) => file.startsWith(oldTempImageId));
      
      if (fileToDelete) {
        fs.unlinkSync(path.join(__dirname, '../uploads2', fileToDelete));
      }
    }

    // Enregistrer les métadonnées de l'image dans la collection Imageinvoices
    const imageData = {
      filename: req.file.filename,
      path: req.file.path,
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
    };

    const image = await Imageinvoices.create(imageData);

    // Lire l'image en tant que buffer
    const imageBuffer = fs.readFileSync(req.file.path);

    // Créer FormData pour envoyer l'image
    const form = new FormData();
    form.append('image', imageBuffer, {
      filename: req.file.originalname,
      contentType: req.file.mimetype,
    });

    // Envoyer la requête à l'API externe avec axios
    const response = await axios.post('http://192.168.1.158:5002/process-invoice', form, {
      headers: {
        ...form.getHeaders(),
      },
    });

    const invoiceData = response.data;
    console.log(invoiceData);
    
    res.status(200).json({
      success: true,
      message: 'Image uploaded and processed successfully',
      imageUrl: `http://${req.headers.host}/uploads2/${image.filename}`,
      invoiceData: invoiceData,
      tempImageId: image._id,
    });

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, message: 'Failed to upload or process image' });
  }
};

exports.moveToPermanent = async (req, res) => {
	try {
	  const { tempImageId } = req.body;
  
	  // Trouver l'image temporaire dans la base de données
	  const image = await Imageinvoices.findById(tempImageId);
	  if (!image) {
		return res.status(404).json({ success: false, message: 'Temp image not found' });
	  }
  
	  // Chemin de l'image temporaire
	  const tempImagePath = path.join(__dirname, '../uploads2', image.filename);
  
	  // Chemin de destination dans le dossier permanent
	  const permanentImagePath = path.join(__dirname, '../uploads3', image.filename);
  
	  // Déplacer l'image vers le dossier permanent
	  fs.renameSync(tempImagePath, permanentImagePath);
  
	  // Mettre à jour le chemin de l'image dans la base de données
	  image.path = permanentImagePath;
	  await image.save();
  
	  res.status(200).json({ success: true, message: 'Image moved to permanent folder' });
	} catch (error) {
	  console.error('Error moving image:', error);
	  res.status(500).json({ success: false, message: 'Failed to move image' });
	}
  };
  exports.deleteTempImage = async (req, res) => {
	console.log('fonction delete')
	try {
	  const { tempImageId } = req.body;
  
	  // Trouver l'image temporaire dans la base de données
	  const image = await Imageinvoices.findById(tempImageId);
	  if (!image) {
		return res.status(404).json({ success: false, message: 'Temp image not found' });
	  }
  
	  // Chemin de l'image temporaire
	  const tempImagePath = path.join(__dirname, '../uploads2', image.filename);
	  console.log(tempImagePath);
	  // Supprimer l'image du dossier temporaire
	  fs.unlinkSync(tempImagePath);
	  console.log("avant la suppression de l'image dans la bd");
	  // Supprimer l'image de la base de données
	  await Imageinvoices.findByIdAndDelete(tempImageId);
	  console.log("apres la suppression de l'image dans la bd");
	  res.status(200).json({ success: true, message: 'Temp image deleted' });
	} catch (error) {
	  console.error('Error deleting temp image:', error);
	  res.status(500).json({ success: false, message: 'Failed to delete temp image' });
	}
  };


    //hethi save jdida b total 
exports.saveInvoice = async (req, res) => {
  console.log("saveInvoice function started");
  try {
    const { 
      number, 
      date, 
      address_country, 
      currency, 
      total, 
      supplier, 
      items, 
      projectId, 
      imageId, 
      userId
    } = req.body;
    
    // Format the date
    const formattedDate = moment.utc(date, 'DD/MM/YYYY').toDate();
    console.log("Formatted date:", formattedDate);
    
    // 1. Check if invoice with same number and supplier already exists
    const existingInvoice = await Invoice.findOne({ 
      invoice_no: number, 
      company: supplier 
    });
    
    if (existingInvoice) {
      return res.status(400).json({ 
        success: false, 
        message:  'Une facture avec ce numéro et ce fournisseur existe déjà' 
      });
    }
    
    // 2. Check if the invoice total is within the remaining budget
    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ 
        success: false, 
        message: 'Projet non trouvé'
      });
    }
    
    // Get the project's main currency and budget
    const mainCurrency = project.currency;
    const budget = project.budget || 0;
    const totalInvoices = project.totalinvoices || 0;
    console.log('budget',budget);
    console.log('totalInvoices',totalInvoices);
    // Convert invoice total to main currency if needed
    let invoiceAmountInMainCurrency = total;
    console.log('currency',currency);
    console.log('maincurrency',mainCurrency);
    if (currency !== mainCurrency) {
      try {
        invoiceAmountInMainCurrency = await convertCurrency(total, currency, mainCurrency);

      } catch (error) {
        return res.status(400).json({
          success: false,
          message: 'Échec de la conversion de devise',
          error: error.message
        });
      }
    }
    
    // Calculate remaining budget
    const remainingBudget = budget - totalInvoices;
    console.log("remainingbudget");
    console.log(remainingBudget);
    // Check if invoice amount exceeds remaining budget
    if (invoiceAmountInMainCurrency > remainingBudget) {
      return res.status(400).json({
        success: false,
        message:'Le montant de la facture dépasse le budget restant',
        budget: budget,
        totalSpent: totalInvoices,
        remaining: remainingBudget,
        invoiceAmount: invoiceAmountInMainCurrency,
        currency: mainCurrency
      });
    }
    
    // Create new invoice object
    const newInvoice = new Invoice({
      invoice_no: number,
      date: formattedDate,
      address: address_country,
      currency,
      total,
      company: supplier,
      items,
      image: imageId,
      userId: userId,
      projectId
    });
    
    // Save the invoice to the database
    await newInvoice.save();
    
    // 3. Update the project's totalInvoice using calculateProjectInvoiceTotal
    await calculateProjectInvoiceTotal(projectId.toString());
    console.log("Total invoices updated for project:", projectId);
    
    // Send successful response
    res.status(201).json({ 
      success: true, 
      message: 'Facture enregistrée avec succès', 
      invoice: newInvoice 
    });
    
  } catch (error) {
    console.error('Error saving invoice:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Échec de l\'enregistrement de la facture', 
      error: error.message 
    });
  }
};

const API_BASE_URL = 'https://v6.exchangerate-api.com/v6';
const API_KEY = process.env.EXCHANGE_RATE_API_KEY;

// Convert currency using the existing getSpecificExchangeRate function
async function convertCurrency(amount, fromCurrency, toCurrency) {
  if (fromCurrency === toCurrency) {
    return amount;
  }
  
  try {
    console.log(`Converting ${amount} from ${fromCurrency} to ${toCurrency}`);
    const exchangeRate = await getSpecificExchangeRate(fromCurrency, toCurrency);
    const convertedAmount = amount * exchangeRate;
    console.log(`Conversion result: ${amount} ${fromCurrency} = ${convertedAmount} ${toCurrency} (rate: ${exchangeRate})`);
    return convertedAmount;
  } catch (error) {
    console.error(`Erreur lors de la conversion de devise: ${error.message}`);
    throw error;
  }
}
const getSpecificExchangeRate = async (fromCurrency, toCurrency) => {
  try {
    const response = await axios.get(`${API_BASE_URL}/${API_KEY}/latest/${fromCurrency}`);
    
    if (response.data.result !== 'success') {
      throw new Error(`Erreur de l'API de taux de change: ${response.data.error || 'Erreur inconnue'}`);
    }
    
    const specificRate = response.data.conversion_rates[toCurrency];
    if (!specificRate) {
      throw new Error(`Taux de change non disponible pour la paire ${fromCurrency}/${toCurrency}`);
    }
    
    return specificRate;
  } catch (error) {
    console.error(`Erreur lors de la récupération du taux de change ${fromCurrency}/${toCurrency}:`, error);
    throw error;
  }
};

exports.fetchinvoices = async (req, res) => {
  const { startDate, endDate, supplier, minMontant, maxMontant, page = 1, limit = 10, projectId } = req.query;
  const token = req.headers['authorization'];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Token manquant' });
  }

  try {
    const decoded = jwt.verify(token.replace('Bearer ', ''), process.env.TOKEN_SECRET);
    const requestingUserId = decoded.userId;
    const requestingUserRole = decoded.role;
    const skip = (page - 1) * limit;

    // Étape 1: Déterminer le projet cible et vérifier les permissions
    let targetProject = null;
    let filter = {};

    if (requestingUserRole === 'PM') {
      // Cas 1: projectId spécifié dans la requête
      if (projectId) {
        targetProject = await Project.findOne({
          _id: projectId,
          $or: [
            { manager: requestingUserId },
            { vupar: requestingUserId }
          ]
        });

        if (!targetProject) {
          return res.status(403).json({ success: false, message: 'Accès refusé à ce projet' });
        }

        filter.projectId = projectId;
      } 
      // Cas 2: Aucun projectId spécifié - utiliser le currentProject
      else {
        const user = await User.findById(requestingUserId).populate('currentProject');
        if (!user?.currentProject) {
          return res.json({
            success: true,
            data: [],
            pagination: { page: parseInt(page), limit: parseInt(limit), total: 0, totalPages: 0 }
          });
        }

        // Vérifier que le PM a accès à son currentProject
        const hasAccess = await Project.exists({
          _id: user.currentProject._id,
          $or: [
            { manager: requestingUserId },
            { vupar: requestingUserId }
          ]
        });

        if (!hasAccess) {
          return res.status(403).json({ success: false, message: 'Accès refusé au projet courant' });
        }

        targetProject = user.currentProject;
        filter.projectId = targetProject._id;
      }

      // On a supprimé le filtre par userId pour les PM
      // filter.userId = requestingUserId; // LIGNE SUPPRIMÉE
    }
    else if (['RF', 'Admin'].includes(requestingUserRole)) {
      if (projectId) filter.projectId = projectId;
      // Les RF/Admin peuvent éventuellement filtrer par userId s'ils le souhaitent
      // Mais ce n'est pas obligatoire
    } else {
      return res.status(403).json({ success: false, message: 'Rôle non autorisé' });
    }
    // Étape 2: Appliquer les filtres supplémentaires
    if (startDate && endDate) {
      filter.date = { 
        $gte: new Date(startDate), 
        $lte: new Date(endDate) 
      };
    }
    if (supplier) {
      filter.company = { $regex: supplier, $options: 'i' };
    }
    if (minMontant || maxMontant) {
      filter.total = {};
      if (minMontant) filter.total.$gte = parseFloat(minMontant);
      if (maxMontant) filter.total.$lte = parseFloat(maxMontant);
    }
    console.log('filter');
    console.log(filter);
    // Étape 3: Récupérer les factures avec populate
    const [factures, totalFactures] = await Promise.all([
      Invoice.find(filter)
        .populate('userId', 'name email role')
        .populate('projectId', 'name status manager vupar')
        .populate('image', 'filename')
        .skip(skip)
        .limit(parseInt(limit)),
      Invoice.countDocuments(filter)
    ]);

    // Étape 4: Formater la réponse
    const responseData = factures.map(facture => {
      const factureObj = facture.toObject();
      
      // Formatage de la date
      let formattedDate = null;
      if (factureObj.date) {
        try {
          const dateStr = factureObj.date.toString();
          const [day, month, year] = dateStr.split('/');
          if (day && month && year) {
            formattedDate = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
          }
        } catch (e) {
          console.error('Erreur formatage date:', e);
        }
      }

      return {
        ...factureObj,
        user: factureObj.userId,
        date: formattedDate,
        project: {
          _id: factureObj.projectId?._id || targetProject?._id,
          name: factureObj.projectId?.name || targetProject?.name,
          status: factureObj.projectId?.status || targetProject?.status,
          manager: factureObj.projectId?.manager || targetProject?.manager,
          vupar: factureObj.projectId?.vupar || targetProject?.vupar || []
        },
        number: factureObj.invoice_no,
        supplier: factureObj.company,
        imageUrl: factureObj.image 
          ? `${req.protocol}://${req.headers.host}/uploads2/${factureObj.image.filename}`
          : null
      };
    });

    res.json({
      success: true,
      data: responseData,
      currentProject: targetProject ? {
        _id: targetProject._id,
        name: targetProject.name,
        status: targetProject.status,
        manager: targetProject.manager,
        vupar: targetProject.vupar || []
      } : null,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalFactures,
        totalPages: Math.ceil(totalFactures / limit)
      }
    });

  } catch (error) {
    console.error('Erreur fetchInvoices:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur serveur',
      error: error.message 
    });
  }
};
// project 

exports.createProject = async (req, res) => {
  try {
    const { name, budget, currency, pays } = req.body;
    const token = req.headers.authorization;

   
    if (!token) {
      return res.status(401).json({ 
        success: false, 
        message: 'Token manquant' 
      });
    }

    
    const decoded = jwt.verify(
      token.replace('Bearer ', ''), 
      process.env.TOKEN_SECRET
    );
    
    const requestingUserId = decoded.userId;
    const requestingUserRole = decoded.role;

    // champs obligatoires
    if (!name || !budget || !currency || !pays) {
      return res.status(400).json({ 
        success: false,
        message: "Tous les champs sont obligatoires (name, budget, currency, pays)" 
      });
    }

    // l'utilisateur existe
    const manager = await User.findById(requestingUserId);
    if (!manager) {
      return res.status(404).json({
        success: false,
        message: "Utilisateur non trouvé"
      });
    }

    //  Création projet
    const newProject = new Project({
      name,
      manager: requestingUserId, // On utilise l'ID du token
      budget: Number(budget),
      currency,
      pays,
      status: 2 // "avant début" par défaut
    });

    const savedProject = await newProject.save();
    
    //  Population des infos du manager
    await savedProject.populate('manager', 'name email role');

    //  Réponse réussie
    res.status(201).json({
      success: true,
      message: "Projet créé avec succès",
      data: savedProject
    });

  } catch (error) {
    console.error("Erreur création projet:", error);
    
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: "Token invalide"
      });
    }
    res.status(500).json({ 
      success: false,
      message: "Erreur serveur",
      error: error.message 
    });
  }
};


// fetch les currencies diponibles dans un projet
exports.fetchingallcurrenciesperpproject = async (req, res) => {
  try {
    const projectId = req.params.projectId;
    console.log('projectId',projectId);
    

    // 2. Récupérez le projet
    const project = await Project.findById(projectId)
      .select('currency second_currency');
    
    if (!project) {
      return res.status(404).json({ error: 'Projet non trouvé' });
    }

    // 3. Retournez les devises disponibles
    const currencies = [];
    if (project.currency) currencies.push(project.currency);
    if (project.second_currency) currencies.push(project.second_currency);
    
    // Évitez les doublons
    const uniqueCurrencies = [...new Set(currencies)];
    console.log(uniqueCurrencies);
    res.json({
      success: true,
      currencies: uniqueCurrencies
    });
    
  } catch (error) {
    console.error('Error getting project currencies:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};
exports.updateFacture = async (req, res) => {
  console.log("updateFacture function started");
  try {
    const { factureId } = req.params;
    const {
      invoice_no,
      date,
      total,
      company,
      address,
      currency,
      items,
      projectId
    } = req.body;

    console.log("Request data:", { invoice_no, date, total, company, address, currency });
    console.log("Items:", typeof items === 'string' ? JSON.parse(items) : items);

    // 1. Find the existing invoice
    console.log("Looking for existing invoice...");
    const existingInvoice = await Invoice.findById(factureId);
    if (!existingInvoice) {
      return res.status(404).json({ 
        success: false, 
        message: 'Facture introuvable' 
      });
    }

    // Store the original values
    const originalTotal = existingInvoice.total;
    const originalCurrency = existingInvoice.currency;
    
    // 2. Check if invoice number is being changed and if it would conflict
    if (invoice_no && invoice_no !== existingInvoice.invoice_no) {
      const duplicateInvoice = await Invoice.findOne({
        invoice_no: invoice_no,
        company: company || existingInvoice.company,
        _id: { $ne: factureId } // Exclude current invoice
      });
      
      if (duplicateInvoice) {
        return res.status(400).json({
          success: false,
          message: 'Une facture avec ce numéro et ce fournisseur existe déjà'
        });
      }
    }

    // Define projectIdToUse at the highest scope so it's available throughout the function
    const projectIdToUse = projectId || existingInvoice.projectId;
    console.log("projectIdToUse:", projectIdToUse);

    // 3. Budget validation only if total is being updated
    if (total !== undefined) {
      // Get the project
      const project = await Project.findById(projectIdToUse);
      if (!project) {
        return res.status(404).json({
          success: false,
          message: 'Projet non trouvé'
        });
      }

      // Get the project's main currency and budget
      const mainCurrency = project.currency;
      const budget = project.budget || 0;
      const totalInvoices = project.totalinvoices || 0;
      
      // Convert original invoice amount to main currency if needed
      let originalTotalInMainCurrency = originalTotal;
      if (originalCurrency !== mainCurrency) {
        try {
          originalTotalInMainCurrency = await convertCurrency(originalTotal, originalCurrency, mainCurrency);
        } catch (error) {
          return res.status(400).json({
            success: false,
            message: 'Échec de la conversion de devise pour le montant original',
            error: error.message
          });
        }
      }
      
      // Convert new invoice amount to main currency if needed
      const newTotal = parseFloat(total);
      const newCurrency = currency || originalCurrency;
      let newTotalInMainCurrency = newTotal;
      if (newCurrency !== mainCurrency) {
        try {
          newTotalInMainCurrency = await convertCurrency(newTotal, newCurrency, mainCurrency);
        } catch (error) {
          return res.status(400).json({
            success: false,
            message: 'Échec de la conversion de devise pour le nouveau montant',
            error: error.message
          });
        }
      }
      
      console.log('Original total in main currency:', originalTotalInMainCurrency);
      console.log('New total in main currency:', newTotalInMainCurrency);
      
      // Only check budget if new total is higher than original total (in main currency)
      if (newTotalInMainCurrency > originalTotalInMainCurrency) {
        // Calculate remaining budget (budget - totalInvoices + original invoice amount)
        const remainingBudget = budget - totalInvoices + originalTotalInMainCurrency;
        console.log('Budget:', budget);
        console.log('Total invoices:', totalInvoices);
        console.log('Remaining budget (with original invoice excluded):', remainingBudget);
        
        // Check if new invoice amount exceeds remaining budget
        if (newTotalInMainCurrency > remainingBudget) {
          return res.status(400).json({
            success: false,
            message: 'Le montant de la facture dépasse le budget restant',
            budget: budget,
            totalSpent: totalInvoices - originalTotalInMainCurrency,
            remaining: remainingBudget,
            invoiceAmount: newTotalInMainCurrency,
            currency: mainCurrency
          });
        }
      }
    }

    // 4. Update invoice fields
    if (invoice_no) existingInvoice.invoice_no = invoice_no;
    if (date) existingInvoice.date = date;
    if (total !== undefined) existingInvoice.total = parseFloat(total);
    if (company) existingInvoice.company = company;
    if (address) existingInvoice.address = address;
    if (currency) existingInvoice.currency = currency;
    if (projectId) existingInvoice.projectId = projectId;

    // 5. Handle items
    if (items) {
      try {
        const parsedItems = typeof items === 'string' ? JSON.parse(items) : items;
        existingInvoice.items = parsedItems.map(item => ({
          description: item.description,
          quantity: item.quantity,
          unit_price: parseFloat(item.unit_price) || 0
        }));
      } catch (error) {
        console.error("Error parsing items:", error);
        return res.status(400).json({
          success: false,
          message: 'Format des articles invalide'
        });
      }
    }

    // 6. Handle image upload if present
    if (req.file) {
      console.log("New invoice image detected...");
      
      if (existingInvoice.image) {
        const oldImage = await Imageinvoices.findById(existingInvoice.image);
        if (oldImage) {
          fs.unlinkSync(oldImage.path);
          await Imageinvoices.findByIdAndDelete(existingInvoice.image);
        }
      }
      
      const imageData = {
        filename: req.file.filename,
        path: req.file.path,
        originalname: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
      };
      
      const newImage = await Imageinvoices.create(imageData);
      existingInvoice.image = newImage._id;
    }

    // 7. Save the updated invoice
    await existingInvoice.save();
    
    // 8. Update the project's totalInvoice
    await calculateProjectInvoiceTotal(projectIdToUse.toString());
    console.log("Total invoices updated for project:", projectIdToUse);
    
    res.status(200).json({
      success: true,
      message: 'Facture mise à jour avec succès',
      data: existingInvoice
    });
    
  } catch (error) {
    console.error('Error updating invoice:', error);
    res.status(500).json({
      success: false,
      message: 'Échec de la mise à jour de la facture',
      error: error.message
    });
  }
};

exports.getinvoice = async (req, res) => {
  try {
    const factureId = req.params.id;

    // Vérification de la validité de l'ID
    if (!factureId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ 
        success: false, 
        message: 'ID de facture invalide' 
      });
    }

    // Récupération de la facture avec les relations
    const facture = await Invoice.findById(factureId)
      .populate('projectId', 'name currency second_currency')  // on suppose que le modèle projet contient un champ "name"
      .populate('userId', 'name ') // on suppose que le modèle user contient les champs "name" et "email"
      .populate('image','filename');

    if (!facture) {
      return res.status(404).json({ 
        success: false, 
        message: 'Facture non trouvée' 
      });
    }

    // Formatage des données pour correspondre à la structure attendue par le frontend
    const formattedFacture = {
      _id: facture._id,
      invoice_no: facture.invoice_no || '', // champ exact de la base
      total: facture.total || 0,
      currency: facture.currency || 'EUR',
      date: facture.date,
      address: facture.address || '', // ou un autre champ si tu stockes une description ailleurs
      image: facture.image || null,
      company: facture.company || '',

      items: facture.items?.map(item => ({
        description: item.description,
        quantity: item.quantity,
        unit_price: item.unit_price,
        _id: item._id
      })) || [],

      project: facture.projectId ? {
        id: facture.projectId._id,
        name: facture.projectId.name,
        currency:facture.projectId.currency || null,
        second_currency:facture.projectId.second_currency || null,
      } : null,

      createdAt: facture.createdAt,
      updatedAt: facture.updatedAt,

      createdBy: facture.userId ? {
        id: facture.userId._id,
        name: facture.userId.name,
        email: facture.userId.email
      } : null,

      imageUrl : facture.image
      ? `http://${req.headers.host}/uploads2/${facture.image.filename}`
      : null,
    
    };
     // console.log(imageUrl);
    //console.log(formattedFacture);
    return res.status(200).json({
      success: true,
      data: formattedFacture
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des détails:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération des détails'
    });
  }
};
/////////////////

// Suppression facture
exports.deleteFacture = async (req, res) => {
  console.log("supprime ");
  try {
    const { id } = req.params;
    console.log(id);
    // Trouver la facture avant suppression pour obtenir le projectId
    const facture = await Invoice.findOne({ _id: id });
    
    if (!facture) {
      return res.status(404).json({ 
        success: false,
        message: 'Facture non trouvée' 
      });
    }

    const projectId = facture.projectId;
    console.log(projectId);
    // Supprimer la facture
    await Invoice.findOneAndDelete({ _id: id });

    // Recalculer le total avec la logique complète
    //await calculateProjectInvoiceTotal(projectId);

    res.json({ 
      success: true,
      message: 'Facture supprimée avec succès',
      data: facture
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: 'Erreur lors de la suppression',
      error: error.message 
    });
  }
};

// Suppression multiple de factures 
exports.deleteMultipleFactures = async (req, res) => {
  try {
    const { ids } = req.body;
    console.log("suppr multiple ");
    
    if (!ids || !Array.isArray(ids)) {
      return res.status(400).json({
        success: false,
        message: 'IDs des factures requis'
      });
    }
    
    // Trouver une facture pour obtenir le projectId (toutes du même projet)
    const sampleFacture = await Invoice.findOne({ _id: { $in: ids } });
    
    if (!sampleFacture) {
      return res.status(404).json({
        success: false,
        message: 'Aucune facture trouvée'
      });
    }
    
    if (!sampleFacture.projectId) {
      console.error("Erreur: projectId est manquant dans la facture", sampleFacture._id);
      return res.status(400).json({
        success: false,
        message: 'ID du projet manquant dans la facture'
      });
    }
    
    const projectId = sampleFacture.projectId;
    console.log('on est dans projectId');
    console.log(projectId);
    
    try {
      // Supprimer les factures
      const result = await Invoice.deleteMany({ _id: { $in: ids } });
      console.log(`${result.deletedCount} facture(s) supprimée(s)`);
      
      try {
        // Appel direct à la fonction de calcul du total avec l'ID du projet
        await calculateProjectInvoiceTotal(projectId.toString());
        console.log("Total des factures mis à jour pour le projet:", projectId);
        
        res.json({
          success: true,
          message: `${result.deletedCount} facture(s) supprimée(s)`,
          data: result
        });
      } catch (updateError) {
        console.error("Erreur lors de la mise à jour du total:", updateError);
        // On continue quand même pour retourner un succès partiel
        res.status(207).json({
          success: true,
          message: `${result.deletedCount} facture(s) supprimée(s), mais erreur lors de la mise à jour du total`,
          error: updateError.message,
          data: result
        });
      }
    } catch (deleteError) {
      console.error("Erreur lors de la suppression:", deleteError);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la suppression des factures',
        error: deleteError.message
      });
    }
  } catch (error) {
    console.error("Erreur générale:", error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression multiple',
      error: error.message
    });
  }
};
