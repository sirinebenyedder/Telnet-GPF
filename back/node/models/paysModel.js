const mongoose = require('mongoose');

const paysSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  currency: {
    type: String,
    required: true
  },
  tauxdechangeeuro: {
    type: Number,
    required: true
  },
  tauxdechangedollar: {
    type: Number,
    required: true
  }
});

const Pays = mongoose.model('Pays', paysSchema);

module.exports = Pays;
