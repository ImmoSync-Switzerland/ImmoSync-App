const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function fixExistingInvitation() {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    // Find the accepted invitation
    const acceptedInvitation = await db.collection('invitations').findOne({
      _id: new ObjectId('689f08f5d5f0e9acf07b924a'),
      status: 'accepted'
    });
    
    if (acceptedInvitation) {
      console.log('Found accepted invitation:', acceptedInvitation);
      console.log('Property ID:', acceptedInvitation.propertyId);
      console.log('Tenant ID:', acceptedInvitation.tenantId);
      
      // Update the property to add the tenant
      console.log('\nUpdating property...');
      const propertyUpdateResult = await db.collection('properties').updateOne(
        { _id: new ObjectId(acceptedInvitation.propertyId) },
        { 
          $addToSet: { tenantIds: acceptedInvitation.tenantId },
          $set: { status: 'rented' }
        }
      );
      
      console.log('Property update result:', propertyUpdateResult);
      
      // Verify the update
      const updatedProperty = await db.collection('properties').findOne({
        _id: new ObjectId(acceptedInvitation.propertyId)
      });
      
      console.log('\nUpdated property:');
      console.log('tenantIds:', updatedProperty?.tenantIds);
      console.log('status:', updatedProperty?.status);
      
      // Test the tenant query
      console.log('\nTesting tenant properties query...');
      const tenantProperties = await db.collection('properties').find({
        tenantIds: { $in: [acceptedInvitation.tenantId] }
      }).toArray();
      
      console.log('Found properties for tenant:', tenantProperties.length);
      
    } else {
      console.log('Accepted invitation not found');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

fixExistingInvitation();
