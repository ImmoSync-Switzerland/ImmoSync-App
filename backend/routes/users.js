const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');

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

// Update user profile
router.patch('/:userId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { userId } = req.params;
  const { fullName, email, phone, address, profileImage } = req.body;
    
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