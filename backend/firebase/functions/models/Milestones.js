// Milestone types
const MilestoneTypes = Object.freeze({
    WEIGHT_LOSS: 'WEIGHT_LOSS',           // Lost X pounds
    WEIGHT_GAIN: 'WEIGHT_GAIN',           // Gained X pounds
    WORKOUT_COUNT: 'WORKOUT_COUNT',       // Completed X workouts
    DISTANCE_RUN: 'DISTANCE_RUN',         // Ran X miles total
    CALORIES_BURNED: 'CALORIES_BURNED',   // Burned X calories total
    DAYS_ACTIVE: 'DAYS_ACTIVE',           // Active for X days
    GOAL_REACHED: 'GOAL_REACHED',         // Reached weight/activity goal
    PERSONAL_BEST: 'PERSONAL_BEST'        // Hit personal best in exercise
});

class Milestone
{
    constructor(milestoneID, userID, milestoneType, targetValue, currentValue = 0, isCompleted = false, completedDate = null)
    {
        this.milestoneID = milestoneID;
        this.userID = userID;
        this.milestoneType = milestoneType;
        this.targetValue = targetValue;
        this.currentValue = currentValue;
        this.isCompleted = isCompleted;
        this.completedDate = completedDate;
        this.createdDate = new Date();
    }

    getMilestoneID() { return this.milestoneID; }
    getUserID() { return this.userID; }
    getMilestoneType() { return this.milestoneType; }
    getTargetValue() { return this.targetValue; }
    getCurrentValue() { return this.currentValue; }
    getIsCompleted() { return this.isCompleted; }
    getCompletedDate() { return this.completedDate; }
    getCreatedDate() { return this.createdDate; }

    setMilestoneID(milestoneID) { this.milestoneID = milestoneID; }
    setUserID(userID) { this.userID = userID; }
    setMilestoneType(milestoneType) { this.milestoneType = milestoneType; }
    setTargetValue(targetValue) { this.targetValue = targetValue; }
    setCurrentValue(currentValue) { this.currentValue = currentValue; }
    setIsCompleted(isCompleted) { this.isCompleted = isCompleted; }
    setCompletedDate(completedDate) { this.completedDate = completedDate; }
    setCreatedDate(createdDate) { this.createdDate = createdDate; }

    // Update progress towards milestone
    updateProgress(newValue)
    {
        this.currentValue = newValue;
        
        if (this.currentValue >= this.targetValue && !this.isCompleted) {
            this.complete();
        }
    }

    // Add to current progress
    addProgress(amount)
    {
        this.currentValue += amount;
        
        if (this.currentValue >= this.targetValue && !this.isCompleted) {
            this.complete();
        }
    }

    // Mark milestone as completed
    complete()
    {
        this.isCompleted = true;
        this.completedDate = new Date();
    }

    // Get progress percentage
    getProgress()
    {
        if (this.targetValue === 0) return 0;
        return Math.min(100, (this.currentValue / this.targetValue) * 100);
    }

    // Get remaining value to complete
    getRemaining()
    {
        return Math.max(0, this.targetValue - this.currentValue);
    }

    toJSON()
    {
        return {
            milestone_id: this.milestoneID,
            user_id: this.userID,
            milestone_type: this.milestoneType,
            target_value: this.targetValue,
            current_value: this.currentValue,
            is_completed: this.isCompleted,
            completed_date: this.completedDate,
            created_date: this.createdDate,
            progress_percentage: this.getProgress(),
            remaining: this.getRemaining()
        };
    }
}

module.exports = { Milestone, MilestoneTypes };