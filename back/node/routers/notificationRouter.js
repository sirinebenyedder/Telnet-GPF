const express = require('express');
const router = express.Router();
const Notification = require('../models/notificationModel');
const { identifier } = require('../middlewares/identification');
const notificationController = require('../controllers/notificationsControllers');
// Créer une notification
//router.post('/', identifier, notificationController.createNotification);

// Récupérer les notifications
router.get('/', identifier, notificationController.getUserNotifications);

// Répondre à une notification
//router.put('/:id/respond', identifier, notificationController.handleResponse);

// Marquer comme lu
//router.put('/:id/read', identifier, notificationController.markAsRead);


module.exports = router;