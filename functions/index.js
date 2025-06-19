/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const postsApp = require('./post-service/src/server');
const usersApp = require('./user-service/src/server');

exports.postsService = onRequest(
  { timeoutSeconds: 300, memory: '512MB', region: 'us-central1' },
  postsApp.postsService
);

exports.usersService = onRequest(
  { timeoutSeconds: 300, memory: '512MB', region: 'us-central1' },
  usersApp.usersService
);