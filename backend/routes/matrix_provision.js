const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const { getDB } = require('../database');

// Toggle verbose debug via env (optional)
const DEBUG_MATRIX_PROVISION = process.env.DEBUG_MATRIX_PROVISION === '1';

// Helper: compute MAC in two styles
function computeMac({ nonce, username, password, admin, secret, style }) {
  // style: 'text' => admin/notadmin ; 'bool' => true/false
  const segment = style === 'text'
    ? (admin ? 'admin' : 'notadmin')
    : (admin ? 'true' : 'false');

  const macSource = [nonce, username, password, segment].join('\0'); // keine extra \0 am Ende
  const mac = crypto.createHmac('sha1', secret).update(macSource).digest('hex');

  if (DEBUG_MATRIX_PROVISION) {
    console.log('[matrix provision][debug] mac style=%s source(hex)=%s mac=%s',
      style,
      Buffer.from(macSource, 'utf8').toString('hex'),
      mac
    );
  }
  return mac;
}

async function attemptRegister({ base, secret, username, password, admin }) {
  // 1. Nonce holen
  const nonceResp = await fetch(`${base}/_synapse/admin/v1/register`);
  if (!nonceResp.ok) {
    const text = await nonceResp.text();
    return { ok: false, phase: 'nonce', status: nonceResp.status, detail: text };
  }
  const { nonce } = await nonceResp.json();

  // Zuerst Variante 'text' (admin/notadmin)
  for (const style of ['text', 'bool']) {
    const mac = computeMac({ nonce, username, password, admin, secret, style });
    const body = JSON.stringify({ nonce, username, password, mac, admin });
    const registerResp = await fetch(`${base}/_synapse/admin/v1/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body
    });
    const text = await registerResp.text();

    // Erfolg oder User existiert bereits => akzeptieren
    if (registerResp.ok || text.includes('User ID already taken')) {
      return { ok: true, reused: text.includes('User ID already taken'), style };
    }

    // HMAC/Nonce Fehler → nächster Stil
    if (/HMAC|mac|nonce/i.test(text) && style === 'text') {
      if (DEBUG_MATRIX_PROVISION) console.warn('[matrix provision] style=text failed, retry style=bool');
      continue;
    }

    // Anderer Fehler → abbrechen
    return { ok: false, phase: 'register', status: registerResp.status, detail: text, styleTried: style };
  }

  return { ok: false, phase: 'register', status: 500, detail: 'All MAC styles failed' };
}

// POST /api/matrix/provision { userId }
router.post('/provision', async (req, res) => {
  try {
    const { userId } = req.body || {};
    if (!userId) return res.status(400).json({ message: 'userId required' });

    const base = process.env.MATRIX_BASE_URL;
    const secret = process.env.MATRIX_ADMIN_REG_SECRET;
    const serverName = process.env.SERVER_NAME || (base ? new URL(base).hostname : undefined);
    if (!base || !secret) {
      return res.status(500).json({ message: 'MATRIX_BASE_URL and MATRIX_ADMIN_REG_SECRET must be set in env' });
    }

    const username = userId.toString();
    const password = crypto.randomBytes(24).toString('hex');
    const admin = false;

    const result = await attemptRegister({ base, secret, username, password, admin });

    if (!result.ok) {
      if (DEBUG_MATRIX_PROVISION) console.warn('[matrix provision] failure detail:', result);
      const hint = (() => {
        if (result.phase === 'nonce') return 'Konnte Nonce nicht holen (Proxy / Synapse / Pfad prüfen)';
        if (/HMAC|mac/i.test(result.detail || '')) return 'HMAC mismatch – Secret oder MAC-Format prüfen';
        if (/nonce/i.test(result.detail || '')) return 'Nonce Ablauf oder doppelte Verwendung';
        return undefined;
      })();
      return res.status(502).json({
        message: 'Registration failed',
        phase: result.phase,
        style: result.styleTried,
        status: result.status,
        detail: result.detail,
        hint
      });
    }

    const mxid = `@${username}:${serverName}`;
    const db = getDB();
    const coll = db.collection('matrix_accounts');
    await coll.updateOne(
      { userId },
      {
        $set: {
          userId,
            mxid,
            accessToken: password,
            updatedAt: new Date(),
            createdAt: new Date()
        }
      },
      { upsert: true }
    );

    return res.json({
      userId,
      mxid,
      styleUsed: result.style,
      reused: !!result.reused
    });
  } catch (e) {
    console.error('matrix provision error', e);
    return res.status(500).json({ message: e.message });
  }
});

// GET /api/matrix/account/:userId
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
      username: acct.userId,
      password: acct.accessToken,
      baseUrl: base,
      serverName
    });
  } catch (e) {
    console.error('matrix account fetch error', e);
    return res.status(500).json({ message: e.message });
  }
});

module.exports = router;