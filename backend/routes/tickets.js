const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');

// GET /api/tickets - Fetch maintenance requests/tickets with filtering
router.get('/', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { 
      status, 
      priority, 
      landlordId, 
      propertyId, 
      tenantId, 
      assignedTo 
    } = req.query;
    
    // Build query based on filters
    let query = {};
    
    if (status) {
      query.status = status;
    }
    
    if (priority) {
      query.priority = priority;
    }
    
    if (landlordId) {
      if (!ObjectId.isValid(landlordId)) {
        return res.status(400).json({ message: 'Invalid landlord ID format' });
      }
      query.landlordId = new ObjectId(landlordId);
    }
    
    if (propertyId) {
      if (!ObjectId.isValid(propertyId)) {
        return res.status(400).json({ message: 'Invalid property ID format' });
      }
      query.propertyId = new ObjectId(propertyId);
    }
    
    if (tenantId) {
      if (!ObjectId.isValid(tenantId)) {
        return res.status(400).json({ message: 'Invalid tenant ID format' });
      }
      query.tenantId = new ObjectId(tenantId);
    }
    
    if (assignedTo) {
      if (!ObjectId.isValid(assignedTo)) {
        return res.status(400).json({ message: 'Invalid assignedTo ID format' });
      }
      query.assignedTo = new ObjectId(assignedTo);
    }
    
    const tickets = await db.collection('maintenanceRequests')
      .find(query)
      .sort({ createdAt: -1 })
      .toArray();
    
    // Format response to match expected structure
    const formattedTickets = tickets.map(ticket => ({
      _id: ticket._id.toString(),
      title: ticket.title || '',
      description: ticket.description || '',
      status: ticket.status || 'pending',
      priority: ticket.priority || 'medium',
      propertyId: ticket.propertyId ? ticket.propertyId.toString() : '',
      tenantId: ticket.tenantId ? ticket.tenantId.toString() : '',
      landlordId: ticket.landlordId ? ticket.landlordId.toString() : '',
      assignedTo: ticket.assignedTo ? ticket.assignedTo.toString() : '',
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt
    }));
    
    const response = {
      tickets: formattedTickets,
      Count: formattedTickets.length
    };
    
    console.log(`Found ${formattedTickets.length} tickets with filters:`, { 
      status, priority, landlordId, propertyId, tenantId, assignedTo 
    });
    res.json(response);
  } catch (error) {
    console.error('Error fetching tickets:', error);
    res.status(500).json({ message: 'Error fetching tickets', error: error.message });
  } finally {
    await client.close();
  }
});

// PUT /api/tickets/:id - Update ticket status/details
router.put('/:id', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { id } = req.params;
    const { status, assignedTo, notes } = req.body;
    
    // Validate ticket ID format
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid ticket ID format' });
    }
    
    // Build update object
    const updateData = {
      updatedAt: new Date()
    };
    
    if (status !== undefined) {
      updateData.status = status;
    }
    
    if (assignedTo !== undefined) {
      if (assignedTo && !ObjectId.isValid(assignedTo)) {
        return res.status(400).json({ message: 'Invalid assignedTo ID format' });
      }
      updateData.assignedTo = assignedTo ? new ObjectId(assignedTo) : null;
    }
    
    if (notes !== undefined) {
      updateData.notes = notes;
    }
    
    // Update the ticket
    const result = await db.collection('maintenanceRequests').updateOne(
      { _id: new ObjectId(id) },
      { $set: updateData }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Ticket not found' });
    }
    
    // Get the updated ticket
    const updatedTicket = await db.collection('maintenanceRequests')
      .findOne({ _id: new ObjectId(id) });
    
    const response = {
      success: true,
      ticket: {
        _id: updatedTicket._id.toString(),
        title: updatedTicket.title || '',
        description: updatedTicket.description || '',
        status: updatedTicket.status || 'pending',
        priority: updatedTicket.priority || 'medium',
        propertyId: updatedTicket.propertyId ? updatedTicket.propertyId.toString() : '',
        tenantId: updatedTicket.tenantId ? updatedTicket.tenantId.toString() : '',
        landlordId: updatedTicket.landlordId ? updatedTicket.landlordId.toString() : '',
        assignedTo: updatedTicket.assignedTo ? updatedTicket.assignedTo.toString() : '',
        notes: updatedTicket.notes || '',
        createdAt: updatedTicket.createdAt,
        updatedAt: updatedTicket.updatedAt
      }
    };
    
    console.log(`Updated ticket ${id} with new status: ${status}`);
    res.json(response);
  } catch (error) {
    console.error('Error updating ticket:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error updating ticket', 
      error: error.message 
    });
  } finally {
    await client.close();
  }
});

module.exports = router;
