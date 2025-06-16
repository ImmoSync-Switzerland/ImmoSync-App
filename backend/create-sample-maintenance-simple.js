const { connectDB } = require('./database');
const { ObjectId } = require('mongodb');

async function createSampleMaintenanceRequests() {
  try {
    const db = await connectDB();
    console.log('Connected to MongoDB');

    // Clear existing maintenance requests
    await db.collection('maintenanceRequests').deleteMany({});
    console.log('Cleared existing maintenance requests');

    const sampleRequests = [
      {
        propertyId: new ObjectId('684478e4c96b1ebd4147fc5b'), // Existing property
        tenantId: new ObjectId('67ba0042ad10d79f7aba01a2'), // Existing tenant
        landlordId: new ObjectId('6838699baefe2c0213aba1c3'), // Existing landlord
        title: 'Heating System Not Working',
        description: 'The heating system in the living room is not working properly. Temperature is not reaching the set level.',
        category: 'heating',
        priority: 'high',
        status: 'pending',
        location: 'Living Room',
        images: [],
        urgencyLevel: 4,
        notes: [],
        createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
        updatedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
      },
      {
        propertyId: new ObjectId('684478e4c96b1ebd4147fc5b'),
        tenantId: new ObjectId('68474aa1e3240f44ed3cc8bc'),
        landlordId: new ObjectId('6838699baefe2c0213aba1c3'),
        title: 'Kitchen Sink Leaking',
        description: 'The kitchen sink has been leaking water from the faucet. It\'s getting worse over time.',
        category: 'plumbing',
        priority: 'medium',
        status: 'pending',
        location: 'Kitchen',
        images: [],
        urgencyLevel: 3,
        notes: [],
        createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000), // 5 hours ago
        updatedAt: new Date(Date.now() - 5 * 60 * 60 * 1000),
      },
      {
        propertyId: new ObjectId('684478e4c96b1ebd4147fc5b'),
        tenantId: new ObjectId('67ba0042ad10d79f7aba01a2'),
        landlordId: new ObjectId('6838699baefe2c0213aba1c3'),
        title: 'Bedroom Light Fixture',
        description: 'The light fixture in the bedroom is flickering and sometimes doesn\'t turn on.',
        category: 'electrical',
        priority: 'low',
        status: 'pending',
        location: 'Bedroom',
        images: [],
        urgencyLevel: 2,
        notes: [],
        createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
        updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
      },
    ];

    const result = await db.collection('maintenanceRequests').insertMany(sampleRequests);
    console.log(`Created ${result.insertedCount} sample maintenance requests:`);
    
    sampleRequests.forEach((request, index) => {
      console.log(`${index + 1}. ${request.title} - Priority: ${request.priority} - Status: ${request.status}`);
    });

  } catch (error) {
    console.error('Error creating sample maintenance requests:', error);
  } finally {
    process.exit(0);
  }
}

createSampleMaintenanceRequests();
