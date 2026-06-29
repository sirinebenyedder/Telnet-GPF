const mongoose = require('mongoose');
const imageSchema = mongoose.Schema(
    {
      filename: {
        type: String,
        required: true,
      }, 
      path: {
        type: String,
        required: true,
      },
      originalname: {
        type: String,
        required: true,
      },
      mimetype: {
        type: String,
        required: true,
      },
      size: {
        type: Number,
        required: true, 
      },
     
    },
    {
      timestamps: true,
    }
  );
  
  module.exports = mongoose.model('Image', imageSchema);