const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');
const { buildProfileImageUrl } = require('../utils');

// Get tenants for a specific landlord
router.get('/landlord/:landlordId/tenants', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const landlordId = req.params.landlordId;
    
    // Find properties owned by this landlord
    const properties = await db.collection('properties')
      .find({ landlordId: landlordId })
      .toArray();
    
    if (properties.length === 0) {
      return res.json([]);
    }
    
    // Get all tenant IDs from these properties
    const tenantIds = properties.reduce((acc, property) => {
      if (property.tenantIds && Array.isArray(property.tenantIds)) {
        acc.push(...property.tenantIds);
      }
      return acc;
    }, []);
    
    if (tenantIds.length === 0) {
      return res.json([]);
    }
    
    // Get tenant details
    const tenants = await db.collection('users')
      .find({ 
        _id: { $in: tenantIds.map(id => new ObjectId(id)) },
        role: 'tenant'
      })
      .toArray();
    
    // Add property information to each tenant
    const tenantsWithProperties = tenants.map(tenant => {
      const tenantProperties = properties
        .filter(prop => prop.tenantIds && prop.tenantIds.includes(tenant._id.toString()))
        .map(prop => `${prop.address.street}, ${prop.address.city}`);
      
      return {
        ...tenant,
        properties: tenantProperties,
        phone: tenant.phone || '',
        profileImageUrl: buildProfileImageUrl(tenant.profileImage || tenant.providerPicture, req),
      };
    });
    
    console.log(`Found ${tenantsWithProperties.length} tenants for landlord ${landlordId}`);
    res.json(tenantsWithProperties);
    
  } catch (error) {
    console.error('Error fetching tenants:', error);
    res.status(500).json({ message: 'Error fetching tenants' });
  } finally {
    await client.close();
  }
});

// Get landlords for a specific tenant
router.get('/tenant/:tenantId/landlords', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const tenantId = req.params.tenantId;
    
    // Find properties where this tenant is listed
    const properties = await db.collection('properties')
      .find({ 
        tenantIds: tenantId 
      })
      .toArray();
    
    if (properties.length === 0) {
      return res.json([]);
    }
    
    // Get unique landlord IDs
    const landlordIds = [...new Set(properties.map(prop => prop.landlordId))];
    
    // Get landlord details
    const landlords = await db.collection('users')
      .find({ 
        _id: { $in: landlordIds.map(id => new ObjectId(id)) },
        role: 'landlord'
      })
      .toArray();
    
    // Add property information to each landlord
    const landlordsWithProperties = landlords.map(landlord => {
      const landlordProperties = properties
        .filter(prop => prop.landlordId === landlord._id.toString())
        .map(prop => `${prop.address.street}, ${prop.address.city}`);
      
      return {
        ...landlord,
        properties: landlordProperties,
        phone: landlord.phone || '',
        profileImageUrl: buildProfileImageUrl(landlord.profileImage || landlord.providerPicture, req),
      };
    });
    
    console.log(`Found ${landlordsWithProperties.length} landlords for tenant ${tenantId}`);
    res.json(landlordsWithProperties);
    
  } catch (error) {
    console.error('Error fetching landlords:', error);
    res.status(500).json({ message: 'Error fetching landlords' });
  } finally {
    await client.close();
  }
});

module.exports = router;
