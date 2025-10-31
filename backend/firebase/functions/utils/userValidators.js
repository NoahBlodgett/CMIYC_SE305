// User Validators
// For Validating parameters for the user class

//  getEmail() { return this.email; }
function isValidEmail(email)
{
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

    return emailRegex.test(email);
}

function isValidPassword(password)
{
    const specialChars = /[`!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~]/;
    const numbers = /\d/;
    const finalTruth = true;

    const isValidLength = (length(password) > 0 && length(password) <= 20);
    const hasSpecialChar = specialChars.test(password);
    const hasNumber = numbers.test(password);

    if(!isValidLength || !hasSpecialChar || !hasNumber)
        finalTruth = false;

    return finalTruth;
}

//   getWeight() { return this.weight; }
// getGoalWeight() { return this.goal_weight; }
function isValidWeight(weight)
{
    return (weight > 0);
}

//  getHeight() { return this.height; }
// in Inches
function isValidHeight(height)
{
    return (height > 0);
}

// getAge() { return this.age; }
function isValidAge(age)
{
    return (age > 0);
}

//  getGender() { return this.gender; }
// M =  Male, F = Female
function isValidGender(gender)
{
    const genderCap = gender.ToUpperCase();
    const truthValue = true;

    if (genderCap != 'M' || genderCap != 'F')
        truthValue = false;

    return truthValue;
}

// getActivityLevel() { return this.activity_level; } 
// 1.2 = sedentary, 1.375 = light activity, 1.55 = moderate activity
// 1.725 = very active, 1.9 = extreme activity
function isValidActivityLevel(activity_level)
{
    const validLevels = [1.2, 1,375, 1.55, 1.725, 1.9];

    return(validLevels.includes(activity_level));
}

// Export the functions so other files can use them
module.exports = 
{
    isValidEmail,
    isValidPassword,
    isValidWeight,
    isValidHeight,
    isValidAge,
    isValidGender,
    isValidActivityLevel
};