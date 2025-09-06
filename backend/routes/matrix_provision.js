const express = require('express');
const router = express.Router();
// Node 18+ provides global fetch; no import needed
const crypto = require('crypto');
const { getDB } = require('../database');

// POST /api/matrix/provision  { userId }
// Requires env: MATRIX_BASE_URL, MATRIX_ADMIN_REG_SECRET, SERVER_NAME

router.post('/provision', async (req, res) => {
  try {
    const { userId } = req.body || {};
    if (!userId) return res.status(400).json({ message: 'userId required' });
    const base = process.env.MATRIX_BASE_URL;
    const secret = process.env.MATRIX_ADMIN_REG_SECRET;
    const serverName = process.env.SERVER_NAME || (new URL(base)).hostname;
    if (!base || !secret) return res.status(500).json({ message: 'MATRIX_BASE_URL and MATRIX_ADMIN_REG_SECRET must be set in env' });

    // Derive username from mongo id for uniqueness
    const username = userId.toString();
    const password = crypto.randomBytes(24).toString('hex');

    // Step 1: GET nonce
    const nonceResp = await fetch(`${base}/_synapse/admin/v1/register`);
    if (!nonceResp.ok) {
      const text = await nonceResp.text();
      return res.status(502).json({ message: 'Failed to fetch nonce', detail: text });
    }
    const { nonce } = await nonceResp.json();

    // Step 2: compute mac
    const macSource = [nonce, username, password, 'notadmin', ''].join('\0');
    const mac = crypto.createHmac('sha1', secret).update(macSource).digest('hex');

    // Step 3: POST register
    const registerResp = await fetch(`${base}/_synapse/admin/v1/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ nonce, username, password, mac, admin: false })
    });

    const registerText = await registerResp.text();
    if (!registerResp.ok && !registerText.includes('User ID already taken')) {
      return res.status(502).json({ message: 'Registration failed', detail: registerText });
    }

    const mxid = `@${username}:${serverName}`;
    const db = getDB();
    const coll = db.collection('matrix_accounts');
    await coll.updateOne({ userId }, { $set: { userId, mxid, accessToken: password, updatedAt: new Date(), createdAt: new Date() } }, { upsert: true });

    return res.json({ userId, mxid });
  } catch (e) {
    console.error('matrix provision error', e);
    return res.status(500).json({ message: e.message });
  }
});

// GET /api/matrix/account/:userId
// Returns stored Matrix credentials for the given user (for client-side login via SDK)
// WARNING: This exposes password-equivalent secret; secure behind proper auth in production.
router.get('/account/:userId', async (req, res) => {
  try {
    const { userId } = req.params || {};
    if (!userId) return res.status(400).json({ message: 'userId required' });
    const db = getDB();
    const coll = db.collection('matrix_accounts');
    const acct = await coll.findOne({ userId: userId.toString() });
    if (!acct) return res.status(404).json({ message: 'No matrix account found for user' });
    const base = process.env.MATRIX_BASE_URL;
    const serverName = process.env.SERVER_NAME || (base ? new URL(base).hostname : undefined);
    return res.json({
      userId: acct.userId,
      mxid: acct.mxid,
      username: acct.userId, // localpart chosen during provision
      password: acct.accessToken, // stored random password from provision step
      baseUrl: base,
      serverName,
    });
  } catch (e) {
    console.error('matrix account fetch error', e);
    return res.status(500).json({ message: e.message });
  }
});

module.exports = router;
