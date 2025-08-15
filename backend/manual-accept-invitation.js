const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function manuallyAcceptInvitation() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Manually Accepting Invitation ===\n');
    
    // Find a pending invitation
    const pendingInvitation = await db.collection('invitations').findOne({ status: 'pending' });
    
    if (!pendingInvitation) {
      console.log('No pending invitations found.');
      return;
    }
    
    console.log('Processing invitation:', pendingInvitation._id.toString());
    console.log('- tenantId:', pendingInvitation.tenantId);
    console.log('- propertyId:', pendingInvitation.propertyId);
    
    // Step 1: Update invitation status
    console.log('\\nStep 1: Updating invitation status...');
    const invitationUpdate = await db.collection('invitations').findOneAndUpdate(
      { _id: pendingInvitation._id, status: 'pending' },
      { 
        $set: { 
          status: 'accepted',
          acceptedAt: new Date()
        }
      },
      { returnDocument: 'after' }
    );
    
    console.log('Invitation update result:', invitationUpdate.ok ? 'SUCCESS' : 'FAILED');
    
    if (!invitationUpdate.value) {
      console.log('Failed to update invitation');
      return;
    }
    
    // Step 2: Update property
    console.log('\\nStep 2: Updating property...');
    console.log('Property ID to update:', invitationUpdate.value.propertyId);
    console.log('Tenant ID to add:', invitationUpdate.value.tenantId);
    
    const propertyBefore = await db.collection('properties').findOne({ 
      _id: new ObjectId(invitationUpdate.value.propertyId) 
    });
    console.log('Property before update:', {
      id: propertyBefore?._id,
      tenantIds: propertyBefore?.tenantIds,
      status: propertyBefore?.status
    });
    
    const propertyUpdate = await db.collection('properties').updateOne(
      { _id: new ObjectId(invitationUpdate.value.propertyId) },
      { 
        $addToSet: { tenantIds: invitationUpdate.value.tenantId },
        $set: { status: 'rented' }
      }
    );
    
    console.log('Property update result:', {
      acknowledged: propertyUpdate.acknowledged,
      matchedCount: propertyUpdate.matchedCount,
      modifiedCount: propertyUpdate.modifiedCount
    });
    
    const propertyAfter = await db.collection('properties').findOne({ 
      _id: new ObjectId(invitationUpdate.value.propertyId) 
    });
    console.log('Property after update:', {
      id: propertyAfter?._id,
      tenantIds: propertyAfter?.tenantIds,
      status: propertyAfter?.status
    });
    
    // Step 3: Verify tenant can find the property
    console.log('\\nStep 3: Testing tenant property lookup...');
    const tenantProperties = await db.collection('properties').find({
      tenantIds: { $in: [invitationUpdate.value.tenantId] }
    }).toArray();
    
    console.log('Properties found for tenant:', tenantProperties.length);
    tenantProperties.forEach(prop => {
      console.log('- Property:', prop._id, 'tenantIds:', prop.tenantIds);
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

manuallyAcceptInvitation();
