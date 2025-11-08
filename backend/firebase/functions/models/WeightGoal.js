// enums for Goal_Objective
const Weight_Objectives = Object.freeze({
    LOSE_WEIGHT: 'LOSE_WEIGHT',
    GAIN_WEIGHT: 'GAIN_WEIGHT',
    MAINTAIN_WEIGHT: 'MAINTAIN_WEIGHT'
});

class WeightGoal
{
    // Goal_Objective From the enum above
    // Goal Weight is the weight the user wants to get to
    //      Will be current weight if the user wants to maintain
    constructor(UserID, Weight_Objective, Goal_Weight, Finish_Date)
    {
        this.UserID = UserID;
        this.Weight_Objective = Weight_Objective;
        this.Goal_Weight = Goal_Weight;
        this.Finish_Date = Finish_Date;
    }

    getUserID() { return this.UserID; }
    getWeightObjective() { return this.Weight_Objective; }
    getGoalWeight() { return this.Goal_Weight; }
    getFinishDate() { return this.Finish_Date; }

    setUserID(UserID) { this.UserID = UserID; }
    setGoalObjective(Weight_Objective) { this.Weight_Objective =  Weight_Objective; }
    setGoalWeight(Goal_Weight)  { this.Goal_Weight = Goal_Weight; }
    setFinishDate(Finish_Date) { this.Finish_Date = Finish_Date; }

    toJSON()
    {
        return {
            user_id: this.UserID,
            weight_objective: this.Weight_Objective,
            goal_weight: this.Goal_Weight,
            finish_date: this.Finish_Date
        };
    } 
}

module.exports = { WeightGoal, Weight_Objectives };