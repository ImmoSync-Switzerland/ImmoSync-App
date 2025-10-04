const express = require('express');
const router = express.Router();
const { ObjectId } = require('mongodb');
const notifications = require('./notifications');
const chatStore = require('../stores/chatStore');

// Get messages for a conversation
router.get('/:conversationId/messages', async (req, res) => {
  try {
    console.log(`[Chat][GET] messages conv=${req.params.conversationId}`);
    const messages = await chatStore.fetchMessages(req.params.conversationId);
    res.json(messages);
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ message: 'Error fetching messages' });
  }
});

// Send a new message
router.post('/:conversationId/messages', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { senderId, receiverId, content, messageType = 'text', metadata, e2ee, matrixRoomId, matrixEventId } = req.body;

    // Block check
    if (senderId && receiverId) {
      const blocked = await chatStore.areUsersBlocked(senderId, receiverId);
      if (blocked) return res.status(403).json({ message: 'Messaging blocked between users' });
    }

    // Idempotency by Matrix event
    if (matrixEventId) {
      const existing = await chatStore.findMessageByMatrixEventId(matrixEventId.toString());
      if (existing) {
        return res.status(200).json({
          messageId: existing._id,
          message: 'Message already stored (idempotent)',
          stored: existing,
        });
      }
    }

    // Construct message document
    const encrypted = !!e2ee || (metadata && metadata.ciphertext);
    const now = new Date();
    const message = {
      conversationId,
      senderId,
      receiverId,
      content: encrypted ? (content || '') : content,
      timestamp: now,
      messageType,
      isRead: false,
      attachments: req.body.attachments || [],
      metadata: metadata || null,
      e2ee: e2ee || null,
      isEncrypted: encrypted,
      deliveredAt: null,
      readAt: null,
      ...(matrixRoomId ? { matrixRoomId: matrixRoomId.toString() } : {}),
      ...(matrixEventId ? { matrixEventId: matrixEventId.toString() } : {}),
    };

    // Persist
    const messageResult = await chatStore.insertMessage(message);
    const deliveredAt = new Date();
    await chatStore.markDelivered(messageResult.insertedId, deliveredAt);
    message.deliveredAt = deliveredAt;

    // Update conversation preview
    await chatStore.updateConversationPreview(conversationId, {
      content,
      isEncrypted: encrypted,
      messageType,
    });

    // Response
    res.status(201).json({
      messageId: messageResult.insertedId,
      message: 'Message sent successfully',
      stored: { ...message, _id: messageResult.insertedId },
    });

    // Notify receiver
    if (receiverId) {
      const bodyPreview = (content || (encrypted ? '[encrypted]' : '') || '').toString().slice(0, 80);
      notifications
        .sendDomainNotification(receiverId, {
          title: 'New Message',
          body: bodyPreview,
          type: 'message',
          data: { conversationId, messageId: messageResult.insertedId.toString(), senderId },
        })
        .then((r) => console.log('[Chat][Notify] receiverId=%s result=%j', receiverId, r))
        .catch((e) => console.error('[Chat][Notify][Error]', e));
    }
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ message: 'Error sending message' });
  }
});

module.exports = router;
