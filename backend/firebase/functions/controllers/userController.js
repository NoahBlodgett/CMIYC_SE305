const User = require('../models/User');
const validators = require('../utils/userValidators');
const { getFirestore } = require('firebase-admin/firestore');
/*
Example for what a request looks like
// When someone makes this request:
POST /users
{
  "name": "John Doe", 
  "age": 25,
  "email": "john@example.com"
}

// The 'req' parameter contains:
req = {
  method: "POST",           // What type of request
  url: "/users",           // What URL they hit
  body: {                  // The data they sent
    name: "John Doe",
    age: 25,
    email: "john@example.com"
  },
  headers: { ... },        // Browser info, auth tokens, etc.
  // ... lots of other stuff
} 
    this.user_id = null;
    this.name = name;
    this.age = age;
    this.gender = '';
    this.email = '';
    this.height = '';
    this.weight = 0.0;
    this.allergies = '';
    this.activity_level = 0.0;
    */

async function createUser(req, res)
{
  try 
  {
      const { 
        name, 
        age, 
        gender = '', 
        email, 
        height = '', 
        weight = 0.0, 
        allergies = '', 
        activity_level = 0.0
      } = req.body;

      if (!name || !age || !email) 
      {
          return res.status(400).json({ 
          error: 'Missing required fields: name, age, email' 
          });
      }

      if(!validators.isValidEmail(email))
      {
          return res.status(400).json({ 
          error: 'Invalid email format' 
          });
      }

      const newUser = new User(name, age);
      newUser.setEmail(email);
      if (validators.isValidGender(gender)) newUser.setGender(gender);
      if (validators.isValidHeight(height)) newUser.setHeight(height);
      if (validators.isValidWeight(weight)) newUser.setWeight(weight);
      if (validators.isValidActivityLevel(activity_level)) newUser.setActivityLevel(activity_level);
      if (validators.isValidAllergies(allergies)) newUser.setAllergies(allergies);

      // Validate email isn't already in the DB
      const db = getFirestore();
      
      // Check if email already exists
      const existingUserQuery = await db.collection('users').where('email', '==', email).get();
      if (!existingUserQuery.empty) 
      {
          return res.status(409).json({ 
            error: 'User with this email already exists' 
          });
      }

      // Save to database - Firestore will auto-generate an ID
      const userRef = await db.collection('users').add(newUser.toJSON());
      
      // Get the generated ID and update the user object
      const generatedUserID = userRef.id;
      newUser.setUserID(generatedUserID);
      
      // Update the document with the user_id
      await userRef.update({ user_id: generatedUserID });

      res.status(201).json({
        message: 'User created successfully',
        user: newUser.toJSON()
      });
  } 
  catch(e)
  {
    console.error('Error creating user:', e);
    res.status(500).json({ 
      error: 'Internal server error' 
    });
  }
}

async function getUser(userID, res)
{
  // Get the user from the DB
  try
  {
    const db = getFirestore();

    const existingUserQuery = await db.collection('users').where('user_id',  '==', userID).get();

    if(existingUserQuery.empty)
    {
        return res.status(404).json({ 
          error: 'User does not exist' 
        });
    }

    // Get the first (and should be only) document from the query results
    const userDoc = existingUserQuery.docs[0];
    const userData = userDoc.data();
    
    // Send the user information back to the frontend
    res.status(200).json({
      message: 'User found successfully',
      user: userData
    });
  }
  catch(e)
  {
    console.error('Error finding user:', e);
    res.status(500).json({ 
      error: 'Internal server error' 
    });
  }
}

function updateUser(userID, req, res)
{
  // Get the user from the DB
  
  // Update the user information

  // Send Update back to the DB

  // Return the result
}

function deleteUser(userID, res)
{

}

module.exports = {
  createUser,
  getUser,
  updateUser,
  deleteUser
};