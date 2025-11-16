const express = require('express');
const router = express.Router();
const { authenticate, authorizeUser, rateLimit } = require('../middleware/auth');
const { createWeekPlan } = require('../controllers/mealPlanController');

// Route to generate a weekly meal plan
router.post('/:userID/generateWeekPlan', 
    authenticate,
    createWeekPlan
);

module.exports = router;
