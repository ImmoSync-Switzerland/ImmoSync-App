const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function testInvitationFlow() {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    // Test data
    const propertyId = '684478e4c96b1ebd4147fc5b';
    const landlordId = '6838699baefe2c0213aba1c3';
    const tenantId = '68474aa1e3240f44ed3cc8bc';
    
    console.log('=== Testing Invitation Flow ===');
    console.log(`Property: ${propertyId}`);
    console.log(`Landlord: ${landlordId}`);
    console.log(`Tenant: ${tenantId}`);
    
    // 1. Check current property state
    console.log('\n1. Current property state:');
    const property = await db.collection('properties').findOne({ _id: new ObjectId(propertyId) });
    console.log('tenantIds:', property?.tenantIds);
    console.log('status:', property?.status);
    
    // 2. Check existing invitations
    console.log('\n2. Existing invitations:');
    const invitations = await db.collection('invitations').find({
      propertyId: propertyId,
      tenantId: tenantId
    }).toArray();
    console.log('Found invitations:', invitations.length);
    invitations.forEach(inv => {
      console.log(`- ${inv._id}: ${inv.status} (created: ${inv.createdAt})`);
    });
    
    // 3. Create new invitation
    console.log('\n3. Creating new invitation...');
    const newInvitation = {
      propertyId: propertyId,
      landlordId: landlordId,
      tenantId: tenantId,
      message: 'Test invitation',
      status: 'pending',
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    };
    
    const invitationResult = await db.collection('invitations').insertOne(newInvitation);
    console.log('Invitation created:', invitationResult.insertedId);
    
    // 4. Accept the invitation (simulate)
    console.log('\n4. Accepting invitation...');
    const acceptResult = await db.collection('invitations').findOneAndUpdate(
      { _id: invitationResult.insertedId, status: 'pending' },
      { 
        $set: { 
          status: 'accepted',
          acceptedAt: new Date()
        }
      },
      { returnDocument: 'after' }
    );
    
    if (acceptResult.value) {
      console.log('Invitation accepted successfully');
      
      // 5. Add tenant to property
      console.log('\n5. Adding tenant to property...');
      const propertyUpdateResult = await db.collection('properties').updateOne(
        { _id: new ObjectId(acceptResult.value.propertyId) },
        { 
          $addToSet: { tenantIds: acceptResult.value.tenantId },
          $set: { status: 'rented' }
        }
      );
      
      console.log('Property update result:', propertyUpdateResult);
      console.log('Matched:', propertyUpdateResult.matchedCount);
      console.log('Modified:', propertyUpdateResult.modifiedCount);
      
      // 6. Verify property was updated
      console.log('\n6. Verifying property update...');
      const updatedProperty = await db.collection('properties').findOne({ _id: new ObjectId(propertyId) });
      console.log('Updated tenantIds:', updatedProperty?.tenantIds);
      console.log('Updated status:', updatedProperty?.status);
      
      // 7. Test tenant properties query
      console.log('\n7. Testing tenant properties query...');
      const tenantProperties = await db.collection('properties').find({
        tenantIds: { $in: [tenantId] }
      }).toArray();
      console.log('Found properties for tenant:', tenantProperties.length);
      
    } else {
      console.log('Failed to accept invitation');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

testInvitationFlow();
