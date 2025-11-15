// Badge types
const BadgeTypes = Object.freeze({
    STREAK_MASTER: 'STREAK_MASTER',              // Maintain streak > 10 days
    WEEKLY_WARRIOR: 'WEEKLY_WARRIOR',            // Workout every day in a week
    MILESTONE_ACHIEVER: 'MILESTONE_ACHIEVER',    // Hit a milestone
    GOAL_CRUSHER: 'GOAL_CRUSHER',                // Complete a goal
    LEVEL_LEGEND: 'LEVEL_LEGEND',                // Reach certain level (e.g., Level 5, 10)
    CONSISTENCY_KING: 'CONSISTENCY_KING',        // 30-day streak
    FIRST_STEPS: 'FIRST_STEPS',                  // Complete first workout
    CENTURY_CLUB: 'CENTURY_CLUB'                 // 100 workouts total
});

class UserBadges
{
    constructor(userID, earnedBadges = [], currentStreak = 0, longestStreak = 0)
    {
        this.userID = userID;
        this.earnedBadges = earnedBadges; // Array of badge types
        this.currentStreak = currentStreak;
        this.longestStreak = longestStreak;
        this.lastActivityDate = null;
    }

    getUserID() { return this.userID; }
    getEarnedBadges() { return this.earnedBadges; }
    getCurrentStreak() { return this.currentStreak; }
    getLongestStreak() { return this.longestStreak; }
    getLastActivityDate() { return this.lastActivityDate; }

    setUserID(userID) { this.userID = userID; }
    setEarnedBadges(earnedBadges) { this.earnedBadges = earnedBadges; }
    setCurrentStreak(currentStreak) { this.currentStreak = currentStreak; }
    setLongestStreak(longestStreak) { this.longestStreak = longestStreak; }
    setLastActivityDate(lastActivityDate) { this.lastActivityDate = lastActivityDate; }

    // Add a badge if not already earned
    awardBadge(badgeType)
    {
        if (!Object.values(BadgeTypes).includes(badgeType)) {
            throw new Error('Invalid badge type');
        }
        
        if (!this.hasBadge(badgeType)) {
            this.earnedBadges.push(badgeType);
            return true;
        }
        return false;
    }

    // Check if user has a specific badge
    hasBadge(badgeType)
    {
        return this.earnedBadges.includes(badgeType);
    }

    // Update streak based on activity
    updateStreak(activityDate = new Date())
    {
        if (!this.lastActivityDate) {
            // First activity
            this.currentStreak = 1;
            this.lastActivityDate = activityDate;
            return;
        }

        const lastDate = new Date(this.lastActivityDate);
        const currentDate = new Date(activityDate);
        
        // Reset time to compare only dates
        lastDate.setHours(0, 0, 0, 0);
        currentDate.setHours(0, 0, 0, 0);
        
        const daysDiff = Math.floor((currentDate - lastDate) / (1000 * 60 * 60 * 24));

        if (daysDiff === 1) {
            // Consecutive day
            this.currentStreak++;
            if (this.currentStreak > this.longestStreak) {
                this.longestStreak = this.currentStreak;
            }
        } else if (daysDiff > 1) {
            // Streak broken
            this.currentStreak = 1;
        }
        // If daysDiff === 0, same day activity, don't update streak

        this.lastActivityDate = activityDate;
        
        // Auto-award streak badges
        this.checkStreakBadges();
    }

    // Check and award streak-related badges
    checkStreakBadges()
    {
        if (this.currentStreak >= 10 && !this.hasBadge(BadgeTypes.STREAK_MASTER)) {
            this.awardBadge(BadgeTypes.STREAK_MASTER);
        }
        
        if (this.currentStreak >= 30 && !this.hasBadge(BadgeTypes.CONSISTENCY_KING)) {
            this.awardBadge(BadgeTypes.CONSISTENCY_KING);
        }
    }

    // Get total badge count
    getBadgeCount()
    {
        return this.earnedBadges.length;
    }

    toJSON()
    {
        return {
            user_id: this.userID,
            earned_badges: this.earnedBadges,
            current_streak: this.currentStreak,
            longest_streak: this.longestStreak,
            last_activity_date: this.lastActivityDate,
            badge_count: this.getBadgeCount()
        };
    }
}

module.exports = { UserBadges, BadgeTypes };