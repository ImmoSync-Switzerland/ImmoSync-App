const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function testInvitationAcceptance() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Testing Invitation Acceptance Logic ===\n');
    
    // Find a pending invitation to test with
    const pendingInvitation = await db.collection('invitations').findOne({ status: 'pending' });
    
    if (!pendingInvitation) {
      console.log('No pending invitations found. Let\'s check the accepted ones that failed.');
      
      // Get an accepted invitation that should have updated the property
      const acceptedInvitation = await db.collection('invitations').findOne({ status: 'accepted' });
      
      if (acceptedInvitation) {
        console.log('Testing with accepted invitation:', acceptedInvitation._id.toString());
        console.log('Invitation details:');
        console.log('- tenantId:', acceptedInvitation.tenantId, '(type:', typeof acceptedInvitation.tenantId, ')');
        console.log('- propertyId:', acceptedInvitation.propertyId, '(type:', typeof acceptedInvitation.propertyId, ')');
        
        // Test the property update query that should have been executed
        console.log('\nTesting property update query...');
        
        const propertyBefore = await db.collection('properties').findOne({ 
          _id: new ObjectId(acceptedInvitation.propertyId) 
        });
        console.log('Property before update:', {
          id: propertyBefore._id,
          tenantIds: propertyBefore.tenantIds,
          status: propertyBefore.status
        });
        
        // Try the same update that should have happened
        console.log('\\nAttempting property update...');
        const updateResult = await db.collection('properties').updateOne(
          { _id: new ObjectId(acceptedInvitation.propertyId) },
          { 
            $addToSet: { tenantIds: acceptedInvitation.tenantId },
            $set: { status: 'rented' }
          }
        );
        
        console.log('Update result:', updateResult);
        
        const propertyAfter = await db.collection('properties').findOne({ 
          _id: new ObjectId(acceptedInvitation.propertyId) 
        });
        console.log('Property after update:', {
          id: propertyAfter._id,
          tenantIds: propertyAfter.tenantIds,
          status: propertyAfter.status
        });
      }
    } else {
      console.log('Found pending invitation:', pendingInvitation._id.toString());
      // We could simulate acceptance here if needed
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

testInvitationAcceptance();
