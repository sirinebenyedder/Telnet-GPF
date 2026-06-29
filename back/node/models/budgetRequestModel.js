const mongoose = require('mongoose');
const budgetRequestSchema =  mongoose.Schema({
    project: { type: mongoose.Schema.Types.ObjectId, ref: 'Project'},
    requester: { type: mongoose.Schema.Types.ObjectId, ref: 'User'},
    amount: { type: Number},
    currency: { type: String, enum: ['EUR', 'USD'], default: 'EUR' },
    reason: { type: String//, required: true
     }, 
    status: { 
      type: String, 
      enum: ['pending', 'approved', 'rejected'], 
      default: 'pending' 
    },
    approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    comments: [{
      user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      text: String,
      createdAt: { type: Date, default: Date.now }
    }]
  }, { timestamps: true });
  module.exports = mongoose.model('BudgetRequest', budgetRequestSchema);