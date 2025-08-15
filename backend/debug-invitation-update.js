const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function debugInvitationUpdate() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Debugging Invitation Update ===\n');
    
    // Find a pending invitation and check its exact structure
    const pendingInvitation = await db.collection('invitations').findOne({ status: 'pending' });
    
    if (!pendingInvitation) {
      console.log('No pending invitations found.');
      return;
    }
    
    console.log('Pending invitation details:');
    console.log(JSON.stringify(pendingInvitation, null, 2));
    
    // Test the exact query used in the update
    console.log('\\nTesting find query...');
    const findQuery = { _id: pendingInvitation._id, status: 'pending' };
    const foundInvitation = await db.collection('invitations').findOne(findQuery);
    console.log('Found with query:', foundInvitation ? 'YES' : 'NO');
    
    if (foundInvitation) {
      console.log('Found invitation:', foundInvitation._id);
      
      // Try a simple update without findOneAndUpdate
      console.log('\\nTrying simple update...');
      const simpleUpdate = await db.collection('invitations').updateOne(
        { _id: pendingInvitation._id },
        { 
          $set: { 
            status: 'accepted',
            acceptedAt: new Date()
          }
        }
      );
      
      console.log('Simple update result:', {
        acknowledged: simpleUpdate.acknowledged,
        matchedCount: simpleUpdate.matchedCount,
        modifiedCount: simpleUpdate.modifiedCount
      });
      
      // Check the invitation after update
      const afterUpdate = await db.collection('invitations').findOne({ _id: pendingInvitation._id });
      console.log('Invitation after update:', {
        id: afterUpdate._id,
        status: afterUpdate.status,
        acceptedAt: afterUpdate.acceptedAt
      });
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

debugInvitationUpdate();
