const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');

// Get activities for a user
router.get('/user/:userId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const userId = req.params.userId;
    const limit = parseInt(req.query.limit) || 10;
    const skip = parseInt(req.query.skip) || 0;
    const type = req.query.type; // Optional filter by activity type
    
    let query = { userId };
    if (type) {
      query.type = type;
    }
    
    const activities = await db.collection('activities')
      .find(query)
      .sort({ timestamp: -1 })
      .limit(limit)
      .skip(skip)
      .toArray();
    
    res.json(activities);
  } catch (error) {
    console.error('Error fetching activities:', error);
    res.status(500).json({ message: 'Error fetching activities' });
  } finally {
    await client.close();
  }
});

// Get all activities for landlord (includes tenant activities for their properties)
router.get('/landlord/:landlordId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const landlordId = req.params.landlordId;
    const limit = parseInt(req.query.limit) || 20;
    const skip = parseInt(req.query.skip) || 0;
    
    // Get all properties owned by landlord
    const properties = await db.collection('properties')
      .find({ landlordId })
      .toArray();
    
    const propertyIds = properties.map(p => p._id.toString());
    
    // Get activities related to landlord or their properties
    const activities = await db.collection('activities')
      .find({
        $or: [
          { userId: landlordId },
          { relatedPropertyId: { $in: propertyIds } },
          { metadata: { landlordId } }
        ]
      })
      .sort({ timestamp: -1 })
      .limit(limit)
      .skip(skip)
      .toArray();
    
    res.json(activities);
  } catch (error) {
    console.error('Error fetching landlord activities:', error);
    res.status(500).json({ message: 'Error fetching activities' });
  } finally {
    await client.close();
  }
});

// Create new activity
router.post('/', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const {
      userId,
      title,
      description,
      type,
      relatedId,
      relatedPropertyId,
      metadata,
      timestamp
    } = req.body;
    
    // Validate required fields
    if (!userId || !title || !type) {
      return res.status(400).json({ 
        message: 'Missing required fields: userId, title, type' 
      });
    }
    
    const activity = {
      userId,
      title,
      description: description || '',
      type, // 'payment', 'maintenance', 'message', 'property', 'tenant', 'login', 'system'
      relatedId: relatedId || null, // ID of related entity (payment, maintenance request, etc.)
      relatedPropertyId: relatedPropertyId || null,
      metadata: metadata || {}, // Additional data specific to activity type
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      isRead: false,
      createdAt: new Date()
    };
    
    const result = await db.collection('activities').insertOne(activity);
    
    const createdActivity = await db.collection('activities')
      .findOne({ _id: result.insertedId });
    
    res.status(201).json(createdActivity);
  } catch (error) {
    console.error('Error creating activity:', error);
    res.status(500).json({ message: 'Error creating activity' });
  } finally {
    await client.close();
  }
});

// Mark activity as read
router.patch('/:activityId/read', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const activityId = req.params.activityId;
    
    const result = await db.collection('activities').updateOne(
      { _id: new ObjectId(activityId) },
      { 
        $set: { 
          isRead: true,
          readAt: new Date()
        } 
      }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Activity not found' });
    }
    
    res.json({ message: 'Activity marked as read' });
  } catch (error) {
    console.error('Error marking activity as read:', error);
    res.status(500).json({ message: 'Error updating activity' });
  } finally {
    await client.close();
  }
});

// Mark all activities as read for a user
router.patch('/user/:userId/mark-all-read', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const userId = req.params.userId;
    
    const result = await db.collection('activities').updateMany(
      { userId, isRead: false },
      { 
        $set: { 
          isRead: true,
          readAt: new Date()
        } 
      }
    );
    
    res.json({ 
      message: 'All activities marked as read',
      modifiedCount: result.modifiedCount 
    });
  } catch (error) {
    console.error('Error marking all activities as read:', error);
    res.status(500).json({ message: 'Error updating activities' });
  } finally {
    await client.close();
  }
});

// Get activity statistics for a user
router.get('/user/:userId/stats', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const userId = req.params.userId;
    const days = parseInt(req.query.days) || 30;
    
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    
    // Aggregate activity statistics
    const stats = await db.collection('activities').aggregate([
      {
        $match: {
          userId,
          timestamp: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
          unreadCount: {
            $sum: { $cond: [{ $eq: ['$isRead', false] }, 1, 0] }
          }
        }
      }
    ]).toArray();
    
    const totalActivities = await db.collection('activities')
      .countDocuments({ userId, timestamp: { $gte: startDate } });
    
    const unreadActivities = await db.collection('activities')
      .countDocuments({ userId, isRead: false });
    
    res.json({
      totalActivities,
      unreadActivities,
      byType: stats,
      periodDays: days
    });
  } catch (error) {
    console.error('Error fetching activity stats:', error);
    res.status(500).json({ message: 'Error fetching activity statistics' });
  } finally {
    await client.close();
  }
});

// Delete activity
router.delete('/:activityId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const activityId = req.params.activityId;
    
    const result = await db.collection('activities').deleteOne(
      { _id: new ObjectId(activityId) }
    );
    
    if (result.deletedCount === 0) {
      return res.status(404).json({ message: 'Activity not found' });
    }
    
    res.json({ message: 'Activity deleted successfully' });
  } catch (error) {
    console.error('Error deleting activity:', error);
    res.status(500).json({ message: 'Error deleting activity' });
  } finally {
    await client.close();
  }
});

// Delete old activities (cleanup)
router.delete('/cleanup/:userId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const userId = req.params.userId;
    const days = parseInt(req.query.days) || 90; // Default: delete activities older than 90 days
    
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);
    
    const result = await db.collection('activities').deleteMany({
      userId,
      timestamp: { $lt: cutoffDate }
    });
    
    res.json({ 
      message: `Deleted ${result.deletedCount} old activities`,
      deletedCount: result.deletedCount,
      cutoffDate
    });
  } catch (error) {
    console.error('Error cleaning up activities:', error);
    res.status(500).json({ message: 'Error cleaning up activities' });
  } finally {
    await client.close();
  }
});

// Helper function to create activity (can be imported and used by other routes)
const createActivity = async (activityData) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const activity = {
      ...activityData,
      timestamp: activityData.timestamp || new Date(),
      isRead: false,
      createdAt: new Date()
    };
    
    const result = await db.collection('activities').insertOne(activity);
    return result.insertedId;
  } catch (error) {
    console.error('Error creating activity:', error);
    throw error;
  } finally {
    await client.close();
  }
};

module.exports = router;
module.exports.createActivity = createActivity;
