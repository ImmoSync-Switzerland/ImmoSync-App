// Load environment variables first
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');
const { connectDB } = require('./database');
const app = express();
const http = require('http');
const server = http.createServer(app);
const { Server } = require('socket.io');
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET','POST'], allowedHeaders: ['Authorization'] }
});
const { getDB } = require('./database');
const { ObjectId } = require('mongodb');
const authRoutes = require('./routes/auth');
const auth2faRoutes = require('./routes/auth-2fa');
const propertyRoutes = require('./routes/properties');
const usersRouter = require('./routes/users');
const contactsRoutes = require('./routes/contacts');
const conversationsRoutes = require('./routes/conversations');
const chatRoutes = require('./routes/chat');
const invitationsRoutes = require('./routes/invitations');
const uploadRoutes = require('./routes/upload');
const imagesRoutes = require('./routes/images');
const maintenanceRoutes = require('./routes/maintenance');
const maintenanceRequestsRoutes = require('./routes/maintenance-requests');
const emailRoutes = require('./routes/email');
const notificationRoutes = require('./routes/notifications');
const servicesRoutes = require('./routes/services');
const ticketsRoutes = require('./routes/tickets');
const paymentsRoutes = require('./routes/payments');
const subscriptionsRoutes = require('./routes/subscriptions');
const connectRoutes = require('./routes/connect');
const activitiesRoutes = require('./routes/activities');
const documentsRoutes = require('./routes/documents');

// Enable CORS for all routes
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Special handling for Stripe webhook - needs raw body
app.use('/api/payments/stripe-webhook', express.raw({type: 'application/json'}));
app.use('/api/connect/webhook', express.raw({type: 'application/json'}));

// Regular JSON parsing for all other routes
app.use(express.json());

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Mount auth routes
app.use('/api/auth', authRoutes);
app.use('/api/auth/2fa', auth2faRoutes);

// Mount routes
app.use('/api/properties', propertyRoutes);

app.use('/api/users', usersRouter);

app.use('/api/contacts', contactsRoutes);

app.use('/api/conversations', conversationsRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/invitations', invitationsRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/images', imagesRoutes);
app.use('/api/maintenance', maintenanceRoutes);
app.use('/api/maintenance-requests', maintenanceRequestsRoutes);
app.use('/api/email', emailRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/services', servicesRoutes);
app.use('/api/tickets', ticketsRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/subscriptions', subscriptionsRoutes);
// Alias singular path to the same router to avoid confusion ("Cannot GET /api/subscription")
app.use('/api/subscription', subscriptionsRoutes);
app.use('/api/connect', connectRoutes);
app.use('/api/activities', activitiesRoutes);
app.use('/api/documents', documentsRoutes);

// Add specific route for /api/tenants that points to users/tenants
app.use('/api/tenants', (req, res, next) => {
  // Redirect /api/tenants to /api/users/tenants
  req.url = '/tenants' + req.url;
  usersRouter(req, res, next);
});

const PORT = process.env.PORT || 3000;

// Initialize database connection and start server
async function startServer() {
  try {
    await connectDB();
    console.log('Database connected successfully');
  } catch (error) {
    console.warn('Database connection failed - running in development mode:', error.message);
    console.log('Server will start without database connection');
  }
  
  // Use a single HTTP server (with Socket.IO). Removed duplicate app.listen to prevent EADDRINUSE.
  server.listen(PORT, () => {
    console.log(`HTTP + WebSocket server on :${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/api/health`);
  });

  // In-memory presence map { userId: { socketId, lastPing } }
  const presence = new Map();

  async function persistLastSeen(userId, ts) {
    try {
      const db = getDB();
      await db.collection('users').updateOne({ _id: new ObjectId(userId) }, { $set: { lastSeen: new Date(ts), updatedAt: new Date() } });
    } catch (e) {
      // Don't log database unavailable errors repeatedly
      if (!e.message.includes('Database not initialized')) {
        console.warn('Failed to persist lastSeen', userId, e.message);
      }
    }
  }

  function broadcastPresenceUpdate(userId) {
    const entry = presence.get(userId);
    const lastSeenIso = entry ? new Date(entry.lastPing).toISOString() : new Date().toISOString();
    io.of('/presence').emit('presence:update', {
      userId,
      online: !!entry,
      lastSeen: lastSeenIso
    });
  }

  // Auth middleware (expects ?token= or Authorization header)
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.query?.token || socket.handshake.headers['authorization'];
      if (!token) {
        console.log('[WS][auth] No token provided');
        return next(new Error('NO_TOKEN'));
      }
      
      let db;
      try {
        db = getDB();
      } catch (dbError) {
        console.error('[WS][auth] Database not available:', dbError.message);
        return next(new Error('DATABASE_UNAVAILABLE'));
      }
      
      const user = await db.collection('users').findOne({ sessionToken: token });
      if (!user) {
        console.log('[WS][auth] Invalid token provided');
        return next(new Error('BAD_TOKEN'));
      }
      
      socket.data.userId = user._id.toString();
      console.log('[WS][auth] User authenticated: %s', socket.data.userId);
      return next();
    } catch (e) {
      console.error('[WS][auth] Authentication error:', e.message);
      return next(new Error('AUTH_ERROR'));
    }
  });

  // Namespaces: /presence and /chat
  const presenceNs = io.of('/presence');
  const chatNs = io.of('/chat');

  // Helper to (re)authenticate a socket if socket.data.userId is missing
  async function ensureSocketUser(socket) {
    if (socket.data.userId) return true;
    try {
      const token = socket.handshake?.auth?.token || socket.handshake?.query?.token || socket.handshake?.headers?.authorization;
      if (!token) {
        console.warn('[WS][ensureSocketUser] missing token for sid=%s', socket.id);
        return false;
      }
      let db;
      try { db = getDB(); } catch (e) { console.warn('[WS][ensureSocketUser] db unavailable sid=%s', socket.id); return false; }
      const user = await db.collection('users').findOne({ sessionToken: token });
      if (!user) { console.warn('[WS][ensureSocketUser] token not found sid=%s', socket.id); return false; }
      socket.data.userId = user._id.toString();
      console.log('[WS][ensureSocketUser] bound userId=%s sid=%s', socket.data.userId, socket.id);
      return true;
    } catch (e) {
      console.error('[WS][ensureSocketUser] error sid=%s %s', socket.id, e.message);
      return false;
    }
  }

  // Apply explicit per-namespace middleware (some Socket.IO deployments require this rather than relying on root io.use)
  presenceNs.use(async (socket, next) => { await ensureSocketUser(socket); next(); });
  chatNs.use(async (socket, next) => { await ensureSocketUser(socket); next(); });

  // Global namespace connection error logging (client auth failures etc.)
  presenceNs.on('connect_error', (err) => {
    console.warn('[WS][presence][connect_error]', err.message, err?.data || '');
  });
  chatNs.on('connect_error', (err) => {
    console.warn('[WS][chat][connect_error]', err.message, err?.data || '');
  });

  presenceNs.on('connection', (socket) => {
    if (!socket.data.userId) {
      console.warn('[WS][presence] connection without userId sid=%s', socket.id);
    } else {
      console.log('[WS][presence] connection userId=%s sid=%s', socket.data.userId, socket.id);
    }
    const userId = socket.data.userId;
    if (userId) {
      presence.set(userId, { socketId: socket.id, lastPing: Date.now() });
      persistLastSeen(userId, Date.now());
      broadcastPresenceUpdate(userId);
    }
    socket.on('presence:ping', () => {
      if (!userId) return;
      const entry = presence.get(userId);
      if (entry) {
        entry.lastPing = Date.now();
        presence.set(userId, entry);
        persistLastSeen(userId, entry.lastPing);
        broadcastPresenceUpdate(userId);
      }
    });
    socket.on('disconnect', () => {
      if (userId && presence.get(userId)?.socketId === socket.id) {
        presence.delete(userId);
        broadcastPresenceUpdate(userId);
      }
    });
  });

  chatNs.on('connection', (socket) => {
    if (!socket.data.userId) {
      console.warn('[WS][chat] connection without userId sid=%s', socket.id);
    } else {
      console.log('[WS][chat] connection userId=%s sid=%s', socket.data.userId, socket.id);
    }
    // Create new conversation and optional first message
    socket.on('chat:create', async (payload) => {
      try {
  const { otherUserId, initialMessage, initialE2EE } = payload || {};
        const senderId = socket.data.userId;
        if (!otherUserId || !senderId) return;
        const db = getDB();
        // Find existing conversation between users
        let conversation = await db.collection('conversations').findOne({
          participants: { $all: [senderId, otherUserId], $size: 2 }
        });
        if (!conversation) {
          const convDoc = {
            participants: [senderId, otherUserId].sort(),
            lastMessage: initialMessage || '',
            lastMessageTime: new Date(),
            unreadCount: initialMessage ? 1 : 0,
            createdAt: new Date(),
            updatedAt: new Date()
          };
            const convResult = await db.collection('conversations').insertOne(convDoc);
          conversation = { _id: convResult.insertedId, ...convDoc };
        }
        let firstMessage = null;
        if (initialMessage || initialE2EE) {
          const encrypted = !!initialE2EE && !initialMessage;
          const msgDoc = {
            conversationId: conversation._id.toString(),
            senderId,
            receiverId: otherUserId,
            content: encrypted ? '' : (initialMessage || ''),
            e2ee: initialE2EE || null,
            isEncrypted: encrypted,
            timestamp: new Date(),
            messageType: 'text',
            isRead: false,
            attachments: [],
            deliveredAt: null,
            readAt: null
          };
          const msgRes = await db.collection('messages').insertOne(msgDoc);
          firstMessage = { _id: msgRes.insertedId, ...msgDoc };
          await db.collection('conversations').updateOne(
            { _id: conversation._id },
            { $set: { lastMessage: encrypted ? '[encrypted]' : initialMessage, lastMessageTime: msgDoc.timestamp, updatedAt: new Date() } }
          );
          // Mark delivered immediately (best-effort) and notify sender
          await db.collection('messages').updateOne({ _id: msgRes.insertedId }, { $set: { deliveredAt: new Date() } });
          firstMessage.deliveredAt = new Date();
        }
        // Ack creator
        socket.emit('chat:create:ack', { conversation, firstMessage });
        // Notify other participant about new conversation
        socket.broadcast.emit('chat:conversation:new', { conversation, firstMessage });
      } catch (e) {
        console.error('chat:create error', e);
        socket.emit('chat:error', { type: 'create', message: e.message });
      }
    });

    // Typing indicator
    socket.on('chat:typing', (data) => {
      const { conversationId, isTyping } = data || {};
      if (!conversationId) return;
      socket.broadcast.emit('chat:typing', { conversationId, userId: socket.data.userId, isTyping: !!isTyping });
    });

    // Mark messages read
    socket.on('chat:read', async (data) => {
      try {
        const { conversationId, messageIds } = data || {};
        const userId = socket.data.userId;
        if (!conversationId || !Array.isArray(messageIds) || !messageIds.length) return;
        const db = getDB();
        const readAt = new Date();
        await db.collection('messages').updateMany(
          { _id: { $in: messageIds.map(id => new ObjectId(id)) }, conversationId },
          { $set: { isRead: true, readAt } }
        );
        socket.broadcast.emit('chat:read', { conversationId, messageIds, userId, readAt });
      } catch (e) {
        console.error('chat:read error', e);
      }
    });

    socket.on('chat:message', async (msg) => {
      try {
  console.log('[WS][chat:message][in]', msg);
        // msg may include plaintext content OR e2ee bundle
        const { conversationId, content, receiverId, e2ee } = msg || {};
        let senderId = socket.data.userId;
        if (!senderId) {
          const ok = await ensureSocketUser(socket);
          senderId = socket.data.userId;
          if (!ok || !senderId) {
            console.warn('[WS][chat:message] dropping message (unauthenticated) sid=%s conv=%s', socket.id, conversationId);
            socket.emit('chat:error', { type: 'auth', message: 'Unauthenticated socket' });
            return;
          }
        }
        if (!conversationId || !senderId) {
          console.log('[WS][chat:message] missing required fields: conversationId=%s senderId=%s', conversationId, senderId);
          return;
        }
        
        let db;
        try {
          db = getDB();
        } catch (dbError) {
          console.error('[WS][chat:message] database not available:', dbError.message);
          socket.emit('chat:error', { type: 'database', message: 'Database not available' });
          return;
        }
        
        const encrypted = !!e2ee && !content;
        if (!content && !encrypted) {
          console.log('[WS][chat:message] no content to store: content=%s encrypted=%s', !!content, encrypted);
          return; // nothing to store
        }
  console.log('[WS][chat:message] resolved sender=%s conv=%s encrypted=%s', senderId, conversationId, encrypted);
        const doc = {
          conversationId,
          senderId,
          receiverId: receiverId || null,
          content: encrypted ? '' : content,
          e2ee: e2ee || null,
          isEncrypted: encrypted,
          timestamp: new Date(),
          messageType: 'text',
          isRead: false,
          attachments: [],
          deliveredAt: null,
          readAt: null
        };
        
        try {
          const result = await db.collection('messages').insertOne(doc);
          const fullDoc = { ...doc, _id: result.insertedId };
          console.log('[WS][chat:message] stored message _id=%s conv=%s', result.insertedId.toString(), conversationId);
          
          // Ack & broadcast early so client UI updates even if conversation update fails (e.g. invalid ObjectId)
          socket.emit('chat:ack', fullDoc);
          socket.broadcast.emit('chat:message', fullDoc);
          console.log('[WS][chat:message] broadcasting message to other clients');
          
          // Try to update conversation document; ignore errors
          try {
            await db.collection('conversations').updateOne(
              { _id: new ObjectId(conversationId) },
              { $set: { lastMessage: encrypted ? '[encrypted]' : content, lastMessageTime: new Date(), updatedAt: new Date() } }
            );
            console.log('[WS][chat:message] conversation metadata updated %s', conversationId);
          } catch (convErr) {
            console.warn('conversation update failed (possibly invalid id)', convErr?.message || convErr);
          }
          
          // Mark delivered immediately (best-effort) and inform sender
          try {
            await db.collection('messages').updateOne({ _id: result.insertedId }, { $set: { deliveredAt: new Date() } });
            const deliveredPayload = { _id: result.insertedId, conversationId, deliveredAt: new Date() };
            socket.emit('chat:delivered', deliveredPayload);
            console.log('[WS][chat:message] delivered emit %j', deliveredPayload);
          } catch (deliveryErr) {
            console.warn('[WS][chat:message] failed to mark as delivered:', deliveryErr.message);
          }
        } catch (insertError) {
          console.error('[WS][chat:message] failed to insert message:', insertError.message);
          socket.emit('chat:error', { type: 'insert', message: 'Failed to save message' });
        }
      } catch (e) {
        console.error('chat:message ws error', e);
      }
    });
  });
}

startServer();