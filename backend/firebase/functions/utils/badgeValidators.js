const { BadgeTypes } = require('../models/Badges');

function isValidBadgeType(badgeType) 
{
    if (!BadgeTypes || typeof BadgeTypes !== 'object') return false;
    return Object.values(BadgeTypes).includes(badgeType);
}

function isValidUserID(userID) 
{
    return typeof userID === 'string' && userID.trim().length > 0;
}

function isValidEarnedBadges(earnedBadges) 
{
    if (!Array.isArray(earnedBadges)) return false;
    
    // Check all badges are valid types
    if (!earnedBadges.every(badge => isValidBadgeType(badge))) return false;
    
    // Check for duplicates
    const uniqueBadges = new Set(earnedBadges);
    if (uniqueBadges.size !== earnedBadges.length) return false;
    
    return true;
}

function isValidStreak(streak) 
{
    return typeof streak === 'number' && 
           Number.isFinite(streak) && 
           Number.isInteger(streak) &&
           streak >= 0 && 
           streak <= 10000; // Max reasonable streak
}

function isValidStreakRelationship(currentStreak, longestStreak) 
{
    return isValidStreak(currentStreak) && 
           isValidStreak(longestStreak) && 
           currentStreak <= longestStreak;
}

function isValidActivityDate(date) 
{
    if (date === null || date === undefined) return true; // null is valid (no activity yet)
    
    const dateObj = date instanceof Date ? date : new Date(date);
    const time = dateObj.getTime();
    
    if (!Number.isFinite(time)) return false; // Invalid date
    
    // Activity date should be in the past or present
    return time <= Date.now();
}

function isValidBadgeCount(count) 
{
    return typeof count === 'number' && 
           Number.isFinite(count) && 
           Number.isInteger(count) &&
           count >= 0 && 
           count <= 100; // Max reasonable badge count
}

function isValidBadgeData(data) 
{
    if (!data || typeof data !== 'object') return false;
    
    // Check required fields
    if (!isValidUserID(data.userID)) return false;
    
    // Check optional fields if provided
    if (data.earnedBadges !== undefined && !isValidEarnedBadges(data.earnedBadges)) return false;
    if (data.currentStreak !== undefined && !isValidStreak(data.currentStreak)) return false;
    if (data.longestStreak !== undefined && !isValidStreak(data.longestStreak)) return false;
    if (data.lastActivityDate !== undefined && !isValidActivityDate(data.lastActivityDate)) return false;
    
    // Validate streak relationship
    if (data.currentStreak !== undefined && data.longestStreak !== undefined) {
        if (!isValidStreakRelationship(data.currentStreak, data.longestStreak)) return false;
    }
    
    // Validate badge count matches array length
    if (data.earnedBadges !== undefined && data.badge_count !== undefined) {
        if (data.earnedBadges.length !== data.badge_count) return false;
    }
    
    return true;
}

module.exports = {
    isValidBadgeType,
    isValidUserID,
    isValidEarnedBadges,
    isValidStreak,
    isValidStreakRelationship,
    isValidActivityDate,
    isValidBadgeCount,
    isValidBadgeData
};
