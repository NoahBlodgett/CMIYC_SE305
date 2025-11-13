const express = require('express');
const router = express.Router();
const weightGoalController = require('../controllers/weightGoalController');
const activityGoalController = require('../controllers/activityGoalController');
const { authenticate, authorizeUser, rateLimit } = require('../middleware/auth');

// ==================== WEIGHT GOAL ROUTES ====================

/**
 * POST /goals/weight
 * Create a new weight goal for a user
 * Requires: Authentication
 */
router.post('/:userID/goals/weight/:goalID',
  authenticate, 
  weightGoalController.createWeightGoal
);

/**
 * GET /goals/weight/:userID
 * Get weight goal for a specific user
 * Requires: Authentication + User must be accessing their own goal
 */
router.get('/:userID/goals/weight/:goalID', 
  authenticate, 
  authorizeUser, 
  weightGoalController.getWeightGoal
);

/**
 * PATCH /goals/weight/:userID
 * Update weight goal for a specific user
 * Requires: Authentication + User must be accessing their own goal
 * Rate limited: 5 requests per minute
 */
router.patch('/:userID/goals/weight/:goalID', 
  authenticate, 
  authorizeUser, 
  rateLimit(5, 60000), // 5 requests per 60 seconds
  weightGoalController.updateWeightGoal
);

/**
 * DELETE /goals/weight/:userID
 * Delete weight goal for a specific user
 * Requires: Authentication + User must be accessing their own goal
 * Rate limited: 3 requests per minute for safety
 */
router.delete('/:userID/goals/weight/:goalID', 
  authenticate, 
  authorizeUser,
  rateLimit(3, 60000), // 3 requests per 60 seconds
  weightGoalController.deleteWeightGoal
);

// Activity goals

/**
 * POST /goals/activity
 * Create a new activity goal for a user
 * Requires: Authentication
 */
router.post('/:userID/goals/activity/:goalID', 
  authenticate, 
  activityGoalController.createActivityGoal
);

/**
 * GET /goals/activity/:userID
 * Get all activity goals for a specific user
 * Requires: Authentication + User must be accessing their own goals
 */
router.get('/:userID/goals/activity/:goalID', 
  authenticate, 
  authorizeUser, 
  activityGoalController.getActivityGoal
);

/**
 * PATCH /goals/activity/:goalID
 * Update a specific activity goal by goalID
 * Requires: Authentication
 * Rate limited: 5 requests per minute
 */
router.patch('/:userID/goals/activity/:goalID', 
  authenticate, 
  rateLimit(5, 60000), // 5 requests per 60 seconds
  activityGoalController.updateActivityGoal
);

/**
 * DELETE /goals/activity/:goalID
 * Delete a specific activity goal by goalID
 * Requires: Authentication
 * Rate limited: 3 requests per minute for safety
 */
router.delete('/:userID/goals/activity/:goalID', 
  authenticate,
  rateLimit(3, 60000), // 3 requests per 60 seconds
  activityGoalController.deleteActivityGoal
);

module.exports = router;
