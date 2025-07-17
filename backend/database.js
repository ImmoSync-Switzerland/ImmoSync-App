const { MongoClient } = require('mongodb');
const { dbUri, dbName } = require('./config');

let db = null;
let client = null;

const connectDB = async () => {
  if (db) {
    return db;
  }

  try {
    // Add connection timeout to prevent hanging
    const options = {
      serverSelectionTimeoutMS: 5000, // 5 second timeout
      connectTimeoutMS: 5000
    };
    
    client = new MongoClient(dbUri, options);
    await client.connect();
    db = client.db(dbName);
    console.log('Connected to MongoDB');
    return db;
  } catch (error) {
    console.error('MongoDB connection error:', error.message);
    throw error;
  }
};

const getDB = () => {
  if (!db) {
    throw new Error('Database not initialized. Call connectDB() first.');
  }
  return db;
};

const closeDB = async () => {
  if (client) {
    await client.close();
    client = null;
    db = null;
    console.log('MongoDB connection closed');
  }
};

module.exports = {
  connectDB,
  getDB,
  closeDB
};
