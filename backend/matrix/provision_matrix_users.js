#!/usr/bin/env node
/**
 * Provision Matrix accounts for existing application users using Synapse's shared secret registration.
 * Requires env: MATRIX_ADMIN_REG_SECRET, MATRIX_BASE_URL (e.g. http://localhost:8008), SERVER_NAME.
 */
const crypto = require('crypto');
// Node 18+ provides global fetch; no import needed
const { getDB, connectDB } = require('../database');

async function generateMac(username, password, admin, sharedSecret) {
  const nonceResp = await fetch(process.env.MATRIX_BASE_URL + '/_synapse/admin/v1/register');
  if (!nonceResp.ok) throw new Error('Failed to fetch nonce');
  const { nonce } = await nonceResp.json();
  const mac = crypto.createHmac('sha1', sharedSecret).update(nonce + '\0' + username + '\0' + password + '\0' + (admin ? 'admin' : 'notadmin') + '\0' + '').digest('hex');
  return { nonce, mac };
}

async function upsertMatrixAccount(user) {
  const username = user._id.toString(); // use mongo id for global uniqueness
  const password = crypto.randomBytes(16).toString('hex');
  const admin = false;
  const sharedSecret = process.env.MATRIX_ADMIN_REG_SECRET;
  if (!sharedSecret) throw new Error('Missing MATRIX_ADMIN_REG_SECRET');
  const { nonce, mac } = await generateMac(username, password, admin, sharedSecret);
  const registerResp = await fetch(process.env.MATRIX_BASE_URL + '/_synapse/admin/v1/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ nonce, username, password, mac, admin })
  });
  if (!registerResp.ok) {
    const text = await registerResp.text();
    if (!text.includes('User ID already taken')) {
      throw new Error('Registration failed: ' + text);
    }
  }
  return { mxid: `@${username}:${process.env.SERVER_NAME || 'localhost'}`, accessToken: password };
}

async function run() {
  await connectDB();
  const db = getDB();
  const users = await db.collection('users').find({}).toArray();
  console.log('Provisioning matrix accounts for %d users', users.length);
  const matrixAccounts = db.collection('matrix_accounts');
  for (const user of users) {
    const existing = await matrixAccounts.findOne({ userId: user._id.toString() });
    if (existing) {
      console.log('Skip existing', existing.mxid);
      continue;
    }
    try {
      const acct = await upsertMatrixAccount(user);
      await matrixAccounts.insertOne({ userId: user._id.toString(), ...acct, createdAt: new Date(), updatedAt: new Date() });
      console.log('Provisioned', acct.mxid);
    } catch (e) {
      console.warn('Failed provisioning for user %s: %s', user._id.toString(), e.message);
    }
  }
  process.exit(0);
}

run().catch(e => { console.error(e); process.exit(1); });
