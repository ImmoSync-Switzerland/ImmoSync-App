const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function testAvailableTenants() {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const propertyId = '684478e4c96b1ebd4147fc5b';
    const tenantId = '68474aa1e3240f44ed3cc8bc';
    
    console.log('=== Testing Available Tenants Logic ===');
    console.log(`Property ID: ${propertyId}`);
    console.log(`Tenant ID: ${tenantId}`);
    
    // 1. Get all tenants
    console.log('\n1. All tenants:');
    const allTenants = await db.collection('users').find({ role: 'tenant' }).toArray();
    console.log(`Found ${allTenants.length} total tenants`);
    
    // 2. Check property tenantIds
    console.log('\n2. Property tenantIds:');
    const property = await db.collection('properties').findOne({ _id: new ObjectId(propertyId) });
    const assignedTenantIds = property?.tenantIds || [];
    console.log('Assigned tenant IDs:', assignedTenantIds);
    
    // 3. Check invitations for this property
    console.log('\n3. Invitations for this property:');
    const invitations = await db.collection('invitations').find({ 
      propertyId: propertyId,
      status: { $in: ['pending', 'accepted'] }
    }).toArray();
    console.log(`Found ${invitations.length} invitations:`);
    invitations.forEach(inv => {
      console.log(`- Tenant: ${inv.tenantId}, Status: ${inv.status}`);
    });
    
    const invitedTenantIds = invitations.map(inv => inv.tenantId);
    
    // 4. Combine exclusions
    console.log('\n4. Exclusion logic:');
    const excludedTenantIds = [...assignedTenantIds, ...invitedTenantIds];
    console.log('Excluded tenant IDs:', excludedTenantIds);
    
    // 5. Filter available tenants
    console.log('\n5. Available tenants:');
    const availableTenants = allTenants.filter(tenant => 
      !excludedTenantIds.includes(tenant._id.toString())
    );
    console.log(`Available tenants: ${availableTenants.length}`);
    availableTenants.forEach(tenant => {
      console.log(`- ${tenant.fullName} (${tenant.email})`);
    });
    
    // 6. Check if our specific tenant is excluded
    console.log('\n6. Specific tenant check:');
    const isExcluded = excludedTenantIds.includes(tenantId);
    console.log(`Is tenant ${tenantId} excluded? ${isExcluded}`);
    if (isExcluded) {
      console.log('- Assigned to property:', assignedTenantIds.includes(tenantId));
      console.log('- Has invitation:', invitedTenantIds.includes(tenantId));
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

testAvailableTenants();
