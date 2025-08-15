const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function checkAllInvitations() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Checking All Invitations ===\n');
    
    // Get the tenant
    const tenant = await db.collection('users').findOne({ email: 'markus@bs.ch' });
    const tenantId = tenant._id.toString();
    
    // Check all invitations in the database
    const allInvitations = await db.collection('invitations').find({}).toArray();
    console.log(`Total invitations in database: ${allInvitations.length}`);
    
    // Check invitations for this specific tenant
    const tenantInvitations = allInvitations.filter(inv => inv.tenantId === tenantId);
    console.log(`\\nInvitations for tenant ${tenant.fullName} (${tenantId}):`);
    
    if (tenantInvitations.length === 0) {
      console.log('- No invitations found');
    } else {
      tenantInvitations.forEach((inv, index) => {
        console.log(`\\nInvitation ${index + 1}:`);
        console.log(`- ID: ${inv._id}`);
        console.log(`- Property: ${inv.propertyId}`);
        console.log(`- Status: ${inv.status}`);
        console.log(`- Created: ${inv.createdAt}`);
        if (inv.acceptedAt) console.log(`- Accepted: ${inv.acceptedAt}`);
      });
    }
    
    // Check the most recent invitation we just created
    const recentInvitations = await db.collection('invitations')
      .find({ tenantId: tenantId })
      .sort({ createdAt: -1 })
      .limit(3)
      .toArray();
      
    console.log(`\\nMost recent invitations for this tenant:`);
    recentInvitations.forEach((inv, index) => {
      console.log(`${index + 1}. ${inv._id} - ${inv.status} (${inv.createdAt})`);
    });
    
    // Check if the tenant is currently assigned to any properties
    const currentAssignments = await db.collection('properties').find({
      tenantIds: { $in: [tenantId] }
    }).toArray();
    
    console.log(`\\nCurrent property assignments: ${currentAssignments.length}`);
    currentAssignments.forEach(prop => {
      console.log(`- Property: ${prop._id} (${prop.address?.street})`);
    });
    
    // Check for any conflicting invitations that might block new ones
    const conflicts = await db.collection('invitations').find({
      tenantId: tenantId,
      status: { $in: ['pending', 'accepted'] }
    }).toArray();
    
    console.log(`\\nPotential blocking invitations: ${conflicts.length}`);
    conflicts.forEach(inv => {
      console.log(`- ${inv._id}: ${inv.status} for property ${inv.propertyId}`);
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

checkAllInvitations();
