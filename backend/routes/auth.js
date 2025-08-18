const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { MongoClient } = require('mongodb');
const { dbUri, dbName } = require('../config');
const { sendVerificationEmail } = require('./email');

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

    // Check if email already exists
    const existingUser = await db.collection('users').findOne({ email });
    if (existingUser) {
      return res.status(400).json({ 
        message: 'Registration failed', 
        error: 'Email already registered' 
      });
    }

    // Generate email verification token
    const verificationToken = jwt.sign(
      { email: email, type: 'email-verification' }, 
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    // Create user document with enhanced fields
    const newUser = {
      email: email,
      password: await bcrypt.hash(password, 10),
      fullName: fullName,
      role: role.toLowerCase(), // Ensure lowercase for enum match
      phone: phone,
      isCompany: isCompany || false,
      isAdmin: false,
      isValidated: false, // User must verify email first
      emailVerified: false,
      verificationToken: verificationToken,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    // Add company-specific fields
    if (isCompany) {
      newUser.companyName = companyName;
      newUser.companyAddress = companyAddress;
      newUser.taxId = taxId;
      // Companies don't have birth dates, use a placeholder date
      newUser.birthDate = new Date('1900-01-01');
    } else {
      newUser.address = address;
      // Always set birthDate, use placeholder if not provided
      newUser.birthDate = birthDate ? new Date(birthDate) : new Date('1900-01-01');
    }

    // Log document for verification
    console.log('Attempting to insert user:', newUser);

    const result = await db.collection('users').insertOne(newUser);
    
    // Update the verification token with the actual user ID
    const finalVerificationToken = jwt.sign(
      { userId: result.insertedId.toString(), type: 'email-verification' }, 
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );
    
    // Update user with the final verification token
    await db.collection('users').updateOne(
      { _id: result.insertedId },
      { $set: { verificationToken: finalVerificationToken } }
    );
    
    // Send verification email
    try {
      await sendVerificationEmail(email, finalVerificationToken);
      console.log('Verification email sent to:', email);
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError);
      // Don't fail registration if email fails, just log it
    }
    
    res.status(201).json({
      success: true,
      userId: result.insertedId,
      message: 'Registration successful! Please check your email to verify your account.',
      emailSent: true
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

    // Check if email is verified
    if (!user.emailVerified) {
      return res.status(403).json({ 
        message: 'Please verify your email address before logging in',
        emailVerificationRequired: true
      });
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