const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');
const { buildProfileImageUrl, buildInlineUserImageUrl } = require('../utils');

// Helper to compute if a timestamp is considered online (e.g. last 60s)
function isOnline(lastSeen) {
  if (!lastSeen) return false;
  const thresholdMs = 60 * 1000; // 60 seconds window
  return Date.now() - new Date(lastSeen).getTime() < thresholdMs;
}

// Get all available tenants (for a specific property or all available)
router.get('/available-tenants', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { propertyId } = req.query;
    
    if (propertyId) {
      // Get tenants available for a specific property
      if (!ObjectId.isValid(propertyId)) {
        return res.status(400).json({ message: 'Invalid property ID format' });
      }
      
      // Find tenants who are NOT assigned to this specific property
      // and don't have a pending/accepted invitation for this property
      const tenants = await db.collection('users')
        .find({ 
          role: 'tenant'
        })
        .toArray();
      
      // Filter out tenants who are already assigned to this property
      const property = await db.collection('properties')
        .findOne({ _id: new ObjectId(propertyId) });
      
      const assignedTenantIds = property?.tenantIds || [];
      
      // Filter out tenants with pending/accepted invitations for this property
      const invitations = await db.collection('invitations')
        .find({ 
          propertyId: propertyId,
          status: { $in: ['pending', 'accepted'] }
        })
        .toArray();
      
      const invitedTenantIds = invitations.map(inv => inv.tenantId);
      
      // Combine both lists to exclude
      const excludedTenantIds = [...assignedTenantIds, ...invitedTenantIds];
      
      const availableTenants = tenants.filter(tenant => 
        !excludedTenantIds.includes(tenant._id.toString())
      );
      
      console.log(`Found ${availableTenants.length} available tenants for property ${propertyId}`);
      console.log(`Excluded ${excludedTenantIds.length} tenants (assigned: ${assignedTenantIds.length}, invited: ${invitedTenantIds.length})`);
      
      // Convert ObjectIds to strings for frontend compatibility
      const serializedTenants = availableTenants.map(tenant => ({
        ...tenant,
        _id: tenant._id.toString(),
        profileImageUrl: buildProfileImageUrl(tenant.profileImage || tenant.providerPicture, req),
      }));
      
      res.json(serializedTenants);
    } else {
      // Original logic - get all tenants without any property assignment
      const tenants = await db.collection('users')
        .find({ 
          role: 'tenant',
          propertyId: { $exists: false } 
        })
        .toArray();
      
      console.log(`Found ${tenants.length} available tenants (no property assigned)`);
      
      // Convert ObjectIds to strings for frontend compatibility
      const serializedTenants = tenants.map(tenant => ({
        ...tenant,
        _id: tenant._id.toString(),
        profileImageUrl: buildProfileImageUrl(tenant.profileImage || tenant.providerPicture, req),
      }));
      
      res.json(serializedTenants);
    }
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ message: 'Error fetching tenants' });
  } finally {
    await client.close();
  }
});

// Upload inline profile image to user document (base64 or raw bytes)
// POST /users/:userId/profile-image with JSON { dataUrl: 'data:image/png;base64,...' } or multipart/form-data 'image'
router.post('/:userId/profile-image', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    let { userId } = req.params;
    userId = (userId || '').toString().trim();
    if (!ObjectId.isValid(userId)) return res.status(400).json({ message: 'Invalid userId' });

    // Support either JSON body with dataUrl, or raw base64 in { base64 }, fallback to req.body.image
    let contentType = null;
    let buffer = null;

    if (req.is('application/json')) {
      const dataUrl = req.body?.dataUrl || req.body?.dataURL || null;
      const base64 = req.body?.base64 || null;
      if (dataUrl && typeof dataUrl === 'string' && dataUrl.startsWith('data:')) {
        const match = /^data:([^;]+);base64,(.*)$/i.exec(dataUrl);
        if (!match) return res.status(400).json({ message: 'Invalid dataUrl' });
        contentType = match[1];
        buffer = Buffer.from(match[2], 'base64');
      } else if (base64 && typeof base64 === 'string') {
        contentType = 'image/png';
        buffer = Buffer.from(base64, 'base64');
      }
    }

    if (!buffer) {
      // As a minimal fallback, allow plain text body with base64 (not ideal, but pragmatic)
      if (typeof req.body === 'string') {
        contentType = 'image/png';
        buffer = Buffer.from(req.body, 'base64');
      }
    }

    if (!buffer) {
      return res.status(400).json({ message: 'No image data provided' });
    }

    const update = {
      $set: {
        profileImageInline: {
          contentType: contentType || 'image/png',
          data: buffer,
          uploadedAt: new Date(),
        },
        updatedAt: new Date(),
      }
    };
    await db.collection('users').updateOne({ _id: new ObjectId(userId) }, update);
    return res.json({ ok: true, profileImageUrl: buildInlineUserImageUrl(userId, req) });
  } catch (e) {
    console.error('POST /users/:userId/profile-image error', e);
    return res.status(500).json({ message: 'Failed to upload profile image' });
  } finally {
    await client.close();
  }
});

// Serve inline profile image if present; else 404
router.get('/:userId/profile-image', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const { userId } = req.params;
    if (!ObjectId.isValid(userId)) return res.status(400).json({ message: 'Invalid userId' });
    const doc = await db.collection('users').findOne({ _id: new ObjectId(userId) }, { projection: { profileImageInline: 1 } });
    const inline = doc?.profileImageInline;
    if (!inline || !inline.data) return res.status(404).json({ message: 'No inline profile image' });
    res.setHeader('Content-Type', inline.contentType || 'image/png');
    // Disable caching so updated avatars are reflected immediately
    res.setHeader('Cache-Control', 'no-store, must-revalidate');
    return res.send(Buffer.from(inline.data.buffer || inline.data));
  } catch (e) {
    console.error('GET /users/:userId/profile-image error', e);
    return res.status(500).json({ message: 'Failed to fetch profile image' });
  } finally {
    await client.close();
  }
});

// GET /api/tenants - Fetch tenant users with filtering support
router.get('/tenants', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { propertyId, landlordId } = req.query;
    
    // Build query based on filters
    let query = { role: 'tenant' };
    
    if (propertyId) {
      if (!ObjectId.isValid(propertyId)) {
        return res.status(400).json({ message: 'Invalid property ID format' });
      }
      // Find tenants assigned to specific property
      query.propertyId = new ObjectId(propertyId);
    }
    
    if (landlordId) {
      if (!ObjectId.isValid(landlordId)) {
        return res.status(400).json({ message: 'Invalid landlord ID format' });
      }
      // Find tenants associated with landlord's properties
      query.landlordId = new ObjectId(landlordId);
    }
    
    // Get all tenants matching the filters
    const tenants = await db.collection('users')
      .find(query)
      .toArray();
    
    // Find property and lease information for each tenant
    const tenantsWithDetails = await Promise.all(
      tenants.map(async (tenant) => {
        let propertyInfo = null;
        let leaseInfo = null;
        
        // Get property information if tenant has propertyId
        if (tenant.propertyId) {
          propertyInfo = await db.collection('properties')
            .findOne({ _id: new ObjectId(tenant.propertyId) });
        }
        
        // Get lease information from leases collection
        leaseInfo = await db.collection('leases')
          .findOne({ tenantId: tenant._id });
        
        return {
          _id: tenant._id.toString(),
          name: tenant.fullName || tenant.name || '',
          email: tenant.email || '',
          propertyId: tenant.propertyId ? tenant.propertyId.toString() : '',
          landlordId: tenant.landlordId ? tenant.landlordId.toString() : '',
          phone: tenant.phone || '',
          leaseStart: leaseInfo ? leaseInfo.startDate : null,
          leaseEnd: leaseInfo ? leaseInfo.endDate : null,
          rentAmount: leaseInfo ? leaseInfo.rentAmount : (propertyInfo ? propertyInfo.rentAmount : 0),
          profileImageUrl: buildProfileImageUrl(tenant.profileImage || tenant.providerPicture, req),
        };
      })
    );
    
    // Format response to match expected structure
    const response = {
      tenants: tenantsWithDetails,
      Count: tenantsWithDetails.length
    };
    
  console.log(`Found ${tenantsWithDetails.length} tenants with filters:`, { propertyId, landlordId });
    res.json(response);
  } catch (error) {
    console.error('Error fetching tenants:', error);
    res.status(500).json({ message: 'Error fetching tenants', error: error.message });
  } finally {
    await client.close();
  }
});

// Get all users (for general use)
router.get('/', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const users = await db.collection('users')
      .find({})
      .toArray();
    
    console.log(`Found ${users.length} total users`);
    const shaped = users.map(u => ({
      ...u,
      _id: u._id?.toString?.() || u._id,
      profileImageUrl: buildProfileImageUrl(u.profileImage || u.providerPicture, req),
    }));
    res.json(shaped);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Error fetching users' });
  } finally {
    await client.close();
  }
});

// Get current user by session token (Authorization header)
router.get('/me', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const authHeader = req.headers['authorization'] || req.headers['Authorization'];
    if (!authHeader || typeof authHeader !== 'string' || !authHeader.trim()) {
      return res.status(401).json({ message: 'Authorization token required' });
    }
    const token = authHeader.trim();
    const doc = await db.collection('users').findOne({ sessionToken: token });
    if (!doc) return res.status(404).json({ message: 'User not found' });
    const serialized = { ...doc };
    try {
      if (doc._id) serialized._id = doc._id.toString();
      if (doc.propertyId) serialized.propertyId = doc.propertyId.toString();
      if (doc.landlordId) serialized.landlordId = doc.landlordId.toString();
      ['birthDate','updatedAt','createdAt','lastSeen','passwordChangedAt','sessionTokenCreatedAt']
        .forEach(k => { if (doc[k]) serialized[k] = new Date(doc[k]).toISOString(); });
  delete serialized.password;
  // Prefer inline image if present
  const inlineUrl = doc.profileImageInline ? buildInlineUserImageUrl(doc._id, req) : null;
  serialized.profileImageUrl = inlineUrl || buildProfileImageUrl(doc.profileImage || doc.providerPicture, req);
    } catch (e) { /* no-op */ }
    return res.json(serialized);
  } catch (e) {
    console.error('GET /users/me error', e);
    res.status(500).json({ message: 'Failed to fetch current user' });
  } finally {
    await client.close();
  }
});

// Get user by id without conflicting with specific subroutes
router.get('/by-id/:userId', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    let { userId } = req.params;
    userId = (userId || '').toString().trim();
    if (!ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID format' });
    }
    const doc = await db.collection('users').findOne({ _id: new ObjectId(userId) });
    if (!doc) return res.status(404).json({ message: 'User not found' });
    const serialized = { ...doc };
    try {
      if (doc._id) serialized._id = doc._id.toString();
      if (doc.propertyId) serialized.propertyId = doc.propertyId.toString();
      if (doc.landlordId) serialized.landlordId = doc.landlordId.toString();
      ['birthDate','updatedAt','createdAt','lastSeen','passwordChangedAt','sessionTokenCreatedAt']
        .forEach(k => { if (doc[k]) serialized[k] = new Date(doc[k]).toISOString(); });
  delete serialized.password;
  const inlineUrl2 = doc.profileImageInline ? buildInlineUserImageUrl(doc._id, req) : null;
  serialized.profileImageUrl = inlineUrl2 || buildProfileImageUrl(doc.profileImage || doc.providerPicture, req);
    } catch (e) { /* no-op */ }
    return res.json(serialized);
  } catch (e) {
    console.error('GET /users/by-id/:userId error', e);
    res.status(500).json({ message: 'Failed to fetch user' });
  } finally {
    await client.close();
  }
});

// Update user profile (extended to allow setting publicKey for E2EE bootstrap)
router.patch('/:userId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    let { userId } = req.params;
  const { fullName, email, phone, address, profileImage, publicKey } = req.body;
    
    // Normalize id input
    userId = (userId || '').toString().trim();
    if (!ObjectId.isValid(userId)) {
      // Try to extract from Extended JSON like '{"$oid":"..."}'
      const match = /\{\s*"?\$oid"?\s*:\s*"([a-fA-F0-9]{24})"\s*\}/.exec(userId);
      if (match && match[1]) {
        userId = match[1];
      }
    }

  const isValidObjId = ObjectId.isValid(userId);
  const filter = isValidObjId ? { _id: new ObjectId(userId) } : { _id: userId };

    console.log('[Users PATCH] userId param=%s normalized validObjId=%s filter=%j', req.params.userId, isValidObjId, filter);
    
  // Prepare update data
    const updateData = {};
    if (fullName) updateData.fullName = fullName;
    if (email) updateData.email = email;
    if (phone) updateData.phone = phone;
  if (address) updateData.address = address;
  if (profileImage !== undefined) updateData.profileImage = profileImage; // allow clearing with null
    if (publicKey && typeof publicKey === 'string') {
      // Only allow setting once to prevent key swapping attacks without explicit reset flow
      const existing = await db.collection('users').findOne({ _id: new ObjectId(userId) }, { projection: { publicKey: 1 } });
      if (existing && existing.publicKey && existing.publicKey !== publicKey) {
        return res.status(400).json({ message: 'Public key already set; key rotation not yet supported.' });
      }
      updateData.publicKey = publicKey;
    }
    
    updateData.updatedAt = new Date();

    const updateKeys = Object.keys(updateData);
    console.log('[Users PATCH] update keys=%s', updateKeys.join(','));

    // If no changes provided, just return current user doc (by id or token)
    if (updateKeys.length === 1 && updateKeys[0] === 'updatedAt') {
      // No actual fields to update
      let doc = await db.collection('users').findOne(filter);
      if (!doc) {
        const authHeader = req.headers['authorization'] || req.headers['Authorization'];
        if (authHeader && typeof authHeader === 'string' && authHeader.trim()) {
          const token = authHeader.trim();
          doc = await db.collection('users').findOne({ sessionToken: token });
        }
      }
      if (!doc) {
        return res.status(404).json({ message: 'User not found' });
      }
      console.log('[Users PATCH] No-op update, returning current doc id=%s', doc._id?.toString?.());
      return res.status(200).json(doc);
    }
    
    let result = await db.collection('users').findOneAndUpdate(
      filter,
      { $set: updateData },
      { returnDocument: 'after' }
    );
    
    if (!result.value) {
      console.warn('[Users PATCH] Not found for filter=%j', filter);
      // Fallback: try to resolve by session token from Authorization header
      const authHeader = req.headers['authorization'] || req.headers['Authorization'];
      if (authHeader && typeof authHeader === 'string' && authHeader.trim()) {
        const token = authHeader.trim();
        const byToken = await db.collection('users').findOne({ sessionToken: token });
        if (byToken) {
          console.log('[Users PATCH] Resolved user via session token, id=%s', byToken._id.toString());
          result = await db.collection('users').findOneAndUpdate(
            { _id: byToken._id },
            { $set: updateData },
            { returnDocument: 'after' }
          );
          if (!result.value) {
            console.warn('[Users PATCH] findOneAndUpdate returned null after token resolve; doing updateOne+findOne');
            await db.collection('users').updateOne({ _id: byToken._id }, { $set: updateData });
            const fetched = await db.collection('users').findOne({ _id: byToken._id });
            // Shape like findOneAndUpdate result
            if (fetched) result = { value: fetched };
          }
        }
      }
    }

    if (!result.value) {
      return res.status(404).json({ message: 'User not found' });
    }
    const doc = result.value;
    // Build a stable JSON-friendly user object
  const serialized = { ...doc };
    try {
      if (doc._id) serialized._id = doc._id.toString();
      if (doc.propertyId) serialized.propertyId = doc.propertyId.toString();
      if (doc.landlordId) serialized.landlordId = doc.landlordId.toString();
      // Coerce dates to ISO strings
      ['birthDate','updatedAt','createdAt','lastSeen','passwordChangedAt','sessionTokenCreatedAt']
        .forEach(k => { if (doc[k]) serialized[k] = new Date(doc[k]).toISOString(); });
    // Remove sensitive fields
    delete serialized.password;
    const inlineUrl3 = doc.profileImageInline ? buildInlineUserImageUrl(doc._id, req) : null;
    serialized.profileImageUrl = inlineUrl3 || buildProfileImageUrl(doc.profileImage || doc.providerPicture, req);
    } catch (e) {
      console.warn('[Users PATCH] serialize warning:', e.message);
    }
  console.log('[Users PATCH] Updated user profile id=%s -> 200', serialized._id || userId);
  return res.status(200).json(serialized);
  } catch (error) {
    console.error('Error updating user profile:', error);
    res.status(500).json({ message: 'Error updating user profile', error: error.message });
  } finally {
    await client.close();
  }
});

module.exports = router;

// --- E2EE PUBLIC KEY ENDPOINTS ---
// Publish identity public key (one-time). Body: { userId, publicKey }
router.post('/publish-key', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const { userId, publicKey } = req.body || {};
    if (!userId || !publicKey) return res.status(400).json({ message: 'userId and publicKey required' });
    if (!ObjectId.isValid(userId)) return res.status(400).json({ message: 'Invalid userId' });
    const existing = await db.collection('users').findOne({ _id: new ObjectId(userId) }, { projection: { publicKey: 1 } });
    if (existing && existing.publicKey && existing.publicKey !== publicKey) {
      return res.status(400).json({ message: 'Public key already set; rotation not supported.' });
    }
    await db.collection('users').updateOne({ _id: new ObjectId(userId) }, { $set: { publicKey, updatedAt: new Date() } });
    res.json({ success: true });
  } catch (e) {
    console.error('publish-key error', e);
    res.status(500).json({ message: 'Failed to publish key' });
  } finally { await client.close(); }
});

// Get a user's public key
router.get('/:userId/public-key', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const { userId } = req.params;
    if (!ObjectId.isValid(userId)) return res.status(400).json({ message: 'Invalid userId' });
    const user = await db.collection('users').findOne({ _id: new ObjectId(userId) }, { projection: { publicKey: 1 } });
    if (!user || !user.publicKey) return res.status(404).json({ message: 'Public key not found' });
    res.json({ userId, publicKey: user.publicKey });
  } catch (e) {
    console.error('get public-key error', e);
    res.status(500).json({ message: 'Failed to fetch public key' });
  } finally { await client.close(); }
});

// Heartbeat endpoint to update user's lastSeen (client should POST every ~30s)
router.post('/:userId/heartbeat', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const { userId } = req.params;
    if (!ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID format' });
    }
    await db.collection('users').updateOne(
      { _id: new ObjectId(userId) },
      { $set: { lastSeen: new Date(), updatedAt: new Date() } }
    );
    res.json({ success: true });
  } catch (e) {
    console.error('Heartbeat error:', e);
    res.status(500).json({ message: 'Heartbeat failed' });
  } finally {
    await client.close();
  }
});

// Batch online status lookup: /api/users/online-status?ids=comma,separated,ids
router.get('/online-status', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    const idsRaw = req.query.ids;
    if (!idsRaw) return res.status(400).json({ message: 'ids query param required' });
    const ids = idsRaw.split(',').filter(Boolean).slice(0, 100); // limit
    await client.connect();
    const db = client.db(dbName);
    const objectIds = ids.filter(id => ObjectId.isValid(id)).map(id => new ObjectId(id));
    const users = await db.collection('users')
      .find({ _id: { $in: objectIds } })
      .project({ lastSeen: 1 })
      .toArray();
    const map = {};
    users.forEach(u => { map[u._id.toString()] = { online: isOnline(u.lastSeen), lastSeen: u.lastSeen }; });
    // Fill missing ids
    ids.forEach(id => { if (!map[id]) map[id] = { online: false, lastSeen: null }; });
    res.json({ statuses: map, serverTime: new Date().toISOString(), windowSeconds: 60 });
  } catch (e) {
    console.error('Online status error:', e);
    res.status(500).json({ message: 'Failed to fetch online status' });
  } finally {
    await client.close();
  }
});

// Key rotation (requires providing oldPublicKey to verify continuity)
router.post('/rotate-key', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const { userId, oldPublicKey, newPublicKey } = req.body || {};
    if (!userId || !oldPublicKey || !newPublicKey) return res.status(400).json({ message: 'userId, oldPublicKey, newPublicKey required' });
    if (!ObjectId.isValid(userId)) return res.status(400).json({ message: 'Invalid userId' });
    const user = await db.collection('users').findOne({ _id: new ObjectId(userId) }, { projection: { publicKey: 1 } });
    if (!user || !user.publicKey) return res.status(400).json({ message: 'No existing key to rotate' });
    if (user.publicKey !== oldPublicKey) return res.status(403).json({ message: 'Old key mismatch' });
    await db.collection('users').updateOne({ _id: new ObjectId(userId) }, { $set: { publicKey: newPublicKey, updatedAt: new Date(), keyRotatedAt: new Date() } });
    // NOTE: Clients must re-establish conversation keys after rotation; we do not auto-invalidate stored conversation keys here.
    res.json({ success: true });
  } catch (e) {
    console.error('rotate-key error', e);
    res.status(500).json({ message: 'Failed to rotate key' });
  } finally { await client.close(); }
});

// Block a user: adds targetUserId to caller's blockedUsers array
router.post('/:userId/block', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const { userId } = req.params;
    const { targetUserId } = req.body || {};
    if (!ObjectId.isValid(userId) || !ObjectId.isValid(targetUserId)) {
      return res.status(400).json({ message: 'Invalid user IDs' });
    }
    await db.collection('users').updateOne(
      { _id: new ObjectId(userId) },
      { $addToSet: { blockedUsers: targetUserId.toString() }, $set: { updatedAt: new Date() } }
    );
    res.json({ message: 'User blocked' });
  } catch (e) {
    console.error('Block user error:', e);
    res.status(500).json({ message: 'Failed to block user' });
  } finally {
    await client.close();
  }
});

// Unblock a user
router.post('/:userId/unblock', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const { userId } = req.params;
    const { targetUserId } = req.body || {};
    if (!ObjectId.isValid(userId) || !ObjectId.isValid(targetUserId)) {
      return res.status(400).json({ message: 'Invalid user IDs' });
    }
    await db.collection('users').updateOne(
      { _id: new ObjectId(userId) },
      { $pull: { blockedUsers: targetUserId.toString() }, $set: { updatedAt: new Date() } }
    );
    res.json({ message: 'User unblocked' });
  } catch (e) {
    console.error('Unblock user error:', e);
    res.status(500).json({ message: 'Failed to unblock user' });
  } finally {
    await client.close();
  }
});

// Upload inline profile image for the current user resolved from Authorization header
router.post('/me/profile-image', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    let auth = req.headers['authorization'] || req.headers['Authorization'];
    if (!auth || typeof auth !== 'string') return res.status(401).json({ message: 'Authorization required' });
    auth = auth.trim();
    // Support both "Bearer <token>" and raw token
    const token = auth.toLowerCase().startsWith('bearer ') ? auth.slice(7).trim() : auth;
    const user = await db.collection('users').findOne({ sessionToken: token }, { projection: { _id: 1 } });
    if (!user) return res.status(401).json({ message: 'Invalid token' });

    let contentType = null;
    let buffer = null;
    if (req.is('application/json')) {
      const dataUrl = req.body?.dataUrl || req.body?.dataURL || null;
      const base64 = req.body?.base64 || null;
      if (dataUrl && typeof dataUrl === 'string' && dataUrl.startsWith('data:')) {
        const match = /^data:([^;]+);base64,(.*)$/i.exec(dataUrl);
        if (!match) return res.status(400).json({ message: 'Invalid dataUrl' });
        contentType = match[1];
        buffer = Buffer.from(match[2], 'base64');
      } else if (base64 && typeof base64 === 'string') {
        contentType = 'image/png';
        buffer = Buffer.from(base64, 'base64');
      }
    }
    if (!buffer && typeof req.body === 'string') {
      contentType = 'image/png';
      buffer = Buffer.from(req.body, 'base64');
    }
    if (!buffer) return res.status(400).json({ message: 'No image data provided' });

    const update = {
      $set: {
        profileImageInline: { contentType: contentType || 'image/png', data: buffer, uploadedAt: new Date() },
        updatedAt: new Date(),
      }
    };
    await db.collection('users').updateOne({ _id: new ObjectId(user._id) }, update);
    return res.json({ ok: true, profileImageUrl: buildInlineUserImageUrl(user._id, req) });
  } catch (e) {
    console.error('POST /users/me/profile-image error', e);
    return res.status(500).json({ message: 'Failed to upload profile image' });
  } finally {
    await client.close();
  }
});