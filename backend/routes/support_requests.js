const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const notifications = require('./notifications');
const { dbUri, dbName } = require('../config');

// Resolve user from session token (returns user document or null)
async function resolveUser(req) {
  try {
    const token = req.headers['authorization']?.replace('Bearer ', '') || req.headers['x-session-token'];
    if (!token) return null;
    const client = new MongoClient(dbUri);
    await client.connect();
    try {
      const db = client.db(dbName);
      const user = await db.collection('users').findOne({ sessionToken: token });
      return user;
    } finally {
      await client.close();
    }
  } catch {
    return null;
  }
}

// Simple auth middleware (enforces authenticated user)
async function requireAuth(req, res, next) {
  const user = await resolveUser(req);
  if (!user) return res.status(401).json({ success: false, message: 'Unauthorized' });
  req.user = user; // attach for downstream
  next();
}

// Basic role/privilege check (support staff or admin) via user.role
function requireStaff(req, res, next) {
  const role = req.user?.role;
  if (role === 'admin' || role === 'support') return next();
  return res.status(403).json({ success: false, message: 'Forbidden' });
}

// Create a support request
router.post('/', requireAuth, async (req, res) => {
  const { subject, message, category, priority, userId, meta } = req.body || {};
  if (!subject || !message) {
    return res.status(400).json({ success: false, message: 'Subject and message are required' });
  }
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const now = new Date();
    // Always trust authenticated user; ignore arbitrary userId in body unless staff overrides
    let resolvedId = req.user._id;
    if (userId && ObjectId.isValid(userId) && (req.user.role === 'admin' || req.user.role === 'support')) {
      resolvedId = new ObjectId(userId);
    }
    const doc = {
      subject: String(subject).trim(),
      message: String(message).trim(),
      category: category || 'General',
      priority: priority || 'Medium',
      userId: resolvedId,
      status: 'open',
      meta: meta || {},
      notes: [],
      createdAt: now,
      updatedAt: now
    };
    const result = await db.collection('supportRequests').insertOne(doc);
    const insertedId = result.insertedId.toString();
    if (resolvedId) {
      notifications.sendDomainNotification(resolvedId.toString(), {
        title: 'Support-Anfrage erstellt',
        body: `"${doc.subject}" wurde eingereicht`,
        type: 'support_request_created',
        data: { requestId: insertedId }
      });
    }
    // Optional internal email notification (environment controlled)
    try {
      if (process.env.SUPPORT_INTERNAL_EMAIL && process.env.NOTIFY_SUPPORT_EMAIL === 'true') {
        // Lazy load nodemailer to avoid cost if disabled
        const nodemailer = require('nodemailer');
        const transporter = nodemailer.createTransport({
          host: process.env.SMTP_HOST || 'localhost',
          port: Number(process.env.SMTP_PORT || 25),
          secure: false,
        });
        await transporter.sendMail({
          from: process.env.SMTP_FROM || 'no-reply@example.com',
          to: process.env.SUPPORT_INTERNAL_EMAIL,
          subject: `[Support] Neue Anfrage: ${doc.subject}`,
          text: `Kategorie: ${doc.category}\nPriorität: ${doc.priority}\nUser: ${resolvedId?.toString() || 'Unbekannt'}\n\n${doc.message}`,
        });
      }
    } catch (emailErr) {
      console.warn('Failed sending internal support email:', emailErr.message);
    }
    res.json({ success: true, id: insertedId });
  } catch (e) {
    console.error('Error creating support request', e);
    res.status(500).json({ success: false, message: 'Failed to create support request', error: e.message });
  } finally {
    await client.close();
  }
});

// List support requests (user sees own; staff can filter)
router.get('/', requireAuth, async (req, res) => {
  const { userId, status } = req.query; // staff only
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const query = {};
    if (status) query.status = status;
    if (req.user.role === 'admin' || req.user.role === 'support') {
      if (userId && ObjectId.isValid(userId)) query.userId = new ObjectId(userId);
    } else {
      query.userId = req.user._id; // regular users only see their own
    }
    const items = await db.collection('supportRequests')
      .find(query)
      .sort({ createdAt: -1 })
      .limit(200)
      .toArray();
    res.json({
      success: true,
      count: items.length,
      requests: items.map(r => ({
        id: r._id.toString(),
        subject: r.subject,
        category: r.category,
        priority: r.priority,
        status: r.status,
        userId: r.userId ? r.userId.toString() : null,
        notes: (r.notes || []).map(n => ({ body: n.body, author: n.author?.toString?.() || n.author, createdAt: n.createdAt })),
        createdAt: r.createdAt,
        updatedAt: r.updatedAt
      }))
    });
  } catch (e) {
    console.error('Error listing support requests', e);
    res.status(500).json({ success: false, message: 'Failed to list support requests', error: e.message });
  } finally {
    await client.close();
  }
});

// Get single support request
router.get('/:id', requireAuth, async (req, res) => {
  const { id } = req.params;
  if (!ObjectId.isValid(id)) return res.status(400).json({ success: false, message: 'Invalid id' });
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const r = await db.collection('supportRequests').findOne({ _id: new ObjectId(id) });
    if (!r) return res.status(404).json({ success: false, message: 'Not found' });
    if (!(req.user.role === 'admin' || req.user.role === 'support') && (!r.userId || r.userId.toString() !== req.user._id.toString())) {
      return res.status(403).json({ success: false, message: 'Forbidden' });
    }
    res.json({ success: true, request: {
      id: r._id.toString(),
      subject: r.subject,
      message: r.message,
      category: r.category,
      priority: r.priority,
      status: r.status,
      userId: r.userId ? r.userId.toString() : null,
      notes: (r.notes || []).map(n => ({ body: n.body, author: n.author?.toString?.() || n.author, createdAt: n.createdAt })),
      meta: r.meta || {},
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    }});
  } catch (e) {
    console.error('Error fetching support request', e);
    res.status(500).json({ success: false, message: 'Failed to fetch', error: e.message });
  } finally {
    await client.close();
  }
});

// Update a support request (status or add note)
router.put('/:id', requireAuth, async (req, res) => {
  const { id } = req.params;
  const { status, note } = req.body || {};
  if (!ObjectId.isValid(id)) {
    return res.status(400).json({ success: false, message: 'Invalid id' });
  }
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const existing = await db.collection('supportRequests').findOne({ _id: new ObjectId(id) });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    // Authorization: user can only modify if they own it; only staff can change status of others
    if (existing.userId && existing.userId.toString() !== req.user._id.toString()) {
      if (!(req.user.role === 'admin' || req.user.role === 'support')) {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }
    }
    const update = { updatedAt: new Date() };
    if (status) {
      if (!(req.user.role === 'admin' || req.user.role === 'support') && existing.userId.toString() !== req.user._id.toString()) {
        return res.status(403).json({ success: false, message: 'Forbidden' });
      }
      update.status = status;
    }
    const ops = [];
    if (note) {
      ops.push({ body: String(note).trim(), author: req.user._id, createdAt: new Date() });
    }
    const result = await db.collection('supportRequests').updateOne(
      { _id: new ObjectId(id) },
      { $set: update, ...(ops.length ? { $push: { notes: { $each: ops, $position: 0 } } } : {}) }
    );
    if (!result.matchedCount) {
      return res.status(404).json({ success: false, message: 'Not found' });
    }
    // Notify owner (if stored) about status change
    const updated = await db.collection('supportRequests').findOne({ _id: new ObjectId(id) });
    if (updated?.userId) {
      notifications.sendDomainNotification(updated.userId.toString(), {
        title: 'Support-Anfrage aktualisiert',
        body: `Status: ${updated.status}`,
        type: 'support_request_updated',
        data: { requestId: id, status: updated.status }
      });
    }
    res.json({ success: true, updated: true });
  } catch (e) {
    console.error('Error updating support request', e);
    res.status(500).json({ success: false, message: 'Failed to update', error: e.message });
  } finally {
    await client.close();
  }
});

module.exports = router;