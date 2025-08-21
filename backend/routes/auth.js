const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');

router.post('/register', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);

    const {
      email,
      password,
      fullName,
      role,
      phone,
      isCompany,
      companyName,
      companyAddress,
      taxId,
      address,
      birthDate
    } = req.body;

    // Create user document with enhanced fields
    const newUser = {
      email: email,
      password: await bcrypt.hash(password, 10),
      fullName: fullName,
      role: role.toLowerCase(), // Ensure lowercase for enum match
      phone: phone,
      isCompany: isCompany || false,
      isAdmin: false,
      isValidated: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    // Add company-specific fields
    if (isCompany) {
      newUser.companyName = companyName;
      newUser.companyAddress = companyAddress;
      newUser.taxId = taxId;
    } else {
      newUser.address = address;
      if (birthDate) {
        newUser.birthDate = new Date(birthDate);
      }
    }

    // Log document for verification
    console.log('Attempting to insert user:', newUser);

    const result = await db.collection('users').insertOne(newUser);
    
    // Send registration confirmation email
    try {
      const emailEndpoint = `${process.env.API_URL || 'http://backend.immosync.ch/api'}/email/send-registration-confirmation`;
      const emailData = {
        userEmail: email,
        userName: fullName
      };
      
      // Use fetch or http to call the email endpoint
      const http = require('http');
      const https = require('https');
      const url = require('url');
      
      const parsedUrl = url.parse(emailEndpoint);
      const httpModule = parsedUrl.protocol === 'https:' ? https : http;
      
      const postData = JSON.stringify(emailData);
      const options = {
        hostname: parsedUrl.hostname,
        port: parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 80),
        path: parsedUrl.path,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData)
        }
      };
      
      const req = httpModule.request(options, (res) => {
        console.log('Registration email sent, status:', res.statusCode);
      });
      
      req.on('error', (e) => {
        console.error('Error sending registration email:', e.message);
      });
      
      req.write(postData);
      req.end();
    } catch (emailError) {
      console.error('Failed to send registration email:', emailError);
      // Don't fail registration if email fails
    }
    
    res.status(201).json({
      success: true,
      userId: result.insertedId,
      message: 'Registration successful'
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ 
      message: 'Registration failed', 
      error: error.message,
      details: error.errInfo 
    });
  } finally {
    await client.close();
  }
});

// Add login endpoint
router.post('/login', async (req, res) => {
  const client = new MongoClient(dbUri);

  try {
    await client.connect();
    const db = client.db(dbName);
    const users = db.collection('users');

    // Find user by email
    const user = await users.findOne({ email: req.body.email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Verify password
    const validPassword = await bcrypt.compare(req.body.password, user.password);
    if (!validPassword) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Create session or token
    const sessionData = {
      userId: user._id,
      email: user.email,
      role: user.role,
      fullName: user.fullName
    };

    res.status(200).json({
      message: 'Login successful',
      user: sessionData
    });

  } catch (error) {
    res.status(500).json({ message: 'Login failed', error: error.message });
  } finally {
    await client.close();
  }
});

// Forgot password endpoint
router.post('/forgot-password', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ 
        message: 'Email is required' 
      });
    }
    
    // Find user by email
    const user = await db.collection('users').findOne({ email: email });
    
    // Always return success for security (don't reveal if email exists)
    if (!user) {
      return res.status(200).json({ 
        message: 'If an account with this email exists, you will receive a password reset link.' 
      });
    }
    
    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpiry = new Date(Date.now() + 3600000); // 1 hour from now
    
    // Save reset token to user
    await db.collection('users').updateOne(
      { _id: user._id },
      { 
        $set: { 
          resetPasswordToken: resetToken,
          resetPasswordExpiry: resetTokenExpiry,
          updatedAt: new Date()
        } 
      }
    );
    
    // Send password reset email
    try {
      const emailEndpoint = `${process.env.API_URL || 'http://backend.immosync.ch/api'}/email/send-password-reset`;
      
      const emailData = {
        userEmail: email,
        resetToken: resetToken
      };
      
      console.log('🔐 Attempting to send password reset email...');
      console.log('📧 Email endpoint:', emailEndpoint);
      console.log('📩 Email data:', JSON.stringify(emailData, null, 2));
      
      const http = require('http');
      const https = require('https');
      const url = require('url');
      
      const parsedUrl = url.parse(emailEndpoint);
      const httpModule = parsedUrl.protocol === 'https:' ? https : http;
      
      const postData = JSON.stringify(emailData);
      const options = {
        hostname: parsedUrl.hostname,
        port: parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 80),
        path: parsedUrl.path,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData)
        }
      };
      
      console.log('🌐 HTTP request options:', JSON.stringify(options, null, 2));
      
      const req = httpModule.request(options, (emailRes) => {
        let responseData = '';
        
        emailRes.on('data', (chunk) => {
          responseData += chunk;
        });
        
        emailRes.on('end', () => {
          console.log('📨 Password reset email response status:', emailRes.statusCode);
          console.log('📨 Password reset email response headers:', emailRes.headers);
          console.log('📨 Password reset email response body:', responseData);
          
          if (emailRes.statusCode >= 400) {
            console.error('❌ Password reset email failed with status:', emailRes.statusCode);
            console.error('❌ Response body:', responseData);
          } else {
            console.log('✅ Password reset email sent successfully');
          }
        });
      });
      
      req.on('error', (e) => {
        console.error('❌ Error sending password reset email:', e.message);
        console.error('❌ Full error:', e);
      });
      
      req.write(postData);
      req.end();
    } catch (emailError) {
      console.error('Failed to send password reset email:', emailError);
    }
    
    res.status(200).json({ 
      message: 'If an account with this email exists, you will receive a password reset link.' 
    });
    
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ message: 'Error processing forgot password request' });
  } finally {
    await client.close();
  }
});

// Reset password endpoint
router.post('/reset-password', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { token, newPassword } = req.body;
    
    if (!token || !newPassword) {
      return res.status(400).json({ 
        message: 'Reset token and new password are required' 
      });
    }
    
    if (newPassword.length < 6) {
      return res.status(400).json({ 
        message: 'Password must be at least 6 characters long' 
      });
    }
    
    // Find user with valid reset token
    const user = await db.collection('users').findOne({ 
      resetPasswordToken: token,
      resetPasswordExpiry: { $gt: new Date() }
    });
    
    if (!user) {
      return res.status(400).json({ 
        message: 'Invalid or expired reset token' 
      });
    }
    
    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update password and clear reset token
    await db.collection('users').updateOne(
      { _id: user._id },
      { 
        $set: { 
          password: hashedPassword,
          passwordChangedAt: new Date(),
          updatedAt: new Date()
        },
        $unset: {
          resetPasswordToken: 1,
          resetPasswordExpiry: 1
        }
      }
    );
    
    res.status(200).json({ 
      message: 'Password reset successfully' 
    });
    
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ message: 'Error resetting password' });
  } finally {
    await client.close();
  }
});

// Change password endpoint
router.patch('/change-password', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { userId, currentPassword, newPassword } = req.body;
    
    if (!userId || !currentPassword || !newPassword) {
      return res.status(400).json({ 
        message: 'Missing required fields: userId, currentPassword, newPassword' 
      });
    }
    
    // Find user
    const user = await db.collection('users')
      .findOne({ _id: new ObjectId(userId) });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Verify current password
    const bcrypt = require('bcryptjs');
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
    
    if (!isCurrentPasswordValid) {
      return res.status(400).json({ message: 'Current password is incorrect' });
    }
    
    // Hash new password
    const saltRounds = 10;
    const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);
    
    // Update password
    await db.collection('users').updateOne(
      { _id: new ObjectId(userId) },
      { 
        $set: { 
          password: hashedNewPassword,
          passwordChangedAt: new Date(),
          updatedAt: new Date()
        } 
      }
    );
    
    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({ message: 'Error changing password' });
  } finally {
    await client.close();
  }
});

module.exports = router;