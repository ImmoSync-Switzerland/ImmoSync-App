const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function debugMarkusInvitation() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('=== Debugging Markus Invitation Issue ===\n');
    
    // Get tenant info
    const tenant = await db.collection('users').findOne({ email: 'markus@bs.ch' });
    console.log('Tenant info:');
    console.log('- ID:', tenant._id.toString());
    console.log('- Name:', tenant.fullName);
    console.log('- Email:', tenant.email);
    
    // Check all invitations for this tenant
    const invitations = await db.collection('invitations').find({ 
      tenantId: tenant._id.toString() 
    }).sort({ createdAt: -1 }).toArray();
    
    console.log(`\\nFound ${invitations.length} invitations for this tenant:`);
    invitations.forEach((inv, index) => {
      console.log(`\\n${index + 1}. Invitation ${inv._id}:`);
      console.log('   - Property ID:', inv.propertyId);
      console.log('   - Status:', inv.status);
      console.log('   - Created:', inv.createdAt);
      if (inv.acceptedAt) console.log('   - Accepted:', inv.acceptedAt);
    });
    
    // Check properties to see current tenant assignments
    const properties = await db.collection('properties').find({}).toArray();
    console.log('\\nCurrent property tenant assignments:');
    properties.forEach(prop => {
      console.log(`\\nProperty ${prop._id} (${prop.address?.street}):`);
      console.log('- Status:', prop.status);
      console.log('- TenantIds:', prop.tenantIds || []);
      if (prop.tenantIds && prop.tenantIds.includes(tenant._id.toString())) {
        console.log('  ✅ Markus IS assigned to this property');
      } else {
        console.log('  ❌ Markus is NOT assigned to this property');
      }
    });
    
    // If there's a pending invitation, let's test accepting it
    const pendingInvitation = invitations.find(inv => inv.status === 'pending');
    if (pendingInvitation) {
      console.log(`\\n🔄 Found pending invitation ${pendingInvitation._id}`);
      console.log('Attempting to accept it via API...');
      
      try {
        const response = await fetch(`http://localhost:3000/api/invitations/${pendingInvitation._id}/accept`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          }
        });
        
        const responseData = await response.json();
        console.log('Accept API Response:');
        console.log('- Status:', response.status);
        console.log('- Data:', responseData);
        
        if (response.status === 200) {
          // Check if the property was updated
          const updatedProperty = await db.collection('properties').findOne({ 
            _id: new ObjectId(pendingInvitation.propertyId) 
          });
          console.log('\\nProperty after acceptance:');
          console.log('- TenantIds:', updatedProperty?.tenantIds);
          console.log('- Status:', updatedProperty?.status);
          
          // Check if invitation status changed
          const updatedInvitation = await db.collection('invitations').findOne({ 
            _id: pendingInvitation._id 
          });
          console.log('\\nInvitation after acceptance:');
          console.log('- Status:', updatedInvitation?.status);
          console.log('- AcceptedAt:', updatedInvitation?.acceptedAt);
        }
        
      } catch (error) {
        console.error('API Error:', error.message);
      }
    } else {
      console.log('\\n ℹ️ No pending invitations found');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

debugMarkusInvitation();
