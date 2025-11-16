const express = require('express');
const router = express.Router();
const { authenticate, authorizeUser, rateLimit } = require('../middleware/auth');

router.post('/:userID/generateWeekPlan', 
    authenticate);
