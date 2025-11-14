const WorkoutLog = require('../models/WorkoutLog');
const validators = require('../utils/workoutValidators');
const { getFirestore } = require('firebase-admin/firestore');

/**
 * Create a new workout log entry
 */
async function createWorkout(req, res) 
{
    try {
        const {
            user_id,
            duration,
            cals_burned,
            date,
            weight_lifted,
            movement
        } = req.body;

        // Validate required fields
        if (!user_id || duration === undefined || cals_burned === undefined || !date || weight_lifted === undefined) 
        {
            return res.status(400).json({
                error: 'Missing required fields: user_id, duration, cals_burned, date, weight_lifted'
            });
        }

        // Validate user_id
        if (!validators.isValidUserID(user_id)) 
        {
            return res.status(400).json({
                error: 'Invalid user_id'
            });
        }

        // Validate duration
        if (!validators.isValidDuration(duration)) 
        {
            return res.status(400).json({
                error: 'Invalid duration: must be a positive number'
            });
        }

        // Validate calories burned
        if (!validators.isvalidcalsburned(cals_burned)) 
        {
            return res.status(400).json({
                error: 'Invalid calories burned: must be a positive number'
            });
        }

        // Validate date
        if (!validators.isValidDate(date)) 
        {
            return res.status(400).json(
            {
                error: 'Invalid date'
            });
        }

        // Validate weight lifted
        if (!validators.isvalidweightlifted(weight_lifted)) 
        {
            return res.status(400).json(
            {
                error: 'Invalid weight lifted: must be a positive number'
            });
        }

        // Validate movement if provided
        if (movement && !validators.isvalidmovement(movement)) {
            return res.status(400).json(
            {
                error: 'Invalid movement object'
            });
        }

        // Create new workout log entry
        const workoutLog = new WorkoutLog(
            user_id,
            duration,
            cals_burned,
            new Date(date),
            weight_lifted,
            movement
        );

        // Save to Firestore
        const db = getFirestore();
        const workoutRef = await db.collection('workouts').add(workoutLog.toJSON());

        return res.status(201).json(
        {
            id: workoutRef.id,
            ...workoutLog.toJSON()
        });

    } catch (error) {
        console.error('Error creating workout:', error);
        return res.status(500).json({
            error: 'Internal server error'
        });
    }
}

/**
 * Get a workout log by ID
 */
async function getWorkout(req, res) 
{
    try {
        const { id } = req.params;

        if (!id) {
            return res.status(400).json({
                error: 'Workout ID is required'
            });
        }

        const db = getFirestore();
        const workoutDoc = await db.collection('workouts').doc(id).get();

        if (!workoutDoc.exists) {
            return res.status(404).json(
            {
                error: 'Workout not found'
            });
        }

        return res.status(200).json(
        {
            id: workoutDoc.id,
            ...workoutDoc.data()
        });

    } catch (error) {
        console.error('Error getting workout:', error);
        return res.status(500).json(
        {
            error: 'Internal server error'
        });
    }
}

/**
 * Get all workouts for a user
 */
async function getUserWorkouts(req, res) 
{
    try {
        const { user_id } = req.params;

        if (!user_id || !validators.isValidUserID(user_id)) 
        {
            return res.status(400).json(
            {
                error: 'Valid user_id is required'
            });
        }

        const db = getFirestore();
        const workoutsSnapshot = await db.collection('workouts')
            .where('user_id', '==', user_id)
            .orderBy('date', 'desc')
            .get();

        const workouts = [];
        workoutsSnapshot.forEach(doc => 
        {
            workouts.push(
            {
                id: doc.id,
                ...doc.data()
            });
        });

        return res.status(200).json(workouts);

    } catch (error) {
        console.error('Error getting user workouts:', error);
        return res.status(500).json(
        {
            error: 'Internal server error'
        });
    }
}

/**
 * Update a workout log
 */
async function updateWorkout(req, res) 
{
    try {
        const { id } = req.params;
        const updateData = req.body;

        if (!id) {
            return res.status(400).json(
            {
                error: 'Workout ID is required'
            });
        }

        // Validate fields that are being updated
        if (updateData.user_id && !validators.isValidUserID(updateData.user_id)) 
        {
            return res.status(400).json(
            {
                error: 'Invalid user_id'
            });
        }

        if (updateData.duration && !validators.isValidDuration(updateData.duration)) 
        {
            return res.status(400).json(
            {
                error: 'Invalid duration'
            });
        }

        if (updateData.cals_burned && !validators.isvalidcalsburned(updateData.cals_burned)) 
        {
            return res.status(400).json(
            {
                error: 'Invalid calories burned'
            });
        }

        if (updateData.date && !validators.isValidDate(updateData.date)) 
        {
            return res.status(400).json(
            {
                error: 'Invalid date'
            });
        }

        if (updateData.weight_lifted && !validators.isvalidweightlifted(updateData.weight_lifted)) 
        {
            return res.status(400).json(
            {
                error: 'Invalid weight lifted'
            });
        }

        if (updateData.movement && !validators.isvalidmovement(updateData.movement)) 
        {
            return res.status(400).json(
            {
                error: 'Invalid movement object'
            });
        }

        // Update in Firestore
        const db = getFirestore();
        const workoutRef = db.collection('workouts').doc(id);
        const workoutDoc = await workoutRef.get();

        if (!workoutDoc.exists) 
        {
            return res.status(404).json(
            {
                error: 'Workout not found'
            });
        }

        await workoutRef.update(updateData);

        // Get updated document
        const updatedDoc = await workoutRef.get();
        return res.status(200).json(
        {
            id: updatedDoc.id,
            ...updatedDoc.data()
        });

    } catch (error) {
        console.error('Error updating workout:', error);
        return res.status(500).json({
            error: 'Internal server error'
        });
    }
}

/**
 * Delete a workout log
 */
async function deleteWorkout(req, res) 
{
    try {
        const { id } = req.params;

        if (!id) {
            return res.status(400).json(
            {
                error: 'Workout ID is required'
            });
        }

        const db = getFirestore();
        const workoutRef = db.collection('workouts').doc(id);
        const workoutDoc = await workoutRef.get();

        if (!workoutDoc.exists) {
            return res.status(404).json(
            {
                error: 'Workout not found'
            });
        }

        await workoutRef.delete();

        return res.status(200).json({
            message: 'Workout deleted successfully'
        });

    } catch (error) {
        console.error('Error deleting workout:', error);
        return res.status(500).json(
        {
            error: 'Internal server error'
        });
    }
}

module.exports = {
    createWorkout,
    getWorkout,
    getUserWorkouts,
    updateWorkout,
    deleteWorkout
};