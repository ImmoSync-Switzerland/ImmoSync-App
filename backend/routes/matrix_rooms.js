const express = require('express');
const router = express.Router();
// Node 18+ provides global fetch; no import needed
const { getDB } = require('../database');

// POST /api/matrix/create-room
// body: { conversationId, creatorUserId, otherUserId }
// Requires MATRIX_BASE_URL and SERVER_NAME env set
router.post('/create-room', async (req, res) => {
  try {
    const { conversationId, creatorUserId, otherUserId } = req.body || {};
    if (!conversationId || !creatorUserId || !otherUserId) return res.status(400).json({ message: 'conversationId, creatorUserId and otherUserId required' });

    const db = getDB();
    const accounts = db.collection('matrix_accounts');
    const convs = db.collection('matrix_conversations');

    // If mapping already exists, return it
    const existing = await convs.findOne({ conversationId: conversationId.toString() });
    if (existing) return res.json(existing);

    // Load account for creator
    const creator = await accounts.findOne({ userId: creatorUserId.toString() });
    if (!creator) return res.status(404).json({ message: 'creator has no matrix account; provision first' });

    // Load account for other user (may or may not exist yet)
    const other = await accounts.findOne({ userId: otherUserId.toString() });

    const MATRIX_BASE = process.env.MATRIX_BASE_URL;
    if (!MATRIX_BASE) return res.status(500).json({ message: 'MATRIX_BASE_URL not configured on server' });

    // Login as creator to get access_token (creator.accessToken currently stores password from provisioning script)
    const loginResp = await fetch(`${MATRIX_BASE}/_matrix/client/r0/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'm.login.password', user: creator.userId || creator.mxid?.replace(/^@/, '')?.split(':')?.[0], password: creator.accessToken })
    });
    const loginJson = await loginResp.json();
    if (!loginResp.ok) {
      return res.status(502).json({ message: 'failed to login to Matrix as creator', detail: loginJson });
    }
    const access_token = loginJson.access_token;

    // Determine invitees' mxid; if other account not provisioned yet, infer mxid from mongo user id
    let other_mxid = other ? other.mxid : `@${otherUserId}:${process.env.SERVER_NAME || new URL(MATRIX_BASE).hostname}`;
    let creator_mxid = creator.mxid;

    // Create direct private room with initial invite to other user
    const createResp = await fetch(`${MATRIX_BASE}/_matrix/client/r0/createRoom?access_token=${access_token}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        visibility: 'private',
        preset: 'trusted_private_chat',
        invite: [other_mxid],
        is_direct: true
      })
    });
    const createJson = await createResp.json();
    if (!createResp.ok) {
      return res.status(502).json({ message: 'failed to create matrix room', detail: createJson });
    }
    const roomId = createJson.room_id;

    // IMPORTANT: Also invite the creator's MXID so all their devices/sessions can access the room
    // This is safe because the creator is already in the room from creating it
    try {
      const inviteCreatorResp = await fetch(`${MATRIX_BASE}/_matrix/client/r0/rooms/${encodeURIComponent(roomId)}/invite?access_token=${access_token}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: creator_mxid })
      });
      if (!inviteCreatorResp.ok) {
        // Log but don't fail - the invite might fail if user already in room
        const det = await inviteCreatorResp.text();
        console.log('[Matrix][Info] invite creator response', inviteCreatorResp.status, det);
      }
    } catch (e) {
      console.warn('[Matrix][Warn] failed to invite creator', e);
    }

    // Enable Megolm encryption (E2EE) for the room
    try {
      const encResp = await fetch(`${MATRIX_BASE}/_matrix/client/r0/rooms/${encodeURIComponent(roomId)}/state/m.room.encryption?access_token=${access_token}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ algorithm: 'm.megolm.v1.aes-sha2' })
      });
      if (!encResp.ok) {
        const det = await encResp.text();
        console.warn('[Matrix][Warn] failed to enable encryption', det);
      }
    } catch (e) {
      console.warn('[Matrix][Warn] encryption state error', e);
    }

    // Persist mapping
    const mapDoc = {
      conversationId: conversationId.toString(),
      roomId,
      participants: [creatorUserId.toString(), otherUserId.toString()],
      createdAt: new Date(),
      updatedAt: new Date()
    };
    await convs.insertOne(mapDoc);

    return res.json(mapDoc);
  } catch (e) {
    console.error('matrix create-room error', e);
    return res.status(500).json({ message: e.message });
  }
});

// GET /api/matrix/rooms/by-users/:a/:b
// Returns an existing matrix_conversations mapping that includes both participants
// Response: { conversationId, roomId, participants }
router.get('/by-users/:a/:b', async (req, res) => {
  try {
    const a = (req.params.a || '').toString();
    const b = (req.params.b || '').toString();
    if (!a || !b) return res.status(400).json({ message: 'user ids required' });
    const db = getDB();
    const convs = db.collection('matrix_conversations');
    const doc = await convs.findOne({ participants: { $all: [a, b] } });
    if (!doc) return res.status(404).json({ message: 'no mapping for users' });
    return res.json({
      conversationId: doc.conversationId,
      roomId: doc.roomId,
      participants: doc.participants,
    });
  } catch (e) {
    console.error('matrix by-users error', e);
    return res.status(500).json({ message: e.message });
  }
});

// POST /api/matrix/rooms/persist-mapping
// Persist a room mapping created by the SDK client
// body: { conversationId, roomId, participants: [userId1, userId2] }
router.post('/persist-mapping', async (req, res) => {
  try {
    const { conversationId, roomId, participants } = req.body || {};
    if (!conversationId || !roomId || !Array.isArray(participants)) {
      return res.status(400).json({ message: 'conversationId, roomId and participants required' });
    }
    const db = getDB();
    const convs = db.collection('matrix_conversations');
    
    // Check if mapping already exists
    const existing = await convs.findOne({ conversationId: conversationId.toString() });
    if (existing) return res.json(existing);
    
    const mapDoc = {
      conversationId: conversationId.toString(),
      roomId,
      participants: participants.map(p => p.toString()),
      createdAt: new Date(),
      updatedAt: new Date()
    };
    await convs.insertOne(mapDoc);
    return res.json(mapDoc);
  } catch (e) {
    console.error('matrix persist-mapping error', e);
    return res.status(500).json({ message: e.message });
  }
});

// POST /api/matrix/rooms/invite
// Invite a user to an existing room
// body: { roomId, inviterUserId, inviteeUserId }
router.post('/invite', async (req, res) => {
  try {
    const { roomId, inviterUserId, inviteeUserId } = req.body || {};
    if (!roomId || !inviterUserId || !inviteeUserId) {
      return res.status(400).json({ message: 'roomId, inviterUserId and inviteeUserId required' });
    }

    const db = getDB();
    const accounts = db.collection('matrix_accounts');

    // Get inviter's account
    const inviter = await accounts.findOne({ userId: inviterUserId.toString() });
    if (!inviter) return res.status(404).json({ message: 'inviter has no matrix account' });

    // Get invitee's account
    const invitee = await accounts.findOne({ userId: inviteeUserId.toString() });
    if (!invitee) return res.status(404).json({ message: 'invitee has no matrix account' });

    const MATRIX_BASE = process.env.MATRIX_BASE_URL;
    if (!MATRIX_BASE) return res.status(500).json({ message: 'MATRIX_BASE_URL not configured' });

    // Login as inviter
    const loginResp = await fetch(`${MATRIX_BASE}/_matrix/client/r0/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'm.login.password', user: inviter.userId || inviter.mxid?.replace(/^@/, '')?.split(':')?.[0], password: inviter.accessToken })
    });
    const loginJson = await loginResp.json();
    if (!loginResp.ok) {
      return res.status(502).json({ message: 'failed to login as inviter', detail: loginJson });
    }
    const access_token = loginJson.access_token;

    // Invite the user
    const inviteResp = await fetch(`${MATRIX_BASE}/_matrix/client/r0/rooms/${encodeURIComponent(roomId)}/invite?access_token=${access_token}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: invitee.mxid })
    });
    const inviteJson = await inviteResp.json();
    if (!inviteResp.ok) {
      return res.status(502).json({ message: 'failed to invite user', detail: inviteJson });
    }

    return res.json({ success: true, roomId, invitee: invitee.mxid });
  } catch (e) {
    console.error('matrix invite error', e);
    return res.status(500).json({ message: e.message });
  }
});

// GET /api/matrix/accounts/:userId/mxid
// Get the Matrix ID (MXID) for a user
router.get('/accounts/:userId/mxid', async (req, res) => {
  try {
    const userId = (req.params.userId || '').toString();
    if (!userId) return res.status(400).json({ message: 'userId required' });
    const db = getDB();
    const accounts = db.collection('matrix_accounts');
    const account = await accounts.findOne({ userId });
    if (!account || !account.mxid) {
      return res.status(404).json({ message: 'No Matrix account found for user' });
    }
    return res.json({ mxid: account.mxid });
  } catch (e) {
    console.error('matrix get-mxid error', e);
    return res.status(500).json({ message: e.message });
  }
});

// DELETE /api/matrix/rooms/mapping/:conversationId
// Delete a Matrix room mapping (to force recreation)
router.delete('/mapping/:conversationId', async (req, res) => {
  try {
    const conversationId = (req.params.conversationId || '').toString();
    if (!conversationId) return res.status(400).json({ message: 'conversationId required' });
    const db = getDB();
    const convs = db.collection('matrix_conversations');
    const result = await convs.deleteOne({ conversationId });
    return res.json({ deleted: result.deletedCount > 0 });
  } catch (e) {
    console.error('matrix delete-mapping error', e);
    return res.status(500).json({ message: e.message });
  }
});

module.exports = router;
