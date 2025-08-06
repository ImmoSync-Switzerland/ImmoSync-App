const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');
const { triggerNotification } = require('./notifications');

// Get invitations for a user
router.get('/user/:userId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const userId = req.params.userId;
    
    // Find invitations for this user
    const invitations = await db.collection('invitations')
      .find({ 
        tenantId: userId,
        status: { $in: ['pending', 'accepted'] }
      })
      .sort({ createdAt: -1 })
      .toArray();
    
    // Populate property and landlord details
    const populatedInvitations = await Promise.all(
      invitations.map(async (invitation) => {
        const property = await db.collection('properties')
          .findOne({ _id: new ObjectId(invitation.propertyId) });
        
        const landlord = await db.collection('users')
          .findOne({ _id: new ObjectId(invitation.landlordId) });
        
        return {
          ...invitation,
          propertyAddress: property ? `${property.address.street}, ${property.address.city}` : 'Unknown Property',
          propertyRent: property ? property.rentAmount : 0,
          landlordName: landlord ? landlord.fullName : 'Unknown Landlord',
          landlordEmail: landlord ? landlord.email : '',
        };
      })
    );
    
    console.log(`Found ${populatedInvitations.length} invitations for user ${userId}`);
    res.json(populatedInvitations);
    
  } catch (error) {
    console.error('Error fetching invitations:', error);
    res.status(500).json({ message: 'Error fetching invitations' });
  } finally {
    await client.close();
  }
});

// Create a new invitation
router.post('/', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { propertyId, landlordId, tenantId, message } = req.body;
    
    // Check if invitation already exists
    const existingInvitation = await db.collection('invitations')
      .findOne({
        propertyId: propertyId,
        tenantId: tenantId,
        status: { $in: ['pending', 'accepted'] }
      });
    
    if (existingInvitation) {
      return res.status(400).json({ 
        message: 'Invitation already exists for this tenant and property' 
      });
    }
    
    // Create new invitation
    const invitation = {
      propertyId: propertyId,
      landlordId: landlordId,
      tenantId: tenantId,
      message: message || 'You have been invited to rent this property',
      status: 'pending',
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days from now
    };
    
    const result = await db.collection('invitations').insertOne(invitation);
    
    // Create a conversation for this invitation
    const conversation = {
      propertyId: propertyId,
      landlordId: landlordId,
      tenantId: tenantId,
      lastMessage: `Property invitation: ${message || 'You have been invited to rent this property'}`,
      lastMessageTime: new Date(),
      createdAt: new Date(),
      relatedInvitationId: result.insertedId.toString()
    };
    
    const conversationResult = await db.collection('conversations').insertOne(conversation);
    
    // Add initial message to the conversation
    const initialMessage = {
      conversationId: conversationResult.insertedId.toString(),
      senderId: landlordId,
      content: `Hi! I'd like to invite you to rent my property. ${message || 'Please let me know if you\'re interested!'}`,
      timestamp: new Date(),
      messageType: 'invitation'
    };
    
    await db.collection('messages').insertOne(initialMessage);
    
    // Trigger notification to tenant about property invitation
    try {
      const property = await db.collection('properties').findOne({ _id: new ObjectId(propertyId) });
      const propertyAddress = property ? `${property.address.street}, ${property.address.city}` : 'a property';
      
      await triggerNotification(
        tenantId,
        'property_invitation',
        'Property Invitation',
        `You have been invited to rent a property at ${propertyAddress}`,
        {
          propertyId: propertyId,
          landlordId: landlordId,
          invitationId: result.insertedId.toString(),
          conversationId: conversationResult.insertedId.toString(),
          propertyAddress: propertyAddress
        }
      );
    } catch (notifError) {
      console.error('Error sending invitation notification:', notifError);
      // Don't fail the request if notification fails
    }
    
    console.log(`Created invitation ${result.insertedId} for tenant ${tenantId}`);
    res.status(201).json({ 
      invitationId: result.insertedId,
      conversationId: conversationResult.insertedId,
      message: 'Invitation sent successfully' 
    });
    
  } catch (error) {
    console.error('Error creating invitation:', error);
    res.status(500).json({ message: 'Error creating invitation' });
  } finally {
    await client.close();
  }
});

// Accept an invitation
router.put('/:invitationId/accept', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const invitationId = req.params.invitationId;
    
    // Find and update the invitation
    const invitation = await db.collection('invitations')
      .findOneAndUpdate(
        { _id: new ObjectId(invitationId), status: 'pending' },
        { 
          $set: { 
            status: 'accepted',
            acceptedAt: new Date()
          }
        },
        { returnDocument: 'after' }
      );
    
    if (!invitation.value) {
      return res.status(404).json({ message: 'Invitation not found or already processed' });
    }
    
    // Add tenant to property
    await db.collection('properties').updateOne(
      { _id: new ObjectId(invitation.value.propertyId) },
      { 
        $addToSet: { tenantIds: invitation.value.tenantId },
        $set: { status: 'rented' }
      }
    );
    
    // Send acceptance message
    const conversation = await db.collection('conversations')
      .findOne({ relatedInvitationId: invitationId });
    
    if (conversation) {
      const acceptanceMessage = {
        conversationId: conversation._id.toString(),
        senderId: invitation.value.tenantId,
        content: 'Great! I accept your invitation. Looking forward to renting this property.',
        timestamp: new Date(),
        messageType: 'text'
      };
      
      await db.collection('messages').insertOne(acceptanceMessage);
      
      // Update conversation last message
      await db.collection('conversations').updateOne(
        { _id: conversation._id },
        {
          $set: {
            lastMessage: acceptanceMessage.content,
            lastMessageTime: new Date()
          }
        }
      );
    }
    
    // Trigger notification to landlord about invitation acceptance
    try {
      const property = await db.collection('properties').findOne({ _id: new ObjectId(invitation.value.propertyId) });
      const propertyAddress = property ? `${property.address.street}, ${property.address.city}` : 'your property';
      
      await triggerNotification(
        invitation.value.landlordId,
        'invitation_accepted',
        'Invitation Accepted',
        `Your tenant has accepted the invitation for ${propertyAddress}`,
        {
          propertyId: invitation.value.propertyId,
          tenantId: invitation.value.tenantId,
          invitationId: invitationId,
          propertyAddress: propertyAddress
        }
      );
    } catch (notifError) {
      console.error('Error sending invitation acceptance notification:', notifError);
      // Don't fail the request if notification fails
    }
    
    console.log(`Invitation ${invitationId} accepted`);
    res.json({ message: 'Invitation accepted successfully' });
    
  } catch (error) {
    console.error('Error accepting invitation:', error);
    res.status(500).json({ message: 'Error accepting invitation' });
  } finally {
    await client.close();
  }
});

// Decline an invitation
router.put('/:invitationId/decline', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const invitationId = req.params.invitationId;
    
    // Find and update the invitation
    const invitation = await db.collection('invitations')
      .findOneAndUpdate(
        { _id: new ObjectId(invitationId), status: 'pending' },
        { 
          $set: { 
            status: 'declined',
            declinedAt: new Date()
          }
        },
        { returnDocument: 'after' }
      );
    
    if (!invitation.value) {
      return res.status(404).json({ message: 'Invitation not found or already processed' });
    }
    
    // Send decline message if conversation exists
    const conversation = await db.collection('conversations')
      .findOne({ relatedInvitationId: invitationId });
    
    if (conversation) {
      const declineMessage = {
        conversationId: conversation._id.toString(),
        senderId: invitation.value.tenantId,
        content: 'Thank you for the invitation, but I have to decline at this time.',
        timestamp: new Date(),
        messageType: 'text'
      };
      
      await db.collection('messages').insertOne(declineMessage);
      
      // Update conversation last message
      await db.collection('conversations').updateOne(
        { _id: conversation._id },
        {
          $set: {
            lastMessage: declineMessage.content,
            lastMessageTime: new Date()
          }
        }
      );
    }
    
    console.log(`Invitation ${invitationId} declined`);
    res.json({ message: 'Invitation declined' });
    
  } catch (error) {
    console.error('Error declining invitation:', error);
    res.status(500).json({ message: 'Error declining invitation' });
  } finally {
    await client.close();
  }
});

module.exports = router;
