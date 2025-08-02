const { MongoClient } = require('mongodb');
const uri = 'mongodb+srv://immolink_service:CekXrtrJhJLj4sWx@cluster0.h6adx.mongodb.net/immolink_db';

async function checkImages() {
  try {
    console.log('Connecting to MongoDB Atlas...');
    const client = new MongoClient(uri);
    await client.connect();
    console.log('Connected successfully!');
    
    const db = client.db('immolink_db');
    
    // Check properties collection for image URLs
    const properties = await db.collection('properties').find({}).limit(5).toArray();
    console.log('Found', properties.length, 'properties');
    
    properties.forEach((property, index) => {
      console.log(`\nProperty ${index + 1}:`);
      console.log(`  ID: ${property._id}`);
      console.log(`  Address: ${property.address?.street || 'No address'}`);
      console.log(`  Image URLs: ${JSON.stringify(property.imageUrls || [])}`);
    });
    
    // Check for images in fs.files collection (GridFS)
    const imageFiles = await db.collection('fs.files').find({}).limit(5).toArray();
    console.log('\nFound', imageFiles.length, 'files in GridFS:');
    imageFiles.forEach((file, index) => {
      console.log(`${index + 1}. ID: ${file._id}, Filename: ${file.filename}, Size: ${file.length} bytes`);
    });
    
    await client.close();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkImages();
