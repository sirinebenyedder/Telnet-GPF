const jwt = require('jsonwebtoken');
const User = require('../models/usersModel');

exports.identifier = async (req, res, next) => {
 
  const authHeader = req.headers['authorization'];
  console.log("En-tête Authorization reçu:", authHeader); 
  if (!authHeader) {
    return res.status(403).json({ success: false, message: 'Unauthorized: No token provided' });
  }

  // en-tête commence par "Bearer "
  if (!authHeader.startsWith('Bearer ')) {
    return res.status(403).json({ success: false, message: 'Unauthorized: Invalid token format' });
  }

  // 
  const token = authHeader.split(' ')[1];
  console.log("Token extrait:", token); 

  try {
   
    const jwtVerified = jwt.verify(token, process.env.TOKEN_SECRET);
    
    if (jwtVerified) {
      req.user = jwtVerified; 
      next(); 
    } else {
      throw new Error('Invalid token');
    }
  } catch (error) {
    console.log("Erreur lors de la vérification du token:", error); 
    return res.status(403).json({ success: false, message: 'Unauthorized: Invalid or expired token' });
  }
};
//
// Nouvelle version enrichie pour Socket.io et les notifications
exports.authenticateWithSocket = (socket, next) => {
  try {
    const token = socket.handshake.auth.token || 
                 socket.handshake.headers.authorization?.split(' ')[1];
    
    if (!token) throw new Error('Token manquant');

    const decoded = jwt.verify(token, process.env.TOKEN_SECRET);
    socket.user = decoded;
    next();
  } catch (error) {
    console.log('Authentification Socket.io échouée:', error);
    next(new Error('Authentification invalide'));
  }
};