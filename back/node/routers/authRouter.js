const express = require('express');
const authController = require('../controllers/authController');
const { identifier } = require('../middlewares/identification');
const router = express.Router();

//router.post('/add', authController.addUser);
router.post('/signin', authController.signin);
router.post('/signout', identifier, authController.signout);
router.post('/google', authController.googleSignIn); //  Google Sign-In

router.patch('/change-password', identifier, authController.changePassword);
router.patch(
	'/send-forgot-password-code',
	authController.sendForgotPasswordCode
);
router.patch(
	'/verify-forgot-password-code',
	authController.verifyForgotPasswordCode
);
router.patch('/verify-code', authController.verifyCode);
module.exports = router;
