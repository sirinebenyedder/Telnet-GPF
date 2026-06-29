const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const mongoose = require('mongoose');
const path = require('path');
const http = require('http');
const socketIo = require('socket.io');
const fs = require('fs'); 
const axios = require('axios'); 
const mime = require('mime-types');
const authRouter = require('./routers/authRouter');
const invoicesRouter = require('./routers/invoicesRouter');
const userRouter = require('./routers/userRouter');
const RequestResponseRouter = require('./routers/RequestRouter');
const notificationRouter = require('./routers/notificationRouter');
const projectRouter = require('./routers/projectRouter');
const { authenticateWithSocket } = require('./middlewares/identification');

const app = express();
const server = http.createServer(app); 
const io = socketIo(server, { // Initialisation de Socket.io
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const userSockets = new Map();

// Middlewares
app.use(cors());
app.use(helmet());
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Passez io aux routes qui en ont besoin
app.use((req, res, next) => {
  req.io = io;
  req.userSockets = userSockets;
  next();
});

// Configuration Socket.io
io.use(authenticateWithSocket);

io.on('connection', (socket) => {
  console.log(`Utilisateur ${socket.user?.id} connecté`);
  
  if (socket.user?.id) {
    userSockets.set(socket.user.id, socket.id);
  }
  
  socket.on('disconnect', () => {
    if (socket.user?.id) {
      userSockets.delete(socket.user.id);
    }
  });
});

// Connexion MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('Database connected'))
  .catch(err => console.log(err));

// Routes
app.use('/api/RequestResponse', RequestResponseRouter);
app.use('/api/auth', authRouter);
app.use('/api/invoices', invoicesRouter);
app.use('/api/user', userRouter);
app.use('/api/notifications', notificationRouter);
app.use('/api/project',projectRouter);
app.get('/', (req, res) => {
  res.json({ message: 'Hello from the server' });
});

app.post('/api/send-message', (req, res) => {
  const { message } = req.body;
  console.log("Message reçu :", message);
  res.json({ success: true, receivedMessage: message });
});

// Node.js - index.js (simplifié)
app.post('/process-invoice', async (req, res) => {
  try {
    const { imagePath } = req.body;
    
    if (!fs.existsSync(imagePath)) {
      return res.status(404).json({ error: 'Image not found' });
    }
    
    // Lire l'image en tant que buffer
    const imageBuffer = fs.readFileSync(imagePath);
    
    // Créer FormData pour envoyer l'image au Flask
    const form = new FormData();
    form.append('image', imageBuffer, {
      filename: path.basename(imagePath),
      contentType: 'image/jpeg', // ou déterminer automatiquement
    });
    
    const jupyterResponse = await axios.post('http://localhost:8888/execute', form, {
      headers: {
        ...form.getHeaders(),
      },
    });
    
    res.json(jupyterResponse.data);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Failed to process image' });
  }
});
app.use('/uploads2', express.static(path.join(__dirname, 'uploads2')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
// Nouveau endpoint dans votre serveur Node


app.get('/api/images/:filename', (req, res) => {
    console.log("script entrainement !!!!!!!!!!!!!!!!!!!!!!!");

    try {
        const filename = req.params.filename;
        console.log("filename :", filename);

        const filePath = path.join(__dirname, 'uploads2', filename);
        console.log("filePath :", filePath);

        if (fs.existsSync(filePath)) {
            console.log("en fc att");

            const mimeType = mime.lookup(filePath) || 'application/octet-stream';
            res.setHeader('Content-Type', mimeType);
            console.log("mimeType :", mimeType);
            console.log("hey");

            const fileStream = fs.createReadStream(filePath);

            fileStream.on('open', () => {
                console.log("✅ Stream ouvert, on va pipe !");
                fileStream.pipe(res);
            });

            fileStream.on('error', (streamErr) => {
                console.error("❌ Erreur dans le stream :", streamErr);
                res.status(500).json({ error: 'Erreur de lecture du fichier' });
            });

        } else {
            console.log("Fichier non trouvé :", filePath);
            res.status(404).json({ error: 'Fichier non trouvé' });
        }
    } catch (error) {
        console.error("Erreur serveur :", error);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});
//
const os = require('os');
const networkInterfaces = os.networkInterfaces();
console.log('Adresses IP disponibles :');
for (const name of Object.keys(networkInterfaces)) {
  for (const net of networkInterfaces[name]) {
    // Ignorer les adresses IPv6 
    if (net.family === 'IPv4' && !net.internal) {
      console.log(`- ${name}: ${net.address}`);
    }
  }
}
//
// Démarrer le serveur

server.listen(process.env.PORT,'0.0.0.0', () => {
  console.log(`Server is running on port ${process.env.PORT}`);
});
