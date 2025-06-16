const { connectDB } = require('./database');
const { ObjectId } = require('mongodb');

async function createSampleConversations() {
  try {
    const db = await connectDB();
    console.log('Connected to MongoDB');

    // Clear existing conversations
    await db.collection('conversations').deleteMany({});
    console.log('Cleared existing conversations');    const sampleConversations = [
      {
        propertyId: new ObjectId('684478e4c96b1ebd4147fc5b'),
        landlordId: new ObjectId('6838699baefe2c0213aba1c3'),
        tenantId: new ObjectId('67ba0042ad10d79f7aba01a2'),
        participants: ['6838699baefe2c0213aba1c3', '67ba0042ad10d79f7aba01a2'],
        propertyAddress: 'Hinterkirchweg 78, Therwil',
        lastMessage: 'Thank you for fixing the heating issue so quickly!',
        lastMessageTime: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
        otherParticipantName: 'John Doe',
        otherParticipantRole: 'tenant',
        createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
        updatedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
      },
      {
        propertyId: new ObjectId('684478e4c96b1ebd4147fc5b'),
        landlordId: new ObjectId('6838699baefe2c0213aba1c3'),
        tenantId: new ObjectId('68474aa1e3240f44ed3cc8bc'),
        participants: ['6838699baefe2c0213aba1c3', '68474aa1e3240f44ed3cc8bc'],
        propertyAddress: 'Hinterkirchweg 78, Therwil',
        lastMessage: 'I will send the rent payment by tomorrow.',
        lastMessageTime: new Date(Date.now() - 5 * 60 * 60 * 1000), // 5 hours ago
        otherParticipantName: 'Jane Smith',
        otherParticipantRole: 'tenant',
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000), // 5 days ago
        updatedAt: new Date(Date.now() - 5 * 60 * 60 * 1000),
      },
      {
        propertyId: new ObjectId('684478e4c96b1ebd4147fc5b'),
        landlordId: new ObjectId('6838699baefe2c0213aba1c3'),
        tenantId: new ObjectId('67ba0042ad10d79f7aba01a2'),
        participants: ['6838699baefe2c0213aba1c3', '67ba0042ad10d79f7aba01a2'],
        propertyAddress: 'Hinterkirchweg 78, Therwil',
        lastMessage: 'Can we schedule a property inspection next week?',
        lastMessageTime: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
        otherParticipantName: 'Mike Johnson',
        otherParticipantRole: 'tenant',
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
        updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
      },
    ];

    const result = await db.collection('conversations').insertMany(sampleConversations);
    console.log(`Created ${result.insertedCount} sample conversations:`);
    
    sampleConversations.forEach((conversation, index) => {
      console.log(`${index + 1}. ${conversation.otherParticipantName}: ${conversation.lastMessage}`);
    });

  } catch (error) {
    console.error('Error creating sample conversations:', error);
  } finally {
    process.exit(0);
  }
}

createSampleConversations();
