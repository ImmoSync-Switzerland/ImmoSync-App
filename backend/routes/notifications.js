const express = require('express');
const router = express.Router();

// Mock push notification service - in production, integrate with Firebase Admin SDK
class PushNotificationService {
  static async sendNotification(token, title, body, data = {}) {
    // Mock implementation - replace with actual Firebase Admin SDK
    console.log(`
=== PUSH NOTIFICATION SENT ===
Token: ${token}
Title: ${title}
Body: ${body}
Data: ${JSON.stringify(data)}
==============================
    `);
    return { success: true, messageId: `push_${Date.now()}` };
  }

  static async sendToMultipleTokens(tokens, title, body, data = {}) {
    // Mock implementation for sending to multiple devices
    console.log(`
=== BULK PUSH NOTIFICATION ===
Tokens: ${tokens.length} devices
Title: ${title}
Body: ${body}
Data: ${JSON.stringify(data)}
==============================
    `);
    return { 
      success: true, 
      results: tokens.map(token => ({ token, success: true, messageId: `push_${Date.now()}` }))
    };
  }

  static async sendToTopic(topic, title, body, data = {}) {
    // Mock implementation for topic-based notifications
    console.log(`
=== TOPIC NOTIFICATION ===
Topic: ${topic}
Title: ${title}
Body: ${body}
Data: ${JSON.stringify(data)}
=========================
    `);
    return { success: true, messageId: `topic_${Date.now()}` };
  }
}

// In-memory storage for demo - use database in production
const userTokens = new Map(); // userId -> [tokens]
const notificationSettings = new Map(); // userId -> settings

// Register FCM token for a user
router.post('/register-token', async (req, res) => {
  try {
    const { userId, token } = req.body;

    if (!userId || !token) {
      return res.status(400).json({
        error: 'User ID and FCM token are required'
      });
    }

    // Store token for user
    if (!userTokens.has(userId)) {
      userTokens.set(userId, []);
    }
    
    const tokens = userTokens.get(userId);
    if (!tokens.includes(token)) {
      tokens.push(token);
    }

    res.json({
      success: true,
      message: 'FCM token registered successfully'
    });

  } catch (error) {
    console.error('Error registering FCM token:', error);
    res.status(500).json({
      error: 'Failed to register FCM token',
      details: error.message
    });
  }
});

// Remove FCM token for a user
router.post('/unregister-token', async (req, res) => {
  try {
    const { userId, token } = req.body;

    if (!userId || !token) {
      return res.status(400).json({
        error: 'User ID and FCM token are required'
      });
    }

    if (userTokens.has(userId)) {
      const tokens = userTokens.get(userId);
      const index = tokens.indexOf(token);
      if (index > -1) {
        tokens.splice(index, 1);
      }
    }

    res.json({
      success: true,
      message: 'FCM token unregistered successfully'
    });

  } catch (error) {
    console.error('Error unregistering FCM token:', error);
    res.status(500).json({
      error: 'Failed to unregister FCM token',
      details: error.message
    });
  }
});

// Send notification to specific user
router.post('/send-to-user', async (req, res) => {
  try {
    const { userId, title, body, type, data } = req.body;

    if (!userId || !title || !body) {
      return res.status(400).json({
        error: 'User ID, title, and body are required'
      });
    }

    const tokens = userTokens.get(userId);
    if (!tokens || tokens.length === 0) {
      return res.status(404).json({
        error: 'No FCM tokens found for user'
      });
    }

    // Check user notification settings
    const settings = notificationSettings.get(userId) || { pushNotifications: true };
    if (!settings.pushNotifications) {
      return res.status(400).json({
        error: 'Push notifications are disabled for this user'
      });
    }

    const notificationData = {
      type: type || 'general',
      timestamp: new Date().toISOString(),
      ...data
    };

    let results;
    if (tokens.length === 1) {
      results = await PushNotificationService.sendNotification(tokens[0], title, body, notificationData);
    } else {
      results = await PushNotificationService.sendToMultipleTokens(tokens, title, body, notificationData);
    }

    res.json({
      success: true,
      message: 'Notification sent successfully',
      results: results
    });

  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({
      error: 'Failed to send notification',
      details: error.message
    });
  }
});

// Send notification to multiple users
router.post('/send-to-users', async (req, res) => {
  try {
    const { userIds, title, body, type, data } = req.body;

    if (!userIds || !Array.isArray(userIds) || !title || !body) {
      return res.status(400).json({
        error: 'User IDs array, title, and body are required'
      });
    }

    const results = [];
    const notificationData = {
      type: type || 'general',
      timestamp: new Date().toISOString(),
      ...data
    };

    for (const userId of userIds) {
      const tokens = userTokens.get(userId);
      const settings = notificationSettings.get(userId) || { pushNotifications: true };
      
      if (tokens && tokens.length > 0 && settings.pushNotifications) {
        try {
          const result = await PushNotificationService.sendToMultipleTokens(tokens, title, body, notificationData);
          results.push({ userId, success: true, result });
        } catch (error) {
          results.push({ userId, success: false, error: error.message });
        }
      } else {
        results.push({ userId, success: false, error: 'No tokens or notifications disabled' });
      }
    }

    const successCount = results.filter(r => r.success).length;

    res.json({
      success: true,
      message: `Sent notifications to ${successCount} of ${userIds.length} users`,
      results: results
    });

  } catch (error) {
    console.error('Error sending bulk notifications:', error);
    res.status(500).json({
      error: 'Failed to send bulk notifications',
      details: error.message
    });
  }
});

// Send notification to topic
router.post('/send-to-topic', async (req, res) => {
  try {
    const { topic, title, body, type, data } = req.body;

    if (!topic || !title || !body) {
      return res.status(400).json({
        error: 'Topic, title, and body are required'
      });
    }

    const notificationData = {
      type: type || 'general',
      timestamp: new Date().toISOString(),
      ...data
    };

    const result = await PushNotificationService.sendToTopic(topic, title, body, notificationData);

    res.json({
      success: true,
      message: 'Topic notification sent successfully',
      result: result
    });

  } catch (error) {
    console.error('Error sending topic notification:', error);
    res.status(500).json({
      error: 'Failed to send topic notification',
      details: error.message
    });
  }
});

// Update notification settings for user
router.post('/update-settings', async (req, res) => {
  try {
    const { userId, pushNotifications, emailNotifications, paymentReminders } = req.body;

    if (!userId) {
      return res.status(400).json({
        error: 'User ID is required'
      });
    }

    const settings = notificationSettings.get(userId) || {};
    
    if (typeof pushNotifications === 'boolean') {
      settings.pushNotifications = pushNotifications;
    }
    if (typeof emailNotifications === 'boolean') {
      settings.emailNotifications = emailNotifications;
    }
    if (typeof paymentReminders === 'boolean') {
      settings.paymentReminders = paymentReminders;
    }

    notificationSettings.set(userId, settings);

    res.json({
      success: true,
      message: 'Notification settings updated successfully',
      settings: settings
    });

  } catch (error) {
    console.error('Error updating notification settings:', error);
    res.status(500).json({
      error: 'Failed to update notification settings',
      details: error.message
    });
  }
});

// Get notification settings for user
router.get('/settings/:userId', (req, res) => {
  try {
    const { userId } = req.params;
    
    const settings = notificationSettings.get(userId) || {
      pushNotifications: true,
      emailNotifications: true,
      paymentReminders: true
    };
    
    res.json({
      success: true,
      settings: settings
    });

  } catch (error) {
    console.error('Error getting notification settings:', error);
    res.status(500).json({
      error: 'Failed to get notification settings',
      details: error.message
    });
  }
});

// Send payment reminder notifications
router.post('/send-payment-reminders', async (req, res) => {
  try {
    const { reminders } = req.body; // Array of {userId, propertyAddress, amount, dueDate}

    if (!reminders || !Array.isArray(reminders)) {
      return res.status(400).json({
        error: 'Reminders array is required'
      });
    }

    const results = [];

    for (const reminder of reminders) {
      const { userId, propertyAddress, amount, dueDate } = reminder;
      const tokens = userTokens.get(userId);
      const settings = notificationSettings.get(userId) || { paymentReminders: true };
      
      if (tokens && tokens.length > 0 && settings.paymentReminders) {
        try {
          const title = 'Payment Reminder';
          const body = `Payment due for ${propertyAddress}: ${amount}`;
          const data = {
            type: 'payment_reminder',
            propertyAddress,
            amount,
            dueDate
          };

          const result = await PushNotificationService.sendToMultipleTokens(tokens, title, body, data);
          results.push({ userId, success: true, result });
        } catch (error) {
          results.push({ userId, success: false, error: error.message });
        }
      } else {
        results.push({ userId, success: false, error: 'No tokens or reminders disabled' });
      }
    }

    const successCount = results.filter(r => r.success).length;

    res.json({
      success: true,
      message: `Sent payment reminders to ${successCount} of ${reminders.length} users`,
      results: results
    });

  } catch (error) {
    console.error('Error sending payment reminders:', error);
    res.status(500).json({
      error: 'Failed to send payment reminders',
      details: error.message
    });
  }
});

// Send maintenance request notifications
router.post('/send-maintenance-notifications', async (req, res) => {
  try {
    const { notifications } = req.body; // Array of {userId, requestId, status, propertyAddress}

    if (!notifications || !Array.isArray(notifications)) {
      return res.status(400).json({
        error: 'Notifications array is required'
      });
    }

    const results = [];

    for (const notification of notifications) {
      const { userId, requestId, status, propertyAddress } = notification;
      const tokens = userTokens.get(userId);
      const settings = notificationSettings.get(userId) || { pushNotifications: true };
      
      if (tokens && tokens.length > 0 && settings.pushNotifications) {
        try {
          const title = 'Maintenance Request Update';
          const body = `Your maintenance request for ${propertyAddress} is now ${status}`;
          const data = {
            type: 'maintenance_request',
            requestId,
            status,
            propertyAddress
          };

          const result = await PushNotificationService.sendToMultipleTokens(tokens, title, body, data);
          results.push({ userId, success: true, result });
        } catch (error) {
          results.push({ userId, success: false, error: error.message });
        }
      } else {
        results.push({ userId, success: false, error: 'No tokens or notifications disabled' });
      }
    }

    const successCount = results.filter(r => r.success).length;

    res.json({
      success: true,
      message: `Sent maintenance notifications to ${successCount} of ${notifications.length} users`,
      results: results
    });

  } catch (error) {
    console.error('Error sending maintenance notifications:', error);
    res.status(500).json({
      error: 'Failed to send maintenance notifications',
      details: error.message
    });
  }
});

module.exports = router;