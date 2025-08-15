const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function debugCurrentInvitations() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Current Invitations Status ===\n');
    
    // Get Markus info
    const tenant = await db.collection('users').findOne({ email: 'markus@bs.ch' });
    console.log(`Tenant: ${tenant.fullName} (${tenant._id})`);
    
    // Check all invitations for Markus
    const allInvitations = await db.collection('invitations').find({
      tenantId: tenant._id.toString()
    }).sort({ createdAt: -1 }).toArray();
    
    console.log(`\\nAll invitations for Markus (${allInvitations.length}):`);
    allInvitations.forEach((inv, index) => {
      console.log(`${index + 1}. ${inv._id} - Status: ${inv.status} - Property: ${inv.propertyId}`);
      console.log(`   Created: ${inv.createdAt}`);
      if (inv.acceptedAt) console.log(`   Accepted: ${inv.acceptedAt}`);
    });
    
    // Check for pending invitations specifically
    const pendingInvitations = await db.collection('invitations').find({
      tenantId: tenant._id.toString(),
      status: 'pending'
    }).toArray();
    
    console.log(`\\nPending invitations (${pendingInvitations.length}):`);
    if (pendingInvitations.length === 0) {
      console.log('❌ No pending invitations found! This explains why clicking Accept does nothing.');
      console.log('\\nLet me create a test invitation to reproduce the issue...');
      
      // Create a test invitation
      const testInvitation = {
        propertyId: '6894ec4ad8ef35fa899f29fc', // Different property to test
        landlordId: '6838699baefe2c0213aba1c3',
        tenantId: tenant._id.toString(),
        message: 'Test invitation to debug acceptance issue',
        status: 'pending',
        createdAt: new Date(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      };
      
      const result = await db.collection('invitations').insertOne(testInvitation);
      console.log(`\\n✅ Created test invitation: ${result.insertedId}`);
      
      // Test accepting it immediately
      console.log('\\n🧪 Testing invitation acceptance API...');
      try {
        const response = await fetch(`http://localhost:3000/api/invitations/${result.insertedId}/accept`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          }
        });
        
        const responseData = await response.json();
        console.log('API Response:');
        console.log('- Status:', response.status);
        console.log('- Data:', JSON.stringify(responseData, null, 2));
        
        if (response.status === 200) {
          console.log('\\n✅ API call successful! Check server logs for detailed acceptance process.');
        } else {
          console.log('\\n❌ API call failed!');
        }
        
      } catch (error) {
        console.error('❌ Network error:', error.message);
      }
      
    } else {
      pendingInvitations.forEach((inv, index) => {
        console.log(`${index + 1}. ${inv._id} - Property: ${inv.propertyId}`);
      });
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

debugCurrentInvitations();
