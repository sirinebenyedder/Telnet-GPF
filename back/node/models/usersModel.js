const mongoose = require('mongoose');
const userSchema = mongoose.Schema(
	{
		email: {
			type: String,
			required: [true, 'Email is required!'],
			trim: true, 
			unique: [true, 'Email must be unique!'],
			minLength: [5, 'Email must have at least 5 characters!'],
			lowercase: true,
		},
		name: {
			type: String,
			required: [true, 'Name is required!'],
			trim: true,
			unique: [true, 'Name must be unique!'],
			minLength: [5, 'Name must have at least 5 characters!'],
			lowercase: true,
		},
		phone: {
			type: Number,
			required: [true, 'Phone is required!'],
			unique: [true, 'Phone must be unique!'],
			min: [10000000, 'Phone number must have at least 8 digits!'], 
			max: [99999999, 'Phone number must have at most 8 digits!'], 
		},
		role: {
			type: String, 
			default: 'PM', 
		}, 
		password: {
			type: String,
			required: [true, 'Password must be provided!'],
			trim: true,
			select: false,
		},
		adresse:{
			type: String,
		},
		activated:{
			type: Boolean,
			default: true,
		},
		verificationCode: {
			type: String,
			select: false,
		},
		verificationCodeValidation: {
			type: Number,
			select: false,
		},
		forgotPasswordCode: {
			type: String,
			select: false,
		},
		forgotPasswordCodeValidation: {
			type: Number,
			select: false,
		},
		image: {
			type: mongoose.Schema.Types.ObjectId,
			ref: 'Image', // Reference to the Image model
		  },
		creepar: {
			type: mongoose.Schema.Types.ObjectId,
			ref: 'User',
			//required: true
			validate: {
				validator: function (value) {
				  // Si c'est un admin, on autorise que creepar soit vide
				  if (this.role === 'Admin') return true;
				  // Sinon, il doit être défini
				  return value != null;
				},
				message: 'Le champ "creepar" est requis sauf pour les utilisateurs Admin.',
			  },
		},
		currentProject: {
			type: mongoose.Schema.Types.ObjectId,
			ref: 'Project',
			default: null
		},
		resetpassword:{type: Boolean,
			default: false,}
	},
	
	{
		timestamps: true,
	}
);

module.exports = mongoose.model('User', userSchema);
