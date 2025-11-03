const User = require('../models/User');
const validators = require('../utils/userValidators');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
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
} */

async function createUser(req, res)
{
  try 
  {
      const { 
        name, 
        age, 
        gender, 
        email, 
        password,
        height, 
        weight, 
        allergies = '', 
        activity_level
      } = req.body;

      // Validate required fields
      if (!name || !age || !gender || !email || !password || !height || weight === undefined || activity_level === undefined) 
      {
          return res.status(400).json({ 
            error: 'Missing required fields: name, age, gender, email, password, height, weight, activity_level' 
          });
      }

      // Validate email format
      if(!validators.isValidEmail(email))
      {
          return res.status(400).json({ 
            error: 'Invalid email format' 
          });
      }

      // Validate password format
      if(!validators.isValidPassword(password))
      {
          return res.status(400).json({ 
            error: 'Invalid password format' 
          });
      }

      // Validate age
      if(!validators.isValidAge(age))
      {
          return res.status(400).json({ 
            error: 'Invalid age' 
          });
      }

      // Validate gender
      if(!validators.isValidGender(gender))
      {
          return res.status(400).json({ 
            error: 'Invalid gender' 
          });
      }

      // Validate height
      if(!validators.isValidHeight(height))
      {
          return res.status(400).json({ 
            error: 'Invalid height' 
          });
      }

      // Validate weight
      const parsedWeight = parseFloat(weight);
      if(!validators.isValidWeight(parsedWeight))
      {
          return res.status(400).json({ 
            error: 'Invalid weight' 
          });
      }

      // Validate activity level
      const parsedActivityLevel = parseFloat(activity_level);
      if(!validators.isValidActivityLevel(parsedActivityLevel))
      {
          return res.status(400).json({ 
            error: 'Invalid activity level' 
          });
      }

      // Optional fields
      // Validate allergies if provided
      if(allergies && !validators.isValidAllergies(allergies))
      {
          return res.status(400).json({ 
            error: 'Invalid allergies format' 
          });
      }

      // Check if user already exists in Firestore
      const db = getFirestore();
      const existingUser = await db.collection('users')
        .where('email', '==', email)
        .limit(1)
        .get();

      if (!existingUser.empty) 
      {
        return res.status(409).json({ 
          error: 'User with this email already exists' 
        });
      }

      // Create Firebase Auth user
      const auth = getAuth();
      const authUser = await auth.createUser({
        email: email,
        password: password,
        displayName: name
      });

      const userID = authUser.uid;

      // Create User object with all required fields
      const newUser = new User(name, age, gender, email, height, parsedWeight, parsedActivityLevel, allergies);
      newUser.setUserID(userID);

      // Save to Firestore with rollback on failure
      try 
      {
        await db.collection('users').doc(userID).set(newUser.toJSON());
      } catch (firestoreError) {
        // Rollback: Delete the Auth user if Firestore write fails
        console.error('Firestore write failed, rolling back Auth user:', firestoreError);
        await auth.deleteUser(userID);
        return res.status(500).json({ 
          error: 'Internal server error' 
    });
      }

      // Return success response (without sensitive data)
      res.status(201).json({
        message: 'User created successfully',
        user: newUser.toJSON(),
        uid: userID
      });
  } 
  catch(e)
  {
    console.error('Error creating user:', e);
    
    // Handle specific Firebase Auth errors
    if (e.code === 'auth/email-already-exists') {
      return res.status(409).json({ 
        error: 'User with this email already exists' 
      });
    }
    if (e.code === 'auth/weak-password') {
      return res.status(400).json({ 
        error: 'Password is too weak' 
      });
    }
    if (e.code === 'auth/invalid-email') {
      return res.status(400).json({ 
        error: 'Invalid email address' 
      });
    }
    
    // Generic error for unexpected issues
    res.status(500).json({ 
      error: 'Internal server error' 
    });
  }
}

async function getUser(req, res)
{
  // Get the user from the DB
  try
  {
    const {userID} = req.params;

    const db = getFirestore();

    // Use the userID directly as the document ID
    const userDoc = await db.collection('users').doc(userID).get();

    if(!userDoc.exists)
    {
        return res.status(404).json({ 
          error: 'User does not exist' 
        });
    }

    // Get the document data
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

async function updateUser(req, res)
{
  try
  {
    const {userID} = req.params;
    
    const { 
      name,
      age,
      gender,
      height,
      weight, 
      allergies, 
      activity_level, 
      email,
      password
    } = req.body;

    const db = getFirestore();
    const auth = getAuth();
    
    // Get the user document directly by ID
    const userDoc = await db.collection('users').doc(userID).get();

    if(!userDoc.exists)
    {
        return res.status(404).json({ 
          error: 'User does not exist' 
        });
    }

    const userData = userDoc.data();
    const updates = {};
    let authUpdates = {};

    // Update Firestore fields only if provided and valid
    if(name !== undefined && name !== '') 
    {
      updates.name = name;
      authUpdates.displayName = name;
    }

    if(age !== undefined && validators.isValidAge(age)) 
    {
      updates.age = age;
    }

    if(gender !== undefined && validators.isValidGender(gender)) 
    {
      updates.gender = gender;
    }

    if(height !== undefined && validators.isValidHeight(height)) 
    {
      updates.height = height;
    }

    if(weight !== undefined && validators.isValidWeight(parseFloat(weight))) 
    {
      updates.weight = parseFloat(weight);
    }
    
    if(allergies !== undefined && allergies !== '' && validators.isValidAllergies(allergies)) 
    {
      // Smart merge without duplicates
      const existingAllergies = userData.allergies 
        ? userData.allergies.split(',').map(a => a.trim()) 
        : [];
      const newAllergies = allergies.split(',').map(a => a.trim());
      const mergedAllergies = [...new Set([...existingAllergies, ...newAllergies])];
      updates.allergies = mergedAllergies.join(', ');
    }
    
    if(activity_level !== undefined && validators.isValidActivityLevel(parseFloat(activity_level))) 
    {
      updates.activity_level = parseFloat(activity_level);
    }

    // Validate and prepare email update
    if(email !== undefined && validators.isValidEmail(email)) 
    {
      // Check if email is already in use by another user
      const emailCheck = await db.collection('users')
        .where('email', '==', email)
        .limit(1)
        .get();
      
      if (!emailCheck.empty && emailCheck.docs[0].id !== userID) {
        return res.status(409).json({ 
          error: 'Email already in use by another account' 
        });
      }
      
      authUpdates.email = email;
      updates.email = email;
    }
    
    if(password !== undefined && validators.isValidPassword(password)) 
    {
      authUpdates.password = password;
    }

    // Check if there are any updates to make
    if(Object.keys(updates).length === 0 && Object.keys(authUpdates).length === 0) 
    {
      return res.status(400).json({ 
        error: 'No valid fields provided for update' 
      });
    }

    if(Object.keys(updates).length > 0) 
    {
      await db.collection('users').doc(userID).update(updates);
    }

    // Then update Firebase Auth 
    if(Object.keys(authUpdates).length > 0) 
    {
      try {
        // Verify user exists in Auth
        await auth.getUser(userID);
        
        // Perform Auth update
        await auth.updateUser(userID, authUpdates);
      } 
      catch (authError) 
      {
        console.error('Auth update failed after Firestore update:', authError);
        
        if (authError.code === 'auth/user-not-found') {
          return res.status(404).json({ 
            error: 'User authentication record not found' 
          });
        }
        
        // Auth failed but Firestore succeeded - log for manual intervention
        console.error('CRITICAL: Firestore updated but Auth update failed - data inconsistency');
        throw authError;
      }
    }

    // Get updated user data
    const updatedUserDoc = await db.collection('users').doc(userID).get();
    
    res.status(200).json({
      message: 'User updated successfully',
      user: updatedUserDoc.data()
    });
  }
  catch(e)
  {
      console.error('Error updating user:', e);
      
      // Handle specific Firebase Auth errors
      if (e.code === 'auth/email-already-exists') {
        return res.status(409).json({ 
          error: 'Email already in use by another account' 
        });
      }
      if (e.code === 'auth/invalid-email') {
        return res.status(400).json({ 
          error: 'Invalid email address' 
        });
      }
      if (e.code === 'auth/weak-password') {
        return res.status(400).json({ 
          error: 'Password is too weak' 
        });
      }
      
      res.status(500).json({ 
        error: 'Internal server error' 
      });
  }
}

async function deleteUser(req, res)
{
  try
  {
    const {userID} = req.params;
    
    const db = getFirestore();
    const auth = getAuth();
    
    // Check if user exists in Firestore
    const userDoc = await db.collection('users').doc(userID).get();
    if (!userDoc.exists) 
    {
      return res.status(404).json({ 
        error: 'User does not exist' 
      });
    }
    
    // Delete from Firestore first
    await db.collection('users').doc(userID).delete();
    
    // Then delete from Firebase Auth
    try 
    {
      await auth.deleteUser(userID);
    } 
    catch (authError) 
    {
      // If Auth deletion fails, log it but don't rollback Firestore
      // (user data is already gone, and Auth user without data is less problematic)
      console.error('Warning: Failed to delete Auth user:', authError);
    }
    
    res.status(200).json({
      message: 'User deleted successfully',
      uid: userID
    });
  }
  catch(e)
  {
    console.error('Error deleting user:', e);
    
    if (e.code === 'auth/user-not-found') 
    {
      return res.status(404).json({ 
        error: 'User not found in authentication system' 
      });
    }
    
    res.status(500).json({ 
      error: 'Internal server error' 
    });
  }
}

module.exports = {
  createUser,
  getUser,
  updateUser,
  deleteUser
};