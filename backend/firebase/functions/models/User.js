class User 
{
  constructor(name, age) 
  {
    this.user_id = null;
    this.name = name;
    this.age = age;
    this.email = '';
    this.height = '';
    this.weight = '';
    this.goal_weight = 0.0;
    this.workout_type = '';
    this.diet_type = '';
    this.preferences = 
    {
      workout_type: this.workout_type,
      diet_type: this.diet_type
    };
  }

  // --- Getters ---
  getName() { return this.name; }
  getAge() { return this.age; }
  getEmail() { return this.email; }
  getHeight() { return this.height; }
  getWeight() { return this.weight; }
  getGoalWeight() { return this.goal_weight; }
  getPreferences() { return this.preferences; }

  // --- Setters ---
  setUserID() { return; }

  setName(name) { this.name = name; }

  setAge(age) { this.age = age; }

  setEmail(email) { this.email = email; }

  setHeight(height) { this.height = height; }

  setWeight(weight) { this.weight = weight; }

  setGoalWeight(goal_weight) { this.goal_weight = goal_weight; }

  setPreferences(workout_type, diet_type) 
  {
    this.workout_type = workout_type;
    this.diet_type = diet_type;
    this.preferences = { workout_type, diet_type };
  }

  toJSON()
    {
        return {
            user_id: this.user_id,
            name: this.name,
            age: this.age,
            email: this.email,
            height: this.height,
            weight: this.weight,
            goal_weight: this.goal_weight,
            workout_type: this.workout_type,
            diet_type: this.diet_type,
            preferences: this.preferences
        };
    }
}

module.exports = User;













