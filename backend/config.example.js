// Configuration for database connection
// Copy this file to config.js and update with your actual values
// This file exports database configuration based on environment variables

require('dotenv').config();

module.exports = {
  dbUri: process.env.MONGODB_URI || 'mongodb://localhost:27017',
  dbName: process.env.MONGODB_DB_NAME || 'immolink_db'
};