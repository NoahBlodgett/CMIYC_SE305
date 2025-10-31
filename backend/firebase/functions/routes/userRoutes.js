const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate, authorizeUser, rateLimit } = require('../middleware/auth');

/**
 * POST /users
 * Create a new user account
 * Public endpoint - no authentication required
 */
router.post('/', userController.createUser);

/**
 * GET /users/:userID
 * Get user information
 * Requires: Authentication + User must be accessing their own account
 */
router.get('/:userID', 
  authenticate, 
  authorizeUser, 
  userController.getUser
);

/**
 * PATCH /users/:userID
 * Update user information
 * Requires: Authentication + User must be accessing their own account
 * Rate limited: 5 requests per minute to prevent abuse
 */
router.patch('/:userID', 
  authenticate, 
  authorizeUser, 
  rateLimit(5, 60000), // 5 requests per 60 seconds
  userController.updateUser
);

/**
 * DELETE /users/:userID
 * Delete user account
 * Requires: Authentication + User must be accessing their own account
 * Rate limited: 3 requests per minute for safety
 */
router.delete('/:userID', 
  authenticate, 
  authorizeUser,
  rateLimit(3, 60000), // 3 requests per 60 seconds
  userController.deleteUser
);

module.exports = router;
