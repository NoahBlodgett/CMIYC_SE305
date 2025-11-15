const express = require('express');
const router = express.Router();
const milestoneController = require('../controllers/milestoneController');
const { authenticate, authorizeUser, requireAdmin, rateLimit } = require('../middleware/auth');

/**
 * POST /milestones
 * Create a milestone
 * Requires: Authentication + User must be creating their own milestone
 */
router.post('/milestones', 
  authenticate,
  milestoneController.createMilestone
);

/**
 * GET /milestones/:milestoneID
 * Get milestone by ID
 * Requires: Authentication
 */
router.get('/milestones/:milestoneID', 
  authenticate, 
  milestoneController.getMilestone
);

/**
 * GET /milestones/user/:userID
 * Get all milestones for a user
 * Requires: Authentication + User must be accessing their own milestones
 */
router.get('/milestones/user/:userID', 
  authenticate, 
  authorizeUser, 
  milestoneController.getUserMilestones
);

/**
 * PATCH /milestones/:milestoneID/progress
 * Add to milestone progress
 * Requires: Authentication
 * Rate limited to prevent abuse
 */
router.patch('/milestones/:milestoneID/progress', 
  authenticate,
  rateLimit(30, 60000), // 30 requests per minute
  milestoneController.updateMilestoneProgress
);

/**
 * PUT /milestones/:milestoneID/progress
 * Set milestone progress to a specific value
 * Requires: Authentication
 */
router.put('/milestones/:milestoneID/progress', 
  authenticate,
  milestoneController.setMilestoneProgress
);

/**
 * DELETE /milestones/:milestoneID
 * Delete a milestone
 * Requires: Authentication + Admin privileges
 */
router.delete('/milestones/:milestoneID', 
  authenticate,
  requireAdmin,
  milestoneController.deleteMilestone
);

module.exports = router;
