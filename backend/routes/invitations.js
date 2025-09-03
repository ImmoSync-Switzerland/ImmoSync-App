const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');
const notifications = require('./notifications');

// Get invitations for a user
router.get('/user/:userId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const userId = req.params.userId;
    
    // Find invitations for this user - both as tenant and landlord
    // Handle both string and ObjectId formats for tenantId/landlordId
    const invitations = await db.collection('invitations')
      .find({ 
        $or: [
          { tenantId: userId },                    // String format
          { tenantId: new ObjectId(userId) },      // ObjectId format
          { landlordId: userId },                  // String format
          { landlordId: new ObjectId(userId) }     // ObjectId format
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
        
        // Handle empty tenantId gracefully
        let tenant = null;
        if (invitation.tenantId && ObjectId.isValid(invitation.tenantId)) {
          tenant = await db.collection('users')
            .findOne({ _id: new ObjectId(invitation.tenantId) });
        }
        
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
    
    // Debug logging
    console.log('=== INVITATION CREATION DEBUG ===');
    console.log('Full request body:', JSON.stringify(req.body, null, 2));
    console.log('Extracted tenantId:', tenantId);
    console.log('TenantId type:', typeof tenantId);
    console.log('TenantId length:', tenantId ? tenantId.length : 'null/undefined');
    console.log('================================');
    
    // Validate required fields
    if (!propertyId || !landlordId || !tenantId) {
      console.error('Missing required fields:', { propertyId, landlordId, tenantId });
      return res.status(400).json({ 
        message: 'Missing required fields: propertyId, landlordId, and tenantId are required' 
      });
    }
    
    // Validate ObjectId formats
    if (!ObjectId.isValid(propertyId) || !ObjectId.isValid(landlordId) || !ObjectId.isValid(tenantId)) {
      console.error('Invalid ObjectId format:', { propertyId, landlordId, tenantId });
      return res.status(400).json({ 
        message: 'Invalid ID format - all IDs must be valid ObjectIds' 
      });
    }
    
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

    // Notify tenant of invitation (log outcome for debugging missing push tokens)
    try {
      const notifOutcome = await notifications.sendDomainNotification(tenantId, {
        title: 'Property Invitation',
        body: 'You have been invited to a property',
        type: 'invitation_created',
        data: { invitationId: result.insertedId.toString(), propertyId }
      });
      console.log('[Invitation][Create] Notification outcome:', notifOutcome);
    } catch (e) {
      console.error('[Invitation][Create] Failed sending notification:', e.message);
    }
    
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
    if (!ObjectId.isValid(invitationId)) {
      return res.status(400).json({ message: 'Invalid invitation ID format' });
    }
    
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
    
    // Convert tenantId to string to match schema validation requirements
    const tenantIdString = existingInvitation.tenantId.toString();
    console.log(`Tenant ID as string: ${tenantIdString}`);
    
    let updatedProperty; 
    try {
      // Pre-normalize property document if landlordId stored as ObjectId to string
      const propertiesCol = db.collection('properties');
      const propFilter = { _id: new ObjectId(existingInvitation.propertyId) };
      const currentProperty = await propertiesCol.findOne(propFilter);
      if (currentProperty) {
        const normalizationUpdates = {};
        if (currentProperty.landlordId && typeof currentProperty.landlordId !== 'string') {
          normalizationUpdates.landlordId = currentProperty.landlordId.toString();
        }
        if (Array.isArray(currentProperty.tenantIds)) {
          const coerced = currentProperty.tenantIds.map(t => t && typeof t !== 'string' ? t.toString() : t).filter(Boolean);
          // Only apply if changed
            if (JSON.stringify(coerced) !== JSON.stringify(currentProperty.tenantIds)) {
              normalizationUpdates.tenantIds = coerced;
            }
        }
        if (Object.keys(normalizationUpdates).length) {
          normalizationUpdates.updatedAt = new Date();
          await propertiesCol.updateOne(propFilter, { $set: normalizationUpdates }, { bypassDocumentValidation: true });
          console.log('[Invitation][Accept] Normalized property document for schema compliance');
        }
      }
      const propertyUpdateResult = await db.collection('properties').updateOne(
        { _id: new ObjectId(existingInvitation.propertyId) },
        { 
          $addToSet: { tenantIds: tenantIdString },
          $set: { status: 'rented', updatedAt: new Date() }
        },
        { bypassDocumentValidation: true }
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
      updatedProperty = await db.collection('properties')
        .findOne({ _id: new ObjectId(existingInvitation.propertyId) });
      console.log(`Updated property tenantIds:`, updatedProperty?.tenantIds);
      console.log(`Updated property status:`, updatedProperty?.status);
      
      // Double-check if tenant was actually added
      if (updatedProperty && updatedProperty.tenantIds && updatedProperty.tenantIds.includes(tenantIdString)) {
        console.log(`✅ Tenant ${tenantIdString} successfully added to property`);
      } else {
        console.error(`❌ Tenant ${tenantIdString} not present after initial $addToSet. Attempting fallback force-set.`);
        const existingList = Array.isArray(updatedProperty?.tenantIds) ? updatedProperty.tenantIds : [];
        if (!existingList.includes(tenantIdString)) existingList.push(tenantIdString);
  await propertiesCol.updateOne(propFilter, { $set: { tenantIds: existingList, status: 'rented', updatedAt: new Date() } }, { bypassDocumentValidation: true });
        updatedProperty = await propertiesCol.findOne(propFilter);
        console.log('[Invitation][Accept][Fallback] tenantIds now:', updatedProperty?.tenantIds);
        if (!updatedProperty?.tenantIds?.includes(tenantIdString)) {
          console.error('❌ Fallback assignment failed to persist tenantId. Aborting.');
          return res.status(500).json({ message: 'Failed to assign tenant to property (fallback)' });
        } else {
          console.log(`✅ Tenant ${tenantIdString} added via fallback force-set.`);
        }
      }
      
    } catch (propertyError) {
      console.error('❌ Error updating property:', propertyError);
      if (propertyError && propertyError.code === 121) {
        // Validation failure fallback
        try {
          console.log('[Invitation][Accept][Fallback] Schema validation failed. Sanitizing property document.');
          const propertiesCol = db.collection('properties');
          const propFilter = { _id: new ObjectId(existingInvitation.propertyId) };
          const rawProp = await propertiesCol.findOne(propFilter);
          if (!rawProp) {
            return res.status(500).json({ message: 'Property not found during fallback repair' });
          }
          // Debug dump of problematic document (types)
          try {
            console.log('[Invitation][Accept][Fallback][DebugDoc]', JSON.stringify({
              _id: rawProp._id.toString(),
              landlordId: { value: rawProp.landlordId, type: typeof rawProp.landlordId },
              status: rawProp.status,
              rentAmount: { value: rawProp.rentAmount, type: typeof rawProp.rentAmount },
              hasDetails: !!rawProp.details,
              details: rawProp.details ? {
                size: { value: rawProp.details.size, type: typeof rawProp.details.size },
                rooms: { value: rawProp.details.rooms, type: typeof rawProp.details.rooms },
                amenitiesType: rawProp.details.amenities ? typeof rawProp.details.amenities : 'undefined'
              } : null,
              addressKeys: rawProp.address ? Object.keys(rawProp.address) : [],
              tenantIdsSample: Array.isArray(rawProp.tenantIds) ? rawProp.tenantIds.slice(0,5) : rawProp.tenantIds,
            }, null, 2));
          } catch(e) {}
          const allowedStatus = ['available','rented','maintenance'];
          const sanitized = {
            _id: rawProp._id,
            landlordId: rawProp.landlordId ? rawProp.landlordId.toString() : '',
            address: rawProp.address || { street: '', city: '', postalCode: '', country: '' },
            status: allowedStatus.includes(rawProp.status) ? rawProp.status : 'available',
            rentAmount: typeof rawProp.rentAmount === 'number' ? rawProp.rentAmount : 0,
            details: {
              size: (rawProp.details && typeof rawProp.details.size === 'number') ? rawProp.details.size : 0,
              rooms: (rawProp.details && typeof rawProp.details.rooms === 'number') ? rawProp.details.rooms : 0,
              amenities: (rawProp.details && Array.isArray(rawProp.details.amenities)) ? rawProp.details.amenities.filter(a => typeof a === 'string') : []
            },
            imageUrls: Array.isArray(rawProp.imageUrls) ? rawProp.imageUrls.filter(u => typeof u === 'string') : [],
            tenantIds: Array.isArray(rawProp.tenantIds) ? rawProp.tenantIds.map(t => t && typeof t !== 'string' ? t.toString() : t).filter(Boolean) : [],
            outstandingPayments: typeof rawProp.outstandingPayments === 'number' ? rawProp.outstandingPayments : 0,
            createdAt: rawProp.createdAt instanceof Date ? rawProp.createdAt : new Date(),
            updatedAt: new Date()
          };
          await propertiesCol.replaceOne(propFilter, sanitized, { bypassDocumentValidation: true });
          console.log('[Invitation][Accept][Fallback] Property sanitized. Retrying tenant add.');
          await propertiesCol.updateOne(propFilter, { $addToSet: { tenantIds: tenantIdString }, $set: { status: 'rented', updatedAt: new Date() } }, { bypassDocumentValidation: true });
          updatedProperty = await propertiesCol.findOne(propFilter);
          if (!updatedProperty.tenantIds.includes(tenantIdString)) {
            return res.status(500).json({ message: 'Fallback repair failed to add tenant' });
          }
          console.log('[Invitation][Accept][Fallback] Success after sanitize. tenantIds=', updatedProperty.tenantIds);
        } catch (repairErr) {
          console.error('[Invitation][Accept][Fallback] Repair failed:', repairErr);
          return res.status(500).json({ message: 'Error updating property with tenant assignment (after fallback)' });
        }
      } else {
        return res.status(500).json({ message: 'Error updating property with tenant assignment' });
      }
    }
    
    // Ensure user document has propertyId set (helpful for other lookups)
    try {
      await db.collection('users').updateOne(
        { _id: new ObjectId(existingInvitation.tenantId) },
        { $set: { propertyId: new ObjectId(existingInvitation.propertyId), updatedAt: new Date() } }
      );
    } catch (e) {
      console.error('[Invitation][Accept] Failed to update user with propertyId:', e.message);
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
    
    // Send notifications to landlord & tenant confirming acceptance
    try {
      await notifications.sendDomainNotification(existingInvitation.landlordId, {
        title: 'Invitation Accepted',
        body: 'A tenant accepted your property invitation.',
        type: 'invitation_accepted',
        data: { invitationId, propertyId: existingInvitation.propertyId }
      });
    } catch (e) {
      console.error('[Invitation][Accept] Failed notifying landlord:', e.message);
    }
    try {
      await notifications.sendDomainNotification(existingInvitation.tenantId, {
        title: 'Invitation Accepted',
        body: 'You have successfully accepted the property invitation.',
        type: 'invitation_accept_confirmation',
        data: { invitationId, propertyId: existingInvitation.propertyId }
      });
    } catch (e) {
      console.error('[Invitation][Accept] Failed notifying tenant:', e.message);
    }

    // Return enriched response
    const refreshedInvitation = await db.collection('invitations').findOne({ _id: new ObjectId(invitationId) });
    // Also fetch updated tenant user (with propertyId) for frontend immediate state update
    let updatedTenantUser = null;
    try {
      updatedTenantUser = await db.collection('users').findOne({ _id: new ObjectId(existingInvitation.tenantId) });
      if (updatedTenantUser && updatedTenantUser.propertyId) {
        updatedTenantUser.propertyId = updatedTenantUser.propertyId.toString();
      }
    } catch (e) {
      console.error('[Invitation][Accept] Failed fetching updated tenant user:', e.message);
    }
    console.log(`Invitation ${invitationId} accepted`);
    res.json({ 
      message: 'Invitation accepted successfully',
      invitation: refreshedInvitation,
      property: updatedProperty,
      tenantUser: updatedTenantUser
    });
    
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

// Send email invitation to tenant
router.post('/email-invite', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { propertyId, landlordId, tenantEmail, message } = req.body;
    
    if (!propertyId || !landlordId || !tenantEmail) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    // Validate ObjectId formats
    if (!ObjectId.isValid(propertyId) || !ObjectId.isValid(landlordId)) {
      return res.status(400).json({ message: 'Invalid ID format' });
    }
    
    // Get property and landlord details
    const property = await db.collection('properties')
      .findOne({ _id: new ObjectId(propertyId) });
    
    const landlord = await db.collection('users')
      .findOne({ _id: new ObjectId(landlordId) });
    
    if (!property || !landlord) {
      return res.status(404).json({ message: 'Property or landlord not found' });
    }
    
    // Check if user with this email exists
    let tenant = await db.collection('users')
      .findOne({ email: tenantEmail });
    
    let tenantId = null;
    
    if (!tenant) {
      // User doesn't exist - return error as tenant needs a database ID
      return res.status(404).json({ 
        message: 'Cannot send invitation: User with this email address does not exist in the system',
        tenantEmail: tenantEmail
      });
    }
    
    // User exists, create direct invitation
    tenantId = tenant._id.toString();
    
    const invitation = {
      propertyId: new ObjectId(propertyId),
      landlordId: new ObjectId(landlordId),
      tenantId: new ObjectId(tenantId),
      message: message || 'Sie wurden eingeladen, diese Immobilie zu mieten.',
      status: 'pending',
      createdAt: new Date(),
      updatedAt: new Date(),
      invitationType: 'email'
    };
    
    await db.collection('invitations').insertOne(invitation);
    
    // TODO: Send push notification to existing user
    console.log(`Invitation sent to existing user: ${tenantEmail}`);
    
    // TODO: Send actual email notification
    // This would integrate with an email service like SendGrid, Mailgun, etc.
    
    res.status(201).json({ 
      message: 'Invitation sent successfully',
      recipientExists: true,
      tenantEmail: tenantEmail
    });
    
  } catch (error) {
    console.error('Error sending email invitation:', error);
    res.status(500).json({ message: 'Error sending invitation' });
  } finally {
    await client.close();
  }
});

module.exports = router;
