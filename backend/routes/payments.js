const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');

// Initialize Stripe only if the secret key is available
let stripe = null;
if (process.env.STRIPE_SECRET_KEY) {
  stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
} else {
  console.warn('Warning: STRIPE_SECRET_KEY not found in environment variables');
}

// Helper function to check if Stripe is available
function requireStripe(res) {
  if (!stripe) {
    return res.status(500).json({ 
      message: 'Stripe not configured. Please add STRIPE_SECRET_KEY to environment variables.' 
    });
  }
  return null;
}

// Get payments by tenant
router.get('/tenant/:tenantId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const tenantId = req.params.tenantId;
    
    const payments = await db.collection('payments')
      .find({ tenantId })
      .sort({ date: -1 })
      .toArray();
    
    res.json(payments);
  } catch (error) {
    console.error('Error fetching payments by tenant:', error);
    res.status(500).json({ message: 'Error fetching payments' });
  } finally {
    await client.close();
  }
});

// Get payments by property
router.get('/property/:propertyId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const propertyId = req.params.propertyId;
    
    const payments = await db.collection('payments')
      .find({ propertyId })
      .sort({ date: -1 })
      .toArray();
    
    res.json(payments);
  } catch (error) {
    console.error('Error fetching payments by property:', error);
    res.status(500).json({ message: 'Error fetching payments' });
  } finally {
    await client.close();
  }
});

// Get payments by landlord
router.get('/landlord/:landlordId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const landlordId = req.params.landlordId;
    
    // Get all properties owned by landlord first
    const properties = await db.collection('properties')
      .find({ landlordId })
      .toArray();
    
    const propertyIds = properties.map(p => p._id.toString());
    
    const payments = await db.collection('payments')
      .find({ propertyId: { $in: propertyIds } })
      .sort({ date: -1 })
      .toArray();
    
    res.json(payments);
  } catch (error) {
    console.error('Error fetching payments by landlord:', error);
    res.status(500).json({ message: 'Error fetching payments' });
  } finally {
    await client.close();
  }
});

// Get payment by ID
router.get('/:id', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const paymentId = req.params.id;
    
    const payment = await db.collection('payments')
      .findOne({ _id: new ObjectId(paymentId) });
    
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    
    res.json(payment);
  } catch (error) {
    console.error('Error fetching payment:', error);
    res.status(500).json({ message: 'Error fetching payment' });
  } finally {
    await client.close();
  }
});

// Create new payment
router.post('/', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { 
      propertyId, 
      tenantId, 
      landlordId,
      amount, 
      type, 
      paymentMethod, 
      notes,
      dueDate,
      isRecurring = false,
      recurringInterval = null
    } = req.body;
    
    // Validate required fields
    if (!propertyId || !tenantId || !amount || !type) {
      return res.status(400).json({ 
        message: 'Missing required fields: propertyId, tenantId, amount, type' 
      });
    }
    
    const payment = {
      propertyId,
      tenantId,
      landlordId,
      amount: parseFloat(amount),
      type, // 'rent', 'deposit', 'utilities', 'late_fee', etc.
      paymentMethod: paymentMethod || 'pending', // 'stripe', 'bank_transfer', 'cash', 'pending'
      status: 'pending', // 'pending', 'processing', 'completed', 'failed', 'cancelled'
      date: new Date(),
      dueDate: dueDate ? new Date(dueDate) : null,
      notes: notes || '',
      isRecurring,
      recurringInterval, // 'monthly', 'quarterly', 'yearly'
      stripePaymentIntentId: null,
      bankTransferDetails: null,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    const result = await db.collection('payments').insertOne(payment);
    
    const createdPayment = await db.collection('payments')
      .findOne({ _id: result.insertedId });
    
    res.status(201).json(createdPayment);
  } catch (error) {
    console.error('Error creating payment:', error);
    res.status(500).json({ message: 'Error creating payment' });
  } finally {
    await client.close();
  }
});

// Process Stripe payment
router.post('/:id/process-stripe', async (req, res) => {
  // Check if Stripe is available
  const stripeError = requireStripe(res);
  if (stripeError) return;
  
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const paymentId = req.params.id;
    const { paymentMethodId, customerEmail } = req.body;
    
    // Get payment details
    const payment = await db.collection('payments')
      .findOne({ _id: new ObjectId(paymentId) });
    
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    
    // Create Stripe payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(payment.amount * 100), // Convert to cents
      currency: 'eur', // or 'chf' for Swiss Francs
      payment_method: paymentMethodId,
      confirmation_method: 'manual',
      confirm: true,
      metadata: {
        paymentId: paymentId,
        propertyId: payment.propertyId,
        tenantId: payment.tenantId,
        type: payment.type
      },
      receipt_email: customerEmail
    });
    
    // Update payment with Stripe details
    await db.collection('payments').updateOne(
      { _id: new ObjectId(paymentId) },
      {
        $set: {
          paymentMethod: 'stripe',
          status: paymentIntent.status === 'succeeded' ? 'completed' : 'processing',
          stripePaymentIntentId: paymentIntent.id,
          updatedAt: new Date()
        }
      }
    );
    
    res.json({
      success: true,
      paymentIntent: {
        id: paymentIntent.id,
        status: paymentIntent.status,
        client_secret: paymentIntent.client_secret
      }
    });
    
  } catch (error) {
    console.error('Error processing Stripe payment:', error);
    res.status(500).json({ 
      message: 'Error processing payment',
      error: error.message 
    });
  } finally {
    await client.close();
  }
});

// Process bank transfer
router.post('/:id/process-bank-transfer', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const paymentId = req.params.id;
    const { 
      bankAccount, 
      referenceNumber, 
      transferDate,
      bankName 
    } = req.body;
    
    // Get payment details
    const payment = await db.collection('payments')
      .findOne({ _id: new ObjectId(paymentId) });
    
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    
    // Update payment with bank transfer details
    const bankTransferDetails = {
      bankAccount,
      referenceNumber,
      transferDate: transferDate ? new Date(transferDate) : new Date(),
      bankName,
      verificationStatus: 'pending' // 'pending', 'verified', 'rejected'
    };
    
    await db.collection('payments').updateOne(
      { _id: new ObjectId(paymentId) },
      {
        $set: {
          paymentMethod: 'bank_transfer',
          status: 'processing', // Will be updated to 'completed' after manual verification
          bankTransferDetails,
          updatedAt: new Date()
        }
      }
    );
    
    res.json({
      success: true,
      message: 'Bank transfer details recorded. Payment will be verified manually.',
      referenceNumber
    });
    
  } catch (error) {
    console.error('Error processing bank transfer:', error);
    res.status(500).json({ message: 'Error processing bank transfer' });
  } finally {
    await client.close();
  }
});

// Update payment
router.put('/:id', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const paymentId = req.params.id;
    const updateData = { ...req.body };
    
    // Remove fields that shouldn't be updated directly
    delete updateData._id;
    delete updateData.createdAt;
    updateData.updatedAt = new Date();
    
    const result = await db.collection('payments').updateOne(
      { _id: new ObjectId(paymentId) },
      { $set: updateData }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    
    const updatedPayment = await db.collection('payments')
      .findOne({ _id: new ObjectId(paymentId) });
    
    res.json(updatedPayment);
  } catch (error) {
    console.error('Error updating payment:', error);
    res.status(500).json({ message: 'Error updating payment' });
  } finally {
    await client.close();
  }
});

// Cancel payment
router.patch('/:id/cancel', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const paymentId = req.params.id;
    const { reason } = req.body;
    
    const payment = await db.collection('payments')
      .findOne({ _id: new ObjectId(paymentId) });
    
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    
    // If it's a Stripe payment, cancel the payment intent
    if (payment.stripePaymentIntentId && payment.status !== 'completed') {
      try {
        await stripe.paymentIntents.cancel(payment.stripePaymentIntentId);
      } catch (stripeError) {
        console.error('Error cancelling Stripe payment:', stripeError);
      }
    }
    
    // Update payment status
    await db.collection('payments').updateOne(
      { _id: new ObjectId(paymentId) },
      {
        $set: {
          status: 'cancelled',
          cancellationReason: reason || 'Cancelled by user',
          cancelledAt: new Date(),
          updatedAt: new Date()
        }
      }
    );
    
    const updatedPayment = await db.collection('payments')
      .findOne({ _id: new ObjectId(paymentId) });
    
    res.json(updatedPayment);
  } catch (error) {
    console.error('Error cancelling payment:', error);
    res.status(500).json({ message: 'Error cancelling payment' });
  } finally {
    await client.close();
  }
});

// Delete payment
router.delete('/:id', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const paymentId = req.params.id;
    
    const result = await db.collection('payments').deleteOne(
      { _id: new ObjectId(paymentId) }
    );
    
    if (result.deletedCount === 0) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    
    res.json({ message: 'Payment deleted successfully' });
  } catch (error) {
    console.error('Error deleting payment:', error);
    res.status(500).json({ message: 'Error deleting payment' });
  } finally {
    await client.close();
  }
});

// Get payment receipt
router.get('/:paymentId/receipt', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const paymentId = req.params.paymentId;
    
    const payment = await db.collection('payments')
      .findOne({ _id: new ObjectId(paymentId) });
    
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    
    // Get property and tenant details for receipt
    const property = await db.collection('properties')
      .findOne({ _id: new ObjectId(payment.propertyId) });
    
    const tenant = await db.collection('users')
      .findOne({ _id: new ObjectId(payment.tenantId) });
    
    const landlord = await db.collection('users')
      .findOne({ _id: new ObjectId(payment.landlordId) });
    
    const receipt = {
      payment,
      property: property ? {
        address: property.address,
        id: property._id
      } : null,
      tenant: tenant ? {
        name: tenant.fullName,
        email: tenant.email
      } : null,
      landlord: landlord ? {
        name: landlord.fullName,
        email: landlord.email
      } : null,
      generatedAt: new Date()
    };
    
    res.json(receipt);
  } catch (error) {
    console.error('Error generating receipt:', error);
    res.status(500).json({ message: 'Error generating receipt' });
  } finally {
    await client.close();
  }
});

// Stripe webhook handler for payment status updates
router.post('/stripe-webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;
  
  let event;
  
  // For development: allow webhook without secret verification
  if (!endpointSecret) {
    console.warn('Warning: Running webhook without signature verification (development mode)');
    try {
      event = JSON.parse(req.body);
    } catch (err) {
      console.error('Invalid JSON in webhook body:', err.message);
      return res.status(400).send('Invalid JSON');
    }
  } else {
    try {
      event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
    } catch (err) {
      console.error('Webhook signature verification failed:', err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }
  }
  
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    // Handle the event
    switch (event.type) {
      case 'payment_intent.succeeded':
        const paymentIntent = event.data.object;
        const paymentId = paymentIntent.metadata.paymentId;
        
        if (paymentId) {
          await db.collection('payments').updateOne(
            { _id: new ObjectId(paymentId) },
            {
              $set: {
                status: 'completed',
                completedAt: new Date(),
                updatedAt: new Date()
              }
            }
          );
        }
        break;
        
      case 'payment_intent.payment_failed':
        const failedPayment = event.data.object;
        const failedPaymentId = failedPayment.metadata.paymentId;
        
        if (failedPaymentId) {
          await db.collection('payments').updateOne(
            { _id: new ObjectId(failedPaymentId) },
            {
              $set: {
                status: 'failed',
                failureReason: failedPayment.last_payment_error?.message || 'Payment failed',
                updatedAt: new Date()
              }
            }
          );
        }
        break;
        
      default:
        console.log(`Unhandled event type ${event.type}`);
    }
    
    res.json({ received: true });
  } catch (error) {
    console.error('Error handling webhook:', error);
    res.status(500).json({ message: 'Webhook handler error' });
  } finally {
    await client.close();
  }
});

module.exports = router;
