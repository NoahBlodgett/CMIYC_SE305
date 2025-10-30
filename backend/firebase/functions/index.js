const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");

// Initialize Firebase Admin
const app = initializeApp();
const db = getFirestore();

