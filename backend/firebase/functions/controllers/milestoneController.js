const { Milestone, MilestoneTypes } = require('../models/Milestones');
const milestoneValidators = require('../utils/milestonesValidators');
const { getFirestore } = require('firebase-admin/firestore');

// CREATE - Create a milestone
async function createMilestone(req, res)
{
    try
    {
        const {
            userID,
            milestoneType,
            targetValue,
            currentValue = 0
        } = req.body;

        // Validate required fields
        if (!userID || !milestoneType || targetValue === undefined)
        {
            return res.status(400).json({
                error: 'Missing required fields: userID, milestoneType, targetValue'
            });
        }

        // Validate milestone data
        if (!milestoneValidators.isValidMilestoneData({ userID, milestoneType, targetValue, currentValue }))
        {
            return res.status(400).json({
                error: 'Invalid milestone data'
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

        // Create milestone with auto-generated ID
        const milestoneRef = await db.collection('milestones').add({});
        const milestoneID = milestoneRef.id;

        // Create Milestone object
        const milestone = new Milestone(milestoneID, userID, milestoneType, targetValue, currentValue);

        // Update with complete data
        await milestoneRef.set(milestone.toJSON());

        res.status(201).json({
            message: 'Milestone created successfully',
            milestone: milestone.toJSON(),
            milestoneID: milestoneID
        });
    }
    catch(e)
    {
        console.error('Error creating milestone:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// READ - Get milestone by ID
async function getMilestone(req, res)
{
    try
    {
        const { milestoneID } = req.params;

        const db = getFirestore();

        // Get milestone by ID
        const milestoneDoc = await db.collection('milestones').doc(milestoneID).get();

        if (!milestoneDoc.exists)
        {
            return res.status(404).json({
                error: 'Milestone does not exist'
            });
        }

        const milestoneData = milestoneDoc.data();

        res.status(200).json({
            message: 'Milestone found successfully',
            milestone: milestoneData
        });
    }
    catch(e)
    {
        console.error('Error finding milestone:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// READ - Get all milestones for a user
async function getUserMilestones(req, res)
{
    try
    {
        const { userID } = req.params;

        const db = getFirestore();

        // Find all milestones for user
        const milestonesQuery = await db.collection('milestones')
            .where('user_id', '==', userID)
            .get();

        if (milestonesQuery.empty)
        {
            return res.status(404).json({
                error: 'No milestones found for this user'
            });
        }

        // Get all milestone data
        const milestones = milestonesQuery.docs.map(doc => ({
            milestoneID: doc.id,
            ...doc.data()
        }));

        res.status(200).json({
            message: 'Milestones found successfully',
            milestones: milestones,
            count: milestones.length
        });
    }
    catch(e)
    {
        console.error('Error finding milestones:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// UPDATE - Update milestone progress
async function updateMilestoneProgress(req, res)
{
    try
    {
        const { milestoneID } = req.params;
        const { amount } = req.body;

        // Validate progress amount
        if (!milestoneValidators.isValidProgressAmount(amount))
        {
            return res.status(400).json({
                error: 'Invalid progress amount'
            });
        }

        const db = getFirestore();

        // Get milestone
        const milestoneDoc = await db.collection('milestones').doc(milestoneID).get();

        if (!milestoneDoc.exists)
        {
            return res.status(404).json({
                error: 'Milestone does not exist'
            });
        }

        const milestoneData = milestoneDoc.data();

        // Create Milestone object
        const milestone = new Milestone(
            milestoneData.milestone_id,
            milestoneData.user_id,
            milestoneData.milestone_type,
            milestoneData.target_value,
            milestoneData.current_value,
            milestoneData.is_completed,
            milestoneData.completed_date
        );
        milestone.setCreatedDate(milestoneData.created_date);

        // Add progress
        milestone.addProgress(amount);

        // Update Firestore
        await db.collection('milestones').doc(milestoneID).update({
            current_value: milestone.getCurrentValue(),
            is_completed: milestone.getIsCompleted(),
            completed_date: milestone.getCompletedDate(),
            progress_percentage: milestone.getProgress(),
            remaining: milestone.getRemaining()
        });

        res.status(200).json({
            message: 'Milestone progress updated successfully',
            milestone: milestone.toJSON(),
            completed: milestone.getIsCompleted()
        });
    }
    catch(e)
    {
        console.error('Error updating milestone progress:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// UPDATE - Set milestone progress
async function setMilestoneProgress(req, res)
{
    try
    {
        const { milestoneID } = req.params;
        const { newValue } = req.body;

        // Validate new value
        if (!milestoneValidators.isValidCurrentValue(newValue))
        {
            return res.status(400).json({
                error: 'Invalid progress value'
            });
        }

        const db = getFirestore();

        // Get milestone
        const milestoneDoc = await db.collection('milestones').doc(milestoneID).get();

        if (!milestoneDoc.exists)
        {
            return res.status(404).json({
                error: 'Milestone does not exist'
            });
        }

        const milestoneData = milestoneDoc.data();

        // Create Milestone object
        const milestone = new Milestone(
            milestoneData.milestone_id,
            milestoneData.user_id,
            milestoneData.milestone_type,
            milestoneData.target_value,
            milestoneData.current_value,
            milestoneData.is_completed,
            milestoneData.completed_date
        );
        milestone.setCreatedDate(milestoneData.created_date);

        // Update progress
        milestone.updateProgress(newValue);

        // Update Firestore
        await db.collection('milestones').doc(milestoneID).update({
            current_value: milestone.getCurrentValue(),
            is_completed: milestone.getIsCompleted(),
            completed_date: milestone.getCompletedDate(),
            progress_percentage: milestone.getProgress(),
            remaining: milestone.getRemaining()
        });

        res.status(200).json({
            message: 'Milestone progress set successfully',
            milestone: milestone.toJSON(),
            completed: milestone.getIsCompleted()
        });
    }
    catch(e)
    {
        console.error('Error setting milestone progress:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// DELETE - Delete milestone
async function deleteMilestone(req, res)
{
    try
    {
        const { milestoneID } = req.params;

        const db = getFirestore();

        // Check if milestone exists
        const milestoneDoc = await db.collection('milestones').doc(milestoneID).get();

        if (!milestoneDoc.exists)
        {
            return res.status(404).json({
                error: 'Milestone does not exist'
            });
        }

        // Delete from Firestore
        await db.collection('milestones').doc(milestoneID).delete();

        res.status(200).json({
            message: 'Milestone deleted successfully',
            milestoneID: milestoneID
        });
    }
    catch(e)
    {
        console.error('Error deleting milestone:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

module.exports = {
    createMilestone,
    getMilestone,
    getUserMilestones,
    updateMilestoneProgress,
    setMilestoneProgress,
    deleteMilestone
};
