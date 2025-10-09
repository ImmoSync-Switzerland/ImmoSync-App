const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');
const { buildProfileImageUrl, buildInlineUserImageUrl } = require('../utils');
// Social auth helpers
const { OAuth2Client } = require('google-auth-library');
const jose = require('jose');

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || ''; // Optional enforcement
const APPLE_AUDIENCE = process.env.APPLE_CLIENT_ID || process.env.APPLE_SERVICE_ID || ''; // Apple client / service id

const googleClient = new OAuth2Client();

async function verifyGoogleIdToken(idToken) {
  const ticket = await googleClient.verifyIdToken({ idToken, audience: GOOGLE_CLIENT_ID || undefined });
  const payload = ticket.getPayload();
  return {
    email: payload.email,
    emailVerified: payload.email_verified,
    fullName: payload.name || [payload.given_name, payload.family_name].filter(Boolean).join(' ').trim(),
    providerId: payload.sub,
    picture: payload.picture
  };
}

let appleJWKS; // cached
async function getAppleJWKS() {
  if (!appleJWKS) {
    const jwksUri = 'https://appleid.apple.com/auth/keys';
    const resp = await fetch(jwksUri);
    const jwks = await resp.json();
    appleJWKS = jose.createLocalJWKSet(jwks);
  }
  return appleJWKS;
}

async function verifyAppleIdentityToken(idToken) {
  const JWKS = await getAppleJWKS();
  const { payload } = await jose.jwtVerify(idToken, JWKS, {
    issuer: 'https://appleid.apple.com',
    audience: APPLE_AUDIENCE || undefined
  });
  return {
    email: payload.email,
    emailVerified: payload.email_verified,
    fullName: payload.name || '', // Apple only returns name on first auth usually (handled client-side normally)
    providerId: payload.sub
  };
}

function computeMissingFields(userDoc) {
  const missing = [];
  // Required common fields
  if (!userDoc.fullName) missing.push('fullName');
  if (!userDoc.role) missing.push('role');
  if (!userDoc.phone) missing.push('phone');
  if (userDoc.isCompany === undefined) missing.push('isCompany');
  if (userDoc.isCompany === true) {
    if (!userDoc.companyName) missing.push('companyName');
    if (!userDoc.companyAddress) missing.push('companyAddress');
    // taxId optional
  } else if (userDoc.isCompany === false) {
    if (!userDoc.address) missing.push('address');
    if (!userDoc.birthDate) missing.push('birthDate');
  }
  return missing;
}

// Helper: normalize user document shape returned to clients
function shapeUser(userDoc, sessionToken, req) {
  if (!userDoc) return null;
  const inlineUrl = userDoc.profileImageInline ? buildInlineUserImageUrl(userDoc._id, req) : null;
  return {
    id: (userDoc._id && userDoc._id.toString()) || userDoc.id || userDoc.userId,
    email: userDoc.email || '',
    fullName: userDoc.fullName || '',
    role: userDoc.role || '',
    isAdmin: !!userDoc.isAdmin,
    isValidated: userDoc.isValidated !== false,
    phone: userDoc.phone || null,
    address: userDoc.address || null,
    birthDate: userDoc.birthDate ? new Date(userDoc.birthDate).toISOString() : null,
  profileImage: userDoc.profileImage || userDoc.providerPicture || null,
  profileImageUrl: inlineUrl || buildProfileImageUrl(userDoc.profileImage || userDoc.providerPicture, req),
    sessionToken: sessionToken || userDoc.sessionToken || null,
    createdAt: userDoc.createdAt || null,
    updatedAt: userDoc.updatedAt || null
  };
}

// GET /auth/me – mirror of users /me for frontend expectations (token in Authorization or cookie or query)
router.get('/me', async (req, res) => {
  const { MongoClient } = require('mongodb');
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    // Try headers, cookie, query param
    const rawAuth = req.headers['authorization'] || req.headers['Authorization'];
    let token = null;
    if (rawAuth && typeof rawAuth === 'string') {
      token = rawAuth.replace(/^Bearer\s+/i, '').trim();
    } else if (req.query.sessionToken) {
      token = String(req.query.sessionToken).trim();
    } else if (req.cookies && req.cookies.sessionToken) { // only if cookie-parser mounted upstream
      token = req.cookies.sessionToken;
    }
    if (!token) {
      return res.status(401).json({ success: false, message: 'Missing session token' });
    }
    const user = await db.collection('users').findOne({ sessionToken: token });
    if (!user) return res.status(401).json({ success: false, message: 'Invalid session token' });
  return res.json({ success: true, user: shapeUser(user, token, req) });
  } catch (e) {
    console.error('[auth/me] error', e);
    return res.status(500).json({ success: false, message: 'Server error' });
  } finally {
    await client.close();
  }
});

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

    // Issue (or rotate) session token
    const sessionToken = crypto.randomBytes(32).toString('hex');
    await users.updateOne({ _id: user._id }, { $set: { sessionToken, sessionTokenCreatedAt: new Date(), updatedAt: new Date() } });

  const shaped = shapeUser(user, sessionToken, req);
    res.status(200).json({
      success: true,
      message: 'Login successful',
      user: shaped
    });

  } catch (error) {
    res.status(500).json({ success: false, message: 'Login failed', error: error.message });
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

// Social login endpoint
router.post('/social-login', async (req, res) => {
  const { provider, idToken } = req.body;
  if (!provider || !idToken) {
    return res.status(400).json({ message: 'provider and idToken are required' });
  }

  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const users = db.collection('users');

    let verified;
    try {
      if (provider === 'google') {
        verified = await verifyGoogleIdToken(idToken);
      } else if (provider === 'apple') {
        verified = await verifyAppleIdentityToken(idToken);
      } else {
        return res.status(400).json({ message: 'Unsupported provider' });
      }
    } catch (e) {
      console.error('Token verification failed:', e);
      return res.status(401).json({ message: 'Invalid idToken' });
    }

    if (!verified.email) {
      return res.status(400).json({ message: 'Email claim missing from token' });
    }

    // Find by provider first
    let user = await users.findOne({ provider, providerId: verified.providerId });
    if (!user) {
      // fallback by email
      user = await users.findOne({ email: verified.email });
    }

    if (!user) {
      // Create partial user document
      const partialUser = {
        email: verified.email,
        fullName: verified.fullName || '',
        provider: provider,
        providerId: verified.providerId,
        providerPicture: verified.picture,
        isValidated: false,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      const insertResult = await users.insertOne(partialUser);
      user = { ...partialUser, _id: insertResult.insertedId };
    } else {
      // Ensure provider linkage is saved if missing
      if (!user.provider || !user.providerId) {
        await users.updateOne(
          { _id: user._id },
          { $set: { provider, providerId: verified.providerId, updatedAt: new Date() } }
        );
        user.provider = provider;
        user.providerId = verified.providerId;
      }
    }

    const missingFields = computeMissingFields(user);
    const needCompletion = missingFields.length > 0 || user.isValidated === false;

  if (!needCompletion) {
      // Ensure session token exists / rotate
      const sessionToken = crypto.randomBytes(32).toString('hex');
      await users.updateOne({ _id: user._id }, { $set: { sessionToken, sessionTokenCreatedAt: new Date(), updatedAt: new Date() } });
      return res.json({
        success: true,
        needCompletion: false,
  user: shapeUser(user, sessionToken, req)
      });
    }

    res.json({
      success: true,
      needCompletion: true,
      userId: user._id.toString(),
      missingFields
    });
  } catch (error) {
    console.error('Social login error:', error);
    res.status(500).json({ message: 'Social login failed', error: error.message });
  } finally {
    await client.close();
  }
});

// Social profile completion endpoint
router.post('/social-complete', async (req, res) => {
  const { userId, fullName, role, phone, isCompany, companyName, companyAddress, taxId, address, birthDate } = req.body;
  if (!userId) {
    return res.status(400).json({ message: 'userId is required' });
  }
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const users = db.collection('users');

    const user = await users.findOne({ _id: new ObjectId(userId) });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const update = { updatedAt: new Date() };
    if (fullName !== undefined) update.fullName = fullName;
    if (role !== undefined) update.role = role.toLowerCase();
    if (phone !== undefined) update.phone = phone;
    if (isCompany !== undefined) update.isCompany = isCompany;
    if (isCompany) {
      if (companyName !== undefined) update.companyName = companyName;
      if (companyAddress !== undefined) update.companyAddress = companyAddress;
      if (taxId !== undefined) update.taxId = taxId;
      // Clear individual fields if switching
      update.address = undefined;
      update.birthDate = undefined;
    } else if (isCompany === false) {
      if (address !== undefined) update.address = address;
      if (birthDate) update.birthDate = new Date(birthDate);
      // Clear company fields if switching
      update.companyName = undefined;
      update.companyAddress = undefined;
      update.taxId = undefined;
    }

    // Apply update
    await users.updateOne({ _id: user._id }, { $set: update, $unset: Object.fromEntries(Object.entries(update).filter(([k,v]) => v === undefined).map(([k]) => [k, ''])) });

    const updatedUser = await users.findOne({ _id: user._id });
    const missing = computeMissingFields(updatedUser);
    const needCompletion = missing.length > 0;
    if (!needCompletion) {
      await users.updateOne({ _id: user._id }, { $set: { isValidated: true, updatedAt: new Date() } });
    }

    if (needCompletion) {
      return res.status(400).json({ message: 'Still missing required fields', missing });
    }

    // Issue session token for completed profile
    const sessionToken = crypto.randomBytes(32).toString('hex');
    await users.updateOne({ _id: user._id }, { $set: { sessionToken, sessionTokenCreatedAt: new Date(), updatedAt: new Date() } });

  res.json({
      success: true,
  user: shapeUser(updatedUser, sessionToken, req)
    });
  } catch (error) {
    console.error('Social completion error:', error);
    res.status(500).json({ message: 'Profile completion failed', error: error.message });
  } finally {
    await client.close();
  }
});

module.exports = router;