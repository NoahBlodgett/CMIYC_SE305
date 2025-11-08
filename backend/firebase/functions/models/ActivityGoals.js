const ActiveGoals = Object.freeze({
    WALK_STEPS: 'WALK_STEPS', // Walk x number of steps
    DO_WORKOUTS: 'DO_WORKOUTS', // Do x number of workouts per week
    EAT_HEALTHY: 'EAT_HEALTHY', // Eat x number of homemade meals
    // I am sure there is more but I cannot think of any
});

class ActivityGoals
{
    constructor(UserID, ActiveGoal, FinishDate)
    {
        this.UserID = UserID;
        this.ActiveGoal = ActiveGoal;
        this.Finish_Date = FinishDate;
    };

    getUserID() { return this.UserID; }
    getActivities() { return this.ActiveGoal; }
    getFinishDate() { return this.Finish_Date; }

    setUserID(userID) { this.UserID = userID; }
    setActivities(ActiveGoal) { this.ActiveGoal = ActiveGoal; }
    setFinishDate(FinishDate) { this.Finish_Date = FinishDate; }

    toJSON()
    {
        return{
            user_id: this.UserID,
            activity_goal: this.ActiveGoal,
            finish_date: this.Finish_Date
        };
    }
}

module.exports = { ActivityGoals, ActiveGoals };