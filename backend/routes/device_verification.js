// Device Verification Routes for Email-based Device Security
// This handles registration, verification, and status checking of devices

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { MongoClient } = require('mongodb');

// Import email service (assuming you have one)
// const emailService = require('../services/email_service');

// MongoDB connection (reuse from your existing config)
let db;
MongoClient.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/immolink')
  .then(client => {
    db = client.db();
    console.log('[DeviceAuth] Connected to MongoDB');
  })
  .catch(err => console.error('[DeviceAuth] MongoDB connection error:', err));

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key', (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Helper function to send verification email
async function sendVerificationEmail(email, userName, deviceName, verificationToken) {
  const verificationUrl = `https://immolink.ddns.net/verify-device?token=${verificationToken}`;
  
  // TODO: Implement actual email sending using your email service
  // For now, just log it
  console.log('[DeviceAuth] Verification email for:', email);
  console.log('[DeviceAuth] Device:', deviceName);
  console.log('[DeviceAuth] Verification URL:', verificationUrl);
  
  // Example email content:
  const emailContent = {
    to: email,
    subject: 'ImmoLink - Neues Gerät verifizieren',
    html: `
      <h2>Neues Gerät angemeldet</h2>
      <p>Hallo ${userName},</p>
      <p>Ein neues Gerät hat sich in Ihrem ImmoLink-Konto angemeldet:</p>
      <p><strong>${deviceName}</strong></p>
      <p>Falls Sie das waren, klicken Sie bitte auf den folgenden Link, um dieses Gerät zu verifizieren:</p>
      <p><a href="${verificationUrl}">Gerät verifizieren</a></p>
      <p>Falls Sie sich nicht angemeldet haben, ignorieren Sie diese E-Mail und ändern Sie umgehend Ihr Passwort.</p>
      <p>Der Verifizierungslink ist 24 Stunden gültig.</p>
      <p>Mit freundlichen Grüßen,<br>Ihr ImmoLink Team</p>
    `
  };
  
  // Uncomment when email service is ready:
  // await emailService.sendEmail(emailContent);
  
  // For testing, you can also send via console or store in DB
  return true;
}

// POST /api/auth/device/register - Register a new device
router.post('/register', authenticateToken, async (req, res) => {
  try {
    const { userId, deviceId, deviceName, deviceInfo } = req.body;
    
    console.log('[DeviceAuth] Register device request:', { userId, deviceId, deviceName });

    if (!userId || !deviceId || !deviceName) {
      return res.status(400).json({ 
        error: 'Missing required fields: userId, deviceId, deviceName' 
      });
    }

    // Verify the authenticated user matches the userId
    if (req.user.userId !== userId && req.user.id !== userId) {
      return res.status(403).json({ error: 'Unauthorized: User mismatch' });
    }

    const devicesCollection = db.collection('devices');
    const usersCollection = db.collection('users');

    // Check if device already exists
    const existingDevice = await devicesCollection.findOne({ 
      userId, 
      deviceId 
    });

    if (existingDevice) {
      // Device already registered
      if (existingDevice.verified) {
        return res.json({
          status: 'verified',
          message: 'Device already verified',
          deviceId: existingDevice.deviceId,
          verifiedAt: existingDevice.verifiedAt,
        });
      } else {
        // Re-send verification email if still pending
        const user = await usersCollection.findOne({ _id: userId });
        if (user && user.email) {
          await sendVerificationEmail(
            user.email, 
            user.name || 'Benutzer',
            deviceName,
            existingDevice.verificationToken
          );
        }

        return res.json({
          status: 'pendingVerification',
          message: 'Verification email sent. Please check your inbox.',
          deviceId: existingDevice.deviceId,
        });
      }
    }

    // Generate verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const tokenExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    // Create new device record
    const deviceRecord = {
      userId,
      deviceId,
      deviceName,
      deviceInfo,
      verified: false,
      verificationToken,
      tokenExpiresAt,
      createdAt: new Date(),
      lastSeenAt: new Date(),
    };

    await devicesCollection.insertOne(deviceRecord);
    console.log('[DeviceAuth] Device registered:', deviceId);

    // Get user email and send verification email
    const user = await usersCollection.findOne({ _id: userId });
    if (user && user.email) {
      await sendVerificationEmail(
        user.email,
        user.name || 'Benutzer',
        deviceName,
        verificationToken
      );
      console.log('[DeviceAuth] Verification email sent to:', user.email);
    } else {
      console.warn('[DeviceAuth] User email not found:', userId);
    }

    res.status(201).json({
      status: 'pendingVerification',
      message: 'Device registered. Verification email sent.',
      deviceId,
    });

  } catch (error) {
    console.error('[DeviceAuth] Error registering device:', error);
    res.status(500).json({ 
      error: 'Failed to register device',
      details: error.message 
    });
  }
});

// POST /api/auth/device/verify - Verify device using email token
router.post('/verify', authenticateToken, async (req, res) => {
  try {
    const { userId, deviceId, verificationToken } = req.body;

    console.log('[DeviceAuth] Verify device request:', { userId, deviceId });

    if (!userId || !deviceId || !verificationToken) {
      return res.status(400).json({ 
        error: 'Missing required fields: userId, deviceId, verificationToken' 
      });
    }

    // Verify the authenticated user matches the userId
    if (req.user.userId !== userId && req.user.id !== userId) {
      return res.status(403).json({ error: 'Unauthorized: User mismatch' });
    }

    const devicesCollection = db.collection('devices');

    // Find device with matching token
    const device = await devicesCollection.findOne({
      userId,
      deviceId,
      verificationToken,
    });

    if (!device) {
      return res.status(404).json({ 
        status: 'failed',
        error: 'Invalid verification token or device not found' 
      });
    }

    // Check if token expired
    if (device.tokenExpiresAt < new Date()) {
      return res.status(400).json({ 
        status: 'failed',
        error: 'Verification token expired. Please request a new one.' 
      });
    }

    // Mark device as verified
    await devicesCollection.updateOne(
      { userId, deviceId },
      { 
        $set: { 
          verified: true,
          verifiedAt: new Date(),
          lastSeenAt: new Date(),
        },
        $unset: {
          verificationToken: '',
          tokenExpiresAt: '',
        }
      }
    );

    console.log('[DeviceAuth] Device verified:', deviceId);

    res.json({
      status: 'verified',
      message: 'Device successfully verified',
      deviceId,
      verifiedAt: new Date(),
    });

  } catch (error) {
    console.error('[DeviceAuth] Error verifying device:', error);
    res.status(500).json({ 
      status: 'failed',
      error: 'Failed to verify device',
      details: error.message 
    });
  }
});

// GET /api/auth/device/status - Check device verification status
router.get('/status', authenticateToken, async (req, res) => {
  try {
    const { userId, deviceId } = req.query;

    console.log('[DeviceAuth] Status check:', { userId, deviceId });

    if (!userId || !deviceId) {
      return res.status(400).json({ 
        error: 'Missing required parameters: userId, deviceId' 
      });
    }

    // Verify the authenticated user matches the userId
    if (req.user.userId !== userId && req.user.id !== userId) {
      return res.status(403).json({ error: 'Unauthorized: User mismatch' });
    }

    const devicesCollection = db.collection('devices');

    const device = await devicesCollection.findOne({ userId, deviceId });

    if (!device) {
      return res.json({
        status: 'unknown',
        message: 'Device not registered',
      });
    }

    // Update last seen
    await devicesCollection.updateOne(
      { userId, deviceId },
      { $set: { lastSeenAt: new Date() } }
    );

    if (device.verified) {
      return res.json({
        status: 'verified',
        message: 'Device is verified',
        deviceId: device.deviceId,
        verifiedAt: device.verifiedAt,
      });
    } else {
      return res.json({
        status: 'pendingVerification',
        message: 'Device pending email verification',
        deviceId: device.deviceId,
      });
    }

  } catch (error) {
    console.error('[DeviceAuth] Error checking status:', error);
    res.status(500).json({ 
      status: 'unknown',
      error: 'Failed to check device status',
      details: error.message 
    });
  }
});

// POST /api/auth/device/resend-verification - Resend verification email
router.post('/resend-verification', authenticateToken, async (req, res) => {
  try {
    const { userId, deviceId } = req.body;

    console.log('[DeviceAuth] Resend verification:', { userId, deviceId });

    if (!userId || !deviceId) {
      return res.status(400).json({ 
        error: 'Missing required fields: userId, deviceId' 
      });
    }

    // Verify the authenticated user matches the userId
    if (req.user.userId !== userId && req.user.id !== userId) {
      return res.status(403).json({ error: 'Unauthorized: User mismatch' });
    }

    const devicesCollection = db.collection('devices');
    const usersCollection = db.collection('users');

    const device = await devicesCollection.findOne({ userId, deviceId });

    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }

    if (device.verified) {
      return res.json({ 
        message: 'Device already verified',
        status: 'verified' 
      });
    }

    // Generate new token if expired
    let verificationToken = device.verificationToken;
    if (device.tokenExpiresAt < new Date()) {
      verificationToken = crypto.randomBytes(32).toString('hex');
      const tokenExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

      await devicesCollection.updateOne(
        { userId, deviceId },
        { 
          $set: { 
            verificationToken,
            tokenExpiresAt,
          }
        }
      );
    }

    // Send verification email
    const user = await usersCollection.findOne({ _id: userId });
    if (user && user.email) {
      await sendVerificationEmail(
        user.email,
        user.name || 'Benutzer',
        device.deviceName,
        verificationToken
      );
      console.log('[DeviceAuth] Verification email re-sent to:', user.email);
    }

    res.json({ 
      message: 'Verification email sent',
      status: 'pendingVerification' 
    });

  } catch (error) {
    console.error('[DeviceAuth] Error resending verification:', error);
    res.status(500).json({ 
      error: 'Failed to resend verification email',
      details: error.message 
    });
  }
});

// GET /api/auth/device/list - List all devices for a user
router.get('/list', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({ error: 'Missing userId parameter' });
    }

    // Verify the authenticated user matches the userId
    if (req.user.userId !== userId && req.user.id !== userId) {
      return res.status(403).json({ error: 'Unauthorized: User mismatch' });
    }

    const devicesCollection = db.collection('devices');

    const devices = await devicesCollection.find({ userId })
      .project({ 
        verificationToken: 0, // Don't expose token
      })
      .sort({ lastSeenAt: -1 })
      .toArray();

    res.json({ 
      devices,
      count: devices.length 
    });

  } catch (error) {
    console.error('[DeviceAuth] Error listing devices:', error);
    res.status(500).json({ 
      error: 'Failed to list devices',
      details: error.message 
    });
  }
});

// DELETE /api/auth/device/revoke - Revoke/delete a device
router.delete('/revoke', authenticateToken, async (req, res) => {
  try {
    const { userId, deviceId } = req.body;

    if (!userId || !deviceId) {
      return res.status(400).json({ 
        error: 'Missing required fields: userId, deviceId' 
      });
    }

    // Verify the authenticated user matches the userId
    if (req.user.userId !== userId && req.user.id !== userId) {
      return res.status(403).json({ error: 'Unauthorized: User mismatch' });
    }

    const devicesCollection = db.collection('devices');

    const result = await devicesCollection.deleteOne({ userId, deviceId });

    if (result.deletedCount === 0) {
      return res.status(404).json({ error: 'Device not found' });
    }

    console.log('[DeviceAuth] Device revoked:', deviceId);

    res.json({ 
      message: 'Device revoked successfully',
      deviceId 
    });

  } catch (error) {
    console.error('[DeviceAuth] Error revoking device:', error);
    res.status(500).json({ 
      error: 'Failed to revoke device',
      details: error.message 
    });
  }
});

module.exports = router;
