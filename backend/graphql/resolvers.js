const { MongoClient, ObjectId } = require('mongodb');
const { GraphQLScalarType, Kind } = require('graphql');
const notifications = require('../routes/notifications');
const { dbUri, dbName } = require('../config');

// JSON scalar type for handling arbitrary JSON data
const JSONScalar = new GraphQLScalarType({
  name: 'JSON',
  description: 'Arbitrary JSON value',
  serialize: (value) => value,
  parseValue: (value) => value,
  parseLiteral: (ast) => {
    if (ast.kind === Kind.OBJECT) {
      return JSON.parse(JSON.stringify(ast));
    }
    return null;
  },
});

// Resolve user from session token (returns user document or null)
async function resolveUser(token) {
  if (!token) return null;
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const user = await db.collection('users').findOne({ sessionToken: token });
    return user;
  } finally {
    await client.close();
  }
}

const resolvers = {
  JSON: JSONScalar,

  Query: {
    supportRequests: async (_, { status, userId }, context) => {
      if (!context.user) {
        throw new Error('Unauthorized');
      }

      const client = new MongoClient(dbUri);
      try {
        await client.connect();
        const db = client.db(dbName);
        const query = {};
        
        if (status) query.status = status;
        
        // Staff can filter by userId, regular users only see their own
        if (context.user.role === 'admin' || context.user.role === 'support') {
          if (userId && ObjectId.isValid(userId)) {
            query.userId = new ObjectId(userId);
          }
        } else {
          query.userId = context.user._id;
        }

        const items = await db.collection('supportRequests')
          .find(query)
          .sort({ createdAt: -1 })
          .limit(200)
          .toArray();

        return items.map(r => ({
          id: r._id.toString(),
          subject: r.subject,
          message: r.message,
          category: r.category,
          priority: r.priority,
          status: r.status,
          userId: r.userId ? r.userId.toString() : null,
          notes: (r.notes || []).map(n => ({
            body: n.body,
            author: n.author?.toString?.() || n.author,
            createdAt: n.createdAt.toISOString()
          })),
          meta: r.meta || {},
          createdAt: r.createdAt.toISOString(),
          updatedAt: r.updatedAt.toISOString()
        }));
      } finally {
        await client.close();
      }
    },

    supportRequest: async (_, { id }, context) => {
      if (!context.user) {
        throw new Error('Unauthorized');
      }

      if (!ObjectId.isValid(id)) {
        throw new Error('Invalid id');
      }

      const client = new MongoClient(dbUri);
      try {
        await client.connect();
        const db = client.db(dbName);
        const r = await db.collection('supportRequests').findOne({ _id: new ObjectId(id) });
        
        if (!r) {
          throw new Error('Not found');
        }

        // Authorization check
        const isStaff = context.user.role === 'admin' || context.user.role === 'support';
        const isOwner = r.userId && r.userId.toString() === context.user._id.toString();
        
        if (!isStaff && !isOwner) {
          throw new Error('Forbidden');
        }

        return {
          id: r._id.toString(),
          subject: r.subject,
          message: r.message,
          category: r.category,
          priority: r.priority,
          status: r.status,
          userId: r.userId ? r.userId.toString() : null,
          notes: (r.notes || []).map(n => ({
            body: n.body,
            author: n.author?.toString?.() || n.author,
            createdAt: n.createdAt.toISOString()
          })),
          meta: r.meta || {},
          createdAt: r.createdAt.toISOString(),
          updatedAt: r.updatedAt.toISOString()
        };
      } finally {
        await client.close();
      }
    }
  },

  Mutation: {
    createSupportRequest: async (_, { input }, context) => {
      if (!context.user) {
        throw new Error('Unauthorized');
      }

      const { subject, message, category, priority, meta } = input;
      
      if (!subject || !message) {
        return {
          success: false,
          message: 'Subject and message are required'
        };
      }

      const client = new MongoClient(dbUri);
      try {
        await client.connect();
        const db = client.db(dbName);
        const now = new Date();
        
        const doc = {
          subject: String(subject).trim(),
          message: String(message).trim(),
          category: category || 'General',
          priority: priority || 'Medium',
          userId: context.user._id,
          status: 'open',
          meta: meta || {},
          notes: [],
          createdAt: now,
          updatedAt: now
        };

        const result = await db.collection('supportRequests').insertOne(doc);
        const insertedId = result.insertedId.toString();

        // Send notification
        if (context.user._id) {
          notifications.sendDomainNotification(context.user._id.toString(), {
            title: 'Support-Anfrage erstellt',
            body: `"${doc.subject}" wurde eingereicht`,
            type: 'support_request_created',
            data: { requestId: insertedId }
          });
        }

        return {
          success: true,
          id: insertedId,
          message: 'Support request created successfully'
        };
      } catch (e) {
        console.error('Error creating support request', e);
        return {
          success: false,
          message: `Failed to create support request: ${e.message}`
        };
      } finally {
        await client.close();
      }
    },

    updateSupportRequest: async (_, { id, input }, context) => {
      if (!context.user) {
        throw new Error('Unauthorized');
      }

      if (!ObjectId.isValid(id)) {
        return {
          success: false,
          message: 'Invalid id'
        };
      }

      const { status, note } = input;
      const client = new MongoClient(dbUri);
      
      try {
        await client.connect();
        const db = client.db(dbName);
        
        const existing = await db.collection('supportRequests').findOne({ _id: new ObjectId(id) });
        if (!existing) {
          return {
            success: false,
            message: 'Not found'
          };
        }

        // Authorization check
        const isStaff = context.user.role === 'admin' || context.user.role === 'support';
        const isOwner = existing.userId && existing.userId.toString() === context.user._id.toString();
        
        if (!isStaff && !isOwner) {
          return {
            success: false,
            message: 'Forbidden'
          };
        }

        const update = { updatedAt: new Date() };
        
        if (status) {
          if (!isStaff && !isOwner) {
            return {
              success: false,
              message: 'Forbidden - only staff can change status'
            };
          }
          update.status = status;
        }

        const ops = [];
        if (note) {
          ops.push({ 
            body: String(note).trim(), 
            author: context.user._id, 
            createdAt: new Date() 
          });
        }

        await db.collection('supportRequests').updateOne(
          { _id: new ObjectId(id) },
          { 
            $set: update, 
            ...(ops.length ? { $push: { notes: { $each: ops, $position: 0 } } } : {}) 
          }
        );

        // Notify owner about status change
        const updated = await db.collection('supportRequests').findOne({ _id: new ObjectId(id) });
        if (updated?.userId) {
          notifications.sendDomainNotification(updated.userId.toString(), {
            title: 'Support-Anfrage aktualisiert',
            body: `Status: ${updated.status}`,
            type: 'support_request_updated',
            data: { requestId: id, status: updated.status }
          });
        }

        return {
          success: true,
          updated: true,
          message: 'Support request updated successfully'
        };
      } catch (e) {
        console.error('Error updating support request', e);
        return {
          success: false,
          message: `Failed to update: ${e.message}`
        };
      } finally {
        await client.close();
      }
    }
  }
};

module.exports = { resolvers, resolveUser };
