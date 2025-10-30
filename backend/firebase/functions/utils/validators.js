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

    const isValidLength = (length(password) > 0 && length(password) < 20);
    const hasSpecialChar = specialChars.test(password);
    const hasNumber = numbers.test(password);

    if(!isValidLength || !hasSpecialChar || !hasNumber)
        finalTruth = false;

    return finalTruth;
}

function isValidWeight(weight)
{
    
}

function isValidHeight(height)
{

}

// Export the functions so other files can use them
module.exports = {
    isValidEmail,
    isValidPassword
};