class UserGamification
{
    constructor(userID, workoutLog, user_goal)
    {
        this.userID = userID;
        this.workoutLog = workoutLog;
        this.user_goal = user_goal;
    }

    getUserID() { return this.userID; }
    getActivityLog() { return this.workoutLog; }
    getGoal() { return this.user_goal; }

    setUserID(userID) { this.userID = userID; }
    setActivityLog(workoutLog) { this.workoutLog = this.workoutLog; }
    setGoal(user_goal) { this.user_goal = user_goal; }

    toJSON()
    {
        return {
            user_id: this.userID,
            workout_Log: this.workoutLog,
            user_goal: this.user_goal
        };
    }
}

module.exports = UserGamification;