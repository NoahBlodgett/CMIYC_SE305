const { WeightGoal, Weight_Objectives } = require('../models/WeightGoals');
const goalValidators = require('../utils/goalValidators');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// CREATE
async function createWeightGoal(req, res)
{
    try
    {
        const {
            userID,
            weight_objective,
            goal_weight,
            finish_date
        } = req.body;

        // Validate required fields
        if (!userID || !weight_objective || goal_weight === undefined || !finish_date)
        {
            return res.status(400).json({
                error: 'Missing required fields: userID, weight_objective, goal_weight, finish_date'
            });
        }

        // Validate weight objective
        if (!goalValidators.isValidWeightObjective(weight_objective))
        {
            return res.status(400).json({
                error: 'Invalid weight_objective. Must be one of: LOSE_WEIGHT, GAIN_WEIGHT, MAINTAIN_WEIGHT'
            });
        }

        // Validate goal weight
        const parsedGoalWeight = parseFloat(goal_weight);
        if (!goalValidators.isValidGoalWeight(parsedGoalWeight))
        {
            return res.status(400).json({
                error: 'Invalid goal_weight'
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

        // Check if user already has a weight goal
        const existingGoal = await db.collection('weight_goals')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (!existingGoal.empty)
        {
            return res.status(409).json({
                error: 'User already has a weight goal. Update or delete the existing goal first.'
            });
        }

        // Create WeightGoal object
        const newWeightGoal = new WeightGoal(userID, weight_objective, parsedGoalWeight, finish_date);

        // Save to Firestore
        const goalRef = await db.collection('weight_goals').add(newWeightGoal.toJSON());

        // Return success response
        res.status(201).json({
            message: 'Weight goal created successfully',
            goal: newWeightGoal.toJSON(),
            goalID: goalRef.id
        });
    }
    catch(e)
    {
        console.error('Error creating weight goal:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// RETRIEVE
async function getWeightGoal(req, res)
{
    try
    {
        const { userID } = req.params;

        const db = getFirestore();

        // Find weight goal by userID
        const goalQuery = await db.collection('weight_goals')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (goalQuery.empty)
        {
            return res.status(404).json({
                error: 'Weight goal does not exist for this user'
            });
        }

        // Get the goal data
        const goalDoc = goalQuery.docs[0];
        const goalData = goalDoc.data();

        // Send the weight goal information back to the frontend
        res.status(200).json({
            message: 'Weight goal found successfully',
            goal: goalData,
            goalID: goalDoc.id
        });
    }
    catch(e)
    {
        console.error('Error finding weight goal:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// UPDATE
async function updateWeightGoal(req, res)
{
    try
    {
        const { userID } = req.params;

        const {
            weight_objective,
            goal_weight,
            finish_date
        } = req.body;

        const db = getFirestore();

        // Find the weight goal document
        const goalQuery = await db.collection('weight_goals')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (goalQuery.empty)
        {
            return res.status(404).json({
                error: 'Weight goal does not exist for this user'
            });
        }

        const goalDoc = goalQuery.docs[0];
        const updates = {};

        // Update fields only if provided and valid
        if (weight_objective !== undefined && goalValidators.isValidWeightObjective(weight_objective))
        {
            updates.weight_objective = weight_objective;
        }

        if (goal_weight !== undefined && goalValidators.isValidGoalWeight(parseFloat(goal_weight)))
        {
            updates.goal_weight = parseFloat(goal_weight);
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
        await db.collection('weight_goals').doc(goalDoc.id).update(updates);

        // Get updated goal data
        const updatedGoalDoc = await db.collection('weight_goals').doc(goalDoc.id).get();

        res.status(200).json({
            message: 'Weight goal updated successfully',
            goal: updatedGoalDoc.data(),
            goalID: goalDoc.id
        });
    }
    catch(e)
    {
        console.error('Error updating weight goal:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

// DELETE
async function deleteWeightGoal(req, res)
{
    try
    {
        const { userID } = req.params;

        const db = getFirestore();

        // Find the weight goal document
        const goalQuery = await db.collection('weight_goals')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (goalQuery.empty)
        {
            return res.status(404).json({
                error: 'Weight goal does not exist for this user'
            });
        }

        const goalDoc = goalQuery.docs[0];

        // Delete from Firestore
        await db.collection('weight_goals').doc(goalDoc.id).delete();

        res.status(200).json({
            message: 'Weight goal deleted successfully',
            goalID: goalDoc.id
        });
    }
    catch(e)
    {
        console.error('Error deleting weight goal:', e);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
}

module.exports = {
    createWeightGoal,
    getWeightGoal,
    updateWeightGoal,
    deleteWeightGoal
};