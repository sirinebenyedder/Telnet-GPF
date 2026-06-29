const mongoose = require('mongoose');

// models/Notification.js
const notificationSchema = mongoose.Schema({
  sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User'},
  type: { 
    type: String, 
    enum: ['BUDGET_REQUEST', 'PROJECT_CREATION', 'PROJECT_REVIEW'], 
  },
  message: { type: String},
  metadata: { type: mongoose.Schema.Types.Mixed }, // Données flexibles
  isRead: { type: Boolean, default: false },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'PENDING' }
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);