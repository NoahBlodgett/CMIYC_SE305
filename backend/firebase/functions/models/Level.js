// Level system with XP thresholds
const LEVEL_THRESHOLDS = Object.freeze({
    LEVEL_1: 0,
    LEVEL_2: 100,
    LEVEL_3: 250,
    LEVEL_4: 500,
    LEVEL_5: 1000,
    // Add more levels as needed
});

class UserLevel
{
    constructor(userID, currentXP = 0, currentLevel = 1)
    {
        this.userID = userID;
        this.currentXP = currentXP;
        this.currentLevel = currentLevel;
    }

    getUserID() { return this.userID; }
    getCurrentXP() { return this.currentXP; }
    getCurrentLevel() { return this.currentLevel; }

    setUserID(userID) { this.userID = userID; }
    setCurrentXP(currentXP) { this.currentXP = currentXP; }
    setCurrentLevel(currentLevel) { this.currentLevel = currentLevel; }

    // Add XP and automatically level up if threshold reached
    addXP(amount)
    {
        this.currentXP += amount;
        this.updateLevel();
    }

    // Calculate level based on current XP
    updateLevel()
    {
        const levels = Object.entries(LEVEL_THRESHOLDS)
            .map(([level, xp]) => ({ level: parseInt(level.split('_')[1]), xp }))
            .sort((a, b) => b.xp - a.xp); // Sort descending

        for (const { level, xp } of levels) {
            if (this.currentXP >= xp) {
                this.currentLevel = level;
                break;
            }
        }
    }

    // Get XP needed for next level
    getXPToNextLevel()
    {
        const nextLevel = this.currentLevel + 1;
        const nextLevelKey = `LEVEL_${nextLevel}`;
        
        if (LEVEL_THRESHOLDS[nextLevelKey] !== undefined) {
            return LEVEL_THRESHOLDS[nextLevelKey] - this.currentXP;
        }
        
        return 0; // Max level reached
    }

    // Get progress percentage to next level
    getProgressToNextLevel()
    {
        const currentLevelKey = `LEVEL_${this.currentLevel}`;
        const nextLevelKey = `LEVEL_${this.currentLevel + 1}`;
        
        if (LEVEL_THRESHOLDS[nextLevelKey] === undefined) {
            return 100; // Max level
        }
        
        const currentLevelXP = LEVEL_THRESHOLDS[currentLevelKey];
        const nextLevelXP = LEVEL_THRESHOLDS[nextLevelKey];
        const xpInCurrentLevel = this.currentXP - currentLevelXP;
        const xpNeededForLevel = nextLevelXP - currentLevelXP;
        
        return Math.min(100, (xpInCurrentLevel / xpNeededForLevel) * 100);
    }

    toJSON()
    {
        return {
            user_id: this.userID,
            current_xp: this.currentXP,
            current_level: this.currentLevel,
            xp_to_next_level: this.getXPToNextLevel(),
            progress_percentage: this.getProgressToNextLevel()
        };
    }
}

module.exports = { UserLevel, LEVEL_THRESHOLDS };