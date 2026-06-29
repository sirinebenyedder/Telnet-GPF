const { OAuth2Client } = require('google-auth-library');
require('dotenv').config();

// Vérification des variables d'environnement
if (!process.env.GOOGLE_CLIENT_ID) {
  console.error('❌ Erreur : GOOGLE_CLIENT_ID non défini !');
  process.exit(1);
}

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

async function verifyGoogleToken(token) {
  if (!token) {
    throw new Error('Token non fourni');
  }

  try {
    // Vérifier le token Google
    const ticket = await client.verifyIdToken({
      idToken: token,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    // Récupérer les informations de l'utilisateur
    const payload = ticket.getPayload();
    if (!payload) {
      throw new Error('Impossible de récupérer les informations du token');
    }

    return payload;
  } catch (error) {
    console.error('Erreur lors de la vérification du token Google :', error);
    throw error;
  }
}

module.exports = { verifyGoogleToken };