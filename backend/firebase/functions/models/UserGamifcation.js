class UserGamification
{
    constructor(userID, workoutLog, user_goal, milestones, level, badges)
    {
        this.userID = userID;
        this.workoutLog = workoutLog;
        this.user_goal = user_goal;
        this.milestones = milestones;
        this.level = level;
        this.badges = badges;
    }

    getUserID() { return this.userID; }
    getActivityLog() { return this.workoutLog; }
    getGoal() { return this.user_goal; }
    getMilestones() { return this.milestones; }
    getLevel() { return this.level; }
    getBadges() { return this.badges; }

    setUserID(userID) { this.userID = userID; }
    setActivityLog(workoutLog) { this.workoutLog = workoutLog; }
    setGoal(user_goal) { this.user_goal = user_goal; }
    setMilestones(milestones) { this.milestones = milestones; }
    setLevel(level) { this.level = level; }
    setBadges(badges) { this.badges = badges; }

    toJSON()
    {
        return {
            user_id: this.userID,
            workout_Log: this.workoutLog,
            user_goal: this.user_goal,
            milestones: this.milestones,
            level: this.level,
            badges: this.badges,
        };
    }
}

module.exports = UserGamification;