const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function testFixedInvitationAcceptance() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Testing Fixed Invitation Acceptance ===\n');
    
    // Find a pending invitation
    const pendingInvitation = await db.collection('invitations').findOne({ status: 'pending' });
    
    if (!pendingInvitation) {
      console.log('No pending invitations found. Creating a test invitation...');
      
      // Create a test invitation
      const testInvitation = {
        propertyId: '6894ec4ad8ef35fa899f29fc', // Use existing property
        landlordId: '6838699baefe2c0213aba1c3', // Use existing landlord
        tenantId: '68926670d8ef35fa899f29f5', // Use existing tenant
        message: 'Test invitation for debugging',
        status: 'pending',
        createdAt: new Date(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      };
      
      const result = await db.collection('invitations').insertOne(testInvitation);
      console.log('Created test invitation:', result.insertedId);
      
      pendingInvitation = { ...testInvitation, _id: result.insertedId };
    }
    
    console.log('Processing invitation:', pendingInvitation._id.toString());
    console.log('- tenantId:', pendingInvitation.tenantId);
    console.log('- propertyId:', pendingInvitation.propertyId);
    
    // Test the API endpoint
    console.log('\\nTesting API endpoint...');
    const response = await fetch(`http://localhost:3000/api/invitations/${pendingInvitation._id}/accept`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      }
    });
    
    const responseData = await response.json();
    console.log('API Response status:', response.status);
    console.log('API Response:', responseData);
    
    // Check the results
    console.log('\\nChecking results...');
    
    // Check invitation status
    const updatedInvitation = await db.collection('invitations').findOne({ _id: pendingInvitation._id });
    console.log('Invitation status:', updatedInvitation?.status);
    
    // Check property assignment
    const property = await db.collection('properties').findOne({ 
      _id: new ObjectId(pendingInvitation.propertyId) 
    });
    console.log('Property tenantIds:', property?.tenantIds);
    console.log('Property status:', property?.status);
    
    // Check tenant can find the property
    const tenantProperties = await db.collection('properties').find({
      tenantIds: { $in: [pendingInvitation.tenantId] }
    }).toArray();
    console.log('Properties found for tenant:', tenantProperties.length);
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

testFixedInvitationAcceptance();
