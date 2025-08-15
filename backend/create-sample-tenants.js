const { MongoClient } = require('mongodb');
const { dbUri, dbName } = require('./config');

async function createSampleTenants() {
  const client = new MongoClient(dbUri);

  try {
    await client.connect();
    console.log('Connected to MongoDB');

    const db = client.db(dbName);
    const collection = db.collection('users');

    // Sample tenants data
    const sampleTenants = [
      {
        fullName: 'Emma Weber',
        email: 'emma.weber@email.com',
        role: 'tenant',
        phone: '+41 79 234 56 78',
        createdAt: new Date(),
        isActive: true
      },
      {
        fullName: 'Mike Johnson',
        email: 'mike.johnson@email.com',
        role: 'tenant',
        phone: '+41 79 345 67 89',
        createdAt: new Date(),
        isActive: true
      },
      {
        fullName: 'Sarah Wilson',
        email: 'sarah.wilson@email.com',
        role: 'tenant',
        phone: '+41 79 456 78 90',
        createdAt: new Date(),
        isActive: true
      },
      {
        fullName: 'David Brown',
        email: 'david.brown@email.com',
        role: 'tenant',
        phone: '+41 79 567 89 01',
        createdAt: new Date(),
        isActive: true
      },
      {
        fullName: 'Lisa Martinez',
        email: 'lisa.martinez@email.com',
        role: 'tenant',
        phone: '+41 79 678 90 12',
        createdAt: new Date(),
        isActive: true
      },
      {
        fullName: 'Tom Anderson',
        email: 'tom.anderson@email.com',
        role: 'tenant',
        phone: '+41 79 789 01 23',
        createdAt: new Date(),
        isActive: true
      }
    ];

    // Check if tenants already exist to avoid duplicates
    for (const tenant of sampleTenants) {
      const existingTenant = await collection.findOne({ email: tenant.email });
      if (!existingTenant) {
        await collection.insertOne(tenant);
        console.log(`Created tenant: ${tenant.fullName}`);
      } else {
        console.log(`Tenant already exists: ${tenant.fullName}`);
      }
    }

    console.log('Sample tenants creation completed');

  } catch (error) {
    console.error('Error creating sample tenants:', error);
  } finally {
    await client.close();
  }
}

createSampleTenants();
