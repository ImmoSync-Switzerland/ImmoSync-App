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

// Test all notification types - comprehensive endpoint for testing
router.post('/test-all-notifications', async (req, res) => {
  try {
    const { userId, testUserToken } = req.body;
    
    if (!userId) {
      return res.status(400).json({
        error: 'User ID is required for testing'
      });
    }

    // Register test user token if provided
    if (testUserToken) {
      if (!userTokens.has(userId)) {
        userTokens.set(userId, []);
      }
      const tokens = userTokens.get(userId);
      if (!tokens.includes(testUserToken)) {
        tokens.push(testUserToken);
      }
    }

    const testResults = [];
    
    // Define all notification event types
    const notificationTypes = [
      {
        type: 'maintenance_request_created',
        title: 'New Maintenance Request',
        body: 'A new maintenance request has been submitted for your property at 123 Main St',
        data: { propertyId: 'test-property-1', requestId: 'test-request-1', priority: 'high' }
      },
      {
        type: 'maintenance_request_updated',
        title: 'Maintenance Request Update',
        body: 'Your maintenance request status has been updated to: In Progress',
        data: { propertyId: 'test-property-1', requestId: 'test-request-1', status: 'in_progress' }
      },
      {
        type: 'new_message',
        title: 'New Message',
        body: 'You have a new message from your landlord',
        data: { conversationId: 'test-conversation-1', senderId: 'test-landlord-1' }
      },
      {
        type: 'payment_reminder',
        title: 'Payment Reminder',
        body: 'Your rent payment of $1,200 is due in 3 days',
        data: { propertyId: 'test-property-1', amount: '$1,200', dueDate: '2024-02-01' }
      },
      {
        type: 'payment_overdue',
        title: 'Payment Overdue',
        body: 'Your rent payment is now overdue. Please pay immediately.',
        data: { propertyId: 'test-property-1', amount: '$1,200', daysPastDue: 5 }
      },
      {
        type: 'property_invitation',
        title: 'Property Invitation',
        body: 'You have been invited to rent a property at 456 Oak Avenue',
        data: { propertyId: 'test-property-2', landlordId: 'test-landlord-1', invitationId: 'test-invite-1' }
      },
      {
        type: 'invitation_accepted',
        title: 'Invitation Accepted',
        body: 'Your tenant has accepted the invitation for 456 Oak Avenue',
        data: { propertyId: 'test-property-2', tenantId: 'test-tenant-1', invitationId: 'test-invite-1' }
      },
      {
        type: 'property_update',
        title: 'Property Update',
        body: 'Important updates have been made to your property listing',
        data: { propertyId: 'test-property-1', updateType: 'rent_change' }
      },
      {
        type: 'auth_2fa_enabled',
        title: 'Security Alert',
        body: 'Two-factor authentication has been enabled for your account',
        data: { securityEvent: 'enable_2fa' }
      },
      {
        type: 'auth_password_changed',
        title: 'Security Alert',
        body: 'Your password has been successfully changed',
        data: { securityEvent: 'password_change' }
      },
      {
        type: 'auth_suspicious_login',
        title: 'Security Alert',
        body: 'Suspicious login attempt detected on your account',
        data: { securityEvent: 'suspicious_login', location: 'Unknown Location' }
      },
      {
        type: 'document_uploaded',
        title: 'Document Uploaded',
        body: 'A new document has been uploaded for your property',
        data: { propertyId: 'test-property-1', documentType: 'lease_agreement' }
      },
      {
        type: 'inspection_scheduled',
        title: 'Inspection Scheduled',
        body: 'A property inspection has been scheduled for next Tuesday at 2 PM',
        data: { propertyId: 'test-property-1', scheduledDate: '2024-02-06T14:00:00Z' }
      },
      {
        type: 'lease_expiry_warning',
        title: 'Lease Expiring Soon',
        body: 'Your lease will expire in 30 days. Please contact your landlord.',
        data: { propertyId: 'test-property-1', expiryDate: '2024-03-01', daysRemaining: 30 }
      }
    ];

    // Send each notification type
    for (const notif of notificationTypes) {
      try {
        const tokens = userTokens.get(userId);
        if (tokens && tokens.length > 0) {
          const result = await PushNotificationService.sendToMultipleTokens(
            tokens, 
            notif.title, 
            notif.body, 
            {
              type: notif.type,
              timestamp: new Date().toISOString(),
              testMode: true,
              ...notif.data
            }
          );
          testResults.push({
            type: notif.type,
            success: true,
            title: notif.title,
            body: notif.body,
            result: result
          });
        } else {
          testResults.push({
            type: notif.type,
            success: false,
            error: 'No FCM tokens found for user'
          });
        }

        // Small delay between notifications to avoid overwhelming
        await new Promise(resolve => setTimeout(resolve, 100));
        
      } catch (error) {
        testResults.push({
          type: notif.type,
          success: false,
          error: error.message
        });
      }
    }

    const successCount = testResults.filter(r => r.success).length;
    const totalCount = notificationTypes.length;

    res.json({
      success: true,
      message: `Test completed: ${successCount}/${totalCount} notifications sent successfully`,
      testSummary: {
        totalTypes: totalCount,
        successful: successCount,
        failed: totalCount - successCount,
        userId: userId,
        tokensRegistered: userTokens.get(userId)?.length || 0
      },
      detailedResults: testResults
    });

  } catch (error) {
    console.error('Error testing notifications:', error);
    res.status(500).json({
      error: 'Failed to test notifications',
      details: error.message
    });
  }
});

// Helper function to trigger notifications from other services
const triggerNotification = async (userId, type, title, body, data = {}) => {
  try {
    const tokens = userTokens.get(userId);
    const settings = notificationSettings.get(userId) || { pushNotifications: true };
    
    if (!tokens || tokens.length === 0) {
      console.log(`No FCM tokens found for user ${userId}`);
      return { success: false, error: 'No tokens' };
    }
    
    if (!settings.pushNotifications) {
      console.log(`Push notifications disabled for user ${userId}`);
      return { success: false, error: 'Notifications disabled' };
    }

    const notificationData = {
      type,
      timestamp: new Date().toISOString(),
      ...data
    };

    const result = await PushNotificationService.sendToMultipleTokens(tokens, title, body, notificationData);
    console.log(`Notification sent to user ${userId}: ${title}`);
    return { success: true, result };
    
  } catch (error) {
    console.error(`Error sending notification to user ${userId}:`, error);
    return { success: false, error: error.message };
  }
};

// Get available notification types - documentation endpoint
router.get('/types', (req, res) => {
  try {
    const notificationTypes = [
      {
        type: 'maintenance_request_created',
        description: 'Triggered when a new maintenance request is submitted',
        audience: 'landlord',
        data: ['propertyId', 'requestId', 'priority', 'category', 'tenantId']
      },
      {
        type: 'maintenance_request_updated',
        description: 'Triggered when maintenance request status is updated',
        audience: 'tenant',
        data: ['propertyId', 'requestId', 'status', 'propertyAddress']
      },
      {
        type: 'new_message',
        description: 'Triggered when a new chat message is received',
        audience: 'recipient',
        data: ['conversationId', 'senderId', 'messageId', 'messageType']
      },
      {
        type: 'payment_reminder',
        description: 'Triggered for rent payment reminders',
        audience: 'tenant',
        data: ['propertyId', 'amount', 'dueDate']
      },
      {
        type: 'payment_overdue',
        description: 'Triggered when rent payment is overdue',
        audience: 'tenant',
        data: ['propertyId', 'amount', 'daysPastDue']
      },
      {
        type: 'property_invitation',
        description: 'Triggered when tenant is invited to rent a property',
        audience: 'tenant',
        data: ['propertyId', 'landlordId', 'invitationId', 'conversationId', 'propertyAddress']
      },
      {
        type: 'invitation_accepted',
        description: 'Triggered when tenant accepts property invitation',
        audience: 'landlord',
        data: ['propertyId', 'tenantId', 'invitationId', 'propertyAddress']
      },
      {
        type: 'property_update',
        description: 'Triggered when property information is updated',
        audience: 'tenant',
        data: ['propertyId', 'updateType']
      },
      {
        type: 'auth_2fa_enabled',
        description: 'Triggered when 2FA is enabled for account',
        audience: 'user',
        data: ['securityEvent']
      },
      {
        type: 'auth_password_changed',
        description: 'Triggered when user password is changed',
        audience: 'user',
        data: ['securityEvent']
      },
      {
        type: 'auth_suspicious_login',
        description: 'Triggered when suspicious login is detected',
        audience: 'user',
        data: ['securityEvent', 'location']
      },
      {
        type: 'document_uploaded',
        description: 'Triggered when a document is uploaded for property',
        audience: 'tenant',
        data: ['propertyId', 'documentType']
      },
      {
        type: 'inspection_scheduled',
        description: 'Triggered when property inspection is scheduled',
        audience: 'tenant',
        data: ['propertyId', 'scheduledDate']
      },
      {
        type: 'lease_expiry_warning',
        description: 'Triggered when lease is approaching expiry',
        audience: 'tenant',
        data: ['propertyId', 'expiryDate', 'daysRemaining']
      }
    ];

    res.json({
      success: true,
      totalTypes: notificationTypes.length,
      types: notificationTypes,
      testEndpoint: '/api/notifications/test-all-notifications',
      documentation: {
        description: 'ImmoSync App Notification System',
        features: [
          'Push notifications for all major app events',
          'Comprehensive test endpoint for all notification types',
          'Automatic notification triggers integrated with app events',
          'Mock notification service for development',
          'Support for user notification preferences'
        ],
        usage: {
          testAllNotifications: 'POST /api/notifications/test-all-notifications with {userId, testUserToken}',
          registerToken: 'POST /api/notifications/register-token with {userId, token}',
          updateSettings: 'POST /api/notifications/update-settings with notification preferences'
        }
      }
    });

  } catch (error) {
    console.error('Error getting notification types:', error);
    res.status(500).json({
      error: 'Failed to get notification types',
      details: error.message
    });
  }
});

// Export the trigger function for use in other modules
module.exports = router;
module.exports.triggerNotification = triggerNotification;