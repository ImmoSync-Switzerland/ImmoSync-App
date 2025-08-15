const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function fixBrokenAcceptedInvitations() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Fixing Previously Broken Accepted Invitations ===\n');
    
    // Find accepted invitations where tenant was not assigned to property
    const acceptedInvitations = await db.collection('invitations').find({ status: 'accepted' }).toArray();
    
    console.log(`Found ${acceptedInvitations.length} accepted invitations to check`);
    
    let fixedCount = 0;
    
    for (const invitation of acceptedInvitations) {
      // Check if tenant is assigned to the property
      const property = await db.collection('properties').findOne({ 
        _id: new ObjectId(invitation.propertyId) 
      });
      
      if (property && (!property.tenantIds || !property.tenantIds.includes(invitation.tenantId))) {
        console.log(`\\nFixing invitation ${invitation._id}:`);
        console.log(`- Adding tenant ${invitation.tenantId} to property ${invitation.propertyId}`);
        
        // Add tenant to property
        const updateResult = await db.collection('properties').updateOne(
          { _id: new ObjectId(invitation.propertyId) },
          { 
            $addToSet: { tenantIds: invitation.tenantId },
            $set: { status: 'rented' }
          }
        );
        
        console.log(`- Update result: ${updateResult.modifiedCount > 0 ? 'SUCCESS' : 'NO CHANGE'}`);
        
        if (updateResult.modifiedCount > 0) {
          fixedCount++;
        }
      }
    }
    
    console.log(`\\nFixed ${fixedCount} broken invitations`);
    
    // Verify all tenants can now find their properties
    console.log('\\nVerification - checking all tenants can find their properties:');
    const uniqueTenantIds = [...new Set(acceptedInvitations.map(inv => inv.tenantId))];
    
    for (const tenantId of uniqueTenantIds) {
      const tenantProperties = await db.collection('properties').find({
        tenantIds: { $in: [tenantId] }
      }).toArray();
      
      console.log(`- Tenant ${tenantId}: ${tenantProperties.length} properties found`);
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

fixBrokenAcceptedInvitations();
