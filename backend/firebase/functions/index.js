const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const express = require("express");

// Initialize Firebase Admin
const app = initializeApp();
const db = getFirestore();
const auth = getAuth();

// Initialize Express app
const expressApp = express();
expressApp.use(express.json()); // Parse JSON request bodies

// Import routes
const userRoutes = require('./routes/userRoutes');
const workoutLogRoutes = require('./routes/workoutLogRoutes');

// Register routes
expressApp.use('/users', userRoutes);
expressApp.use('/workouts', workoutLogRoutes);

// Export the Express app as a Cloud Function
exports.api = onRequest(expressApp);

