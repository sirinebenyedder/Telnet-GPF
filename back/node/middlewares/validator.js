const Joi = require('joi');

exports.addUserSchema = Joi.object({
	email: Joi.string()
		.min(6)
		.max(60)
		.required()
		.email({
			tlds: { allow: ['com', 'net'] }, 
		})
		.messages({
			'string.min': 'Email must be at least 6 characters long',
			'string.max': 'Email cannot exceed 60 characters',
			'string.email': 'Email must be a valid email address (only .com and .net domains are allowed)',
			'any.required': 'Email is required',
		}),
	password: Joi.string()
		.min(8) 
		.required()
		.messages({
			'string.min': 'Password must be at least 8 characters long',
			'any.required': 'Password is required',
		}),
	name: Joi.string()
		.min(3) 
		.required()
		.messages({
			'string.min': 'Name must be at least 3 characters long',
			'any.required': 'Name is required',
		}),
	role: Joi.string()
		.valid('PM', 'RF','Admin') 
		.required()
		.messages({
			'any.only': 'Role must be correct',
			'any.required': 'Role is required',
		}),
		phone: Joi.string()
		.pattern(/^[0-9]{8}$/) 
		.required()
		.messages({
			'string.pattern.base': 'Phone number must be exactly 8 digits', 
			'any.required': 'Phone is required',
		}),
});
exports.signinSchema = Joi.object({
	email: Joi.string()
		.min(6)
		.max(60)
		.required()
		.email({
			tlds: { allow: ['com', 'net'] },
		}),
	password: Joi.string()
		.required()
		
});

exports.acceptCodeSchema = Joi.object({
	email: Joi.string()
		.min(6)
		.max(60)
		.required()
		.email({
			tlds: { allow: ['com', 'net'] },
		}),
	providedCode: Joi.number().required(),
});

exports.changePasswordSchema = Joi.object({
	newPassword: Joi.string()
		.required()
		.pattern(new RegExp('^(?=.*[a-z])(?=.*[A-Z])(?=.*d).{8,}$')),
	oldPassword: Joi.string()
		.required()
		.pattern(new RegExp('^(?=.*[a-z])(?=.*[A-Z])(?=.*d).{8,}$')),
});

exports.acceptFPCodeSchema = Joi.object({
	email: Joi.string()
		.min(6)
		.max(60)
		.required()
		.email({
			tlds: { allow: ['com', 'net'] },
		}),
	providedCode: Joi.number().required(), 
	newPassword: Joi.string()
		.required()
});

exports.createPostSchema = Joi.object({
	title: Joi.string().min(3).max(60).required(),
	description: Joi.string().min(3).max(600).required(),
	userId: Joi.string().required(),
});
