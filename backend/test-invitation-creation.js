const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function testInvitationCreation() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Testing Invitation Creation ===\n');
    
    // Get tenant info
    const tenant = await db.collection('users').findOne({ email: 'markus@bs.ch' });
    console.log('Tenant ID:', tenant._id.toString());
    
    // Get a property to test with (assuming you want to invite to "Hinterkirchweg 78, Therwil")
    const properties = await db.collection('properties').find({}).toArray();
    console.log(`\nAvailable properties:`);
    properties.forEach(prop => {
      console.log(`- ${prop._id}: ${prop.address?.street}, ${prop.address?.city}`);
    });
    
    // Find the specific property from the image
    const targetProperty = properties.find(p => 
      p.address?.street?.includes('Hinterkirchweg') && 
      p.address?.city?.includes('Therwil')
    );
    
    if (!targetProperty) {
      console.log('\\nTarget property not found. Using first available property for testing.');
      const testProperty = properties[0];
      if (testProperty) {
        console.log(`Using property: ${testProperty._id} (${testProperty.address?.street})`);
        await testInvitationAPI(testProperty._id.toString(), tenant._id.toString());
      }
    } else {
      console.log(`\\nFound target property: ${targetProperty._id} (${targetProperty.address?.street})`);
      await testInvitationAPI(targetProperty._id.toString(), tenant._id.toString());
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

async function testInvitationAPI(propertyId, tenantId) {
  try {
    const response = await fetch('http://localhost:3000/api/invitations', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        propertyId: propertyId,
        landlordId: '6838699baefe2c0213aba1c3', // Use existing landlord
        tenantId: tenantId,
        message: 'Test invitation for debugging'
      })
    });
    
    const responseData = await response.json();
    console.log('\\nInvitation API Response:');
    console.log('Status:', response.status);
    console.log('Response:', responseData);
    
    if (response.status === 400) {
      console.log('\\n❌ Invitation creation blocked! This confirms the issue.');
    } else if (response.status === 201) {
      console.log('\\n✅ Invitation created successfully!');
    }
    
  } catch (error) {
    console.error('API Error:', error);
  }
}

testInvitationCreation();
