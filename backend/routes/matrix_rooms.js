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

    // Create direct private room and invite
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

module.exports = router;
