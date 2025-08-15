const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function debugTenantAssignment() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Debugging Tenant Assignment ===\n');
    
    // Check accepted invitations
    const acceptedInvitations = await db.collection('invitations').find({ status: 'accepted' }).toArray();
    console.log(`Found ${acceptedInvitations.length} accepted invitations:`);
    
    for (const invitation of acceptedInvitations) {
      console.log(`\nInvitation ${invitation._id}:`);
      console.log(`- tenantId: ${invitation.tenantId} (type: ${typeof invitation.tenantId})`);
      console.log(`- propertyId: ${invitation.propertyId} (type: ${typeof invitation.propertyId})`);
      console.log(`- status: ${invitation.status}`);
      
      // Check if property was updated
      const property = await db.collection('properties').findOne({ _id: new ObjectId(invitation.propertyId) });
      if (property) {
        console.log(`- Property tenantIds: [${property.tenantIds || 'none'}]`);
        console.log(`- Property status: ${property.status}`);
        
        // Check if tenant ID is in the array
        const tenantInProperty = property.tenantIds && property.tenantIds.includes(invitation.tenantId);
        console.log(`- Tenant assigned to property: ${tenantInProperty}`);
      } else {
        console.log(`- Property not found for ID: ${invitation.propertyId}`);
      }
    }
    
    // Check all properties with tenants
    console.log('\n=== All Properties with Tenants ===');
    const propertiesWithTenants = await db.collection('properties').find({ 
      tenantIds: { $exists: true, $ne: [] } 
    }).toArray();
    
    console.log(`Found ${propertiesWithTenants.length} properties with tenants:`);
    for (const property of propertiesWithTenants) {
      console.log(`\nProperty ${property._id} (${property.address?.street}):`);
      console.log(`- tenantIds: [${property.tenantIds.join(', ')}]`);
      console.log(`- tenantIds types: [${property.tenantIds.map(id => typeof id).join(', ')}]`);
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

debugTenantAssignment();
