const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');

// GET /api/services - Fetch community services
router.get('/', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { category, availability, landlordId } = req.query;
    
    // Build query based on filters
    let query = {};
    
    if (category) {
      query.category = category;
    }
    
    if (availability) {
      query.availability = availability;
    }
    
    if (landlordId) {
      if (!ObjectId.isValid(landlordId)) {
        return res.status(400).json({ message: 'Invalid landlord ID format' });
      }
      query.landlordId = new ObjectId(landlordId);
    }

    console.log(`Looking for services with filters:`, {
      category: category || undefined,
      availability: availability || undefined,
      landlordId: landlordId || undefined
    });
    console.log('MongoDB query object:', query);

    const services = await db.collection('services')
      .find(query)
      .sort({ createdAt: -1 })
      .toArray();

    console.log(`Query returned ${services.length} services`);
    
    // Format response to match expected structure
    const response = {
      value: services.map(service => ({
        _id: service._id.toString(),
        name: service.name || '',
        description: service.description || '',
        category: service.category || '',
        availability: service.availability || 'available',
        landlordId: service.landlordId ? service.landlordId.toString() : '',
        price: service.price || 0,
        contactInfo: service.contactInfo || ''
      })),
      Count: services.length
    };
    
    console.log(`Found ${services.length} services with filters:`, { category, availability, landlordId });
    res.json(response);
  } catch (error) {
    console.error('Error fetching services:', error);
    res.status(500).json({ message: 'Error fetching services', error: error.message });
  } finally {
    await client.close();
  }
});

// POST /api/services - Create a new service
router.post('/', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const {
      name,
      description,
      category,
      availability,
      landlordId,
      price,
      contactInfo
    } = req.body;
    
    // Validate required fields
    if (!name || !description || !landlordId) {
      return res.status(400).json({ 
        message: 'Missing required fields: name, description, landlordId' 
      });
    }
    
    // Validate landlordId format
    if (!ObjectId.isValid(landlordId)) {
      return res.status(400).json({ message: 'Invalid landlord ID format' });
    }
    
    const newService = {
      name,
      description,
      category: category || 'general',
      availability: availability || 'available',
      landlordId: new ObjectId(landlordId),
      price: price || 0,
      contactInfo: contactInfo || '',
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    const result = await db.collection('services').insertOne(newService);
    
    const savedService = await db.collection('services')
      .findOne({ _id: result.insertedId });
    
    res.status(201).json({
      success: true,
      serviceId: savedService._id.toString(),
      service: {
        _id: savedService._id.toString(),
        name: savedService.name,
        description: savedService.description,
        category: savedService.category,
        availability: savedService.availability,
        landlordId: savedService.landlordId.toString(),
        price: savedService.price,
        contactInfo: savedService.contactInfo
      }
    });
  } catch (error) {
    console.error('Error creating service:', error);
    res.status(500).json({ 
      success: false,
      message: 'Error creating service', 
      error: error.message 
    });
  } finally {
    await client.close();
  }
});

// PUT /api/services/:id - Update service
router.put('/:id', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { id } = req.params;
    
    // Validate service ID format
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid service ID format' });
    }
    
    const {
      name,
      description,
      category,
      availability,
      price,
      contactInfo
    } = req.body;
    
    const updateData = {
      updatedAt: new Date()
    };
    
    if (name !== undefined) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (category !== undefined) updateData.category = category;
    if (availability !== undefined) updateData.availability = availability;
    if (price !== undefined) updateData.price = price;
    if (contactInfo !== undefined) updateData.contactInfo = contactInfo;
    
    const result = await db.collection('services').updateOne(
      { _id: new ObjectId(id) },
      { $set: updateData }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Service not found' });
    }
    
    const updatedService = await db.collection('services')
      .findOne({ _id: new ObjectId(id) });
    
    res.json({
      success: true,
      service: {
        _id: updatedService._id.toString(),
        name: updatedService.name,
        description: updatedService.description,
        category: updatedService.category,
        availability: updatedService.availability,
        landlordId: updatedService.landlordId.toString(),
        price: updatedService.price,
        contactInfo: updatedService.contactInfo
      }
    });
  } catch (error) {
    console.error('Error updating service:', error);
    res.status(500).json({ 
      success: false,
      message: 'Error updating service', 
      error: error.message 
    });
  } finally {
    await client.close();
  }
});

// DELETE /api/services/:id - Delete service
router.delete('/:id', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { id } = req.params;
    
    // Validate service ID format
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid service ID format' });
    }
    
    const result = await db.collection('services').deleteOne(
      { _id: new ObjectId(id) }
    );
    
    if (result.deletedCount === 0) {
      return res.status(404).json({ message: 'Service not found' });
    }
    
    res.json({
      success: true,
      message: 'Service deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting service:', error);
    res.status(500).json({ 
      success: false,
      message: 'Error deleting service', 
      error: error.message 
    });
  } finally {
    await client.close();
  }
});

module.exports = router;
