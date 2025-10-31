const User = require('../models/User');
const validators = require('../utils/userValidators');
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

function createUser(req, res)
{

}

function getUser(userID, res)
{

}

function updateUser(userID, req, res)
{

}

function deleteUser(userID, res)
{

}