class Movement {
    constructor(name, muscle_group, sets, reps = null)
    {
        this.name = name;
        this.muscle_group = muscle_group;
        this.sets = sets;
        this.reps = reps;
    }

    // --- Getters ---
    getName() { return this.name; }
    getMuscleGroup() { return this.muscle_group; }
    getSets() { return this.sets; }
    getReps() { return this.reps; }

    // --- Setters ---
    setName(name) { this.name = name; }
    setMuscleGroup(muscle_group) { this.muscle_group = muscle_group; }
    setSets(sets) { this.sets = sets; }
    setReps(reps) { this.reps = reps; }

    toJSON()
    {
        return {
            name: this.name,
            muscle_group: this.muscle_group,
            sets: this.sets,
            reps: this.reps,
        };
    }

}

module.exports = Movement;
