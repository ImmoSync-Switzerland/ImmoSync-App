const { MongoClient } = require('mongodb');
const uri = 'mongodb+srv://immolink_service:CekXrtrJhJLj4sWx@cluster0.h6adx.mongodb.net/immolink_db';

async function checkIds() {
  try {
    console.log('Connecting to MongoDB Atlas...');
    const client = new MongoClient(uri);
    await client.connect();
    console.log('Connected successfully!');
    
    const db = client.db('immolink_db');
    const requests = await db.collection('maintenanceRequests').find({}).limit(5).toArray();
    console.log('Found', requests.length, 'maintenance requests');
    console.log('Sample maintenance request IDs:');
    requests.forEach((req, index) => {
      console.log(`${index + 1}. ID: ${req._id}, Type: ${typeof req._id}, String: ${req._id.toString()}`);
    });
    await client.close();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkIds();
