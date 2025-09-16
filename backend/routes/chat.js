const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');
const notifications = require('./notifications');

// Get messages for a conversation
router.get('/:conversationId/messages', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log(`Fetching messages for conversation: ${req.params.conversationId}`);
    
    const messages = await db
      .collection('messages')
      .find({ conversationId: req.params.conversationId })
      .sort({ timestamp: 1 }) // Sort oldest first
      .toArray();
    
    console.log(`Found ${messages.length} messages`);
    res.json(messages);
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ message: 'Error fetching messages' });
  } finally {
    await client.close();
  }
});

// Send a new message
router.post('/:conversationId/messages', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { conversationId } = req.params;
  const { senderId, receiverId, content, messageType = 'text', metadata, e2ee } = req.body;
    // Block check: if either user has blocked the other, forbid
    if (senderId && receiverId) {
      try {
        const [sender, receiver] = await Promise.all([
          db.collection('users').findOne({ _id: new ObjectId(senderId) }, { projection: { blockedUsers: 1 } }),
          db.collection('users').findOne({ _id: new ObjectId(receiverId) }, { projection: { blockedUsers: 1 } }),
        ]);
        const sBlocked = (sender?.blockedUsers || []).map(String);
        const rBlocked = (receiver?.blockedUsers || []).map(String);
        if (sBlocked.includes(receiverId.toString()) || rBlocked.includes(senderId.toString())) {
          return res.status(403).json({ message: 'Messaging blocked between users' });
        }
      } catch (e) {
        // If lookup fails, proceed (don't block sending due to transient db issue)
      }
    }
    
    // Create message document
    const encrypted = !!e2ee || (metadata && metadata.ciphertext);
    const message = {
      conversationId,
      senderId,
      receiverId,
      content: encrypted ? (content || '') : content,
      timestamp: new Date(),
      messageType,
      isRead: false,
      attachments: req.body.attachments || [],
      metadata: metadata || null,
      e2ee: e2ee || null,
      isEncrypted: encrypted,
      deliveredAt: null,
      readAt: null
    };
    
    // Insert message
    const messageResult = await db.collection('messages').insertOne(message);
    
    // Mark delivered immediately (REST path mimics WS behaviour)
    const deliveredAt = new Date();
    await db.collection('messages').updateOne(
      { _id: messageResult.insertedId },
      { $set: { deliveredAt } }
    );
    message.deliveredAt = deliveredAt;

    // Update conversation's last message and timestamp
    await db.collection('conversations').updateOne(
      { _id: new ObjectId(conversationId) },
      {
        $set: {
          lastMessage: encrypted ? (messageType === 'file' ? '[encrypted file]' : '[encrypted]') : content,
          lastMessageTime: new Date(),
          updatedAt: new Date()
        }
      }
    );
    
    res.status(201).json({
      messageId: messageResult.insertedId,
      message: 'Message sent successfully',
      stored: { ...message, _id: messageResult.insertedId }
    });

    // Notify receiver (now with debug logging)
    if (receiverId) {
      notifications
        .sendDomainNotification(receiverId, {
          title: 'New Message',
          body: content.slice(0, 80),
          type: 'message',
          data: { conversationId, messageId: messageResult.insertedId.toString(), senderId }
        })
        .then(r => {
          console.log('[Chat][Notify] receiverId=%s result=%j', receiverId, r);
        })
        .catch(e => console.error('[Chat][Notify][Error]', e));
    } else {
      console.log('[Chat][Notify] No receiverId provided, skipping push');
    }
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ message: 'Error sending message' });
  } finally {
    await client.close();
  }
});

module.exports = router;
