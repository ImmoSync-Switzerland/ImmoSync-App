const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function clearTenantInvitations() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Clear Tenant Invitations Utility ===\n');
    
    // Get command line arguments
    const args = process.argv.slice(2);
    if (args.length < 1) {
      console.log('Usage: node clear-tenant-invitations.js <tenant-email> [property-id]');
      console.log('');
      console.log('Examples:');
      console.log('  node clear-tenant-invitations.js markus@bs.ch');
      console.log('  node clear-tenant-invitations.js markus@bs.ch 68386e94669815020500ddad');
      return;
    }
    
    const tenantEmail = args[0];
    const specificPropertyId = args[1];
    
    // Find the tenant
    const tenant = await db.collection('users').findOne({ email: tenantEmail });
    if (!tenant) {
      console.log(`❌ Tenant with email ${tenantEmail} not found`);
      return;
    }
    
    console.log(`Found tenant: ${tenant.fullName} (${tenant._id})`);
    
    // Build query
    let query = { tenantId: tenant._id.toString() };
    if (specificPropertyId) {
      query.propertyId = specificPropertyId;
      console.log(`Targeting specific property: ${specificPropertyId}`);
    }
    
    // Find invitations to delete
    const invitationsToDelete = await db.collection('invitations').find(query).toArray();
    
    if (invitationsToDelete.length === 0) {
      console.log('✅ No invitations found to delete');
      return;
    }
    
    console.log(`\\nFound ${invitationsToDelete.length} invitation(s) to delete:`);
    invitationsToDelete.forEach((inv, index) => {
      console.log(`${index + 1}. ${inv._id} - ${inv.status} (Property: ${inv.propertyId})`);
    });
    
    // Delete invitations
    const deleteResult = await db.collection('invitations').deleteMany(query);
    console.log(`\\n✅ Deleted ${deleteResult.deletedCount} invitation(s)`);
    
    // Delete related conversations
    const conversationIds = invitationsToDelete.map(inv => inv._id.toString());
    const conversationDeleteResult = await db.collection('conversations').deleteMany({
      relatedInvitationId: { $in: conversationIds }
    });
    console.log(`✅ Deleted ${conversationDeleteResult.deletedCount} related conversation(s)`);
    
    // Delete related messages (find conversations first, then delete messages)
    const conversations = await db.collection('conversations').find({
      relatedInvitationId: { $in: conversationIds }
    }).toArray();
    
    if (conversations.length > 0) {
      const conversationIdStrings = conversations.map(conv => conv._id.toString());
      const messagesDeleteResult = await db.collection('messages').deleteMany({
        conversationId: { $in: conversationIdStrings }
      });
      console.log(`✅ Deleted ${messagesDeleteResult.deletedCount} related message(s)`);
    }
    
    console.log(`\\n🎉 Successfully cleared invitations for ${tenant.fullName}`);
    console.log('You can now create new invitations for this tenant.');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

clearTenantInvitations();
