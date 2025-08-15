const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');

// Get invitations for a user
router.get('/user/:userId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const userId = req.params.userId;
    
    // Find invitations for this user - both as tenant and landlord
    const invitations = await db.collection('invitations')
      .find({ 
        $or: [
          { tenantId: userId },     // Invitations received as tenant
          { landlordId: userId }    // Invitations sent as landlord
        ],
        status: { $in: ['pending', 'accepted', 'declined'] }
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
        
        const tenant = await db.collection('users')
          .findOne({ _id: new ObjectId(invitation.tenantId) });
        
        return {
          ...invitation,
          propertyAddress: property ? `${property.address.street}, ${property.address.city}` : 'Unknown Property',
          propertyRent: property ? property.rentAmount : 0,
          landlordName: landlord ? landlord.fullName : 'Unknown Landlord',
          landlordEmail: landlord ? landlord.email : '',
          tenantName: tenant ? tenant.fullName : 'Unknown Tenant',
          tenantEmail: tenant ? tenant.email : '',
        };
      })
    );
    
    console.log(`Found ${populatedInvitations.length} invitations for user ${userId} (as tenant and landlord)`);
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
    
    console.log(`Created invitation ${result.insertedId} for tenant ${tenantId}`);
    res.status(201).json({ 
      success: true,
      invitationId: result.insertedId.toString(),
      conversationId: conversationResult.insertedId.toString(),
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
    
    // First find the invitation to ensure it exists and is pending
    const existingInvitation = await db.collection('invitations')
      .findOne({ _id: new ObjectId(invitationId), status: 'pending' });
    
    if (!existingInvitation) {
      return res.status(404).json({ message: 'Invitation not found or already processed' });
    }
    
    // Update the invitation status
    const invitationUpdateResult = await db.collection('invitations')
      .updateOne(
        { _id: new ObjectId(invitationId) },
        { 
          $set: { 
            status: 'accepted',
            acceptedAt: new Date()
          }
        }
      );
    
    if (invitationUpdateResult.modifiedCount === 0) {
      return res.status(500).json({ message: 'Failed to update invitation status' });
    }
    
    console.log(`Successfully updated invitation ${invitationId} to accepted status`);
    
    // Add tenant to property
    console.log(`Attempting to add tenant ${existingInvitation.tenantId} to property ${existingInvitation.propertyId}`);
    console.log(`Property ID type: ${typeof existingInvitation.propertyId}`);
    console.log(`Tenant ID type: ${typeof existingInvitation.tenantId}`);
    
    try {
      const propertyUpdateResult = await db.collection('properties').updateOne(
        { _id: new ObjectId(existingInvitation.propertyId) },
        { 
          $addToSet: { tenantIds: existingInvitation.tenantId },
          $set: { status: 'rented' }
        }
      );
      
      console.log(`Property update result:`, {
        acknowledged: propertyUpdateResult.acknowledged,
        matchedCount: propertyUpdateResult.matchedCount,
        modifiedCount: propertyUpdateResult.modifiedCount
      });
      
      if (propertyUpdateResult.matchedCount === 0) {
        console.error(`❌ Property ${existingInvitation.propertyId} not found during update!`);
        return res.status(500).json({ message: 'Property not found during tenant assignment' });
      }
      
      if (propertyUpdateResult.modifiedCount === 0) {
        console.log(`⚠️ Property ${existingInvitation.propertyId} was not modified - tenant might already be assigned`);
      }
      
      // Verify the property was updated correctly
      const updatedProperty = await db.collection('properties')
        .findOne({ _id: new ObjectId(existingInvitation.propertyId) });
      console.log(`Updated property tenantIds:`, updatedProperty?.tenantIds);
      console.log(`Updated property status:`, updatedProperty?.status);
      
      // Double-check if tenant was actually added
      if (updatedProperty && updatedProperty.tenantIds && updatedProperty.tenantIds.includes(existingInvitation.tenantId)) {
        console.log(`✅ Tenant ${existingInvitation.tenantId} successfully added to property`);
      } else {
        console.error(`❌ Tenant ${existingInvitation.tenantId} was NOT added to property despite update operation`);
        console.error(`Current tenantIds: [${updatedProperty?.tenantIds?.join(', ') || 'empty'}]`);
        return res.status(500).json({ message: 'Failed to assign tenant to property' });
      }
      
    } catch (propertyError) {
      console.error('❌ Error updating property:', propertyError);
      return res.status(500).json({ message: 'Error updating property with tenant assignment' });
    }
    
    // Send acceptance message
    const conversation = await db.collection('conversations')
      .findOne({ relatedInvitationId: invitationId });
    
    if (conversation) {
      const acceptanceMessage = {
        conversationId: conversation._id.toString(),
        senderId: existingInvitation.tenantId,
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
