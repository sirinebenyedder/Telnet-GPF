const mongoose = require('mongoose');
const invoiceSchema = mongoose.Schema(
  {
    invoice_no: {
      type: String,
      alias: 'number', 
      required: [true, 'Invoice number is required!'],
      trim: true,
    },
    address: {
      type: String,
      alias: 'address_country', 
      required: [true, 'Address is required!'],
      trim: true,
    },
    company: {
      type: String,
      alias: 'supplier', 
      required: [true, 'Company is required!'],
      trim: true,
    },
    date: {
      type: Date,
      required: [true, 'Date is required!'],
      get: (v) => v.toLocaleString('en-GB') // kif 25/12/2018 8:13:39 PM
    },
    total: {
      type: Number,
      required: [true, 'Total is required!'],
      set: (v) => parseFloat(v) //"9.00"--> 9.00
    },
    items: [{
      description: String,
      quantity: String,
      unit_price: {
        type: Number,
        set: (v) => parseFloat(v) //  "9.000" --> 9.0
      }
    }],
    currency: { 
      type: String,
      required: [true, 'Currency is required!'],
      trim: true,
    },

    image: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Imageinvoices'
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    projectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Project',
      required: true
    },
  
  },
  { 
    timestamps: true,
    toJSON: { 
      getters: true,
      virtuals: true, // Inclut les alias dans le JSON
    },
    toObject: { 
      getters: true,
      virtuals: true, // Inclut les alias dans les objets JS
    }
  }
);

module.exports = mongoose.model('Invoice', invoiceSchema);
