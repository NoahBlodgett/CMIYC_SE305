const express = require('express');
const router = express.Router();
const levelController = require('../controllers/levelController');
const { authenticate, authorizeUser, requireAdmin, rateLimit } = require('../middleware/auth');

/**
 * POST /levels
 * Create user level for a user
 * Requires: Authentication + Admin privileges
 */
router.post('/levels', 
  authenticate,
  requireAdmin,
  levelController.createUserLevel
);

/**
 * GET /levels/:userID
 * Get user level
 * Requires: Authentication + User must be accessing their own level
 */
router.get('/levels/:userID', 
  authenticate, 
  authorizeUser, 
  levelController.getUserLevel
);

/**
 * POST /levels/:userID/xp
 * Add XP to user
 * Requires: Authentication + User must be accessing their own level
 * Rate limited to prevent abuse
 */
router.post('/levels/:userID/xp', 
  authenticate, 
  authorizeUser,
  rateLimit(20, 60000), // 20 requests per minute
  levelController.addXP
);

/**
 * PATCH /levels/:userID
 * Manually update user level data
 * Requires: Authentication + Admin privileges
 */
router.patch('/levels/:userID', 
  authenticate,
  requireAdmin,
  levelController.updateUserLevel
);

/**
 * DELETE /levels/:userID
 * Delete user level
 * Requires: Authentication + Admin privileges
 */
router.delete('/levels/:userID', 
  authenticate,
  requireAdmin,
  levelController.deleteUserLevel
);

module.exports = router;
