const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');

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
        _id: tenant._id.toString()
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
        _id: tenant._id.toString()
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
          rentAmount: leaseInfo ? leaseInfo.rentAmount : (propertyInfo ? propertyInfo.rentAmount : 0)
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
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Error fetching users' });
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
    
    const { userId } = req.params;
  const { fullName, email, phone, address, profileImage, publicKey } = req.body;
    
    if (!ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID format' });
    }
    
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
    
    const result = await db.collection('users').findOneAndUpdate(
      { _id: new ObjectId(userId) },
      { $set: updateData },
      { returnDocument: 'after' }
    );
    
    if (!result.value) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    console.log(`Updated user profile for user: ${userId}`);
    res.json(result.value);
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