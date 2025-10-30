const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");

// Initialize Firebase Admin
const app = initializeApp();
const db = getFirestore();

// Simple HTTP function to verify Functions (and emulator) are running.
exports.ping = onRequest((req, res) => {
	logger.info("Ping received", { time: Date.now() });
	res.json({ ok: true, ts: Date.now() });
});

