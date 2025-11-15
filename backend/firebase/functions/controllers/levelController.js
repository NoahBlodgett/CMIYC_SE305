const { UserLevel, LEVEL_THRESHOLDS } = require('../models/Level');
const levelValidators = require('../utils/levelValidators');
const { getFirestore } = require('firebase-admin/firestore');

// CREATE - Initialize user level
async function createUserLevel(req, res)
{
    try
    {
        const { userID, currentXP = 0, currentLevel = 1 } = req.body;

        // Validate required fields
        if (!userID)
        {
            return res.status(400).json({
                error: 'Missing required field: userID'
            });
        }

        // Validate fields
        if (!levelValidators.isValidUserID(userID))
        {
            return res.status(400).json({
                error: 'Invalid userID'
            });
        }

        if (!levelValidators.isValidXP(currentXP))
        {
            return res.status(400).json({
                error: 'Invalid currentXP'
            });
        }

        if (!levelValidators.isValidLevel(currentLevel))
        {
            return res.status(400).json({
                error: 'Invalid currentLevel'
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

        // Check if user level already exists
        const existingLevel = await db.collection('user_levels')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (!existingLevel.empty)
        {
            return res.status(409).json({
                error: 'User level already exists'
            });
        }

        // Create UserLevel object
        const userLevel = new UserLevel(userID, currentXP, currentLevel);

        // Save to Firestore
        const levelRef = await db.collection('user_levels').add(userLevel.toJSON());

        res.status(201).json({
            message: 'User level created successfully',
            level: userLevel.toJSON(),
            levelID: levelRef.id
        });
    }
    catch(e)
    {
        console.error('Error creating user level:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// READ - Get user level
async function getUserLevel(req, res)
{
    try
    {
        const { userID } = req.params;

        const db = getFirestore();

        // Find user level by userID
        const levelQuery = await db.collection('user_levels')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (levelQuery.empty)
        {
            return res.status(404).json({
                error: 'User level does not exist'
            });
        }

        const levelDoc = levelQuery.docs[0];
        const levelData = levelDoc.data();

        res.status(200).json({
            message: 'User level found successfully',
            level: levelData,
            levelID: levelDoc.id
        });
    }
    catch(e)
    {
        console.error('Error finding user level:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// UPDATE - Add XP to user
async function addXP(req, res)
{
    try
    {
        const { userID } = req.params;
        const { amount } = req.body;

        // Validate XP amount
        if (!levelValidators.isValidXPAmount(amount))
        {
            return res.status(400).json({
                error: 'Invalid XP amount. Must be a positive integer between 1 and 10000'
            });
        }

        const db = getFirestore();

        // Find user level document reference
        const levelQuerySnapshot = await db.collection('user_levels')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (levelQuerySnapshot.empty)
        {
            return res.status(404).json({
                error: 'User level does not exist'
            });
        }

        const levelDocRef = levelQuerySnapshot.docs[0].ref;

        // Use transaction to prevent race conditions
        const result = await db.runTransaction(async (transaction) => {
            const levelDoc = await transaction.get(levelDocRef);

            if (!levelDoc.exists) {
                throw new Error('User level does not exist');
            }

            const levelData = levelDoc.data();

            // Create UserLevel object from data
            const userLevel = new UserLevel(
                levelData.user_id,
                levelData.current_xp,
                levelData.current_level
            );

            const oldLevel = userLevel.getCurrentLevel();

            // Add XP (this will auto-level up if needed)
            userLevel.addXP(amount);

            // Update Firestore within transaction
            transaction.update(levelDocRef, {
                current_xp: userLevel.getCurrentXP(),
                current_level: userLevel.getCurrentLevel(),
                xp_to_next_level: userLevel.getXPToNextLevel(),
                progress_percentage: userLevel.getProgressToNextLevel()
            });

            return {
                levelData: userLevel.toJSON(),
                leveledUp: userLevel.getCurrentLevel() > oldLevel
            };
        });

        res.status(200).json({
            message: 'XP added successfully',
            level: result.levelData,
            leveledUp: result.leveledUp
        });
    }
    catch(e)
    {
        console.error('Error adding XP:', e);
        
        if (e.message === 'User level does not exist') {
            return res.status(404).json({
                error: 'User level does not exist'
            });
        }
        
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// UPDATE - Manually update level data
async function updateUserLevel(req, res)
{
    try
    {
        const { userID } = req.params;
        const { currentXP, currentLevel } = req.body;

        const db = getFirestore();

        // Find user level
        const levelQuery = await db.collection('user_levels')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (levelQuery.empty)
        {
            return res.status(404).json({
                error: 'User level does not exist'
            });
        }

        const levelDoc = levelQuery.docs[0];
        const updates = {};

        // Validate and update XP if provided
        if (currentXP !== undefined)
        {
            if (!levelValidators.isValidXP(currentXP))
            {
                return res.status(400).json({
                    error: 'Invalid XP value'
                });
            }
            updates.current_xp = currentXP;
        }

        // Validate and update level if provided
        if (currentLevel !== undefined)
        {
            if (!levelValidators.isValidLevel(currentLevel))
            {
                return res.status(400).json({
                    error: 'Invalid level value'
                });
            }
            updates.current_level = currentLevel;
        }

        if (Object.keys(updates).length === 0)
        {
            return res.status(400).json({
                error: 'No valid fields provided for update'
            });
        }

        // Update Firestore
        await db.collection('user_levels').doc(levelDoc.id).update(updates);

        // Get updated data
        const updatedDoc = await db.collection('user_levels').doc(levelDoc.id).get();
        const updatedData = updatedDoc.data();

        // Recreate UserLevel to get calculated fields
        const userLevel = new UserLevel(
            updatedData.user_id,
            updatedData.current_xp,
            updatedData.current_level
        );

        res.status(200).json({
            message: 'User level updated successfully',
            level: userLevel.toJSON()
        });
    }
    catch(e)
    {
        console.error('Error updating user level:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// DELETE - Remove user level
async function deleteUserLevel(req, res)
{
    try
    {
        const { userID } = req.params;

        const db = getFirestore();

        // Find user level
        const levelQuery = await db.collection('user_levels')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (levelQuery.empty)
        {
            return res.status(404).json({
                error: 'User level does not exist'
            });
        }

        const levelDoc = levelQuery.docs[0];

        // Delete from Firestore
        await db.collection('user_levels').doc(levelDoc.id).delete();

        res.status(200).json({
            message: 'User level deleted successfully',
            levelID: levelDoc.id
        });
    }
    catch(e)
    {
        console.error('Error deleting user level:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

module.exports = {
    createUserLevel,
    getUserLevel,
    addXP,
    updateUserLevel,
    deleteUserLevel
};
