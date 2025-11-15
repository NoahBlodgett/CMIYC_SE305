const { MilestoneTypes } = require('../models/Milestones');

function isValidMilestoneType(milestoneType) 
{
    if (!MilestoneTypes || typeof MilestoneTypes !== 'object') return false;
    return Object.values(MilestoneTypes).includes(milestoneType);
}

function isValidMilestoneID(milestoneID) 
{
    return typeof milestoneID === 'string' && milestoneID.trim().length > 0;
}

function isValidUserID(userID) 
{
    return typeof userID === 'string' && userID.trim().length > 0;
}

function isValidTargetValue(targetValue) 
{
    return typeof targetValue === 'number' && 
           Number.isFinite(targetValue) && 
           targetValue > 0 && 
           targetValue <= 1000000; // Max reasonable target
}

function isValidCurrentValue(currentValue) 
{
    return typeof currentValue === 'number' && 
           Number.isFinite(currentValue) && 
           currentValue >= 0 && 
           currentValue <= 1000000; // Max reasonable value
}

function isValidProgressValues(currentValue, targetValue) 
{
    return isValidCurrentValue(currentValue) && 
           isValidTargetValue(targetValue) && 
           currentValue <= targetValue * 2; // Allow some overflow but not excessive
}

function isValidCompletionStatus(isCompleted) 
{
    return typeof isCompleted === 'boolean';
}

function isValidDate(date) 
{
    if (!date) return true; // null/undefined is valid (not yet completed)
    
    const dateObj = date instanceof Date ? date : new Date(date);
    const time = dateObj.getTime();
    
    if (!Number.isFinite(time)) return false; // Invalid date
    
    // Date should be in the past or present (can't complete in future)
    return time <= Date.now();
}

function isValidCompletedDate(completedDate, isCompleted) 
{
    if (!isCompleted) {
        // If not completed, completedDate should be null
        return completedDate === null || completedDate === undefined;
    }
    
    // If completed, must have a valid date
    return isValidDate(completedDate) && completedDate !== null;
}

function isValidCreatedDate(createdDate) 
{
    if (!createdDate) return false; // Must have a created date
    
    const dateObj = createdDate instanceof Date ? createdDate : new Date(createdDate);
    const time = dateObj.getTime();
    
    if (!Number.isFinite(time)) return false;
    
    // Created date should be in the past or present
    return time <= Date.now();
}

function isValidProgressAmount(amount) 
{
    return typeof amount === 'number' && 
           Number.isFinite(amount) && 
           amount > 0 && 
           amount <= 100000; // Reasonable single progress increment
}

function isValidMilestoneData(data) 
{
    if (!data || typeof data !== 'object') return false;
    
    // Check required fields
    if (!isValidUserID(data.userID)) return false;
    if (!isValidMilestoneType(data.milestoneType)) return false;
    if (!isValidTargetValue(data.targetValue)) return false;
    
    // Check optional fields if provided
    if (data.currentValue !== undefined && !isValidCurrentValue(data.currentValue)) return false;
    if (data.isCompleted !== undefined && !isValidCompletionStatus(data.isCompleted)) return false;
    if (data.completedDate !== undefined && !isValidDate(data.completedDate)) return false;
    
    // Validate progress relationship
    if (data.currentValue !== undefined && data.targetValue !== undefined) {
        if (!isValidProgressValues(data.currentValue, data.targetValue)) return false;
    }
    
    // Validate completion consistency
    if (data.isCompleted !== undefined && data.completedDate !== undefined) {
        if (!isValidCompletedDate(data.completedDate, data.isCompleted)) return false;
    }
    
    return true;
}

module.exports = {
    isValidMilestoneType,
    isValidMilestoneID,
    isValidUserID,
    isValidTargetValue,
    isValidCurrentValue,
    isValidProgressValues,
    isValidCompletionStatus,
    isValidDate,
    isValidCompletedDate,
    isValidCreatedDate,
    isValidProgressAmount,
    isValidMilestoneData
};
