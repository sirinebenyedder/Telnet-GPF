const express = require('express');
const userController = require('../controllers/userController');
const {upload} = require('../utils/upload'); // Multer setup
const router = express.Router();
const User = require('../models/usersModel');
//const multer = require('multer');
const { identifier } = require('../middlewares/identification');
// Set up multer for file uploads
//const upload = multer({ dest: 'uploads/' });
router.post('/add',identifier, userController.addUser);
router.get('/profile',identifier, userController.singleProfile);
router.post('/upload',upload.single('image'), userController.uploadImage);
// le middleware  pour gérer image 
router.post('/update', upload.single('image'), userController.updateProfile);
router.get('/users',userController.fetchusers);
//update user
router.put('/modifier/:userId',userController.updateUser);

//fetchusersby role lil admin
router.get('/fetchusersbyrole',userController.fetchUsersByRole);
//fetch PM ta3 les RF 
router.get('/fetchpm', userController.fetchPmByRf);
const jwt = require('jsonwebtoken');

router.get('/check-reset-status',identifier,userController.checkpasswchange);

module.exports = router;