const express = require('express');
const router = express.Router();
const { getDB } = require('../database');
const { ObjectId } = require('mongodb');

// Get all maintenance requests for a landlord
router.get('/landlord/:landlordId', async (req, res) => {
  try {
    const { landlordId } = req.params;
    const { status, priority, limit = 10 } = req.query;
    
    // Validate ObjectId format
    if (!ObjectId.isValid(landlordId)) {
      return res.status(400).json({ message: 'Invalid landlord ID format' });
    }
    
    let query = { landlordId: new ObjectId(landlordId) };
    
    if (status) {
      query.status = status;
    }
    
    if (priority) {
      query.priority = priority;
    }
    
    const db = getDB();
    const requests = await db.collection('maintenanceRequests')
      .find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .toArray();
    
    res.json(requests);
  } catch (error) {
    console.error('Error fetching landlord maintenance requests:', error);
    res.status(500).json({ message: 'Error fetching maintenance requests', error: error.message });
  }
});

// Get all maintenance requests for a tenant
router.get('/tenant/:tenantId', async (req, res) => {
  try {
    const { tenantId } = req.params;
    const { status, limit = 10 } = req.query;
    
    let query = { tenantId: new ObjectId(tenantId) };
    
    if (status) {
      query.status = status;
    }
    
    const db = getDB();
    const requests = await db.collection('maintenanceRequests')
      .find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .toArray();
    
    res.json(requests);
  } catch (error) {
    console.error('Error fetching tenant maintenance requests:', error);
    res.status(500).json({ message: 'Error fetching maintenance requests', error: error.message });
  }
});

// Get recent maintenance requests for dashboard (last 5)
router.get('/recent/:landlordId', async (req, res) => {
  try {
    const { landlordId } = req.params;
    
    const db = getDB();
    const requests = await db.collection('maintenanceRequests')
      .find({ landlordId: new ObjectId(landlordId) })
      .sort({ createdAt: -1 })
      .limit(5)
      .toArray();
    
    res.json(requests);
  } catch (error) {
    console.error('Error fetching recent maintenance requests:', error);
    res.status(500).json({ message: 'Error fetching recent maintenance requests', error: error.message });
  }
});

// Create a new maintenance request
router.post('/', async (req, res) => {
  try {
    const {
      propertyId,
      tenantId,
      landlordId,
      title,
      description,
      category,
      priority,
      location,
      images,
      urgencyLevel
    } = req.body;
    
    // Validate ObjectId formats
    if (!ObjectId.isValid(propertyId)) {
      return res.status(400).json({ message: 'Invalid property ID format' });
    }
    if (!ObjectId.isValid(tenantId)) {
      return res.status(400).json({ message: 'Invalid tenant ID format' });
    }
    if (!ObjectId.isValid(landlordId)) {
      return res.status(400).json({ message: 'Invalid landlord ID format' });
    }
    
    const newRequest = {
      propertyId: new ObjectId(propertyId),
      tenantId: new ObjectId(tenantId),
      landlordId: new ObjectId(landlordId),
      title,
      description,
      category,
      priority: priority || 'medium',
      status: 'pending',
      location,
      images: images || [],
      urgencyLevel: urgencyLevel || 3,
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
      message: 'Maintenance request created successfully',
      ticket: savedRequest
    });
  } catch (error) {
    console.error('Error creating maintenance request:', error);
    res.status(500).json({ message: 'Error creating maintenance request', error: error.message });
  }
});

// Update maintenance request status
router.patch('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes, authorId } = req.body;
    
    // Validate ObjectId format
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid maintenance request ID format' });
    }
    
    // Validate authorId if provided
    if (authorId && !ObjectId.isValid(authorId)) {
      return res.status(400).json({ message: 'Invalid author ID format' });
    }
    
    const updateData = { status, updatedAt: new Date() };
    
    if (status === 'completed') {
      updateData.completedDate = new Date();
    }
    
    const db = getDB();
    let result;
    
    if (notes && authorId) {
      // If there are notes, we need to do both $set and $push operations
      result = await db.collection('maintenanceRequests')
        .findOneAndUpdate(
          { _id: new ObjectId(id) },
          {
            $set: updateData,
            $push: {
              notes: {
                author: new ObjectId(authorId),
                content: notes,
                timestamp: new Date()
              }
            }
          },
          { returnDocument: 'after' }
        );
    } else {
      // If no notes, just update the status
      result = await db.collection('maintenanceRequests')
        .findOneAndUpdate(
          { _id: new ObjectId(id) },
          { $set: updateData },
          { returnDocument: 'after' }
        );
    }
    
    if (!result) {
      return res.status(404).json({ message: 'Maintenance request not found' });
    }
    
    res.json(result);
  } catch (error) {
    console.error('Error updating maintenance request:', error);
    res.status(500).json({ message: 'Error updating maintenance request', error: error.message });
  }
});

// Get a specific maintenance request
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Validate ObjectId format
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid maintenance request ID format' });
    }
    
    const db = getDB();
    const request = await db.collection('maintenanceRequests')
      .findOne({ _id: new ObjectId(id) });
    
    if (!request) {
      return res.status(404).json({ message: 'Maintenance request not found' });
    }
    
    res.json(request);
  } catch (error) {
    console.error('Error fetching maintenance request:', error);
    res.status(500).json({ message: 'Error fetching maintenance request', error: error.message });
  }
});

// Get all maintenance requests for a property
router.get('/property/:propertyId', async (req, res) => {
  try {
    const { propertyId } = req.params;
    const { status, limit = 10 } = req.query;
    
    let query = { propertyId: new ObjectId(propertyId) };
    
    if (status) {
      query.status = status;
    }
    
    const db = getDB();
    const requests = await db.collection('maintenanceRequests')
      .find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .toArray();
    
    res.json(requests);
  } catch (error) {
    console.error('Error fetching property maintenance requests:', error);
    res.status(500).json({ message: 'Error fetching maintenance requests', error: error.message });
  }
});

// Update maintenance request (full update)
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = { ...req.body, updatedAt: new Date() };
    delete updateData.id; // Remove id from update data
    
    const db = getDB();
    const result = await db.collection('maintenanceRequests')
      .findOneAndUpdate(
        { _id: new ObjectId(id) },
        { $set: updateData },
        { returnDocument: 'after' }
      );
    
    if (!result.value) {
      return res.status(404).json({ message: 'Maintenance request not found' });
    }
    
    res.json(result.value);
  } catch (error) {
    console.error('Error updating maintenance request:', error);
    res.status(500).json({ message: 'Error updating maintenance request', error: error.message });
  }
});

// Add a note to maintenance request
router.post('/:id/notes', async (req, res) => {
  try {
    const { id } = req.params;
    const { content, authorId } = req.body;
    const db = getDB();
    
    // Validate ObjectId format
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid maintenance request ID format' });
    }
    
    const result = await db.collection('maintenanceRequests').updateOne(
      { _id: new ObjectId(id) },
      {
        $push: {
          notes: {
            author: authorId,
            content,
            timestamp: new Date()
          }
        }
      }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Maintenance request not found' });
    }
    
    // Fetch and return the updated request
    const updatedRequest = await db.collection('maintenanceRequests')
      .findOne({ _id: new ObjectId(id) });
    
    res.json(updatedRequest);
  } catch (error) {
    console.error('Error adding note to maintenance request:', error);
    res.status(500).json({ message: 'Error adding note', error: error.message });
  }
});

// Delete a maintenance request
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const deletedRequest = await MaintenanceRequest.findByIdAndDelete(id);
    
    if (!deletedRequest) {
      return res.status(404).json({ message: 'Maintenance request not found' });
    }
    
    res.json({ message: 'Maintenance request deleted successfully' });
  } catch (error) {
    console.error('Error deleting maintenance request:', error);
    res.status(500).json({ message: 'Error deleting maintenance request', error: error.message });
  }
});

// Get maintenance statistics for landlord dashboard
router.get('/stats/:landlordId', async (req, res) => {
  try {
    const { landlordId } = req.params;
    
    const stats = await MaintenanceRequest.aggregate([
      { $match: { landlordId: require('mongoose').Types.ObjectId(landlordId) } },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          pending: { $sum: { $cond: [{ $eq: ['$status', 'pending'] }, 1, 0] } },
          inProgress: { $sum: { $cond: [{ $eq: ['$status', 'in_progress'] }, 1, 0] } },
          completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
          highPriority: { $sum: { $cond: [{ $eq: ['$priority', 'high'] }, 1, 0] } },
          urgentPriority: { $sum: { $cond: [{ $eq: ['$priority', 'urgent'] }, 1, 0] } }
        }
      }
    ]);
    
    res.json(stats[0] || {
      total: 0,
      pending: 0,
      inProgress: 0,
      completed: 0,
      highPriority: 0,
      urgentPriority: 0
    });
  } catch (error) {
    console.error('Error fetching maintenance statistics:', error);
    res.status(500).json({ message: 'Error fetching statistics', error: error.message });
  }
});

module.exports = router;
