const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function checkTestAcceptanceResult() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Checking Test Acceptance Result ===\n');
    
    // Check the test invitation we just accepted
    const testInvitation = await db.collection('invitations').findOne({
      _id: new ObjectId('689f887509dec572ddce2063')
    });
    
    if (testInvitation) {
      console.log('Test invitation status:');
      console.log('- Status:', testInvitation.status);
      console.log('- Property ID:', testInvitation.propertyId);
      console.log('- Tenant ID:', testInvitation.tenantId);
      if (testInvitation.acceptedAt) {
        console.log('- Accepted at:', testInvitation.acceptedAt);
      }
      
      // Check if the property was updated
      const property = await db.collection('properties').findOne({
        _id: new ObjectId(testInvitation.propertyId)
      });
      
      console.log('\\nProperty after acceptance:');
      console.log('- Property ID:', property._id);
      console.log('- Current tenantIds:', property.tenantIds);
      console.log('- Status:', property.status);
      
      const tenantAssigned = property.tenantIds && property.tenantIds.includes(testInvitation.tenantId);
      console.log(`\\nResult: ${tenantAssigned ? '✅ SUCCESS' : '❌ FAILED'} - Tenant ${tenantAssigned ? 'was' : 'was NOT'} assigned to property`);
      
      if (!tenantAssigned) {
        console.log('\\n🔍 This confirms the invitation acceptance is NOT working properly!');
        console.log('The API returns success but the property is not updated.');
      }
      
    } else {
      console.log('❌ Test invitation not found');
    }
    
    // Clean up the test invitation
    await db.collection('invitations').deleteOne({
      _id: new ObjectId('689f887509dec572ddce2063')
    });
    console.log('\\n🧹 Cleaned up test invitation');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

checkTestAcceptanceResult();
