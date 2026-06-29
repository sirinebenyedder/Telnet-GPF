const express = require('express');
const router = express.Router();
const projectController = require('../controllers/projectController');
const { identifier } = require('../middlewares/identification');
//fonction de RF 
router.get('/project',identifier,projectController.getAllProjectsWithManager);//hethi traja3 tous les projets 
//fonction de PM 
router.get('/:id/pmproject',projectController.getProjectsByManagerId);
//// 
router.get('/getcurrentprject',projectController.getCurrentProject);
router.put('/modifycurrentproject',identifier,projectController.setCurrentProject)
//currency and coountry
router.get('/getcurrencypay',projectController.getcurrentdevisepays);
router.get('/countries',projectController.fetchcountries);
// ta3 update project ta3 status 
router.put('/projetupdate/:id',projectController.update)
//ta3 fetch Pagination
router.get('/projetcfetchpagination/:id/pmproject',projectController.getProjectsByManagerIdPagination),
router.get('/projectPagination',identifier,projectController.getAllProjectsWithManagerPagination);
// Route pour calculer le total des factures d'un projet avec la devise du projet
router.get('/:projectId/invoice-total', identifier, projectController.calculateProjectInvoiceTotal);
router.get('/viewby', identifier,projectController.getViewableProjects);
// Route pour mettre à jour tous les totaux des factures (pour un cron job)
//router.post('/update-invoice-totals', identifier, projectController.updateAllProjectInvoiceTotals);
//dashboard
router.get('/fetchiliprojet/:projectId?',identifier,projectController.fetchiliproject);
router.get('/dashboardState', projectController.getDashboardStats);
router.get('/getMonthlyInvoiceStats' , projectController.getMonthlyInvoiceStats);
router.get('/dailyStats' ,projectController.dailyStats);
router.get('/global-top-items',projectController.fetchtop5item);
module.exports = router;