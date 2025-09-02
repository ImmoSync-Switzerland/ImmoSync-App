const express = require('express');
const router = express.Router();
const { getDB } = require('../database');
const { ObjectId } = require('mongodb');
const notifications = require('./notifications');

// POST /api/maintenance-requests - Create maintenance requests (alternative endpoint)
router.post('/', async (req, res) => {
  try {
    const {
      propertyId,
      tenantId,
      landlordId,
      title,
      description,
      priority
    } = req.body;
    
    // Validate required fields
    if (!propertyId || !tenantId || !landlordId || !title || !description) {
      return res.status(400).json({ 
        success: false,
        message: 'Missing required fields: propertyId, tenantId, landlordId, title, description' 
      });
    }
    
    // Validate ObjectId formats
    if (!ObjectId.isValid(propertyId)) {
      return res.status(400).json({ success: false, message: 'Invalid property ID format' });
    }
    if (!ObjectId.isValid(tenantId)) {
      return res.status(400).json({ success: false, message: 'Invalid tenant ID format' });
    }
    if (!ObjectId.isValid(landlordId)) {
      return res.status(400).json({ success: false, message: 'Invalid landlord ID format' });
    }
    
    const newRequest = {
      propertyId: new ObjectId(propertyId),
      tenantId: new ObjectId(tenantId),
      landlordId: new ObjectId(landlordId),
      title,
      description,
      priority: priority || 'medium',
      status: 'pending',
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    const db = getDB();
    const result = await db.collection('maintenanceRequests').insertOne(newRequest);
    
    const savedRequest = await db.collection('maintenanceRequests')
      .findOne({ _id: result.insertedId });
    
    res.status(201).json({
      success: true,
      ticketId: savedRequest._id.toString(),
      message: 'Maintenance request created successfully'
    });

    // Notify landlord and tenant
    notifications.sendDomainNotification(landlordId, {
      title: 'New Maintenance Request',
      body: `${title} submitted by tenant`,
      type: 'maintenance_created',
      data: { requestId: savedRequest._id.toString(), propertyId, tenantId }
    });
    notifications.sendDomainNotification(tenantId, {
      title: 'Request Submitted',
      body: `Your maintenance request '${title}' was created`,
      type: 'maintenance_created',
      data: { requestId: savedRequest._id.toString(), propertyId }
    });
  } catch (error) {
    console.error('Error creating maintenance request:', error);
    res.status(500).json({ 
      success: false,
      message: 'Error creating maintenance request', 
      error: error.message 
    });
  }
});

module.exports = router;
