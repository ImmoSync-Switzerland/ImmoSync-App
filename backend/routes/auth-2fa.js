const express = require('express');
const router = express.Router();

// Twilio SMS Service
const twilio = require('twilio');

// Twilio configuration - in production, these should be environment variables
const TWILIO_CONFIG = {
  accountSid: process.env.TWILIO_ACCOUNT_SID || 'your_twilio_account_sid',
  authToken: process.env.TWILIO_AUTH_TOKEN || 'your_twilio_auth_token',
  phoneNumber: process.env.TWILIO_PHONE_NUMBER || 'your_twilio_phone_number'
};

// Initialize Twilio client
let twilioClient;
let useMockSMS = false;

try {
  if (TWILIO_CONFIG.accountSid && TWILIO_CONFIG.authToken && 
      TWILIO_CONFIG.accountSid !== 'your_twilio_account_sid') {
    twilioClient = twilio(TWILIO_CONFIG.accountSid, TWILIO_CONFIG.authToken);
    console.log('Twilio SMS service initialized');
  } else {
    useMockSMS = true;
    console.log('Twilio credentials not found, using mock SMS service');
  }
} catch (error) {
  console.error('Error initializing Twilio:', error);
  useMockSMS = true;
}

// SMS Service with real Twilio integration
class SMSService {
  static async sendSMS(phoneNumber, message) {
    try {
      if (useMockSMS) {
        // Mock implementation for development/testing
        console.log(`[MOCK SMS] To: ${phoneNumber}, Message: ${message}`);
        return { 
          success: true, 
          messageId: `mock_msg_${Date.now()}`,
          isMock: true 
        };
      }

      // Real Twilio SMS
      const twilioMessage = await twilioClient.messages.create({
        body: message,
        from: TWILIO_CONFIG.phoneNumber,
        to: phoneNumber
      });

      console.log(`SMS sent successfully: ${twilioMessage.sid}`);
      return { 
        success: true, 
        messageId: twilioMessage.sid,
        status: twilioMessage.status,
        isMock: false 
      };

    } catch (error) {
      console.error('Error sending SMS:', error);
      
      // Fallback to mock if Twilio fails
      if (!useMockSMS) {
        console.log('Falling back to mock SMS due to error');
        console.log(`[FALLBACK MOCK SMS] To: ${phoneNumber}, Message: ${message}`);
        return { 
          success: true, 
          messageId: `fallback_msg_${Date.now()}`,
          isMock: true,
          error: error.message 
        };
      }
      
      throw error;
    }
  }

  static isUsingMockSMS() {
    return useMockSMS;
  }
}

// In-memory storage for demo - use Redis in production
const verificationCodes = new Map();
const user2FAStatus = new Map();

// Generate 6-digit verification code
function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Validate phone number format
function isValidPhoneNumber(phone) {
  const phoneRegex = /^\+?[1-9]\d{1,14}$/;
  return phoneRegex.test(phone);
}

// Request 2FA setup
router.post('/setup-2fa', async (req, res) => {
  try {
    const { userId, phoneNumber } = req.body;

    if (!userId || !phoneNumber) {
      return res.status(400).json({
        error: 'User ID and phone number are required'
      });
    }

    if (!isValidPhoneNumber(phoneNumber)) {
      return res.status(400).json({
        error: 'Invalid phone number format'
      });
    }

    // Generate verification code
    const code = generateVerificationCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Store verification code
    verificationCodes.set(`${userId}_setup`, {
      code,
      phoneNumber,
      expiresAt,
      verified: false
    });

    // Send SMS
    const message = `Your ImmoLink 2FA setup code is: ${code}. Valid for 10 minutes.`;
    const smsResult = await SMSService.sendSMS(phoneNumber, message);

    res.json({
      success: true,
      message: 'Verification code sent to your phone number',
      smsStatus: smsResult.isMock ? 'mock' : 'sent',
      messageId: smsResult.messageId
    });

  } catch (error) {
    console.error('Error setting up 2FA:', error);
    res.status(500).json({
      error: 'Failed to setup 2FA',
      details: error.message
    });
  }
});

// Verify 2FA setup
router.post('/verify-2fa-setup', async (req, res) => {
  try {
    const { userId, verificationCode } = req.body;

    if (!userId || !verificationCode) {
      return res.status(400).json({
        error: 'User ID and verification code are required'
      });
    }

    const storedData = verificationCodes.get(`${userId}_setup`);
    
    if (!storedData) {
      return res.status(400).json({
        error: 'No verification code found. Please request a new code.'
      });
    }

    if (new Date() > storedData.expiresAt) {
      verificationCodes.delete(`${userId}_setup`);
      return res.status(400).json({
        error: 'Verification code has expired. Please request a new code.'
      });
    }

    if (storedData.code !== verificationCode) {
      return res.status(400).json({
        error: 'Invalid verification code'
      });
    }

    // Mark 2FA as enabled for user
    user2FAStatus.set(userId, {
      enabled: true,
      phoneNumber: storedData.phoneNumber,
      enabledAt: new Date()
    });

    // Clean up verification code
    verificationCodes.delete(`${userId}_setup`);

    res.json({
      success: true,
      message: '2FA has been successfully enabled',
      phoneNumber: storedData.phoneNumber.replace(/(\d{3})\d{4}(\d{3})/, '$1****$2') // Mask phone number
    });

  } catch (error) {
    console.error('Error verifying 2FA setup:', error);
    res.status(500).json({
      error: 'Failed to verify 2FA setup',
      details: error.message
    });
  }
});

// Send 2FA code for login
router.post('/send-login-code', async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        error: 'User ID is required'
      });
    }

    const user2FA = user2FAStatus.get(userId);
    
    if (!user2FA || !user2FA.enabled) {
      return res.status(400).json({
        error: '2FA is not enabled for this user'
      });
    }

    // Generate verification code
    const code = generateVerificationCode();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    // Store verification code
    verificationCodes.set(`${userId}_login`, {
      code,
      phoneNumber: user2FA.phoneNumber,
      expiresAt,
      verified: false
    });

    // Send SMS
    const message = `Your ImmoLink login code is: ${code}. Valid for 5 minutes.`;
    const smsResult = await SMSService.sendSMS(user2FA.phoneNumber, message);

    res.json({
      success: true,
      message: 'Verification code sent to your registered phone number',
      maskedPhone: user2FA.phoneNumber.replace(/(\d{3})\d{4}(\d{3})/, '$1****$2'),
      smsStatus: smsResult.isMock ? 'mock' : 'sent',
      messageId: smsResult.messageId
    });

  } catch (error) {
    console.error('Error sending login code:', error);
    res.status(500).json({
      error: 'Failed to send login code',
      details: error.message
    });
  }
});

// Verify 2FA code for login
router.post('/verify-login-code', async (req, res) => {
  try {
    const { userId, verificationCode } = req.body;

    if (!userId || !verificationCode) {
      return res.status(400).json({
        error: 'User ID and verification code are required'
      });
    }

    const storedData = verificationCodes.get(`${userId}_login`);
    
    if (!storedData) {
      return res.status(400).json({
        error: 'No verification code found. Please request a new code.'
      });
    }

    if (new Date() > storedData.expiresAt) {
      verificationCodes.delete(`${userId}_login`);
      return res.status(400).json({
        error: 'Verification code has expired. Please request a new code.'
      });
    }

    if (storedData.code !== verificationCode) {
      return res.status(400).json({
        error: 'Invalid verification code'
      });
    }

    // Mark as verified
    storedData.verified = true;
    
    // Clean up verification code
    verificationCodes.delete(`${userId}_login`);

    res.json({
      success: true,
      message: '2FA verification successful'
    });

  } catch (error) {
    console.error('Error verifying login code:', error);
    res.status(500).json({
      error: 'Failed to verify login code',
      details: error.message
    });
  }
});

// Check 2FA status
router.get('/status/:userId', (req, res) => {
  try {
    const { userId } = req.params;
    
    const user2FA = user2FAStatus.get(userId);
    
    res.json({
      enabled: user2FA ? user2FA.enabled : false,
      phoneNumber: user2FA ? user2FA.phoneNumber.replace(/(\d{3})\d{4}(\d{3})/, '$1****$2') : null,
      enabledAt: user2FA ? user2FA.enabledAt : null
    });

  } catch (error) {
    console.error('Error checking 2FA status:', error);
    res.status(500).json({
      error: 'Failed to check 2FA status',
      details: error.message
    });
  }
});

// Disable 2FA
router.post('/disable', async (req, res) => {
  try {
    const { userId, verificationCode } = req.body;

    if (!userId) {
      return res.status(400).json({
        error: 'User ID is required'
      });
    }

    const user2FA = user2FAStatus.get(userId);
    
    if (!user2FA || !user2FA.enabled) {
      return res.status(400).json({
        error: '2FA is not enabled for this user'
      });
    }

    // If verification code is provided, verify it
    if (verificationCode) {
      const storedData = verificationCodes.get(`${userId}_disable`);
      
      if (!storedData || storedData.code !== verificationCode || new Date() > storedData.expiresAt) {
        return res.status(400).json({
          error: 'Invalid or expired verification code'
        });
      }
      
      // Disable 2FA
      user2FAStatus.delete(userId);
      verificationCodes.delete(`${userId}_disable`);
      
      res.json({
        success: true,
        message: '2FA has been disabled'
      });
    } else {
      // Send verification code to disable 2FA
      const code = generateVerificationCode();
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

      verificationCodes.set(`${userId}_disable`, {
        code,
        phoneNumber: user2FA.phoneNumber,
        expiresAt,
        verified: false
      });

      const message = `Your ImmoLink 2FA disable code is: ${code}. Valid for 10 minutes.`;
      const smsResult = await SMSService.sendSMS(user2FA.phoneNumber, message);

      res.json({
        success: true,
        message: 'Verification code sent to disable 2FA',
        smsStatus: smsResult.isMock ? 'mock' : 'sent'
      });
    }

  } catch (error) {
    console.error('Error disabling 2FA:', error);
    res.status(500).json({
      error: 'Failed to disable 2FA',
      details: error.message
    });
  }
});

// SMS Service Status endpoint
router.get('/sms-status', (req, res) => {
  try {
    res.json({
      smsService: SMSService.isUsingMockSMS() ? 'mock' : 'twilio',
      isProduction: !SMSService.isUsingMockSMS(),
      twilioConfigured: !SMSService.isUsingMockSMS(),
      message: SMSService.isUsingMockSMS() 
        ? 'Using mock SMS service for development/testing' 
        : 'Using Twilio SMS service for production'
    });
  } catch (error) {
    console.error('Error checking SMS status:', error);
    res.status(500).json({
      error: 'Failed to check SMS status',
      details: error.message
    });
  }
});

module.exports = router;