const express = require('express');
const router = express.Router();
const workoutController = require('../controllers/workoutController');
const { authenticate, authorizeUser, rateLimit } = require('../middleware/auth');

/**
 * POST /workouts
 * Create a new workout log entry
 * Requires: Authentication + User must be logged in
 * Rate limited: 10 requests per minute
 */
router.post('/workouts',
  authenticate,
  rateLimit(10, 60000), // 10 requests per 60 seconds
  workoutController.createWorkout
);

/**
 * GET /workouts/:workoutID
 * Get a specific workout log entry
 * Requires: Authentication + User must own the workout entry
 */
router.get('/workouts/:workoutID',
  authenticate,
  workoutController.getWorkout
);

/**
 * GET /workouts/user/:userID
 * Get all workout logs for a specific user
 * Requires: Authentication + User must be accessing their own workouts
 */
router.get('/workouts/user/:userID',
  authenticate,
  authorizeUser,
  workoutController.getUserWorkouts
);

/**
 * PATCH /workouts/:workoutID
 * Update a workout log entry
 * Requires: Authentication + User must own the workout entry
 * Rate limited: 5 requests per minute to prevent abuse
 */
router.patch('/workouts/:workoutID',
  authenticate,
  rateLimit(5, 60000), // 5 requests per 60 seconds
  workoutController.updateWorkout
);

/**
 * DELETE /workouts/:workoutID
 * Delete a workout log entry
 * Requires: Authentication + User must own the workout entry
 * Rate limited: 3 requests per minute for safety
 */
router.delete('/workouts/:workoutID',
  authenticate,
  rateLimit(3, 60000), // 3 requests per 60 seconds
  workoutController.deleteWorkout
);

module.exports = router;
