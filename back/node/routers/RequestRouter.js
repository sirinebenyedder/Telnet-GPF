const express = require('express');
const router = express.Router();
const { identifier } = require('../middlewares/identification');
const budgetRequestController = require('../controllers/RequestsControllers');
router.post('/request',identifier,budgetRequestController.createRequest);
router.patch('/:id/respond',budgetRequestController.respondToRequest);
router.get('/getcolleague',identifier,budgetRequestController.getColleagueProjects);
module.exports = router;