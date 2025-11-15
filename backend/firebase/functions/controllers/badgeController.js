const { UserBadges, BadgeTypes } = require('../models/Badges');
const badgeValidators = require('../utils/badgeValidators');
const { getFirestore } = require('firebase-admin/firestore');

// CREATE - Initialize user badges
async function createUserBadges(req, res)
{
    try
    {
        const { userID, earnedBadges = [], currentStreak = 0, longestStreak = 0 } = req.body;

        // Validate required fields
        if (!userID)
        {
            return res.status(400).json({
                error: 'Missing required field: userID'
            });
        }

        // Validate fields
        if (!badgeValidators.isValidUserID(userID))
        {
            return res.status(400).json({
                error: 'Invalid userID'
            });
        }

        if (!badgeValidators.isValidEarnedBadges(earnedBadges))
        {
            return res.status(400).json({
                error: 'Invalid earnedBadges array'
            });
        }

        if (!badgeValidators.isValidStreak(currentStreak) || !badgeValidators.isValidStreak(longestStreak))
        {
            return res.status(400).json({
                error: 'Invalid streak values'
            });
        }

        const db = getFirestore();

        // Check if user exists
        const userDoc = await db.collection('users').doc(userID).get();
        if (!userDoc.exists)
        {
            return res.status(404).json({
                error: 'User does not exist'
            });
        }

        // Check if user badges already exist
        const existingBadges = await db.collection('user_badges')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (!existingBadges.empty)
        {
            return res.status(409).json({
                error: 'User badges already exist'
            });
        }

        // Create UserBadges object
        const userBadges = new UserBadges(userID, earnedBadges, currentStreak, longestStreak);

        // Save to Firestore
        const badgesRef = await db.collection('user_badges').add(userBadges.toJSON());

        res.status(201).json({
            message: 'User badges created successfully',
            badges: userBadges.toJSON(),
            badgesID: badgesRef.id
        });
    }
    catch(e)
    {
        console.error('Error creating user badges:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// READ - Get user badges
async function getUserBadges(req, res)
{
    try
    {
        const { userID } = req.params;

        const db = getFirestore();

        // Find user badges by userID
        const badgesQuery = await db.collection('user_badges')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (badgesQuery.empty)
        {
            return res.status(404).json({
                error: 'User badges do not exist'
            });
        }

        const badgesDoc = badgesQuery.docs[0];
        const badgesData = badgesDoc.data();

        res.status(200).json({
            message: 'User badges found successfully',
            badges: badgesData,
            badgesID: badgesDoc.id
        });
    }
    catch(e)
    {
        console.error('Error finding user badges:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// UPDATE - Award a badge
async function awardBadge(req, res)
{
    try
    {
        const { userID } = req.params;
        const { badgeType } = req.body;

        // Validate badge type
        if (!badgeValidators.isValidBadgeType(badgeType))
        {
            return res.status(400).json({
                error: 'Invalid badge type'
            });
        }

        const db = getFirestore();

        // Find user badges
        const badgesQuery = await db.collection('user_badges')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (badgesQuery.empty)
        {
            return res.status(404).json({
                error: 'User badges do not exist'
            });
        }

        const badgesDoc = badgesQuery.docs[0];
        const badgesData = badgesDoc.data();

        // Create UserBadges object
        const userBadges = new UserBadges(
            badgesData.user_id,
            badgesData.earned_badges,
            badgesData.current_streak,
            badgesData.longest_streak
        );
        userBadges.setLastActivityDate(badgesData.last_activity_date);

        // Try to award badge
        const awarded = userBadges.awardBadge(badgeType);

        if (!awarded)
        {
            return res.status(409).json({
                error: 'User already has this badge'
            });
        }

        // Update Firestore
        await db.collection('user_badges').doc(badgesDoc.id).update({
            earned_badges: userBadges.getEarnedBadges(),
            badge_count: userBadges.getBadgeCount()
        });

        res.status(200).json({
            message: 'Badge awarded successfully',
            badges: userBadges.toJSON()
        });
    }
    catch(e)
    {
        console.error('Error awarding badge:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// UPDATE - Update streak
async function updateStreak(req, res)
{
    try
    {
        const { userID } = req.params;
        const { activityDate = new Date() } = req.body;

        const db = getFirestore();

        // Find user badges
        const badgesQuery = await db.collection('user_badges')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (badgesQuery.empty)
        {
            return res.status(404).json({
                error: 'User badges do not exist'
            });
        }

        const badgesDoc = badgesQuery.docs[0];
        const badgesData = badgesDoc.data();

        // Create UserBadges object
        const userBadges = new UserBadges(
            badgesData.user_id,
            badgesData.earned_badges,
            badgesData.current_streak,
            badgesData.longest_streak
        );
        userBadges.setLastActivityDate(badgesData.last_activity_date);

        // Update streak
        userBadges.updateStreak(activityDate);

        // Update Firestore
        await db.collection('user_badges').doc(badgesDoc.id).update({
            current_streak: userBadges.getCurrentStreak(),
            longest_streak: userBadges.getLongestStreak(),
            last_activity_date: userBadges.getLastActivityDate(),
            earned_badges: userBadges.getEarnedBadges(),
            badge_count: userBadges.getBadgeCount()
        });

        res.status(200).json({
            message: 'Streak updated successfully',
            badges: userBadges.toJSON()
        });
    }
    catch(e)
    {
        console.error('Error updating streak:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// DELETE - Remove user badges
async function deleteUserBadges(req, res)
{
    try
    {
        const { userID } = req.params;

        const db = getFirestore();

        // Find user badges
        const badgesQuery = await db.collection('user_badges')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (badgesQuery.empty)
        {
            return res.status(404).json({
                error: 'User badges do not exist'
            });
        }

        const badgesDoc = badgesQuery.docs[0];

        // Delete from Firestore
        await db.collection('user_badges').doc(badgesDoc.id).delete();

        res.status(200).json({
            message: 'User badges deleted successfully',
            badgesID: badgesDoc.id
        });
    }
    catch(e)
    {
        console.error('Error deleting user badges:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

module.exports = {
    createUserBadges,
    getUserBadges,
    awardBadge,
    updateStreak,
    deleteUserBadges
};
