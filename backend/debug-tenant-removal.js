const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function debugTenantRemovalIssue() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Debugging Tenant Removal Issue ===\n');
    
    // Search for the tenant by email
    const tenant = await db.collection('users').findOne({ email: 'markus@bs.ch' });
    
    if (!tenant) {
      console.log('Tenant markus@bs.ch not found in users collection');
      return;
    }
    
    console.log('Found tenant:');
    console.log('- ID:', tenant._id);
    console.log('- Name:', tenant.fullName);
    console.log('- Email:', tenant.email);
    
    // Check for existing invitations for this tenant
    const invitations = await db.collection('invitations').find({ 
      tenantId: tenant._id.toString() 
    }).toArray();
    
    console.log(`\nFound ${invitations.length} invitations for this tenant:`);
    
    invitations.forEach((inv, index) => {
      console.log(`\nInvitation ${index + 1}:`);
      console.log('- ID:', inv._id);
      console.log('- Property ID:', inv.propertyId);
      console.log('- Status:', inv.status);
      console.log('- Created:', inv.createdAt);
      if (inv.acceptedAt) console.log('- Accepted:', inv.acceptedAt);
    });
    
    // Check if tenant is still assigned to any properties
    const propertiesWithTenant = await db.collection('properties').find({
      tenantIds: { $in: [tenant._id.toString()] }
    }).toArray();
    
    console.log(`\nTenant is currently assigned to ${propertiesWithTenant.length} properties:`);
    propertiesWithTenant.forEach(prop => {
      console.log(`- Property: ${prop._id} (${prop.address?.street})`);
      console.log(`  tenantIds: [${prop.tenantIds.join(', ')}]`);
    });
    
    // Check for any pending/accepted invitations that would block new invitations
    const blockingInvitations = await db.collection('invitations').find({
      tenantId: tenant._id.toString(),
      status: { $in: ['pending', 'accepted'] }
    }).toArray();
    
    console.log(`\nFound ${blockingInvitations.length} invitations that could block new invitations:`);
    blockingInvitations.forEach(inv => {
      console.log(`- Invitation ${inv._id}: ${inv.status} for property ${inv.propertyId}`);
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

debugTenantRemovalIssue();
