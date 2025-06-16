const mongoose = require('mongoose');
const MaintenanceRequest = require('./models/maintenance_request_schema');
const { connectDB } = require('./database');

async function createSampleMaintenanceRequests() {
  try {
    await connectDB();
    console.log('Connected to MongoDB');

    // Clear existing maintenance requests
    await MaintenanceRequest.deleteMany({});
    console.log('Cleared existing maintenance requests');

    const sampleRequests = [
      {
        propertyId: new mongoose.Types.ObjectId('684478e4c96b1ebd4147fc5b'), // Existing property
        tenantId: new mongoose.Types.ObjectId('67ba0042ad10d79f7aba01a2'), // Existing tenant
        landlordId: new mongoose.Types.ObjectId('6838699baefe2c0213aba1c3'), // Existing landlord
        title: 'Heating System Not Working',
        description: 'The heating system in the living room is not working properly. Temperature is not reaching the set level.',
        category: 'heating',
        priority: 'high',
        status: 'pending',
        location: 'Living Room',
        urgencyLevel: 4,
        requestedDate: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
      },
      {
        propertyId: new mongoose.Types.ObjectId('684478e4c96b1ebd4147fc5b'),
        tenantId: new mongoose.Types.ObjectId('68474aa1e3240f44ed3cc8bc'),
        landlordId: new mongoose.Types.ObjectId('6838699baefe2c0213aba1c3'),
        title: 'Kitchen Sink Leaking',
        description: 'The kitchen sink has been leaking water from the faucet. It\'s getting worse over time.',
        category: 'plumbing',
        priority: 'medium',
        status: 'pending',
        location: 'Kitchen',
        urgencyLevel: 3,
        requestedDate: new Date(Date.now() - 5 * 60 * 60 * 1000), // 5 hours ago
      },
      {
        propertyId: new mongoose.Types.ObjectId('684478e4c96b1ebd4147fc5b'),
        tenantId: new mongoose.Types.ObjectId('67ba0042ad10d79f7aba01a2'),
        landlordId: new mongoose.Types.ObjectId('6838699baefe2c0213aba1c3'),
        title: 'Bedroom Light Fixture',
        description: 'The light fixture in the bedroom is flickering and sometimes doesn\'t turn on.',
        category: 'electrical',
        priority: 'low',
        status: 'pending',
        location: 'Bedroom',
        urgencyLevel: 2,
        requestedDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
      },
    ];

    const createdRequests = await MaintenanceRequest.insertMany(sampleRequests);
    console.log(`Created ${createdRequests.length} sample maintenance requests:`);
    
    createdRequests.forEach((request, index) => {
      console.log(`${index + 1}. ${request.title} - Priority: ${request.priority} - Status: ${request.status}`);
    });

  } catch (error) {
    console.error('Error creating sample maintenance requests:', error);
  } finally {
    await mongoose.connection.close();
    console.log('Database connection closed');
  }
}

createSampleMaintenanceRequests();
