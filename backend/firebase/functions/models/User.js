class User 
{
  constructor(name, age) 
  {
    this.user_id = null;
    this.name = name;
    this.age = age;
    this.gender = '';
    this.email = '';
    this.height = '';
    this.weight = 0.0;
    this.allergies = '';
    this.activity_level = 0.0;
  }

  // --- Getters ---
  getName() { return this.name; }
  getAge() { return this.age; }
  getGender() { return this.gender; }
  getEmail() { return this.email; }
  getHeight() { return this.height; }
  getWeight() { return this.weight; }
  getAllergies() { return this.allergies; }
  getActivityLevel() { return this.activity_level; }  

  // --- Setters ---
  setUserID(user_id) { this.user_id = user_id; }
  setName(name) { this.name = name; }
  setAge(age) { this.age = age; }
  setGender(gender) { this.gender = gender; }
  setEmail(email) { this.email = email; }
  setHeight(height) { this.height = height; }
  setWeight(weight) { this.weight = weight; }
  setAllergies(allergies) { this.allergies = allergies; }
  setActivityLevel(activity_level) { this.activity_level = activity_level; }

  toJSON()
    {
        return {
            user_id: this.user_id,
            name: this.name,
            age: this.age,
            gender: this.gender,
            email: this.email,
            height: this.height,
            weight: this.weight,
            goal_weight: this.goal_weight,
            allergies: this.allergies,
            activity_level: this.activity_level,
        };
    }
}

module.exports = User;













