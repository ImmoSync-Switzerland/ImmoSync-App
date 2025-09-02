const express = require('express');
const router = express.Router();

// Firebase Admin initialization (with graceful fallback to mock)
let admin = null;
try {
  if (process.env.FIREBASE_PROJECT_ID || process.env.FIREBASE_CREDENTIALS_FILE) {
    admin = require('firebase-admin');
    if (!admin.apps.length) {
      // Option 1: external JSON file path
      if (process.env.FIREBASE_CREDENTIALS_FILE) {
        try {
          const serviceAccount = require(process.env.FIREBASE_CREDENTIALS_FILE);
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
          });
          console.log('Firebase Admin initialized (service account file)');
        } catch (fileErr) {
          console.warn('[Firebase Admin] Failed loading file at FIREBASE_CREDENTIALS_FILE:', fileErr.message);
          throw fileErr;
        }
      } else {
        // Option 2: env inline credentials
        const {
          FIREBASE_PROJECT_ID,
          FIREBASE_CLIENT_EMAIL,
          FIREBASE_PRIVATE_KEY
        } = process.env;

        if (FIREBASE_CLIENT_EMAIL && FIREBASE_PRIVATE_KEY) {
        // Parse private key: support escaped \n and optional base64
        function parsePrivateKey(raw) {
          let key = raw.trim();
          // If wrapped in quotes remove them
            if ((key.startsWith('"') && key.endsWith('"')) || (key.startsWith("'") && key.endsWith("'"))) {
            key = key.slice(1, -1);
          }
          // Replace escaped newlines
          key = key.replace(/\\n/g, '\n');
          // If still single line without header but looks base64, attempt decode
          if (!key.includes('BEGIN') && /^[A-Za-z0-9+/=\r\n]+$/.test(key) && key.length % 4 === 0) {
            try {
              const decoded = Buffer.from(key.replace(/\s+/g,''), 'base64').toString('utf8');
              if (decoded.includes('BEGIN PRIVATE KEY')) {
                key = decoded;
              }
            } catch (_) { /* ignore */ }
          }
          return key;
        }
        const privateKey = parsePrivateKey(FIREBASE_PRIVATE_KEY);

        if (!privateKey.includes('BEGIN PRIVATE KEY')) {
          console.warn('[Firebase Admin] Provided FIREBASE_PRIVATE_KEY appears invalid (missing BEGIN PRIVATE KEY header).');
        }
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId: FIREBASE_PROJECT_ID,
            clientEmail: FIREBASE_CLIENT_EMAIL,
            privateKey,
          }),
        });
        console.log('Firebase Admin initialized (cert env vars)');
        } else {
          admin.initializeApp({
            credential: admin.credential.applicationDefault(),
          });
          console.log('Firebase Admin initialized (application default credentials)');
        }
      } // end inline credentials path
    }
  }
} catch (e) {
  console.warn('Firebase Admin not initialized, using mock notification service:', e.message);
  admin = null;
}

class PushNotificationService {
  static async sendNotification(token, title, body, data = {}) {
    if (admin) {
      try {
        const message = {
          token,
            notification: { title, body },
          data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
        };
        const messageId = await admin.messaging().send(message);
        return { success: true, messageId };
      } catch (err) {
        console.error('Firebase sendNotification error:', err);
        return { success: false, error: err.message };
      }
    }
    console.log(`\n=== MOCK PUSH NOTIFICATION SENT ===\nToken: ${token}\nTitle: ${title}\nBody: ${body}\nData: ${JSON.stringify(data)}\n==================================\n`);
    return { success: true, messageId: `mock_${Date.now()}` };
  }

  static async sendToMultipleTokens(tokens, title, body, data = {}) {
    if (admin) {
      try {
        const message = {
          tokens,
            notification: { title, body },
          data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
        };
        const response = await admin.messaging().sendEachForMulticast(message);
        const results = response.responses.map((r, idx) => ({
          token: tokens[idx],
          success: r.success,
          messageId: r.messageId,
          error: r.success ? undefined : r.error?.message,
        }));
        return { success: true, results };
      } catch (err) {
        console.error('Firebase sendToMultipleTokens error:', err);
        return { success: false, error: err.message };
      }
    }
    console.log(`\n=== MOCK BULK PUSH ===\nTokens: ${tokens.length}\nTitle: ${title}\nBody: ${body}\nData: ${JSON.stringify(data)}\n======================\n`);
    return { success: true, results: tokens.map(t => ({ token: t, success: true, messageId: `mock_${Date.now()}` })) };
  }

  static async sendToTopic(topic, title, body, data = {}) {
    if (admin) {
      try {
        const message = {
          topic,
            notification: { title, body },
          data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
        };
        const messageId = await admin.messaging().send(message);
        return { success: true, messageId };
      } catch (err) {
        console.error('Firebase sendToTopic error:', err);
        return { success: false, error: err.message };
      }
    }
    console.log(`\n=== MOCK TOPIC NOTIFICATION ===\nTopic: ${topic}\nTitle: ${title}\nBody: ${body}\nData: ${JSON.stringify(data)}\n================================\n`);
    return { success: true, messageId: `mock_topic_${Date.now()}` };
  }
}

// In-memory storage for demo - use database in production
const userTokens = new Map(); // userId -> [tokens]
const notificationSettings = new Map(); // userId -> settings
const userNotifications = new Map(); // userId -> [{id,title,body,type,data,timestamp,read:false}]

// Reusable helper to send a notification to a single userId (used by other route modules)
async function sendDomainNotification(userId, { title, body, type='general', data = {} }) {
  try {
    const tokens = userTokens.get(userId);
    if (!tokens || tokens.length === 0) {
      return { success: false, reason: 'no_tokens' };
    }
    const settings = notificationSettings.get(userId) || { pushNotifications: true };
    if (!settings.pushNotifications) {
      return { success: false, reason: 'disabled' };
    }
    const payloadData = { ...data, type, timestamp: new Date().toISOString() };
    let result;
    if (tokens.length === 1) {
      result = await PushNotificationService.sendNotification(tokens[0], title, body, payloadData);
    } else {
      result = await PushNotificationService.sendToMultipleTokens(tokens, title, body, payloadData);
    }
    addNotification(userId, { title, body, type, data: payloadData });
    return { success: true, result };
  } catch (e) {
    console.error('[DomainNotification] send error', e);
    return { success: false, reason: 'error', error: e.message };
  }
}

function addNotification(userId, { title, body, type='general', data={} }) {
  if (!userNotifications.has(userId)) userNotifications.set(userId, []);
  const list = userNotifications.get(userId);
  const record = {
    id: `${Date.now()}_${Math.random().toString(36).slice(2,8)}`,
    title,
    body,
    type,
    data,
    timestamp: new Date().toISOString(),
    read: false,
  };
  list.unshift(record); // latest first
  // Trim to last 200 to avoid unbounded growth
  if (list.length > 200) list.splice(200);
  return record;
}

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

  addNotification(userId, { title, body, type: notificationData.type, data: notificationData });

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
          addNotification(userId, { title, body, type: notificationData.type, data: notificationData });
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
          addNotification(userId, { title, body, type: 'payment_reminder', data });
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
          addNotification(userId, { title, body, type: 'maintenance_request', data });
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

// Also export helper for other modules (they can require this file and use sendDomainNotification)
module.exports.sendDomainNotification = sendDomainNotification;

// --- Debug endpoints (non-production use) ---
// List tokens for a user
router.get('/debug/tokens/:userId', (req, res) => {
  if (process.env.NODE_ENV === 'production') {
    return res.status(403).json({ error: 'Disabled in production' });
  }
  const tokens = userTokens.get(req.params.userId) || [];
  res.json({ userId: req.params.userId, tokens, count: tokens.length });
});

// List all users with token counts
router.get('/debug/all-tokens', (req, res) => {
  if (process.env.NODE_ENV === 'production') {
    return res.status(403).json({ error: 'Disabled in production' });
  }
  const summary = [];
  for (const [userId, tokens] of userTokens.entries()) {
    summary.push({ userId, count: tokens.length, tokens });
  }
  res.json({ users: summary });
});

// Fetch notifications for a user (latest first)
router.get('/list/:userId', (req, res) => {
  try {
    const { userId } = req.params;
    const limit = parseInt(req.query.limit || '50', 10);
    const list = (userNotifications.get(userId) || []).slice(0, limit);
    res.json({ success: true, notifications: list });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to fetch notifications', details: e.message });
  }
});

// Mark notifications as read
router.post('/mark-read', (req, res) => {
  try {
    const { userId, ids, all } = req.body;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });
    const list = userNotifications.get(userId) || [];
    if (all) {
      list.forEach(n => n.read = true);
    } else if (Array.isArray(ids)) {
      const idSet = new Set(ids);
      list.forEach(n => { if (idSet.has(n.id)) n.read = true; });
    }
    res.json({ success: true, updated: list.filter(n => n.read).length });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to mark read', details: e.message });
  }
});