const express = require('express');
const router = express.Router();
const badgeController = require('../controllers/badgeController');
const { authenticate, authorizeUser, requireAdmin, rateLimit } = require('../middleware/auth');

/**
 * POST /badges
 * Create user badges for a user
 * Requires: Authentication + Admin privileges
 */
router.post('/badges', 
  authenticate,
  requireAdmin,
  badgeController.createUserBadges
);

/**
 * GET /badges/:userID
 * Get user badges
 * Requires: Authentication + User must be accessing their own badges
 */
router.get('/badges/:userID', 
  authenticate, 
  authorizeUser, 
  badgeController.getUserBadges
);

/**
 * POST /badges/:userID/award
 * Award a badge to a user
 * Requires: Authentication + Admin privileges
 * Note: Badge awarding should ideally be server-side computed from events
 * This endpoint is for admin override purposes only
 */
router.post('/badges/:userID/award', 
  authenticate,
  requireAdmin,
  rateLimit(10, 60000), // 10 requests per minute
  badgeController.awardBadge
);

/**
 * PATCH /badges/:userID/streak
 * Update user streak
 * Requires: Authentication + User must be accessing their own badges
 * Rate limited to prevent abuse
 */
router.patch('/badges/:userID/streak', 
  authenticate, 
  authorizeUser,
  rateLimit(20, 60000), // 20 requests per minute
  badgeController.updateStreak
);

/**
 * DELETE /badges/:userID
 * Delete user badges
 * Requires: Authentication + Admin privileges
 */
router.delete('/badges/:userID', 
  authenticate,
  requireAdmin,
  badgeController.deleteUserBadges
);

module.exports = router;
