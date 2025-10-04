// Chat Store abstraction with pluggable backends.
// Default: Mongo via getDB(); Alternative: Dynamo when DATA_BACKEND=dynamo.

if (process.env.DATA_BACKEND && process.env.DATA_BACKEND.toLowerCase() === 'dynamo') {
  module.exports = require('./chatStore.dynamo');
} else {
  const { ObjectId } = require('mongodb');
  const { getDB } = require('../database');

  async function fetchMessages(conversationId) {
    const db = getDB();
    return db
      .collection('messages')
      .find({ conversationId: conversationId.toString() })
      .sort({ timestamp: 1 })
      .toArray();
  }

  async function findMessageByMatrixEventId(matrixEventId) {
    if (!matrixEventId) return null;
    const db = getDB();
    return db.collection('messages').findOne({ matrixEventId: matrixEventId.toString() });
  }

  async function areUsersBlocked(senderId, receiverId) {
    try {
      if (!senderId || !receiverId) return false;
      if (!ObjectId.isValid(senderId) || !ObjectId.isValid(receiverId)) return false;
      const db = getDB();
      const [sender, receiver] = await Promise.all([
        db.collection('users').findOne({ _id: new ObjectId(senderId) }, { projection: { blockedUsers: 1 } }),
        db.collection('users').findOne({ _id: new ObjectId(receiverId) }, { projection: { blockedUsers: 1 } }),
      ]);
      const sBlocked = (sender?.blockedUsers || []).map(String);
      const rBlocked = (receiver?.blockedUsers || []).map(String);
      return sBlocked.includes(receiverId.toString()) || rBlocked.includes(senderId.toString());
    } catch (e) {
      // Fail-open; do not block sending due to transient errors
      return false;
    }
  }

  async function insertMessage(message) {
    const db = getDB();
    const result = await db.collection('messages').insertOne(message);
    return { insertedId: result.insertedId };
  }

  async function markDelivered(messageId, deliveredAt) {
    const db = getDB();
    try {
      const _id = typeof messageId === 'string' ? new ObjectId(messageId) : messageId;
      await db.collection('messages').updateOne({ _id }, { $set: { deliveredAt } });
    } catch (_) {
      // best-effort
    }
  }

  async function updateConversationPreview(conversationId, { content, isEncrypted, messageType }) {
    const db = getDB();
    try {
      const _id = new ObjectId(conversationId);
      await db.collection('conversations').updateOne(
        { _id },
        {
          $set: {
            lastMessage: isEncrypted ? (messageType === 'file' ? '[encrypted file]' : '[encrypted]') : content,
            lastMessageTime: new Date(),
            updatedAt: new Date(),
          },
        }
      );
    } catch (_) {
      // ignore
    }
  }

  module.exports = {
    fetchMessages,
    findMessageByMatrixEventId,
    areUsersBlocked,
    insertMessage,
    markDelivered,
    updateConversationPreview,
  };
}
