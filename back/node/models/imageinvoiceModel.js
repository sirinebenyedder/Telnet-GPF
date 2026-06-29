const mongoose = require('mongoose');
const imageinvoicesSchema = mongoose.Schema(
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
      /*uploadedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User', // Reference to the user who uploaded the image
        required: true,
      },*/
    },
    {
      timestamps: true,
    }
  );
  
  module.exports = mongoose.model('Imageinvoices', imageinvoicesSchema);