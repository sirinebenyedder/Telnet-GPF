const multer = require('multer');
const path = require('path');


const fs = require('fs');


// Ensure the uploads directory exists
const uploadDir = './uploads';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true }); // Create the uploads directory if it doesn't exist
}

// Set storage engine
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir); // Save files to the uploads directory
  },
  filename: function (req, file, cb) {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});

// Initialize multer with storage configuration (no file filter)
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // Limit file size to 5MB
  },
});

// Configuration pour les images des factures (uploads2)
const invoiceStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = './uploads2';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true }); // Crée le dossier s'il n'existe pas
    }
    cb(null, uploadDir); // Dossier de destination pour les images des factures
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`); // Nom du fichier
  },
});

const uploadInvoice = multer({
  storage: invoiceStorage,
  limits: {
    fileSize: 10 * 1024 * 1024, // Limite de taille à 5MB
  },
});
// Configuration pour les images des factures (uploads2)
const invoicedefStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = './uploads3';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true }); 
    }
    cb(null, uploadDir); 
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`); 
  },
});

const uploadDefInvoice = multer({
  storage: invoicedefStorage,
  limits: {
    fileSize: 10 * 1024 * 1024, 
  },
});

module.exports = { upload , uploadInvoice , uploadDefInvoice };
