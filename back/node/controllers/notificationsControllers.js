const Notification = require('../models/notificationModel');
const BudgetRequest = require('../models/budgetRequestModel');
const jwt = require('jsonwebtoken');


// Récupérer les notifications
exports.getUserNotifications = async (req, res) => {
  console.log(req);
  console.log('le userid de notification ' ,req.user.userId);
  try {
    const notifications = await Notification.find({
      $or: [
        { recipient: req.user.userId},
        { sender: req.user.userId }
      ]
    })
    .sort('-createdAt')
    .populate('sender', 'name email')
    .populate('recipient', 'name email');

    res.json({ 
      success: true,
      notifications 
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message 
    });
  }
};

