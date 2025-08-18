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

// Create Connect account for landlord
router.post('/create-account', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { landlordId, email, businessType = 'individual' } = req.body;
    
    if (!landlordId || !email) {
      return res.status(400).json({ 
        message: 'Missing required fields: landlordId, email' 
      });
    }

    // Check if landlord already has a Connect account
    const landlord = await db.collection('users').findOne({ 
      _id: new ObjectId(landlordId) 
    });
    
    if (!landlord) {
      return res.status(404).json({ message: 'Landlord not found' });
    }

    if (landlord.stripeConnectAccountId) {
      return res.status(400).json({ 
        message: 'Landlord already has a Stripe Connect account' 
      });
    }

    // Create Stripe Connect account
    const account = await stripe.accounts.create({
      type: 'express',
      business_type: businessType,
      email: email,
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
        bank_transfer_payments: { requested: true },
      },
      settings: {
        payouts: {
          schedule: {
            interval: 'daily',
          },
        },
      },
    });

    // Update landlord with Connect account ID
    await db.collection('users').updateOne(
      { _id: new ObjectId(landlordId) },
      { 
        $set: { 
          stripeConnectAccountId: account.id,
          connectAccountStatus: 'pending',
          updatedAt: new Date()
        }
      }
    );

    console.log(`Created Connect account ${account.id} for landlord ${landlordId}`);
    
    res.json({
      accountId: account.id,
      status: 'pending',
      message: 'Connect account created successfully'
    });
    
  } catch (error) {
    console.error('Error creating Connect account:', error);
    res.status(500).json({ message: 'Error creating Connect account' });
  } finally {
    await client.close();
  }
});

// Create onboarding link for landlord
router.post('/create-onboarding-link', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  try {
    const { accountId, refreshUrl, returnUrl } = req.body;
    
    if (!accountId) {
      return res.status(400).json({ 
        message: 'Missing required field: accountId' 
      });
    }

    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: refreshUrl || `${process.env.APP_URL}/connect/refresh`,
      return_url: returnUrl || `${process.env.APP_URL}/connect/return`,
      type: 'account_onboarding',
    });

    res.json({
      url: accountLink.url,
      expires_at: accountLink.expires_at
    });
    
  } catch (error) {
    console.error('Error creating onboarding link:', error);
    res.status(500).json({ message: 'Error creating onboarding link' });
  }
});

// Create AccountSession for embedded components
router.post('/account-session', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { accountId, components } = req.body;
    
    if (!accountId) {
      return res.status(400).json({ 
        message: 'accountId is required' 
      });
    }

    // Create account session for embedded components
    const accountSession = await stripe.accountSessions.create({
      account: accountId,
      components: components || {
        account_onboarding: { enabled: true },
        payments: {
          enabled: true,
          features: {
            refund_management: true,
            dispute_management: true,
            capture_payments: true,
          },
        },
        payouts: {
          enabled: true,
          features: {
            instant_payouts: true,
            standard_payouts: true,
            payout_schedule: true,
          },
        },
        balances: { enabled: true },
        account_management: { enabled: true },
      },
    });

    res.json({
      client_secret: accountSession.client_secret,
    });
    
  } catch (error) {
    console.error('Error creating account session:', error);
    res.status(500).json({ message: 'Error creating account session' });
  } finally {
    await client.close();
  }
});

// Get Connect account status
router.get('/account-status/:landlordId', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const landlordId = req.params.landlordId;
    
    const landlord = await db.collection('users').findOne({ 
      _id: new ObjectId(landlordId) 
    });
    
    if (!landlord || !landlord.stripeConnectAccountId) {
      return res.json({ 
        hasAccount: false,
        status: 'not_created'
      });
    }

    // Get account details from Stripe
    const account = await stripe.accounts.retrieve(landlord.stripeConnectAccountId);
    
    const status = account.details_submitted && account.charges_enabled 
      ? 'complete' 
      : 'pending';

    // Update local status
    await db.collection('users').updateOne(
      { _id: new ObjectId(landlordId) },
      { 
        $set: { 
          connectAccountStatus: status,
          updatedAt: new Date()
        }
      }
    );

    res.json({
      hasAccount: true,
      accountId: account.id,
      status: status,
      chargesEnabled: account.charges_enabled,
      detailsSubmitted: account.details_submitted,
      payoutsEnabled: account.payouts_enabled
    });
    
  } catch (error) {
    console.error('Error getting account status:', error);
    res.status(500).json({ message: 'Error getting account status' });
  } finally {
    await client.close();
  }
});

// Create payment intent for tenant-to-landlord transfer
router.post('/create-tenant-payment', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { 
      tenantId, 
      propertyId, 
      amount, 
      currency = 'chf',
      paymentType = 'rent',
      description 
    } = req.body;
    
    if (!tenantId || !propertyId || !amount) {
      return res.status(400).json({ 
        message: 'Missing required fields: tenantId, propertyId, amount' 
      });
    }

    // Get property and landlord info
    const property = await db.collection('properties').findOne({ 
      _id: new ObjectId(propertyId) 
    });
    
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    const landlord = await db.collection('users').findOne({ 
      _id: new ObjectId(property.landlordId) 
    });
    
    if (!landlord || !landlord.stripeConnectAccountId) {
      return res.status(400).json({ 
        message: 'Landlord does not have a payment account set up' 
      });
    }

    // Calculate application fee (e.g., 2.9% + 30 cents)
    const applicationFeeAmount = Math.round((amount * 0.029) + 30);
    
    // Create payment intent with transfer to landlord
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: currency,
      application_fee_amount: applicationFeeAmount,
      transfer_data: {
        destination: landlord.stripeConnectAccountId,
      },
      payment_method_types: [
        'card',
        'bank_transfer', // For bank transfers
        'sofort',       // For instant bank payments in Europe
        'ideal',        // For Netherlands
        'sepa_debit',   // For SEPA Direct Debit
      ],
      metadata: {
        tenantId: tenantId,
        propertyId: propertyId,
        landlordId: property.landlordId,
        paymentType: paymentType,
        description: description || `${paymentType} payment for ${property.address.street}`
      }
    });

    // Store payment record in database
    const paymentRecord = {
      stripePaymentIntentId: paymentIntent.id,
      tenantId: tenantId,
      propertyId: propertyId,
      landlordId: property.landlordId,
      amount: amount,
      currency: currency,
      type: paymentType,
      status: 'pending',
      applicationFee: applicationFeeAmount / 100, // Convert back to currency units
      description: description || `${paymentType} payment`,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    await db.collection('payments').insertOne(paymentRecord);

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      applicationFee: applicationFeeAmount / 100
    });
    
  } catch (error) {
    console.error('Error creating tenant payment:', error);
    res.status(500).json({ message: 'Error creating payment' });
  } finally {
    await client.close();
  }
});

// Get available payment methods for region
router.get('/payment-methods/:country', async (req, res) => {
  const country = req.params.country.toLowerCase();
  
  // Payment methods by country/region
  const paymentMethods = {
    'ch': [ // Switzerland
      {
        type: 'card',
        name: 'Credit/Debit Card',
        icon: 'credit_card',
        instant: true
      },
      {
        type: 'bank_transfer',
        name: 'Bank Transfer',
        icon: 'account_balance',
        instant: false,
        description: 'Takes 1-3 business days'
      },
      {
        type: 'sofort',
        name: 'Sofort',
        icon: 'flash_on',
        instant: true,
        description: 'Instant bank payment'
      }
    ],
    'de': [ // Germany
      {
        type: 'card',
        name: 'Credit/Debit Card',
        icon: 'credit_card',
        instant: true
      },
      {
        type: 'sepa_debit',
        name: 'SEPA Direct Debit',
        icon: 'account_balance',
        instant: false,
        description: 'Takes 1-3 business days'
      },
      {
        type: 'sofort',
        name: 'Sofort',
        icon: 'flash_on',
        instant: true
      }
    ],
    'nl': [ // Netherlands
      {
        type: 'card',
        name: 'Credit/Debit Card',
        icon: 'credit_card',
        instant: true
      },
      {
        type: 'ideal',
        name: 'iDEAL',
        icon: 'flash_on',
        instant: true,
        description: 'Dutch bank payment'
      },
      {
        type: 'sepa_debit',
        name: 'SEPA Direct Debit',
        icon: 'account_balance',
        instant: false
      }
    ],
    'default': [
      {
        type: 'card',
        name: 'Credit/Debit Card',
        icon: 'credit_card',
        instant: true
      },
      {
        type: 'bank_transfer',
        name: 'Bank Transfer',
        icon: 'account_balance',
        instant: false
      }
    ]
  };
  
  res.json(paymentMethods[country] || paymentMethods['default']);
});

// Webhook endpoint for Stripe events
router.post('/webhook', express.raw({type: 'application/json'}), async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  const client = new MongoClient(dbUri);
  const sig = req.headers['stripe-signature'];
  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

  if (!endpointSecret) {
    console.error('Stripe webhook secret not configured');
    return res.status(400).send('Webhook secret not configured');
  }

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    await client.connect();
    const db = client.db(dbName);

    // Handle the event
    switch (event.type) {
      case 'payment_intent.succeeded':
        const paymentIntent = event.data.object;
        console.log('Payment succeeded:', paymentIntent.id);
        
        // Update payment record in database
        await db.collection('payments').updateOne(
          { stripePaymentIntentId: paymentIntent.id },
          { 
            $set: { 
              status: 'completed',
              completedAt: new Date(),
              updatedAt: new Date()
            }
          }
        );
        break;
        
      case 'payment_intent.payment_failed':
        const failedPayment = event.data.object;
        console.log('Payment failed:', failedPayment.id);
        
        // Update payment record in database
        await db.collection('payments').updateOne(
          { stripePaymentIntentId: failedPayment.id },
          { 
            $set: { 
              status: 'failed',
              failureReason: failedPayment.last_payment_error?.message || 'Unknown error',
              updatedAt: new Date()
            }
          }
        );
        break;
        
      case 'account.updated':
        const account = event.data.object;
        console.log('Connect account updated:', account.id);
        
        // Update landlord account status
        await db.collection('users').updateOne(
          { stripeConnectAccountId: account.id },
          { 
            $set: { 
              connectAccountStatus: account.charges_enabled ? 'active' : 'pending',
              connectAccountDetails: {
                chargesEnabled: account.charges_enabled,
                payoutsEnabled: account.payouts_enabled,
                country: account.country,
                updatedAt: new Date()
              },
              updatedAt: new Date()
            }
          }
        );
        break;
        
      default:
        console.log(`Unhandled event type ${event.type}`);
    }

    res.json({received: true});
  } catch (error) {
    console.error('Error handling webhook:', error);
    res.status(500).json({ error: 'Webhook handling failed' });
  } finally {
    await client.close();
  }
});

module.exports = router;
