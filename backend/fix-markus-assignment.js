const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function fixMarkusAssignment() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Fixing Markus Property Assignment ===\n');
    
    const tenant = await db.collection('users').findOne({ email: 'markus@bs.ch' });
    const tenantId = tenant._id.toString();
    
    // Find the accepted invitation
    const acceptedInvitation = await db.collection('invitations').findOne({
      tenantId: tenantId,
      status: 'accepted'
    });
    
    if (!acceptedInvitation) {
      console.log('No accepted invitation found');
      return;
    }
    
    console.log(`Found accepted invitation for property: ${acceptedInvitation.propertyId}`);
    
    // Check property before update
    const propertyBefore = await db.collection('properties').findOne({
      _id: new ObjectId(acceptedInvitation.propertyId)
    });
    
    console.log('Property before fix:');
    console.log('- TenantIds:', propertyBefore?.tenantIds);
    console.log('- Status:', propertyBefore?.status);
    
    // Add tenant to property (this should have happened during invitation acceptance)
    console.log('\\n🔧 Adding Markus to property...');
    const updateResult = await db.collection('properties').updateOne(
      { _id: new ObjectId(acceptedInvitation.propertyId) },
      { 
        $addToSet: { tenantIds: tenantId },
        $set: { status: 'rented' }
      }
    );
    
    console.log('Update result:', {
      acknowledged: updateResult.acknowledged,
      matchedCount: updateResult.matchedCount,
      modifiedCount: updateResult.modifiedCount
    });
    
    // Check property after update
    const propertyAfter = await db.collection('properties').findOne({
      _id: new ObjectId(acceptedInvitation.propertyId)
    });
    
    console.log('\\nProperty after fix:');
    console.log('- TenantIds:', propertyAfter?.tenantIds);
    console.log('- Status:', propertyAfter?.status);
    
    // Verify tenant can now find their properties
    const tenantProperties = await db.collection('properties').find({
      tenantIds: { $in: [tenantId] }
    }).toArray();
    
    console.log(`\\n✅ Markus can now find ${tenantProperties.length} properties:`);
    tenantProperties.forEach(prop => {
      console.log(`- ${prop._id}: ${prop.address?.street}, ${prop.address?.city}`);
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

fixMarkusAssignment();
