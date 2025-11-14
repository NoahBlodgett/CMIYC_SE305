// workoutValidators
const Movement = require('../models/Movement');

function isValidUserID(userId)
{
    let finalTruth = true;

    const isValidLength = (userId.length > 0 && userId.length <= 16);

    if(!isValidLength)
        finalTruth = false;

    return finalTruth;
}

function isValidDuration(duration)
{
    return duration > 0;
}

function isValidCalsBurned(calsBurned)
{
    // calsBurned should be a positive number
    return calsBurned > 0;
}

function isValidDate(date) 
{
    // Check if the input is actually a date object
    if (!(date instanceof Date) && !(typeof date === 'string')) {
        return false;
    }

    // Convert to Date object if it's a string
    const dateObj = date instanceof Date ? date : new Date(date);

    // Check if the date is valid
    if (isNaN(dateObj.getTime())) {
        return false;
    }

    // Check if the date is not in the future
    const currentDate = new Date();
    if (dateObj > currentDate) {
        return false;
    }

    // Check if the date is not too old (e.g., not older than 100 years)
    const hundredYearsAgo = new Date();
    hundredYearsAgo.setFullYear(currentDate.getFullYear() - 100);
    if (dateObj < hundredYearsAgo) 
    {
        return false;
    }

    return true;   
}

function isValidWeightLifted(weightLifted) 
{
    // weightLifted should be a positive number
    return typeof weightLifted === 'number' && weightLifted > 0;
}

function isValidMovement(movement) 
{
    // Check if movement is an object
    if (!movement || typeof movement !== 'object') 
    {
        return false;
    }

    // Validate name (required, non-empty string)
    if (!movement.name || typeof movement.name !== 'string' || 
    movement.name.trim().length === 0) 
    {
        return false;
    }

    // Validate muscle_group (required, non-empty string)
    if (!movement.muscle_group || typeof movement.muscle_group !== 'string' || 
    movement.muscle_group.trim().length === 0) 
    {
        return false;
    }

    // Validate sets (required, positive number)
    if (!Number.isInteger(movement.sets) || movement.sets <= 0) 
    {
        return false;
    }

    // Validate reps (optional, but if present must be a positive number)
    const reps = movement.reps;
    if (reps !== null && reps !== undefined && (!Number.isInteger(reps) || reps <= 0)) 
    {
        return false;
    }

    return true;
}

module.exports = {
    isValidUserID,
    isValidDuration,
    isValidCalsBurned,
    isValidDate,
    isValidWeightLifted,
    isValidMovement
};