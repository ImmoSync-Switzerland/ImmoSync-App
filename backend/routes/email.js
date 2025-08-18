const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');
const jwt = require('jsonwebtoken');
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');

// Debug: Log environment variables
console.log('Email Environment Variables:', {
  SMTP_HOST: process.env.SMTP_HOST,
  SMTP_PORT: process.env.SMTP_PORT,
  SMTP_USER: process.env.SMTP_USER,
  SMTP_PASS: process.env.SMTP_PASS ? 'SET' : 'NOT SET',
  FROM_EMAIL: process.env.FROM_EMAIL,
  FROM_NAME: process.env.FROM_NAME
});

// Email configuration
const createTransporter = () => {
  const config = {
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT) || 587,
    secure: false, // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER || 'your-email@gmail.com',
      pass: process.env.SMTP_PASS || 'your-app-password'
    },
    tls: {
      rejectUnauthorized: false,
      ciphers: 'SSLv3'
    },
    // Additional settings for better compatibility
    connectionTimeout: 60000,
    greetingTimeout: 30000,
    socketTimeout: 60000
  };
  
  console.log('SMTP Configuration:', {
    host: config.host,
    port: config.port,
    user: config.auth.user,
    // Don't log password for security
    hasPassword: !!config.auth.pass,
    secure: config.secure
  });
  
  return nodemailer.createTransport(config);
};

// Send verification email
const sendVerificationEmail = async (email, verificationToken) => {
  const transporter = createTransporter();
  
  // Create universal link that works for both app and web
  const webUrl = `${process.env.WEB_APP_URL || 'https://immosync.ch'}/verify-email/${verificationToken}`;
  const appScheme = process.env.FLUTTER_APP_SCHEME || 'immosync';
  const appUrl = `${appScheme}://verify-email/${verificationToken}`;
  
  const mailOptions = {
    from: `${process.env.FROM_NAME || 'ImmoSync'} <${process.env.FROM_EMAIL || process.env.SMTP_USER || 'noreply@immosync.ch'}>`,
    to: email,
    subject: 'Verify your ImmoSync account',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2563EB;">Welcome to ImmoSync!</h2>
        <p>Thank you for registering with ImmoSync. Please verify your email address by clicking the link below:</p>
        <a href="${webUrl}" style="display: inline-block; background-color: #2563EB; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin: 20px 0;">
          Verify Email Address
        </a>
        <p>If you have the ImmoSync app installed, you can also use this direct app link:</p>
        <a href="${appUrl}" style="color: #2563EB; text-decoration: underline;">Open in ImmoSync App</a>
        <p>If the buttons don't work, you can copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #666;">${webUrl}</p>
        <p>This link will expire in 24 hours.</p>
        <p>If you didn't create an account with ImmoSync, please ignore this email.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #666; font-size: 12px;">ImmoSync - Your Property Management Solution</p>
      </div>
    `
  };

  return transporter.sendMail(mailOptions);
};

// Send password reset email
const sendPasswordResetEmail = async (email, resetToken) => {
  const transporter = createTransporter();
  
  // Create universal link that works for both app and web
  const webUrl = `${process.env.WEB_APP_URL || 'https://immosync.ch'}/reset-password/${resetToken}`;
  const appScheme = process.env.FLUTTER_APP_SCHEME || 'immosync';
  const appUrl = `${appScheme}://reset-password/${resetToken}`;
  
  const mailOptions = {
    from: `${process.env.FROM_NAME || 'ImmoSync'} <${process.env.FROM_EMAIL || process.env.SMTP_USER || 'noreply@immosync.ch'}>`,
    to: email,
    subject: 'Reset your ImmoSync password',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2563EB;">Password Reset Request</h2>
        <p>You requested to reset your password for your ImmoSync account. Click the link below to reset your password:</p>
        <a href="${webUrl}" style="display: inline-block; background-color: #2563EB; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin: 20px 0;">
          Reset Password
        </a>
        <p>If you have the ImmoSync app installed, you can also use this direct app link:</p>
        <a href="${appUrl}" style="color: #2563EB; text-decoration: underline;">Open in ImmoSync App</a>
        <p>If the buttons don't work, you can copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #666;">${webUrl}</p>
        <p>This link will expire in 1 hour.</p>
        <p>If you didn't request a password reset, please ignore this email and your password will remain unchanged.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #666; font-size: 12px;">ImmoSync - Your Property Management Solution</p>
      </div>
    `
  };

  return transporter.sendMail(mailOptions);
};

// Verify email endpoint
router.get('/verify-email', async (req, res) => {
  const { token } = req.query;
  
  if (!token) {
    return res.status(400).json({ message: 'Verification token is required' });
  }

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    // Verify the token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    const userId = decoded.userId;
    
    // Update user verification status
    const result = await db.collection('users').updateOne(
      { _id: new ObjectId(userId) },
      { 
        $set: { 
          isValidated: true,
          emailVerified: true,
          verificationToken: null,
          updatedAt: new Date()
        } 
      }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json({ 
      success: true, 
      message: 'Email verified successfully! You can now log in.' 
    });
    
  } catch (error) {
    console.error('Email verification error:', error);
    if (error.name === 'TokenExpiredError') {
      res.status(400).json({ message: 'Verification token has expired' });
    } else if (error.name === 'JsonWebTokenError') {
      res.status(400).json({ message: 'Invalid verification token' });
    } else {
      res.status(500).json({ message: 'Email verification failed' });
    }
  } finally {
    await client.close();
  }
});

// Request password reset
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  
  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    // Find user by email
    const user = await db.collection('users').findOne({ email });
    
    if (!user) {
      // Don't reveal if email exists or not for security
      return res.json({ 
        success: true, 
        message: 'If an account with this email exists, you will receive a password reset link.' 
      });
    }
    
    // Generate reset token (valid for 1 hour)
    const resetToken = jwt.sign(
      { userId: user._id.toString(), type: 'password-reset' }, 
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '1h' }
    );
    
    // Save reset token to database
    await db.collection('users').updateOne(
      { _id: user._id },
      { 
        $set: { 
          passwordResetToken: resetToken,
          passwordResetExpires: new Date(Date.now() + 3600000), // 1 hour
          updatedAt: new Date()
        } 
      }
    );
    
    // Send reset email
    await sendPasswordResetEmail(email, resetToken);
    
    res.json({ 
      success: true, 
      message: 'If an account with this email exists, you will receive a password reset link.' 
    });
    
  } catch (error) {
    console.error('Password reset request error:', error);
    res.status(500).json({ message: 'Failed to process password reset request' });
  } finally {
    await client.close();
  }
});

// Reset password
router.post('/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;
  
  if (!token || !newPassword) {
    return res.status(400).json({ message: 'Token and new password are required' });
  }

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    // Verify the token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    const userId = decoded.userId;
    
    if (decoded.type !== 'password-reset') {
      return res.status(400).json({ message: 'Invalid token type' });
    }
    
    // Find user and verify token
    const user = await db.collection('users').findOne({ 
      _id: new ObjectId(userId),
      passwordResetToken: token,
      passwordResetExpires: { $gt: new Date() }
    });
    
    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired reset token' });
    }
    
    // Hash new password
    const bcrypt = require('bcryptjs');
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update password and remove reset token
    await db.collection('users').updateOne(
      { _id: user._id },
      { 
        $set: { 
          password: hashedPassword,
          updatedAt: new Date()
        },
        $unset: {
          passwordResetToken: "",
          passwordResetExpires: ""
        }
      }
    );
    
    res.json({ 
      success: true, 
      message: 'Password reset successfully! You can now log in with your new password.' 
    });
    
  } catch (error) {
    console.error('Password reset error:', error);
    if (error.name === 'TokenExpiredError') {
      res.status(400).json({ message: 'Reset token has expired' });
    } else if (error.name === 'JsonWebTokenError') {
      res.status(400).json({ message: 'Invalid reset token' });
    } else {
      res.status(500).json({ message: 'Password reset failed' });
    }
  } finally {
    await client.close();
  }
});

// Verify reset token endpoint
router.post('/verify-reset-token', async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ message: 'Reset token is required' });
    }

    // Verify the token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    
    if (decoded.type !== 'password-reset') {
      return res.status(400).json({ message: 'Invalid token type' });
    }
    
    // Check if user exists
    const client = new MongoClient(dbUri);
    await client.connect();
    const db = client.db(dbName);
    
    const user = await db.collection('users').findOne({ 
      _id: new ObjectId(decoded.userId),
      passwordResetToken: token,
      passwordResetExpires: { $gt: new Date() }
    });

    await client.close();

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired reset token' });
    }

    res.json({ message: 'Token is valid' });
  } catch (error) {
    console.error('Token verification error:', error);
    if (error.name === 'TokenExpiredError') {
      return res.status(400).json({ message: 'Reset link has expired' });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(400).json({ message: 'Invalid reset link' });
    }
    res.status(500).json({ message: 'Server error during token verification' });
  }
});

// Resend verification email
router.post('/resend-verification', async (req, res) => {
  const { email } = req.body;
  
  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    // Find user by email
    const user = await db.collection('users').findOne({ email });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    if (user.emailVerified) {
      return res.status(400).json({ message: 'Email is already verified' });
    }
    
    // Generate new verification token (valid for 24 hours)
    const verificationToken = jwt.sign(
      { userId: user._id.toString(), type: 'email-verification' }, 
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );
    
    // Update verification token in database
    await db.collection('users').updateOne(
      { _id: user._id },
      { 
        $set: { 
          verificationToken: verificationToken,
          updatedAt: new Date()
        } 
      }
    );
    
    // Send verification email
    await sendVerificationEmail(email, verificationToken);
    
    res.json({ 
      success: true, 
      message: 'Verification email sent successfully!' 
    });
    
  } catch (error) {
    console.error('Resend verification error:', error);
    res.status(500).json({ message: 'Failed to resend verification email' });
  } finally {
    await client.close();
  }
});

// Test email endpoint
router.post('/test-smtp', async (req, res) => {
  try {
    console.log('Testing SMTP configuration...');
    const transporter = createTransporter();
    
    // Verify SMTP connection
    await transporter.verify();
    console.log('SMTP connection verified successfully');
    
    res.json({ 
      success: true, 
      message: 'SMTP configuration is working' 
    });
  } catch (error) {
    console.error('SMTP test error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'SMTP test failed', 
      error: error.message 
    });
  }
});

module.exports = { router, sendVerificationEmail };