// Basic configuration for development/testing
// Copy this file to config.js and modify as needed
// In production, these would come from environment variables

module.exports = {
  dbUri: process.env.MONGODB_URI || 'mongodb://localhost:27017',
  dbName: process.env.MONGODB_DB_NAME || 'immolink_test',
  port: process.env.PORT || 3000
};