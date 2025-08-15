const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function cleanupDuplicateInvitations() {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Cleaning up duplicate invitations ===');
    
    // Find duplicate invitations for the same property-tenant combination
    const duplicates = await db.collection('invitations').aggregate([
      {
        $group: {
          _id: { propertyId: "$propertyId", tenantId: "$tenantId" },
          count: { $sum: 1 },
          docs: { $push: "$$ROOT" }
        }
      },
      {
        $match: { count: { $gt: 1 } }
      }
    ]).toArray();
    
    console.log(`Found ${duplicates.length} duplicate groups`);
    
    for (const duplicate of duplicates) {
      console.log(`\nProperty ${duplicate._id.propertyId}, Tenant ${duplicate._id.tenantId}:`);
      console.log(`Found ${duplicate.count} invitations`);
      
      // Sort by date, keep the latest accepted one or the latest one overall
      const sortedDocs = duplicate.docs.sort((a, b) => {
        // Prioritize accepted invitations
        if (a.status === 'accepted' && b.status !== 'accepted') return -1;
        if (b.status === 'accepted' && a.status !== 'accepted') return 1;
        
        // Then by date (newest first)
        return new Date(b.createdAt) - new Date(a.createdAt);
      });
      
      const keepDoc = sortedDocs[0];
      const deleteDoc = sortedDocs.slice(1);
      
      console.log(`Keeping: ${keepDoc._id} (${keepDoc.status})`);
      console.log(`Deleting: ${deleteDoc.map(d => `${d._id} (${d.status})`).join(', ')}`);
      
      // Delete the duplicate invitations
      for (const doc of deleteDoc) {
        await db.collection('invitations').deleteOne({ _id: doc._id });
        console.log(`Deleted invitation ${doc._id}`);
      }
    }
    
    // Also clean up any pending invitations that are redundant (if tenant is already assigned)
    console.log('\n=== Cleaning up redundant pending invitations ===');
    
    const properties = await db.collection('properties').find({ tenantIds: { $exists: true, $ne: [] } }).toArray();
    
    for (const property of properties) {
      for (const tenantId of property.tenantIds) {
        const pendingInvitations = await db.collection('invitations').find({
          propertyId: property._id.toString(),
          tenantId: tenantId,
          status: 'pending'
        }).toArray();
        
        if (pendingInvitations.length > 0) {
          console.log(`Found ${pendingInvitations.length} pending invitations for already assigned tenant ${tenantId}`);
          
          for (const inv of pendingInvitations) {
            await db.collection('invitations').deleteOne({ _id: inv._id });
            console.log(`Deleted redundant pending invitation ${inv._id}`);
          }
        }
      }
    }
    
    console.log('\nCleanup completed!');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

cleanupDuplicateInvitations();
