const { ActivityGoals, ActiveGoals } = require('../models/ActivityGoals');
const goalValidators = require('../utils/goalValidators');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// CREATE
async function createActivityGoal(req, res)
{
    try
    {
        const {
            userID,
            active_goal,
            finish_date
        } = req.body;

        // Validate required fields
        if (!userID || !active_goal || !finish_date)
        {
            return res.status(400).json({
                error: 'Missing required fields: userID, active_goal, finish_date'
            });
        }

        // Validate active goal
        if (!goalValidators.isValidActiveGoal(active_goal))
        {
            return res.status(400).json({
                error: 'Invalid active_goal. Must be one of: WALK_STEPS, DO_WORKOUTS, EAT_HEALTHY'
            });
        }

        // Validate finish date
        if (!goalValidators.isValidFinishDate(finish_date))
        {
            return res.status(400).json({
                error: 'Invalid finish_date. Must be a future date'
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

        // Check if user already has this type of activity goal
        const existingGoal = await db.collection('activity_goals')
            .where('user_id', '==', userID)
            .where('activity_goal', '==', active_goal)
            .limit(1)
            .get();

        if (!existingGoal.empty)
        {
            return res.status(409).json({
                error: 'User already has this type of activity goal. Update or delete the existing goal first.'
            });
        }

        // Create ActivityGoals object
        const goalRef = await db.collection('activity_goals').add({});
        const goalID = goalRef.id;
        
        const newActivityGoal = new ActivityGoals(userID, goalID, active_goal, finish_date);

        // Update the document with the complete goal data
        await goalRef.set(newActivityGoal.toJSON());

        // Return success response
        res.status(201).json({
            message: 'Activity goal created successfully',
            goal: newActivityGoal.toJSON(),
            goalID: goalID
        });
    }
    catch(e)
    {
        console.error('Error creating activity goal:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// RETRIEVE
async function getActivityGoal(req, res)
{
    try
    {
        const { userID } = req.params;

        const db = getFirestore();

        // Find all activity goals for this user
        const goalQuery = await db.collection('activity_goals')
            .where('user_id', '==', userID)
            .get();

        if (goalQuery.empty)
        {
            return res.status(404).json({
                error: 'No activity goals found for this user'
            });
        }

        // Get all goal data
        const goals = goalQuery.docs.map(doc => ({
            goalID: doc.id,
            ...doc.data()
        }));

        // Send the activity goals back to the frontend
        res.status(200).json({
            message: 'Activity goals found successfully',
            goals: goals
        });
    }
    catch(e)
    {
        console.error('Error finding activity goals:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// UPDATE
async function updateActivityGoal(req, res)
{
    try
    {
        const { goalID } = req.params;

        const {
            active_goal,
            finish_date
        } = req.body;

        const db = getFirestore();

        // Find the activity goal document by goalID
        const goalDoc = await db.collection('activity_goals').doc(goalID).get();

        if (!goalDoc.exists)
        {
            return res.status(404).json({
                error: 'Activity goal does not exist'
            });
        }

        const updates = {};

        // Update fields only if provided and valid
        if (active_goal !== undefined && goalValidators.isValidActiveGoal(active_goal))
        {
            updates.activity_goal = active_goal;
        }

        if (finish_date !== undefined && goalValidators.isValidFinishDate(finish_date))
        {
            updates.finish_date = finish_date;
        }

        // Check if there are any updates to make
        if (Object.keys(updates).length === 0)
        {
            return res.status(400).json({
                error: 'No valid fields provided for update'
            });
        }

        // Update Firestore
        await db.collection('activity_goals').doc(goalID).update(updates);

        // Get updated goal data
        const updatedGoalDoc = await db.collection('activity_goals').doc(goalID).get();

        res.status(200).json({
            message: 'Activity goal updated successfully',
            goal: updatedGoalDoc.data(),
            goalID: goalID
        });
    }
    catch(e)
    {
        console.error('Error updating activity goal:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// DELETE
async function deleteActivityGoal(req, res)
{
    try
    {
        const { goalID } = req.params;

        const db = getFirestore();

        // Check if activity goal exists
        const goalDoc = await db.collection('activity_goals').doc(goalID).get();

        if (!goalDoc.exists)
        {
            return res.status(404).json({
                error: 'Activity goal does not exist'
            });
        }

        // Delete from Firestore
        await db.collection('activity_goals').doc(goalID).delete();

        res.status(200).json({
            message: 'Activity goal deleted successfully',
            goalID: goalID
        });
    }
    catch(e)
    {
        console.error('Error deleting activity goal:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

module.exports = {
    createActivityGoal,
    getActivityGoal,
    updateActivityGoal,
    deleteActivityGoal
};