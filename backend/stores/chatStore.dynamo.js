// DynamoDB implementation of chat store.
// Assumes tables with the following keys/indexes:
// - Messages table: PK: conversationId (partition), SK: timestamp (sort),
//   GSI on matrixEventId (for idempotency lookups)
// - Conversations table: PK: _id

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand, PutCommand, UpdateCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { region, dynamo } = require('../config');

const client = new DynamoDBClient({ region });
const ddb = DynamoDBDocumentClient.from(client);

const MESSAGES_TABLE = dynamo?.messagesTable || process.env.DDB_MESSAGES_TABLE || 'ImmoLinkMessages';
const CONVERSATIONS_TABLE = dynamo?.conversationsTable || process.env.DDB_CONVERSATIONS_TABLE || 'ImmoLinkConversations';
const GSI_EVENT = dynamo?.messagesEventGsi || process.env.DDB_MESSAGES_EVENT_GSI || 'matrixEventId-index';

async function fetchMessages(conversationId) {
  // Query by partition key, sorted ascending by default if SK is timestamp
  const cmd = new QueryCommand({
    TableName: MESSAGES_TABLE,
    KeyConditionExpression: 'conversationId = :c',
    ExpressionAttributeValues: { ':c': conversationId.toString() },
    ScanIndexForward: true,
  });
  const res = await ddb.send(cmd);
  return (res.Items || []).map(normalizeMessageItem);
}

async function findMessageByMatrixEventId(matrixEventId) {
  if (!matrixEventId) return null;
  // GSI lookup for idempotency
  try {
    const cmd = new QueryCommand({
      TableName: MESSAGES_TABLE,
      IndexName: GSI_EVENT,
      KeyConditionExpression: 'matrixEventId = :e',
      ExpressionAttributeValues: { ':e': matrixEventId.toString() },
      Limit: 1,
    });
    const res = await ddb.send(cmd);
    const item = (res.Items || [])[0];
    return item ? normalizeMessageItem(item) : null;
  } catch (e) {
    // If index not available, fail-open (no idempotency via GSI)
    return null;
  }
}

async function areUsersBlocked(senderId, receiverId) {
  // Without a user table mirror in Dynamo, return false; blocking can be enforced elsewhere or mirrored later
  return false;
}

async function insertMessage(message) {
  const item = denormalizeMessageItem(message);
  // Default SK if not provided: ISO timestamp
  if (!item.timestamp) item.timestamp = new Date().toISOString();
  const cmd = new PutCommand({ TableName: MESSAGES_TABLE, Item: item });
  await ddb.send(cmd);
  // Compose a synthetic id for API parity (Dynamo doesn't give an id)
  const insertedId = item._id || `${item.conversationId}#${item.timestamp}`;
  return { insertedId };
}

async function markDelivered(messageId, deliveredAt) {
  // For synthetic ids, we cannot update by id; this is best-effort: skip or extend schema with PK+SK from id
  return; // no-op; callers should tolerate best-effort
}

async function updateConversationPreview(conversationId, { content, isEncrypted, messageType }) {
  const preview = isEncrypted ? (messageType === 'file' ? '[encrypted file]' : '[encrypted]') : (content || '');
  const cmd = new UpdateCommand({
    TableName: CONVERSATIONS_TABLE,
    Key: { _id: conversationId.toString() },
    UpdateExpression: 'SET lastMessage = :m, lastMessageTime = :t, updatedAt = :t',
    ExpressionAttributeValues: {
      ':m': preview,
      ':t': new Date().toISOString(),
    },
  });
  try { await ddb.send(cmd); } catch (_) {}
}

function normalizeMessageItem(item) {
  // Map Dynamo item to API shape; tolerate missing fields
  return {
    _id: item._id || `${item.conversationId}#${item.timestamp}`,
    conversationId: item.conversationId,
    senderId: item.senderId || '',
    receiverId: item.receiverId || '',
    content: item.content || '',
    timestamp: item.timestamp ? new Date(item.timestamp) : new Date(),
    messageType: item.messageType || 'text',
    isRead: !!item.isRead,
    attachments: item.attachments || [],
    metadata: item.metadata || null,
    e2ee: item.e2ee || null,
    isEncrypted: !!item.isEncrypted,
    deliveredAt: item.deliveredAt ? new Date(item.deliveredAt) : null,
    readAt: item.readAt ? new Date(item.readAt) : null,
    matrixRoomId: item.matrixRoomId,
    matrixEventId: item.matrixEventId,
  };
}

function denormalizeMessageItem(m) {
  return {
    _id: m._id, // optional for parity; not used in PK
    conversationId: m.conversationId,
    timestamp: m.timestamp instanceof Date ? m.timestamp.toISOString() : (m.timestamp || new Date().toISOString()),
    senderId: m.senderId,
    receiverId: m.receiverId,
    content: m.content,
    messageType: m.messageType,
    isRead: !!m.isRead,
    attachments: m.attachments || [],
    metadata: m.metadata || null,
    e2ee: m.e2ee || null,
    isEncrypted: !!m.isEncrypted,
    deliveredAt: m.deliveredAt ? (m.deliveredAt instanceof Date ? m.deliveredAt.toISOString() : m.deliveredAt) : null,
    readAt: m.readAt ? (m.readAt instanceof Date ? m.readAt.toISOString() : m.readAt) : null,
    matrixRoomId: m.matrixRoomId,
    matrixEventId: m.matrixEventId,
  };
}

module.exports = {
  fetchMessages,
  findMessageByMatrixEventId,
  areUsersBlocked,
  insertMessage,
  markDelivered,
  updateConversationPreview,
};
