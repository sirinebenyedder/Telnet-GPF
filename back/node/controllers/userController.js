const {
	addUserSchema,
} = require('../middlewares/validator');
const User = require('../models/usersModel');
const Image = require('../models/imageModel');
const { doHash, doHashValidation, hmacProcess } = require('../utils/hashing');
const fs = require('fs');
const multer = require('multer');
const transport = require('../middlewares/sendMail');
const jwt = require('jsonwebtoken');

//
const{generatePassword}=require('../utils/hashing');
const { log } = require('console');
// Set up multer for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
      const uploadDir = 'uploads/';
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true }); // Create the uploads directory if it doesn't exist
      }
      cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
      cb(null, `${Date.now()}-${file.originalname}`);
    },
  });
  
  const upload = multer({ storage });
const bcrypt = require('bcrypt');

  exports.addUser = async (req, res) => {
    const { email, name, phone, adress } = req.body;
    
    try {
        if (!email || !name || !phone || !adress) {
            return res.status(400).json({
                success: false,
                errorType: 'MISSING_FIELDS',
                message: 'Tous les champs sont obligatoires (email, nom, téléphone, adresse)'
            });
        }

        // Validation de l'email
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({
                success: false,
                errorType: 'INVALID_EMAIL',
                message: 'Format d\'email invalide'
            });
        }

        // 
        const creator = await User.findById(req.user.userId);
        if (!creator) {
            return res.status(404).json({
                success: false,
                errorType: 'CREATOR_NOT_FOUND',
                message: 'Utilisateur créateur non trouvé'
            });
        }

        // 
        let newUserRole;
        if (creator.role === 'RF') {
            newUserRole = 'PM';
        } else if (creator.role === 'Admin') {
            newUserRole = 'RF';
        } else {
            return res.status(403).json({
                success: false,
                errorType: 'UNAUTHORIZED_ROLE',
                message: 'Vous n\'êtes pas autorisé à créer des utilisateurs'
            });
        }

        // 
        const existingEmail = await User.findOne({ email });
        if (existingEmail) {
            return res.status(409).json({
                success: false,
                errorType: 'DUPLICATE_EMAIL',
                message: 'Un utilisateur avec cet email existe déjà'
            });
        }

        //
        const duplicateChecks = [
          { field: 'email', value: email, message: 'Cet email est déjà utilisé' },
          { field: 'phone', value: phone, message: 'Ce numéro de téléphone est déjà utilisé' },
          { field: 'name', value: name, message: 'Ce nom d\'utilisateur est déjà pris' }
      ];

      for (const check of duplicateChecks) {
          const existing = await User.findOne({ [check.field]: check.value });
          if (existing) {
              return res.status(409).json({
                  success: false,
                  errorType: `DUPLICATE_${check.field.toUpperCase()}`,
                  message: check.message,
                  duplicateField: check.field
              });
          }
      }

        // Création de l'utilisateur m3a password
        const password = generatePassword(12);
        const hashedPassword = await doHash(password, 12);

        const newUser = new User({
            email,
            password: hashedPassword,
            name,
            phone,
            role: newUserRole,
            adresse: adress,
            creepar: req.user.userId,
            //resetpassword:false,
        });

        const savedUser = await newUser.save();
        savedUser.password = undefined;

        try {
            const mailOptions = {
                from: process.env.NODE_CODE_SENDING_EMAIL_ADDRESS,
                to: email,
                subject: 'Votre compte a été créé',
                html:`
                <div style="font-family: Arial, sans-serif; font-size: 16px; color: #333;">
                  <p>Bonjour ${name},</p>
              
                  <p>Votre compte a été créé avec succès sur notre application.</p>
              
                  <p>Voici vos identifiants de connexion :</p>
              
                  <ul style="list-style: none; padding: 0;">
                    <li><strong>Email :</strong> ${email}</li>
                    <li><strong>Mot de passe :</strong> <span>${password}</span></li>
                  </ul>
              
                  <p>Nous vous recommandons de modifier votre mot de passe lors de votre première connexion pour garantir la sécurité de votre compte.</p>
              
                
                  <br>
                 
                </div>
              `
            };
            await transport.sendMail(mailOptions);
        } catch (emailError) {
            console.error('Erreur email:', emailError);
           
        }

      
        res.status(201).json({
            success: true,
            message: 'Utilisateur créé avec succès',
            user: savedUser
        });

    } catch (error) {
        console.error('Erreur dans addUser:', error);

        
        
        if (error.code === 11000) {
          const field = Object.keys(error.keyPattern)[0];
          const friendlyMessages = {
              email: 'Cet email est déjà utilisé',
              phone: 'Ce numéro de téléphone est déjà utilisé',
              name: 'Ce nom d\'utilisateur est déjà pris'
          };

          return res.status(409).json({
              success: false,
              errorType: `DUPLICATE_${field.toUpperCase()}`,
              message: friendlyMessages[field] || 'Cette valeur existe déjà',
              duplicateField: field
          });
      }


        // Erreurs de validation Mongoose
        if (error.name === 'ValidationError') {
            const errors = Object.values(error.errors).map(err => err.message);
            return res.status(400).json({
                success: false,
                errorType: 'VALIDATION_ERROR',
                message: `Erreur de validation: ${errors.join(', ')}`
            });
        }

        // Erreur générique
        res.status(500).json({
            success: false,
            errorType: 'SERVER_ERROR',
            message: 'Erreur serveur lors de la création'
        });
    }
};


// Fetch user data with image
exports.singleProfile = async (req, res) => {
    const { _id } = req.query; // Use req.query to get the _id
    console.log('le id de singleprofile',_id);
    try {
      const existingUser = await User.findOne({ _id }).populate('image').populate('currentProject');;
      if (!existingUser) {
        return res.status(404).json({ success: false, message: 'Profile unavailable' });
      }
      const currentProjectStatus = existingUser.currentProject 
      ? existingUser.currentProject.status 
      : null;
      //console.log(existingUser);
      // Construct the image URL
      const imageUrl = existingUser.image
        ? `http://${req.headers.host}/uploads/${existingUser.image.filename}`
        : null;
      console.log(imageUrl);
      console.log(currentProjectStatus);
      res.status(200).json({
        success: true,
        message: 'Single profile',
        
        data: {
          ...existingUser.toObject(),
          imageUrl, // Include the image URL in the response
          currentProjectStatus,
        },
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ success: false, message: 'Failed to fetch profile' });
    }
  };
  

  // Upload image and attach to user
  exports.uploadImage = async (req, res) => {
  
    try {
      
      // Save image metadata to the Image collection
      const imageData = {
        filename: req.file.filename,
        path: req.file.path,
        originalname: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
        //uploadedBy: _id,
      };
  
      const image = await Image.create(imageData);
  
      // Attach the image ID to the user
      //existingUser.image = image._id;
      //await existingUser.save();
  
      res.status(200).json({
        success: true,
        message: 'Image uploaded successfully',
        imageUrl: `http://${req.headers.host}/uploads/${image.filename}`,
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ success: false, message: 'Failed to upload image' });
    }
  };

  exports.updateProfile = async (req, res) => {
    console.log("Received request to update profile...");
    
    const { _id } = req.query;
    if (!_id) {
        return res.status(400).json({ success: false, message: 'User ID is required' });
    }

    const { name, email, phone,adresse, oldPassword, newPassword } = req.body;
    console.log({ name, email, phone,adresse, oldPassword, newPassword });
    try {
        
        const existingUser = await User.findOne({ _id }).select('+password');
        if (!existingUser) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Validation  mot de passe 
        if (newPassword) {
            if (!oldPassword) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Mot de passe actuel incorrect.' 
                });
            }

            const isPasswordValid = await doHashValidation(oldPassword, existingUser.password);
            if (!isPasswordValid) {
                return res.status(401).json({ 
                    success: false, 
                    message: 'Mot de passe actuel incorrect.' 
                });
            }

            existingUser.password = await doHash(newPassword, 12);
        }

        // Mise à jour des champs uniquement s'ils sont fournis
        if (name !== undefined) existingUser.name = name;
        if (email !== undefined) existingUser.email = email;
        if (phone !== undefined) existingUser.phone = phone;
        if (adresse !== undefined) existingUser.adresse = adresse;
        existingUser.resetpassword=true;
        // Gestion de l'image uploadée
        if (req.file) {
            try {
                // Supprimer l'ancienne image si elle existe
                if (existingUser.image) {
                  console.log("existing image ")
                    const oldImage = await Image.findById(existingUser.image);
                    if (oldImage) {
                      console.log('oldImage',oldImage);
                        // Suppression sécurisée du fichier
                        const filePath = path.join(__dirname, '..', oldImage.path);
                        if (fs.existsSync(filePath)) {
                            fs.unlinkSync(filePath);
                            console.log('wist fc');
                        }
                        await Image.findByIdAndDelete(existingUser.image);
                    }
                }

                
                const newImage = await Image.create({
                    filename: req.file.filename,
                    path: req.file.path,
                    originalname: req.file.originalname,
                    mimetype: req.file.mimetype,
                    size: req.file.size,
                    uploadedBy: _id,
                });

                existingUser.image = newImage._id;
                console.log('existingUser.image',existingUser.image);
            } catch (imageError) {
                console.error("Image processing error:", imageError);
               
            }
        }

        // Sauvegarder les modifications
        await existingUser.save();

        // l'utilisateur blechmot de passe
        const userToReturn = existingUser.toObject();
        delete userToReturn.password;

        res.status(200).json({
            success: true,
            message: 'Profil mis à jour avec succès',
            data: userToReturn
        });

    } catch (error) {
        console.error("Profile update error:", error);
        res.status(500).json({ 
            success: false, 
            message: 'Échec de la mise à jour du profil',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
exports.checkpasswchange= async (req, res) => {
  try {
    console.log("chek_reset-status");
    console.log(req.user.userId);
    /*// 1. Vérifier le token
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ 
        success: false,
        message: 'Token non fourni' 
      });
    }

    // 2. Décoder le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);*/
  
    
    // 3. Récupérer l'utilisateur en base de données
    const user = await User.findById(req.user.userId);
    
    if (!user) {
      return res.status(404).json({ 
        success: false,
        message: 'Utilisateur non trouvé' 
      });
    }

    // 4. Retourner le statut actuel
    res.json({
      success: true,
      requiresReset: user.resetpassword === false // true si besoin de reset
    });

  } catch (error) {
    console.error('Erreur vérification statut reset:', error);
    res.status(500).json({ 
      success: false,
      message: 'Erreur serveur' 
    });
  }
};
  /*exports.fetchusers = async (req, res) => {
    const { page , limit } = req.query;
    const token = req.headers['authorization'];
    console.log("token du fetchusers:", token);
    
    const skip = (page - 1) * limit;

    try {
        // Récupération des utilisateurs avec pagination
        const users = await User.find({})
            .skip(skip)
            .limit(parseInt(limit))
            .populate({
              path: 'image',
          })
          .lean(); // Convertit les documents Mongoose en objets JavaScript simples
          // Transformer les données pour inclure l'URL de l'image
        const usersWithImages = users.map(user => {
          const imageUrl = user.image
          ? `http://${req.headers.host}/uploads/${user.image.filename}`
          : null;
          console.log(imageUrl);

      return {
          ...user,
          imageUrl
      };
  });
        const totalUsers = await User.countDocuments();

        res.json({
            success: true,
            data: usersWithImages,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: totalUsers,
                totalPages: Math.ceil(totalUsers / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ 
            success: false, 
            message: 'Erreur lors de la récupération des utilisateurs', 
            error: error.message 
        });
    }
  
};*/
exports.fetchusers = async (req, res) => {
  const { page, limit } = req.query;
  const token = req.headers['authorization'];
  console.log("token du fetchusers:", token);

  const skip = (page - 1) * limit;

  try {
      // Décoder le token pour obtenir les infos de l'utilisateur
      const decodedToken = jwt.verify(token.replace('Bearer ', ''), process.env.TOKEN_SECRET);
      const currentUserId = decodedToken.userId;
      const currentUserRole = decodedToken.role;
     console.log('fetchuser',currentUserRole)
      // Construire la requête en fonction du rôle
      let query = {};
      
      if (currentUserRole === 'RF') {
          // Un RF ne voit que les utilisateurs qu'il a créés
          query = { creepar: currentUserId };
      } 
      // (Pas de condition pour Admin car on veut tous les users)

      // Récupération des utilisateurs avec pagination et filtre
      const users = await User.find(query)
          .skip(skip)
          .limit(parseInt(limit))
          .populate({
              path: 'image',
          })
          .populate('creepar', 'name') 
          .lean();
        console.log(users);
      // Transformer les données pour inclure l'URL de l'image
      const usersWithImages = users.map(user => {
          const imageUrl = user.image
              ? `http://${req.headers.host}/uploads/${user.image.filename}`
              : null;

          return {
              ...user,
              imageUrl
          };
      });

      const totalUsers = await User.countDocuments(query);

      res.json({
          success: true,
          data: usersWithImages,
          pagination: {
              page: parseInt(page),
              limit: parseInt(limit),
              total: totalUsers,
              totalPages: Math.ceil(totalUsers / limit)
          }
      });
  } catch (error) {
      console.error('Error in fetchusers:', error);
      res.status(500).json({ 
          success: false, 
          message: 'Erreur lors de la récupération des utilisateurs', 
          error: error.message 
      });
  }
};
//update 
//  mettre à jour un utilisateur
exports.updateUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { name, email, phone, adress } = req.body;
    console.log(name, email, phone, adress);
    console.log(userId)
    console.log(req.body);
// devrait afficher : { name: 'John', email: 'john@test.com', phone: '123456789', adress: 'Rue X' }

    // Vérification si l'utilisateur existe
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }

    // Préparation des données à mettre à jour
    const updateData = {
      name,
      email,
      phone,
      adresse:adress
    };
      console.log(updateData);
    // Ajout du mot de passe uniquement s'il est fourni
    /*if (password) {
      // Vous voudrez probablement hasher le mot de passe avant de le stocker
      const bcrypt = require('bcrypt');
      const hashedPassword = await bcrypt.hash(password, 10);
      updateData.password = hashedPassword;
    }*/

    // Mise à jour de l'utilisateur
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      updateData,
      //{ new: true, runValidators: true } // Renvoie le document mis à jour et valide selon le schéma
    )
      //.select('-password'); // Exclut le mot de passe de la réponse

    res.status(200).json({
      message: 'Utilisateur mis à jour avec succès',
      user: updatedUser
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour de l\'utilisateur:', error);
    res.status(500).json({ message: 'Erreur serveur lors de la mise à jour de l\'utilisateur', error: error.message });
  }
};

/// le fetch des users  pour Admin 
exports.fetchUsersByRole = async (req, res) => {
  const { page, limit, role } = req.query;
  const token = req.headers['authorization'];
  console.log('fetchusersby role');
  const skip = (page - 1) * limit;

  try {
    const decodedToken = jwt.verify(token.replace('Bearer ', ''), process.env.TOKEN_SECRET);
    const currentUserId = decodedToken.userId;
    const currentUserRole = decodedToken.role;

    let query = {};

    // Si l'utilisateur est RF, il ne voit que ses PMs
    /*if (currentUserRole === 'RF') {
      query = { 
        creepar: currentUserId,
        role: 'PM' // On ne veut que les PMs de ce RF
      };*/
    
    // Si on demande un rôle spécifique (pour l'admin)
   
    query = { role };
    
    console.log(query);
    const users = await User.find(query)
      .skip(skip)
      .limit(parseInt(limit))
      .populate('image')
      .populate('creepar', 'name')
      .lean();

    const usersWithImages = users.map(user => ({
      ...user,
      imageUrl: user.image 
        ? `http://${req.headers.host}/uploads/${user.image.filename}`
        : null
    }));

    const totalUsers = await User.countDocuments(query);
    //console.log(usersWithImages);
    res.json({
      success: true,
      data: usersWithImages,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalUsers,
        totalPages: Math.ceil(totalUsers / limit)
      }
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur serveur', 
      error: error.message 
    });
  }
};

exports.fetchPmByRf = async (req, res) => {
  const { rfId, page, limit } = req.query;
  const skip = (page - 1) * limit;
  console.log('fetchPMby RF')
  try {
    const users = await User.find({ 
      creepar: rfId,
      role: 'PM'
    })
    .skip(skip)
    .limit(parseInt(limit))
    .populate('image')
    .populate('creepar', 'name')
    .lean();

    const usersWithImages = users.map(user => ({
      ...user,
      imageUrl: user.image 
        ? `http://${req.headers.host}/uploads/${user.image.filename}`
        : null
    }));

    const totalUsers = await User.countDocuments({ creepar: rfId });

    res.json({
      success: true,
      data: usersWithImages,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalUsers,
        totalPages: Math.ceil(totalUsers / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Erreur serveur', 
      error: error.message 
    });
  }
};