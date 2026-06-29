const jwt = require('jsonwebtoken');
const { verifyGoogleToken } = require('../middlewares/auth');
const {
	addUserSchema,
	signinSchema,
	acceptCodeSchema,
	changePasswordSchema,
	acceptFPCodeSchema,
} = require('../middlewares/validator');
const User = require('../models/usersModel');
const { doHash, doHashValidation, hmacProcess } = require('../utils/hashing');
const transport = require('../middlewares/sendMail');

exports.signin = async (req, res) => {
    const { email, password } = req.body;

    console.log("Tentative de connexion avec l'email:", email);

    try {
        // Validation des données d'entrée
        const { error, value } = signinSchema.validate({ email, password });
        if (error) {
            console.log("Erreur de validation:", error.details[0].message);
            return res
                .status(401)
                .json({ success: false, message: error.details[0].message });
        }

        console.log("Validation des données réussie.");

        // Recherche de l'utilisateur dans la base de données
        const existingUser = await User.findOne({ email }).select('+password');
        if (!existingUser) {
            console.log("Utilisateur non trouvé pour l'email:", email);
            return res
                .status(401) 
                .json({ success: false, message: "Utilisateur non trouvé pour cet email" });
        }
        //raja3ha 400 mta3 email non trouvé
        console.log("Utilisateur trouvé:", existingUser.email);

        // Vérification compte est activé
        if (!existingUser.activated) {
            console.log("Compte désactivé pour l'utilisateur:", existingUser.email);
            return res
                .status(403)
                .json({ 
                    success: false, 
                    message: "Votre compte a été désactivé par votre responsable. Veuillez le contacter." 
                });
        }

        // Vérification mot de passe
        const result = await doHashValidation(password, existingUser.password);
        if (!result) {
            console.log("Mot de passe incorrect pour l'utilisateur:", existingUser.email);
            return res
                .status(401)
                .json({ success: false, message: "Identifiants invalides" });
        }

        console.log("Mot de passe correct. Génération du token...");

        // Génération du token JWT
        const token = jwt.sign(
            {
                userId: existingUser._id,
                email: existingUser.email,
                role: existingUser.role,
                //resetPassword:existingUser.resetpassword,
            },
            process.env.TOKEN_SECRET,
            {
                expiresIn: '8h',
            }
        );

        console.log("Token généré avec succès:", token);
       
        const response = {
            success: true,
            token,
            message: 'Connexion réussie',
            
        };

       
        res.cookie('Authorization', 'Bearer ' + token, {
            expires: new Date(Date.now() + 8 * 3600000),
            httpOnly: process.env.NODE_ENV === 'production',
            secure: process.env.NODE_ENV === 'production',
        });

        // Affichage de l'objet `res` avant l'envoi
        console.log("Réponse à envoyer:", {
            statusCode: res.statusCode,
            headers: res.getHeaders(),
            cookies: res.getHeader('Set-Cookie'),
            body: response,
        });

       
        res.json(response);

    } catch (error) {
        console.log("Erreur lors de la connexion:", error);
        res.status(500).json({ 
            success: false, 
            message: "Erreur interne du serveur" 
        });
    }
};

exports.signout = async (req, res) => {
	
	const authHeader = req.headers['authorization'];
	console.log("En-tête Authorization reçu:", authHeader); 
  
	if (!authHeader) {
	  return res.status(400).json({ success: false, message: 'No token provided' });
	}
  
	if (!authHeader.startsWith('Bearer ')) {
	  return res.status(400).json({ success: false, message: 'Invalid token format' });
	}
  
	const token = authHeader.split(' ')[1];
	console.log("Token extrait:", token); 
  
	try {
	 
	  return res.status(200).json({ success: true, message: 'Logged out successfully' });
	} catch (error) {
	  console.log("Erreur lors de la déconnexion:", error); 
	  return res.status(500).json({ success: false, message: 'Failed to logout' });
	}
  };
  //
const messages = {
    userNotFound: 'Aucun utilisateur trouvé avec cet email.',
    alreadyVerified: 'Ce compte est déjà vérifié.',
    codeSent: 'Code envoyé avec succès !',
    sendFailed: "Échec de l'envoi du code.",
    serverError: 'Erreur interne du serveur.'
};



exports.googleSignIn = async (req, res) => {
	const { token } = req.body;
  
	try {
	  // Vérifier le token Google
	  const payload = await verifyGoogleToken(token);
  
	  // Vérifier si l'utilisateur existe déjà dans la base de données
	  let user = await User.findOne({ email: payload.email });
  
	  if (!user) {
		// Créer un nouvel utilisateur si nécessaire
		user = new User({
		  email: payload.email,
		  verified: true, // Marquer l'utilisateur comme vérifié
		});
		await user.save();
	  }
  
	  // Générer un token JWT
	  const jwtToken = jwt.sign(
		{
		  userId: user._id,
		  email: user.email,
		  verified: user.verified,
		},
		process.env.TOKEN_SECRET,
		{
		  expiresIn: '8h',
		}
	  );
  
	  // Renvoyer le token JWT dans un cookie
	  res
		.cookie('Authorization', 'Bearer ' + jwtToken, {
		  expires: new Date(Date.now() + 8 * 3600000),
		  httpOnly: process.env.NODE_ENV === 'production',
		  secure: process.env.NODE_ENV === 'production',
		})
		.json({
		  success: true,
		  token: jwtToken,
		  message: 'Logged in with Google successfully',
		});
	} catch (error) {
	  console.error('Erreur lors de la connexion Google :', error);
	  res.status(401).json({ success: false, message: 'Google authentication failed' });
	}
  };

exports.changePassword = async (req, res) => {
	const { userId } = req.user;
	const { oldPassword, newPassword } = req.body;
	try {
		
		const existingUser = await User.findOne({ _id: userId }).select(
			'+password'
		);
		if (!existingUser) {
			return res
				.status(401)
				.json({ success: false, message: 'User does not exists!' });
		}
		const result = await doHashValidation(oldPassword, existingUser.password);
		if (!result) {
			return res
				.status(401)
				.json({ success: false, message: 'Invalid credentials!' });
		}
		const hashedPassword = await doHash(newPassword, 12);
		existingUser.password = hashedPassword;
		await existingUser.save();
		return res
			.status(200)
			.json({ success: true, message: 'Password updated!!' });
	} catch (error) {
		console.log(error);
	}
};

const crypto = require('crypto');
//////////////hethi fc ta3 mot de passe oublié
exports.sendForgotPasswordCode = async (req, res) => {
    const { email } = req.body;
    console.log('hiii');
    console.log(email);

    try {
        const existingUser = await User.findOne({ email });
        if (!existingUser) {
            return res
                .status(404)
                .json({ success: false, message: 'Aucun utilisateur trouvé avec cet email' });
        }
		  // Vérifier si le compte est activé
        if (!existingUser.activated) {
            return res
                .status(403)
                .json({ success: false, message: 'Votre compte est désactivé' });
        }
        // Générer un code à 6 chiffres avec crypto
        const generateSecureCode = () => {
            const randomBytes = crypto.randomBytes(3);
            return (randomBytes.readUIntBE(0, 3) % 1000000).toString().padStart(6, '0');
        };

        const codeValue = generateSecureCode();
        console.log(codeValue);

        // Envoyer le code par e-mail
        let info = await transport.sendMail({
            from: process.env.NODE_CODE_SENDING_EMAIL_ADDRESS,
            to: existingUser.email,
            subject: 'Code de vérification pour réinitialisation de mot de passe',
            html:`<div><p>Vous avez demandé un code pour accéder à la réinitialisation de votre mot de passe.</p>
			<p>Voici votre code de vérification :</p>
			<div style="text-align: center; margin: 20px 0;">
			  <h1 style="background: #f0f0f0; display: inline-block; padding: 10px 25px; border-radius: 8px; color: #2c3e50;">
				${codeValue}
			  </h1>
			</div>
			<p>Ce code est valable pendant 15 minutes.</p>
			</div>`
			});

        if (info.accepted[0] === existingUser.email) {
            // Hasher le code avant de le stocker
            const hashedCodeValue = hmacProcess(
                codeValue,
                process.env.HMAC_VERIFICATION_CODE_SECRET
            );

            // Stocker le code hashé et la date de validation
            existingUser.forgotPasswordCode = hashedCodeValue;
            existingUser.forgotPasswordCodeValidation = Date.now();
            await existingUser.save();

            return res.status(200).json({ success: true, message: 'Code envoyé avec succès ' });
        }

        res.status(400).json({ success: false, message: "Échec de l'envoi du code" });
    } catch (error) {
        console.log(error);
        res.status(500).json({ success: false, message: 'Erreur interne du serveur' });
    }
};

exports.verifyCode = async (req, res) => {
    
    const { email, code } = req.body;
	console.log({ email, code });

    // Validation des entrées
    if (!email || !code) {
        return res.status(400).json({
            success: false,
            message: 'Le code est requis'
        });
    }

    try {
        const codeValue = code.toString();
        const existingUser = await User.findOne({ email }).select(
            '+forgotPasswordCode +forgotPasswordCodeValidation'
        );
        console.log(existingUser);
        // 1. Vérifie si l'utilisateur existe
        if (!existingUser) {
            return res.status(404).json({ 
                success: false, 
                message: 'Aucun utilisateur trouvé avec cet email.' 
            });
        }

        // 2. Vérifie si une demande de réinitialisation existe
        if (!existingUser.forgotPasswordCode || !existingUser.forgotPasswordCodeValidation) {
            return res.status(400).json({ 
                success: false, 
                message: 'Aucune demande de réinitialisation active pour cet email.' 
            });
        }

        // 3. Vérifie le code
        const hashedCodeValue = hmacProcess(codeValue, process.env.HMAC_VERIFICATION_CODE_SECRET);
        
        if (hashedCodeValue !== existingUser.forgotPasswordCode) {
            return res.status(400).json({ 
                success: false, 
                message: 'Code incorrect. Veuillez vérifier le code reçu.' 
            });
        }

        // 4. Vérifie l'expiration du code (15 minutes)
        const codeAge = Date.now() - existingUser.forgotPasswordCodeValidation;
        const CODE_EXPIRATION_TIME = 15 * 60 * 1000; // 15 minutes en millisecondes
        
        if (codeAge > CODE_EXPIRATION_TIME) {
            // Optionnel : Supprimer le code expiré
            await User.updateOne(
                { email },
                { 
                    $unset: { 
                        forgotPasswordCode: 1,
                        forgotPasswordCodeValidation: 1 
                    } 
                }
            );
            
            return res.status(400).json({ 
                success: false, 
                message: 'Le code a expiré. Veuillez demander un nouveau code.' 
            });
        }

        // Code valide et non expiré
        return res.status(200).json({ 
            success: true, 
            message: 'Code vérifié avec succès.',
            data: {
                email,
                codeValid: true
            }
        });

    } catch (error) {
        console.error('Erreur lors de la vérification du code:', error);
        return res.status(500).json({ 
            success: false, 
            message: 'Une erreur est survenue lors de la vérification du code.' 
        });
    }
};
///////////////////
exports.verifyForgotPasswordCode = async (req, res) => {
    const { email, providedCode, newPassword } = req.body;

    try {
		 // Validation de la longueur du mot de passe avant tout traitement
    if (!newPassword || newPassword.length < 10) {
        return res.status(400).json({ 
            success: false, 
            message: 'Le mot de passe doit contenir au moins 10 caractères.' 
        });
    }
        const codeValue = providedCode.toString();
        const existingUser = await User.findOne({ email }).select(
            '+forgotPasswordCode +forgotPasswordCodeValidation'
        );

        // 1. Vérifie d'abord si l'utilisateur existe
        if (!existingUser) {
            return res.status(401).json({ 
                success: false, 
                message: 'Aucun utilisateur trouvé avec cet email !' 
            });
        }

        // 2. Vérifie si un code existe (actif ou expiré)
        if (!existingUser.forgotPasswordCode || !existingUser.forgotPasswordCodeValidation) {
            return res.status(400).json({ 
                success: false, 
                message: 'Aucune demande de réinitialisation active.' 
            });
        }

        // 3. Compare d'abord le CODE (avant de vérifier l'expiration)
        const hashedCodeValue = hmacProcess(codeValue, process.env.HMAC_VERIFICATION_CODE_SECRET);
        
        if (hashedCodeValue !== existingUser.forgotPasswordCode) {
            return res.status(400).json({ 
                success: false, 
                message: 'Code invalide. Veuillez vérifier le code.' 
            });
        }

        // 4. Ensuite, vérifie l'expiration (seulement si le code est correct)
        const codeAge = Date.now() - existingUser.forgotPasswordCodeValidation;
        if (codeAge > 15 * 60 * 1000) {
            return res.status(400).json({ 
                success: false, 
                message: 'Code expiré. Veuillez en demander un nouveau.' 
            });
        }

        // Si tout est OK, met à jour le mot de passe
        const hashedPassword = await doHash(newPassword, 12);
        existingUser.password = hashedPassword;
        existingUser.forgotPasswordCode = undefined;
        existingUser.forgotPasswordCodeValidation = undefined;
        
        await existingUser.save();
        
        return res.status(200).json({ 
            success: true, 
            message: 'Mot de passe mis à jour avec succès !' 
        });

    } catch (error) {
        console.error('Erreur:', error);
        return res.status(500).json({ 
            success: false, 
            message: 'Erreur serveur.' 
        });
    }
};