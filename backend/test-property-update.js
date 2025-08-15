const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function testPropertyUpdate() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Testing Property Update ===\n');
    
    // Get the accepted invitation we just updated
    const acceptedInvitation = await db.collection('invitations').findOne({ 
      status: 'accepted',
      _id: new ObjectId('6894ec5fd8ef35fa899f29fd')
    });
    
    if (!acceptedInvitation) {
      console.log('No accepted invitation found.');
      return;
    }
    
    console.log('Processing accepted invitation:');
    console.log('- tenantId:', acceptedInvitation.tenantId);
    console.log('- propertyId:', acceptedInvitation.propertyId);
    
    // Check property before update
    const propertyBefore = await db.collection('properties').findOne({ 
      _id: new ObjectId(acceptedInvitation.propertyId) 
    });
    console.log('\\nProperty before update:', {
      id: propertyBefore?._id,
      tenantIds: propertyBefore?.tenantIds,
      status: propertyBefore?.status
    });
    
    // Update the property
    console.log('\\nUpdating property...');
    const propertyUpdate = await db.collection('properties').updateOne(
      { _id: new ObjectId(acceptedInvitation.propertyId) },
      { 
        $addToSet: { tenantIds: acceptedInvitation.tenantId },
        $set: { status: 'rented' }
      }
    );
    
    console.log('Property update result:', {
      acknowledged: propertyUpdate.acknowledged,
      matchedCount: propertyUpdate.matchedCount,
      modifiedCount: propertyUpdate.modifiedCount
    });
    
    // Check property after update
    const propertyAfter = await db.collection('properties').findOne({ 
      _id: new ObjectId(acceptedInvitation.propertyId) 
    });
    console.log('\\nProperty after update:', {
      id: propertyAfter?._id,
      tenantIds: propertyAfter?.tenantIds,
      status: propertyAfter?.status
    });
    
    // Test tenant lookup
    console.log('\\nTesting tenant property lookup...');
    const tenantProperties = await db.collection('properties').find({
      tenantIds: { $in: [acceptedInvitation.tenantId] }
    }).toArray();
    
    console.log('Properties found for tenant:', tenantProperties.length);
    tenantProperties.forEach(prop => {
      console.log('- Property:', prop._id, 'Address:', prop.address?.street);
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

testPropertyUpdate();
