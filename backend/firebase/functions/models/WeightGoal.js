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
    constructor(UserID, Weight_Objective, Goal_Weight)
    {
        this.UserID = UserID;
        this.Weight_Objective = Weight_Objective;
        this.Goal_Weight = Goal_Weight;
    }

    getGoalObjective() { return this.Weight_Objective; }
    getGoalWeight() { return this.Goal_Weight; }
    getUserID() { return this.UserID; }

    setGoalObjective(Weight_Objective) { this.Weight_Objective =  Weight_Objective; }
    setGoalWeight(Goal_Weight)  { this.Goal_Weight = Goal_Weight; }
    setUserID(UserID) { this.UserID = UserID; }

    toJSON()
    {
        return {
            user_id: this.UserID,
            weight_objective: this.Weight_Objective,
            goal_weight: this.Goal_Weight,
        };
    } 
}

module.exports = { WeightGoal, Weight_Objectives };