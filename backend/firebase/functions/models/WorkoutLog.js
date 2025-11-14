class WorkoutLog {
    constructor(user_id, duration, cals_burned, date, weight_lifted, 
        movement = null)
    {
        this.user_id = user_id;
        this.duration = duration;
        this.cals_burned = cals_burned;
        this.date = date;
        this.weight_lifted = weight_lifted;
        this.movement = movement;
    }

    // --- Getters ---
    getUserID() { return this.user_id; }
    getDuration() { return this.duration; }
    getCalsBurned() { return this.cals_burned; }
    getDate() { return this.date; }
    getWeightLifted() { return this.weight_lifted; }
    getMovement() { return this.movement; }

    // --- Setters ---
    setUserID(user_id) { this.user_id = user_id; }
    setDuration(duration) { this.duration = duration; }
    setCalsBurned(cals_burned) { this.cals_burned = cals_burned; }
    setDate(date) { this.date = date; }
    setWeightLifted(weight_lifted) { this.weight_lifted = weight_lifted; }
    setMovement(movement) { this.movement = movement; }

    toJSON()
    {
        return {
            user_id: this.user_id,
            duration: this.duration,
            cals_burned: this.cals_burned,
            date: this.date,
            weight_lifted: this.weight_lifted,
            movement: this.movement,
        };
    }

}

module.exports = WorkoutLog;

