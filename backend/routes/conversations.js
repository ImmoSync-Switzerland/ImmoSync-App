const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');
const { getDB } = require('../database');

// Get all conversations for a user
router.get('/user/:userId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const userId = req.params.userId;
    
    // Find conversations where user is in the participants array
    const conversations = await db.collection('conversations')
      .find({
        participants: userId
      })
      .sort({ lastMessageTime: -1 })
      .toArray();
    
    // Populate participant names
    const populatedConversations = await Promise.all(
      conversations.map(async (conversation) => {
        // Get other participant (not the current user)
        const otherParticipantId = conversation.participants.find(id => id !== userId);
        
        // Get other participant details
        let otherParticipant = null;
        if (otherParticipantId) {
          try {
            otherParticipant = await db.collection('users')
              .findOne({ _id: new ObjectId(otherParticipantId) });
          } catch (err) {
            console.log(`Could not find user with ID: ${otherParticipantId}`);
          }
        }
        
        // Online status (lastSeen within 60s)
        let online = false;
        let lastSeen = null;
        if (otherParticipant && otherParticipant.lastSeen) {
          lastSeen = otherParticipant.lastSeen;
          online = Date.now() - new Date(otherParticipant.lastSeen).getTime() < 60000;
        }
        return {
          ...conversation,
          otherParticipantId,
          otherParticipantName: otherParticipant ? otherParticipant.fullName : 'Unknown User',
          otherParticipantEmail: otherParticipant ? otherParticipant.email : '',
          otherParticipantRole: otherParticipant ? otherParticipant.role : 'unknown',
          otherParticipantOnline: online,
          otherParticipantLastSeen: lastSeen,
        };
      })
    );
    
    console.log(`Found ${populatedConversations.length} conversations for user ${userId}`);
    res.json(populatedConversations);
    
  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json({ message: 'Error fetching conversations' });
  } finally {
    await client.close();
  }
});

// Consolidate conversations between the same participants
router.post('/consolidate', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log('Starting conversation consolidation...');
    
    // Find all conversations
    const allConversations = await db.collection('conversations').find({}).toArray();
    
    // Group conversations by participant pairs
    const participantGroups = {};
    
    allConversations.forEach(conv => {
      const sortedParticipants = conv.participants.sort().join(',');
      
      if (!participantGroups[sortedParticipants]) {
        participantGroups[sortedParticipants] = [];
      }
      participantGroups[sortedParticipants].push(conv);
    });
    
    let consolidatedCount = 0;
    
    // Process each group of conversations
    for (const [participantKey, conversations] of Object.entries(participantGroups)) {
      if (conversations.length > 1) {
        console.log(`Found ${conversations.length} conversations for participants: ${participantKey}`);
        
        // Sort by creation date to keep the oldest one
        conversations.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
        
        const keepConversation = conversations[0];
        const duplicateConversations = conversations.slice(1);
        
        // Consolidate messages from duplicate conversations
        for (const dupConv of duplicateConversations) {
          // Move all messages from duplicate conversation to the main one
          await db.collection('messages').updateMany(
            { conversationId: dupConv._id.toString() },
            { $set: { conversationId: keepConversation._id.toString() } }
          );
          
          // Delete the duplicate conversation
          await db.collection('conversations').deleteOne({ _id: dupConv._id });
          consolidatedCount++;
        }
        
        // Update the kept conversation with the latest message info
        const latestMessage = await db.collection('messages')
          .findOne(
            { conversationId: keepConversation._id.toString() },
            { sort: { timestamp: -1 } }
          );
        
        if (latestMessage) {
          await db.collection('conversations').updateOne(
            { _id: keepConversation._id },
            {
              $set: {
                lastMessage: latestMessage.content,
                lastMessageTime: latestMessage.timestamp,
                updatedAt: new Date()
              }
            }
          );
        }
      }
    }
    
    console.log(`Consolidated ${consolidatedCount} duplicate conversations`);
    res.json({ 
      message: `Successfully consolidated ${consolidatedCount} duplicate conversations`,
      consolidatedCount 
    });
    
  } catch (error) {
    console.error('Error consolidating conversations:', error);
    res.status(500).json({ message: 'Error consolidating conversations' });
  } finally {
    await client.close();
  }
});

// Get or create a conversation between two users
router.post('/find-or-create', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { currentUserId, otherUserId } = req.body;
    
    if (!currentUserId || !otherUserId) {
      return res.status(400).json({ message: 'Both currentUserId and otherUserId are required' });
    }
    
    // Validate ObjectId format
    if (!ObjectId.isValid(currentUserId) || !ObjectId.isValid(otherUserId)) {
      return res.status(400).json({ message: 'Invalid user ID format' });
    }
    
    // Sort participant IDs to ensure consistent ordering
    const participants = [currentUserId, otherUserId].sort();
    
    // Find existing conversation between these two users
    let conversation = await db.collection('conversations')
      .findOne({
        participants: { $all: participants, $size: 2 }
      });
    
    if (!conversation) {
      // Create new conversation if none exists
      const newConversation = {
        participants: participants,
        lastMessage: '',
        lastMessageTime: new Date(),
        unreadCount: 0,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      const result = await db.collection('conversations').insertOne(newConversation);
      conversation = { _id: result.insertedId, ...newConversation };
    }
    
    // Get other participant details
    const otherParticipant = await db.collection('users')
      .findOne({ _id: new ObjectId(otherUserId) });
    
    const response = {
      ...conversation,
      otherParticipantId: otherUserId,
      otherParticipantName: otherParticipant ? otherParticipant.fullName : 'Unknown User',
      otherParticipantEmail: otherParticipant ? otherParticipant.email : '',
      otherParticipantRole: otherParticipant ? otherParticipant.role : 'unknown',
    };
    
    res.json(response);
    
  } catch (error) {
    console.error('Error finding or creating conversation:', error);
    res.status(500).json({ message: 'Error finding or creating conversation' });
  } finally {
    await client.close();
  }
});

// Create a new conversation
router.post('/', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { otherUserId, initialMessage } = req.body;
      // Create conversation document
    const conversation = {
      participants: [req.body.participants?.[0] || req.body.currentUserId || 'current-user-id', otherUserId],
      lastMessage: initialMessage || 'Chat started',
      lastMessageTime: new Date(),
      unreadCount: 1,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    const result = await db.collection('conversations').insertOne(conversation);
    
    // If there's an initial message, add it to messages collection
    if (initialMessage) {
      await db.collection('messages').insertOne({
        conversationId: result.insertedId.toString(),
        senderId: conversation.participants[0],
        receiverId: otherUserId,
        content: initialMessage,
        timestamp: new Date(),
        messageType: 'text',
        isRead: false
      });
    }
    
    res.status(201).json({ 
      conversationId: result.insertedId,
      message: 'Conversation created successfully' 
    });
  } catch (error) {
    console.error('Error creating conversation:', error);
    res.status(500).json({ message: 'Error creating conversation' });
  } finally {
    await client.close();
  }
});

// Get conversation by ID
router.get('/:conversationId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const conversation = await db.collection('conversations')
      .findOne({ _id: new ObjectId(req.params.conversationId) });
    
    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }
    
    // Get participant details
    const participants = await Promise.all(
      conversation.participants.map(async (participantId) => {
        try {
          const user = await db.collection('users')
            .findOne({ _id: new ObjectId(participantId) });
          return user ? {
            id: participantId,
            fullName: user.fullName,
            email: user.email,
            role: user.role
          } : {
            id: participantId,
            fullName: 'Unknown User',
            email: '',
            role: 'unknown'
          };
        } catch (err) {
          return {
            id: participantId,
            fullName: 'Unknown User',
            email: '',
            role: 'unknown'
          };
        }
      })
    );
    
    const populatedConversation = {
      ...conversation,
      participantDetails: participants,
    };
    
    res.json(populatedConversation);
    
  } catch (error) {
    console.error('Error fetching conversation:', error);
    res.status(500).json({ message: 'Error fetching conversation' });
  } finally {
    await client.close();
  }
});

// Update conversation (for last message updates)
router.put('/:conversationId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { conversationId } = req.params;
    const { lastMessage, lastMessageTime } = req.body;
    
    await db.collection('conversations').updateOne(
      { _id: new ObjectId(conversationId) },
      {
        $set: {
          lastMessage,
          lastMessageTime: new Date(lastMessageTime),
          updatedAt: new Date()
        }
      }
    );
    
    res.json({ message: 'Conversation updated successfully' });
  } catch (error) {
    console.error('Error updating conversation:', error);
    res.status(500).json({ message: 'Error updating conversation' });
  } finally {
    await client.close();
  }
});

// Find or create conversation between two users
router.post('/find-or-create', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { participants } = req.body;
    
    if (!participants || participants.length !== 2) {
      return res.status(400).json({ message: 'Exactly two participants required' });
    }
    
    // Check if conversation already exists
    let conversation = await db.collection('conversations')
      .findOne({
        participants: { $all: participants, $size: 2 }
      });
    
    if (!conversation) {
      // Create new conversation
      const newConversation = {
        participants,
        lastMessage: '',
        lastMessageSenderId: '',
        lastMessageTime: new Date(),
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      const result = await db.collection('conversations').insertOne(newConversation);
      conversation = await db.collection('conversations')
        .findOne({ _id: result.insertedId });
    }
    
    res.json(conversation);
  } catch (error) {
    console.error('Error finding/creating conversation:', error);
    res.status(500).json({ message: 'Error finding/creating conversation' });
  } finally {
    await client.close();
  }
});

// Get current user conversations (alternative endpoint)
router.get('/user/current', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    // This endpoint would need authentication middleware to get current user
    // For now, return error asking for user ID
    res.status(400).json({ 
      message: 'Please use /user/:userId endpoint with specific user ID' 
    });
  } catch (error) {
    console.error('Error fetching current user conversations:', error);
    res.status(500).json({ message: 'Error fetching conversations' });
  } finally {
    await client.close();
  }
});

module.exports = router;

// Additional Matrix mapping endpoint: GET /api/conversations/:conversationId/matrix-room
// Returns { matrixRoomId: string } if a mapping exists in matrix_conversations
router.get('/:conversationId/matrix-room', async (req, res) => {
  try {
    const db = getDB();
    const map = await db.collection('matrix_conversations').findOne({ conversationId: req.params.conversationId.toString() });
    if (!map) return res.status(404).json({ message: 'No Matrix room mapping found' });
    return res.json({ matrixRoomId: map.roomId });
  } catch (e) {
    console.error('error fetching matrix room mapping', e);
    return res.status(500).json({ message: e.message });
  }
});
