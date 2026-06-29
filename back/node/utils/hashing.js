const { createHmac } = require('crypto');
const { hash, compare } = require('bcryptjs');
const crypto = require('crypto');
exports.doHash = (value, saltValue) => {
	const result = hash(value, saltValue);
	return result;
};

exports.doHashValidation = (value, hashedValue) => {
	const result = compare(value, hashedValue);
	return result;
};

exports.hmacProcess = (value, key) => {
	const result = createHmac('sha256', key).update(value).digest('hex');
	return result;
};
exports.generatePassword=(length = 10) => {
	const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()';
	const charsLength = chars.length;
	const randomBytes = crypto.randomBytes(length);
  
	let password = '';
	for (let i = 0; i < length; i++) {
	  password += chars[randomBytes[i] % charsLength];
	}
  
	return password;
  }
