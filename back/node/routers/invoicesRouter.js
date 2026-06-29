const express = require('express');
const invoicesController = require('../controllers/invoicesController');
const { identifier } = require('../middlewares/identification');
const {uploadInvoice , uploadDefInvoice} = require('../utils/upload'); // Multer setup
const router = express.Router();
   
/*router.get('/all-posts', invoicesController.getPosts);
router.get('/single-post', invoicesController.singlePost);
router.post('/create-post', identifier, invoicesController.createPost);

//router.put('/update-post', identifier, invoicesController.updatePost);
//router.delete('/delete-post', identifier, invoicesController.deletePost);*/
router.post('/process-invoice',uploadInvoice.single('image'), invoicesController.uploadFactures);
router.post('/save-invoice',invoicesController.saveInvoice);
router.post('/delete-temp-image',invoicesController.deleteTempImage);
router.get('/fetch_invoices',invoicesController.fetchinvoices);
router.post('/add-project',invoicesController.createProject);
router.get('/:projectId/currenciesperproject',invoicesController.fetchingallcurrenciesperpproject);
//fetch une facture
router.get('/getinvioce/:id',invoicesController.getinvoice)

router.put('/updateinvoice/:factureId',uploadInvoice.single('image'),invoicesController.updateFacture);
///////////suppression des factures
router.delete('/:id',invoicesController.deleteFacture);
router.delete('/',invoicesController.deleteMultipleFactures);
module.exports = router;
