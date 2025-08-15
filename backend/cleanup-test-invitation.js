const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function cleanupTestInvitation() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Cleaning Up Test Invitation ===\n');
    
    // Get the tenant
    const tenant = await db.collection('users').findOne({ email: 'markus@bs.ch' });
    const tenantId = tenant._id.toString();
    
    // Find and remove the test invitation we just created
    const testInvitation = await db.collection('invitations').findOne({
      _id: new ObjectId('689f85eb8816bebbcc9b7fc5')
    });
    
    if (testInvitation) {
      console.log('Found test invitation:');
      console.log('- ID:', testInvitation._id);
      console.log('- Status:', testInvitation.status);
      console.log('- Property:', testInvitation.propertyId);
      
      // Delete the test invitation
      const deleteResult = await db.collection('invitations').deleteOne({
        _id: new ObjectId('689f85eb8816bebbcc9b7fc5')
      });
      
      console.log(`\\nDeleted ${deleteResult.deletedCount} test invitation(s)`);
      
      // Also delete the related conversation if it exists
      const conversationDeleteResult = await db.collection('conversations').deleteOne({
        relatedInvitationId: '689f85eb8816bebbcc9b7fc5'
      });
      
      console.log(`Deleted ${conversationDeleteResult.deletedCount} related conversation(s)`);
      
      // Delete related messages
      const messagesDeleteResult = await db.collection('messages').deleteMany({
        conversationId: '689f85eb8816bebbcc9b7fc6'
      });
      
      console.log(`Deleted ${messagesDeleteResult.deletedCount} related message(s)`);
    }
    
    // Verify cleanup
    const remainingInvitations = await db.collection('invitations').find({
      tenantId: tenantId
    }).toArray();
    
    console.log(`\\nRemaining invitations for tenant: ${remainingInvitations.length}`);
    
    console.log('\\n✅ Cleanup complete! You should now be able to invite the tenant again.');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

cleanupTestInvitation();
