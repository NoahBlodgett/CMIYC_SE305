const { LEVEL_THRESHOLDS } = require('../models/Level');

function isValidUserID(userID) 
{
    return typeof userID === 'string' && userID.trim().length > 0;
}

function isValidXP(xp) 
{
    return typeof xp === 'number' && 
           Number.isFinite(xp) && 
           Number.isInteger(xp) &&
           xp >= 0 && 
           xp <= 1000000; // Max reasonable XP
}

function isValidLevel(level) 
{
    if (typeof level !== 'number' || !Number.isFinite(level) || !Number.isInteger(level)) {
        return false;
    }
    
    // Check if level exists in LEVEL_THRESHOLDS
    const maxLevel = Math.max(...Object.keys(LEVEL_THRESHOLDS).map(key => parseInt(key.split('_')[1])));
    
    return level >= 1 && level <= maxLevel;
}

function isValidLevelXPRelationship(currentXP, currentLevel) 
{
    if (!isValidXP(currentXP) || !isValidLevel(currentLevel)) return false;
    
    const currentLevelKey = `LEVEL_${currentLevel}`;
    const nextLevelKey = `LEVEL_${currentLevel + 1}`;
    
    const currentLevelXP = LEVEL_THRESHOLDS[currentLevelKey];
    const nextLevelXP = LEVEL_THRESHOLDS[nextLevelKey];
    
    // XP should be >= current level threshold
    if (currentXP < currentLevelXP) return false;
    
    // If there's a next level, XP should be < next level threshold
    if (nextLevelXP !== undefined && currentXP >= nextLevelXP) return false;
    
    return true;
}

function isValidXPAmount(amount) 
{
    return typeof amount === 'number' && 
           Number.isFinite(amount) && 
           Number.isInteger(amount) &&
           amount > 0 && 
           amount <= 10000; // Max reasonable single XP gain
}

function isValidProgressPercentage(percentage) 
{
    return typeof percentage === 'number' && 
           Number.isFinite(percentage) && 
           percentage >= 0 && 
           percentage <= 100;
}

function isValidLevelData(data) 
{
    if (!data || typeof data !== 'object') return false;
    
    // Check required fields
    if (!isValidUserID(data.userID)) return false;
    
    // Check optional fields if provided
    if (data.currentXP !== undefined && !isValidXP(data.currentXP)) return false;
    if (data.currentLevel !== undefined && !isValidLevel(data.currentLevel)) return false;
    
    // Validate level-XP relationship
    if (data.currentXP !== undefined && data.currentLevel !== undefined) {
        if (!isValidLevelXPRelationship(data.currentXP, data.currentLevel)) return false;
    }
    
    // Validate calculated fields if provided
    if (data.xp_to_next_level !== undefined) {
        if (typeof data.xp_to_next_level !== 'number' || 
            !Number.isFinite(data.xp_to_next_level) || 
            data.xp_to_next_level < 0) {
            return false;
        }
    }
    
    if (data.progress_percentage !== undefined) {
        if (!isValidProgressPercentage(data.progress_percentage)) return false;
    }
    
    return true;
}

module.exports = {
    isValidUserID,
    isValidXP,
    isValidLevel,
    isValidLevelXPRelationship,
    isValidXPAmount,
    isValidProgressPercentage,
    isValidLevelData
};
