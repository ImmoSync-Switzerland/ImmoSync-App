const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');  // Add ObjectId here
const { dbUri, dbName } = require('../config');
const notifications = require('./notifications');

router.get('/landlord/:landlordId', async (req, res) => {
  const client = new MongoClient(dbUri);

  try {
    await client.connect();
    const db = client.db(dbName);

    const landlordIdParam = req.params.landlordId;
    console.log('[Properties][Landlord] Incoming landlordId param:', landlordIdParam);

    // Support legacy documents where landlordId was stored as an ObjectId as well as
    // current documents where it is stored as a plain string.
    const orConditions = [{ landlordId: landlordIdParam }];
    if (ObjectId.isValid(landlordIdParam)) {
      orConditions.push({ landlordId: new ObjectId(landlordIdParam) });
    }

    // If only one condition (invalid ObjectId), query directly without $or for efficiency
    const landlordQuery = orConditions.length === 1 ? orConditions[0] : { $or: orConditions };
    console.log('[Properties][Landlord] Query filter:', JSON.stringify(landlordQuery));

    const properties = await db.collection('properties')
      .find(landlordQuery)
      .toArray();

    console.log('[Properties][Landlord] Found properties:', properties.length);
    if (properties.length === 0) {
      console.log('[Properties][Landlord] No properties matched. Example existing landlordIds (first 5 docs):');
      const sample = await db.collection('properties').find({}, { projection: { landlordId: 1 } }).limit(5).toArray();
      console.log(sample.map(d => d.landlordId));
    } else {
      console.log('[Properties][Landlord] Property IDs:', properties.map(p => p._id.toString()));
    }

    const propertyIds = properties.map(p => p._id);

    const tenants = propertyIds.length > 0 ? await db.collection('users')
      .find({
        role: 'tenant',
        propertyId: { $in: propertyIds }
      })
      .toArray() : [];

    res.json({ properties, tenants });
  } catch (error) {
    console.error('[Properties][Landlord] Database error:', error);
    res.status(500).json({ message: 'Error fetching properties' });
  } finally {
    await client.close();
  }
});

// Get properties for a specific tenant
router.get('/tenant/:tenantId', async (req, res) => {
  const client = new MongoClient(dbUri);

  try {
    await client.connect();
    const db = client.db(dbName);

    console.log('Querying properties for tenantId:', req.params.tenantId);

    // Validate tenantId format
    if (!ObjectId.isValid(req.params.tenantId)) {
      return res.status(400).json({ message: 'Invalid tenant ID format' });
    }

    const tenantId = req.params.tenantId;
    const propertiesCol = db.collection('properties');

    // Primary lookup: tenantIds array contains tenantId
    const listByArray = await propertiesCol.find({ tenantIds: { $in: [tenantId] } }).toArray();

    // Secondary lookup: user document has propertyId referencing property (legacy path)
    let listByUserRef = [];
    try {
      const user = await db.collection('users').findOne({ _id: new ObjectId(tenantId) }, { projection: { propertyId: 1 } });
      if (user?.propertyId) {
        const propId = user.propertyId instanceof ObjectId ? user.propertyId : new ObjectId(user.propertyId);
        const prop = await propertiesCol.findOne({ _id: propId });
        if (prop) listByUserRef.push(prop);
      }
    } catch (e) {
      console.error('[Properties][Tenant] User propertyId lookup error:', e.message);
    }

    // Merge & deduplicate
    const mergedMap = new Map();
    [...listByArray, ...listByUserRef].forEach(p => mergedMap.set(p._id.toString(), p));
    const properties = Array.from(mergedMap.values());

  console.log('Query (array) used:', { tenantIds: { $in: [tenantId] } });
  console.log('Found properties (array match):', listByArray.length, 'via user.propertyId:', listByUserRef.length, 'merged total:', properties.length);
    console.log('Properties with tenantIds:', properties.map(p => ({ 
      id: p._id, 
      address: p.address?.street,
      tenantIds: p.tenantIds 
    })));

    res.json({ properties });
  } catch (error) {
    console.error('Database error:', error);
    res.status(500).json({ message: 'Error fetching tenant properties' });
  } finally {
    await client.close();
  }
});

router.get('/:propertyId', async (req, res) => {
  const client = new MongoClient(dbUri);

  try {
    await client.connect();
    const db = client.db(dbName);

    // Validate propertyId format before conversion
    if (!ObjectId.isValid(req.params.propertyId)) {
      return res.status(400).json({ message: 'Invalid property ID format' });
    }

    const property = await db.collection('properties')
      .findOne({ _id: new ObjectId(req.params.propertyId) });

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    res.json(property);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ message: 'Error fetching property details' });
  } finally {
    await client.close();
  }
});

router.post('/:propertyId/invite-tenant', async (req, res) => {
  const client = new MongoClient(dbUri);

  try {
    await client.connect();
    const db = client.db(dbName);

    const { tenantId } = req.body;
    const propertyId = new ObjectId(req.params.propertyId);

    // Update property with new tenant
    const result = await db.collection('properties').updateOne(
      { _id: propertyId },
      {
        $addToSet: { tenantIds: tenantId },
        $set: { status: 'rented' }
      }
    );

    // Update user with property assignment
    await db.collection('users').updateOne(
      { _id: new ObjectId(tenantId) },
      { $set: { propertyId: propertyId } }
    );

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ message: 'Failed to invite tenant' });
  } finally {
    await client.close();
  }
});

// Remove tenant from property
router.post('/:propertyId/remove-tenant', async (req, res) => {
  const client = new MongoClient(dbUri);

  try {
    await client.connect();
    const db = client.db(dbName);

    const { tenantId } = req.body;
    const propertyId = new ObjectId(req.params.propertyId);

    // Remove tenant from property
    const result = await db.collection('properties').updateOne(
      { _id: propertyId },
      {
        $pull: { tenantIds: tenantId }
      }
    );

    // Check if property has any tenants left
    const property = await db.collection('properties').findOne({ _id: propertyId });
    const hasRemainingTenants = property.tenantIds && property.tenantIds.length > 0;

    // Update property status if no tenants left
    if (!hasRemainingTenants) {
      await db.collection('properties').updateOne(
        { _id: propertyId },
        { $set: { status: 'available' } }
      );
    }

    // Remove property assignment from user
    await db.collection('users').updateOne(
      { _id: new ObjectId(tenantId) },
      { $unset: { propertyId: "" } }
    );

      // Remove all invitations for this property and tenant
      const invitationDeleteResult = await db.collection('invitations').deleteMany({
        propertyId: propertyId.toString(),
        tenantId: tenantId
      });
      console.log(`Deleted ${invitationDeleteResult.deletedCount} invitations for property ${propertyId} and tenant ${tenantId}`);

    res.json({ success: true, message: 'Tenant removed successfully' });

    // Notify tenant of removal
    notifications.sendDomainNotification(tenantId, {
      title: 'Removed from Property',
      body: 'You have been unassigned from a property',
      type: 'tenant_removed',
      data: { propertyId: propertyId.toString() }
    });
  } catch (error) {
    console.error('Error removing tenant:', error);
    res.status(500).json({ message: 'Failed to remove tenant' });
  } finally {
    await client.close();
  }
});

// New POST route for property creation
router.post('/', async (req, res) => {
  const client = new MongoClient(dbUri);

  try {
    await client.connect();
    const db = client.db(dbName);

    console.log('Received property data:', JSON.stringify(req.body, null, 2));

    // Validate required fields
    const { landlordId, address, status, rentAmount } = req.body;
    
    if (!landlordId || !address || !status || rentAmount === undefined) {
      return res.status(400).json({ 
        message: 'Missing required fields: landlordId, address, status, rentAmount' 
      });
    }

    // Validate address structure
    if (!address.street || !address.city || !address.postalCode || !address.country) {
      return res.status(400).json({ 
        message: 'Address must include street, city, postalCode, and country' 
      });
    }

    // Validate status
    const validStatuses = ['available', 'rented', 'maintenance'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        message: 'Status must be one of: available, rented, maintenance' 
      });
    }

    // Validate rentAmount
    if (typeof rentAmount !== 'number' || rentAmount < 0) {
      return res.status(400).json({ 
        message: 'Rent amount must be a positive number' 
      });
    }

    // Create properly formatted document
    const propertyDocument = {
      landlordId: landlordId.toString(),
      address: {
        street: address.street.toString(),
        city: address.city.toString(),
        postalCode: address.postalCode.toString(),
        country: address.country.toString()
      },
      status,
      rentAmount: Number(rentAmount),
      details: req.body.details ? {
        size: req.body.details.size ? Number(req.body.details.size) : 0,
        rooms: req.body.details.rooms ? Number(req.body.details.rooms) : 0,
        amenities: Array.isArray(req.body.details.amenities) ? req.body.details.amenities : []
      } : {
        size: 0,
        rooms: 0,
        amenities: []
      },
      imageUrls: Array.isArray(req.body.imageUrls) ? req.body.imageUrls : [],
      tenantIds: Array.isArray(req.body.tenantIds) ? req.body.tenantIds : [],
      outstandingPayments: req.body.outstandingPayments ? Number(req.body.outstandingPayments) : 0,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    console.log('Formatted property document:', JSON.stringify(propertyDocument, null, 2));

    const result = await db.collection('properties').insertOne(propertyDocument);
    
    res.status(201).json({ 
      message: 'Property created successfully', 
      propertyId: result.insertedId 
    });

  } catch (error) {
    console.error('Property creation error:', error);
    
    if (error.code === 121) {
      console.error('Validation error details:', error.errInfo?.details);
      return res.status(400).json({ 
        message: 'Document validation failed', 
        details: error.errInfo?.details 
      });
    }
    
    res.status(500).json({ message: 'Error creating property' });
  } finally {
    await client.close();
  }
});

// Get all properties
router.get('/', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const properties = await db.collection('properties').find({}).toArray();
    console.log(`Found ${properties.length} properties`);
    res.json(properties);
  } catch (error) {
    console.error('Error fetching properties:', error);
    res.status(500).json({ message: 'Error fetching properties' });
  } finally {
    await client.close();
  }
});

// PUT route for property updates
router.put('/:propertyId', async (req, res) => {
  const client = new MongoClient(dbUri);

  try {
    await client.connect();
    const db = client.db(dbName);

    console.log('Updating property:', req.params.propertyId);
    console.log('Update data:', JSON.stringify(req.body, null, 2));

    // Validate propertyId format
    if (!ObjectId.isValid(req.params.propertyId)) {
      return res.status(400).json({ message: 'Invalid property ID format' });
    }

    // Validate required fields
    const { landlordId, address, status, rentAmount } = req.body;
    
    if (!landlordId || !address || !status || rentAmount === undefined) {
      return res.status(400).json({ 
        message: 'Missing required fields: landlordId, address, status, rentAmount' 
      });
    }

    // Validate address structure
    if (!address.street || !address.city || !address.postalCode || !address.country) {
      return res.status(400).json({ 
        message: 'Address must include street, city, postalCode, and country' 
      });
    }

    // Validate status
    const validStatuses = ['available', 'rented', 'maintenance'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        message: 'Status must be one of: available, rented, maintenance' 
      });
    }

    // Validate rentAmount
    if (typeof rentAmount !== 'number' || rentAmount < 0) {
      return res.status(400).json({ 
        message: 'Rent amount must be a positive number' 
      });
    }

    // Create update document (exclude _id from update)
    const updateDocument = {
      landlordId: landlordId.toString(),
      address: {
        street: address.street.toString(),
        city: address.city.toString(),
        postalCode: address.postalCode.toString(),
        country: address.country.toString()
      },
      status,
      rentAmount: Number(rentAmount),
      details: req.body.details ? {
        size: req.body.details.size ? Number(req.body.details.size) : 0,
        rooms: req.body.details.rooms ? Number(req.body.details.rooms) : 0,
        amenities: Array.isArray(req.body.details.amenities) ? req.body.details.amenities : []
      } : {
        size: 0,
        rooms: 0,
        amenities: []
      },
      imageUrls: Array.isArray(req.body.imageUrls) ? req.body.imageUrls : [],
      tenantIds: Array.isArray(req.body.tenantIds) ? req.body.tenantIds : [],
      outstandingPayments: req.body.outstandingPayments ? Number(req.body.outstandingPayments) : 0,
      updatedAt: new Date()
    };

    console.log('Formatted update document:', JSON.stringify(updateDocument, null, 2));

    const result = await db.collection('properties').updateOne(
      { _id: new ObjectId(req.params.propertyId) },
      { $set: updateDocument }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Property not found' });
    }

    res.json({ 
      message: 'Property updated successfully',
      modifiedCount: result.modifiedCount
    });

  } catch (error) {
    console.error('Property update error:', error);
    
    if (error.code === 121) {
      console.error('Validation error details:', error.errInfo?.details);
      return res.status(400).json({ 
        message: 'Document validation failed', 
        details: error.errInfo?.details 
      });
    }
    
    res.status(500).json({ message: 'Error updating property' });
  } finally {
    await client.close();
  }
});

module.exports = router;