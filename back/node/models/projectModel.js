const mongoose = require('mongoose');
const projectSchema = mongoose.Schema(
    {
        name: {
            type: String,
            required: true
        },
        status: {
            type: Number,
            enum: [1, 2, 3], // 1: avant debut pas encore valide par PM , 2 debut 3:fini
            default: 1 // Par défaut "avant début"
        },
        datedebut: {
            type: Date,
            default: Date.now // Date de création par défaut
        },
        datefin: {
            type: Date
        },
        manager: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true 
        },
        budget: {
            type: Number,
            required: true
        },
        currency: {
            type: String,
            enum: ['EUR', 'USD'], // Euro /Dollar
            required: true
        },
        second_currency: {
            type: String,
        },
        pays: {
            type: String,
            required: true
        },
     vupar: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: []
    }],
    totalinvoices:{
        type:Number
    }
  },
    {
        timestamps: true }
);



module.exports = mongoose.model('Project', projectSchema);