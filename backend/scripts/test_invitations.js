// Automated invitation lifecycle test script
// Usage: node scripts/test_invitations.js <landlordEmail> <tenantEmail>
// Creates landlord & tenant (if missing), creates a property, sends invitation, accepts it,
// then prints property + invitation + user states for debugging tenant assignment.

const { MongoClient, ObjectId } = require('mongodb');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const { dbUri, dbName } = require('../config');

async function ensureUser(db, email, role, apiUrl) {
  let user = await db.collection('users').findOne({ email });
  if (user) {
    console.log(`[reuse] user ${email} id=${user._id} role=${user.role}`);
    return user;
  }

  // Try API registration first (preferred: respects schema & hooks)
  try {
    const body = {
      email,
      password: 'Test!2345',
      fullName: `${role}_${Date.now()}`,
      role: role.toLowerCase(),
      phone: '',
      isCompany: false
    };
    // Supply required fields for validation
    body.birthDate = '1990-01-01T00:00:00.000Z';
    body.address = {
      street: 'Test Street 1',
      city: 'Test City',
      postalCode: '8000',
      country: 'CH'
    };
    const resp = await fetch(`${apiUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    const txt = await resp.text();
    console.log(`[register][${email}] status ${resp.status} body ${txt}`);
    if (resp.status === 201) {
      const json = JSON.parse(txt);
      user = await db.collection('users').findOne({ _id: new ObjectId(json.userId) });
      if (user) return user;
    }
  } catch (e) {
    console.log(`[register][${email}] API attempt failed:`, e.message);
  }

  // Fallback direct insert (mirror registration fields)
  const bcrypt = require('bcryptjs');
  const hashed = await bcrypt.hash('Test!2345', 6);
  const doc = {
    email,
    password: hashed,
    fullName: `${role}_${Date.now()}`,
    role: role.toLowerCase(),
    phone: '',
    isCompany: false,
    isAdmin: false,
    isValidated: true,
    birthDate: new Date('1990-01-01T00:00:00.000Z'),
    address: {
      street: 'Test Street 1',
      city: 'Test City',
      postalCode: '8000',
      country: 'CH'
    },
    createdAt: new Date(),
    updatedAt: new Date()
  };
  try {
    const res = await db.collection('users').insertOne(doc);
    user = { ...doc, _id: res.insertedId };
    console.log(`[create-fallback] user ${email} (${role}) _id=${user._id}`);
  } catch (e) {
    console.error('[direct insert user] failed validation details:', e.errInfo || e.message);
    throw e;
  }
  return user;
}

async function createProperty(db, landlordId) {
  const prop = {
    landlordId: landlordId.toString(),
    address: { street: 'Test Strasse 1', city: 'Teststadt', postalCode: '8000', country: 'CH' },
    status: 'available',
    rentAmount: 1234,
    details: { size: 50, rooms: 2, amenities: ['wifi'] },
    imageUrls: [],
    tenantIds: [],
    outstandingPayments: 0,
    createdAt: new Date(),
    updatedAt: new Date()
  };
  const res = await db.collection('properties').insertOne(prop);
  console.log(`[create] property _id=${res.insertedId}`);
  return { ...prop, _id: res.insertedId };
}

async function sendInvitation(apiUrl, propertyId, landlordId, tenantId) {
  const resp = await fetch(`${apiUrl}/invitations`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ propertyId: propertyId.toString(), landlordId: landlordId.toString(), tenantId: tenantId.toString(), message: 'Test invite' })
  });
  const body = await resp.text();
  console.log('[invite][status]', resp.status, body);
  if (resp.status !== 201) throw new Error('Invitation creation failed');
  const json = JSON.parse(body);
  return json.invitationId;
}

async function acceptInvitation(apiUrl, invitationId) {
  const resp = await fetch(`${apiUrl}/invitations/${invitationId}/accept`, { method: 'PUT' });
  const body = await resp.text();
  console.log('[accept][status]', resp.status, body);
  if (resp.status !== 200) throw new Error('Invitation acceptance failed');
  return JSON.parse(body);
}

async function dumpState(db, propertyId, landlordId, tenantId, invitationId) {
  const property = await db.collection('properties').findOne({ _id: new ObjectId(propertyId) });
  const landlord = await db.collection('users').findOne({ _id: new ObjectId(landlordId) });
  const tenant = await db.collection('users').findOne({ _id: new ObjectId(tenantId) });
  const invitation = await db.collection('invitations').findOne({ _id: new ObjectId(invitationId) });

  function summarize(doc) {
    if (!doc) return 'null';
    const clone = { ...doc };
    Object.keys(clone).forEach(k => { if (clone[k] instanceof ObjectId) clone[k] = clone[k].toString(); });
    return clone;
  }

  console.log('\n=== STATE DUMP ===');
  console.log('Property:', summarize(property));
  console.log('Landlord.user propertyId:', landlord?.propertyId?.toString());
  console.log('Tenant.user propertyId:', tenant?.propertyId?.toString());
  console.log('Invitation:', summarize(invitation));
  console.log('Property.tenantIds:', property?.tenantIds);
  console.log('===================\n');
}

(async () => {
  const landlordEmail = process.argv[2] || 'landlord_test@example.com';
  const tenantEmail = process.argv[3] || 'tenant_test@example.com';
  const apiUrl = process.env.API_URL || 'https://backend.immosync.ch/api';

  const client = new MongoClient(dbUri);
  await client.connect();
  const db = client.db(dbName);
  try {
  const landlord = await ensureUser(db, landlordEmail, 'landlord', apiUrl);
  const tenant = await ensureUser(db, tenantEmail, 'tenant', apiUrl);
    const property = await createProperty(db, landlord._id);
    const invitationId = await sendInvitation(apiUrl, property._id, landlord._id, tenant._id);
    await dumpState(db, property._id, landlord._id, tenant._id, invitationId);
    const acceptance = await acceptInvitation(apiUrl, invitationId);
    console.log('[accept][parsed]', acceptance);
    await dumpState(db, property._id, landlord._id, tenant._id, invitationId);
    console.log('Done.');
  } catch (e) {
    console.error('Test error:', e);
  } finally {
    await client.close();
  }
})();
