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

// Register routes
expressApp.use('/users', userRoutes);

// Export the Express app as a Cloud Function
exports.api = onRequest(expressApp);

// Simple HTTP function to verify Functions (and emulator) are running.
exports.ping = onRequest((req, res) => {
	logger.info("Ping received", { time: Date.now() });
	res.json({ ok: true, ts: Date.now() });
});

