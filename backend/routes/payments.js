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

// Webhook endpoint secret
const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

// Helper function to check if Stripe is available
function requireStripe(res) {
  if (!stripe) {
    return res.status(500).json({ 
      message: 'Stripe not configured. Please add STRIPE_SECRET_KEY to environment variables.' 
    });
  }
  return null;
}

// Stripe Webhook - Handle subscription events
router.post('/stripe-webhook', express.raw({type: 'application/json'}), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    if (!endpointSecret) {
      console.warn('Warning: STRIPE_WEBHOOK_SECRET not configured');
      return res.status(400).send('Webhook secret not configured');
    }

    // Verify webhook signature
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    console.log(`Processing webhook event: ${event.type}`);
    
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await handleSubscriptionChange(db, event.data.object);
        break;
        
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(db, event.data.object);
        break;
        
      case 'invoice.payment_succeeded':
        await handlePaymentSucceeded(db, event.data.object);
        break;
        
      case 'invoice.payment_failed':
        await handlePaymentFailed(db, event.data.object);
        break;
        
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }
    
    res.json({received: true});
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    await client.close();
  }
});

// Helper function to handle subscription creation/updates
async function handleSubscriptionChange(db, subscription) {
  try {
    console.log('Processing subscription change:', subscription.id);
    
    // Get customer details from Stripe
    const customer = await stripe.customers.retrieve(subscription.customer);
    
    // Find user by email
    const user = await db.collection('users').findOne({ email: customer.email });
    if (!user) {
      console.warn(`User not found for email: ${customer.email}`);
      return;
    }
    
    // Get the price details to determine plan type
    const price = await stripe.prices.retrieve(subscription.items.data[0].price.id);
    const product = await stripe.products.retrieve(price.product);
    
    // Map product name to plan type
    let planType = 'basic';
    const productName = product.name.toLowerCase();
    if (productName.includes('pro')) {
      planType = 'pro';
    } else if (productName.includes('enterprise')) {
      planType = 'enterprise';
    }
    
    // Update user's subscription
    const subscriptionData = {
      stripeSubscriptionId: subscription.id,
      stripeCustomerId: subscription.customer,
      status: subscription.status,
      planType: planType,
      startDate: new Date(subscription.created * 1000),
      endDate: subscription.current_period_end ? new Date(subscription.current_period_end * 1000) : null,
      lastUpdated: new Date()
    };
    
    await db.collection('users').updateOne(
      { _id: user._id },
      { 
        $set: { 
          subscription: subscriptionData,
          stripeCustomerId: subscription.customer
        }
      }
    );
    
    console.log(`Updated subscription for user ${user.email}: ${planType} plan`);
  } catch (error) {
    console.error('Error handling subscription change:', error);
  }
}

// Helper function to handle subscription deletion
async function handleSubscriptionDeleted(db, subscription) {
  try {
    console.log('Processing subscription deletion:', subscription.id);
    
    await db.collection('users').updateOne(
      { 'subscription.stripeSubscriptionId': subscription.id },
      { 
        $set: { 
          'subscription.status': 'canceled',
          'subscription.lastUpdated': new Date()
        }
      }
    );
    
    console.log(`Subscription canceled: ${subscription.id}`);
  } catch (error) {
    console.error('Error handling subscription deletion:', error);
  }
}

// Helper function to handle successful payments
async function handlePaymentSucceeded(db, invoice) {
  try {
    console.log('Processing successful payment:', invoice.id);
    
    if (invoice.subscription) {
      // Update subscription status to active
      await db.collection('users').updateOne(
        { 'subscription.stripeSubscriptionId': invoice.subscription },
        { 
          $set: { 
            'subscription.status': 'active',
            'subscription.lastUpdated': new Date()
          }
        }
      );
      
      console.log(`Payment succeeded for subscription: ${invoice.subscription}`);
    }
  } catch (error) {
    console.error('Error handling payment success:', error);
  }
}

// Helper function to handle failed payments
async function handlePaymentFailed(db, invoice) {
  try {
    console.log('Processing failed payment:', invoice.id);
    
    if (invoice.subscription) {
      // Update subscription status
      await db.collection('users').updateOne(
        { 'subscription.stripeSubscriptionId': invoice.subscription },
        { 
          $set: { 
            'subscription.status': 'past_due',
            'subscription.lastUpdated': new Date()
          }
        }
      );
      
      console.log(`Payment failed for subscription: ${invoice.subscription}`);
    }
  } catch (error) {
    console.error('Error handling payment failure:', error);
  }
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

// Get available subscription plans from Stripe
router.get('/subscription-plans', async (req, res) => {
  console.log('📋 Subscription plans endpoint called');
  const stripeError = requireStripe(res);
  if (stripeError) {
    console.log('❌ Stripe not configured');
    return stripeError;
  }

  try {
    console.log('🔍 Fetching products from Stripe...');
    // Fetch all active products from Stripe
    const products = await stripe.products.list({
      active: true,
      limit: 100,
    });
    console.log(`✅ Found ${products.data.length} products`);

    console.log('🔍 Fetching prices from Stripe...');
    // Fetch prices for all products
    const allPrices = await stripe.prices.list({
      active: true,
      limit: 100,
    });
    console.log(`✅ Found ${allPrices.data.length} prices`);

    // Group prices by product and build plan structure
    const plans = [];
    
    for (const product of products.data) {
      console.log(`📦 Processing product: ${product.name}`);
      // Filter prices for this product
      const productPrices = allPrices.data.filter(price => 
        price.product === product.id && price.recurring
      );

      if (productPrices.length > 0) {
        // Find monthly and yearly prices
        const monthlyPrice = productPrices.find(p => p.recurring.interval === 'month');
        const yearlyPrice = productPrices.find(p => p.recurring.interval === 'year');

        // Extract features from product description or metadata
        let features = [];
        if (product.description) {
          features = product.description.split(',').map(f => f.trim());
        }
        if (product.metadata && product.metadata.features) {
          features = product.metadata.features.split(',').map(f => f.trim());
        }

        const plan = {
          id: product.metadata.planId || product.name.toLowerCase().replace(/\s+/g, '_'),
          name: product.name,
          description: product.description || '',
          features: features,
          monthlyPrice: monthlyPrice ? monthlyPrice.unit_amount / 100 : null,
          yearlyPrice: yearlyPrice ? yearlyPrice.unit_amount / 100 : null,
          currency: monthlyPrice?.currency || yearlyPrice?.currency || 'usd',
          stripeProductId: product.id,
          monthlyPriceId: monthlyPrice?.id,
          yearlyPriceId: yearlyPrice?.id,
        };

        plans.push(plan);
        console.log(`✅ Added plan: ${plan.name}`);
      }
    }

    // Sort plans by price (lowest first)
    plans.sort((a, b) => {
      const priceA = a.monthlyPrice || a.yearlyPrice || 0;
      const priceB = b.monthlyPrice || b.yearlyPrice || 0;
      return priceA - priceB;
    });

    console.log(`🎉 Successfully returning ${plans.length} plans`);
    res.json(plans);

  } catch (error) {
    console.error('❌ Error fetching subscription plans:', error);
    res.status(500).json({ 
      message: 'Error fetching subscription plans',
      error: error.message 
    });
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

// Create payment intent for tenant payments
router.post('/create-payment-intent', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  try {
    const { amount, currency, propertyId, tenantId, paymentType } = req.body;
    
    if (!amount || !propertyId || !tenantId) {
      return res.status(400).json({ 
        message: 'Missing required fields: amount, propertyId, tenantId' 
      });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: currency || 'usd',
      automatic_payment_methods: {
        enabled: true,
      },
      metadata: {
        propertyId: propertyId,
        tenantId: tenantId,
        paymentType: paymentType || 'rent'
      }
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id
    });

  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ message: 'Error creating payment intent' });
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

// Create Stripe checkout session for subscriptions
router.post('/create-subscription-checkout', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  try {
    const { planId, isYearly, userId, successUrl, cancelUrl } = req.body;
    
    if (!planId || !userId) {
      return res.status(400).json({ 
        message: 'Missing required fields: planId, userId' 
      });
    }

    // Fetch all products from Stripe
    const products = await stripe.products.list({
      active: true,
      limit: 100,
    });

    // Find the product by name (planId should match product name in Stripe)
    const product = products.data.find(p => 
      p.name.toLowerCase().includes(planId.toLowerCase()) ||
      p.metadata.planId === planId
    );

    if (!product) {
      return res.status(400).json({ 
        message: `Plan '${planId}' not found in Stripe. Please create the product in Stripe Dashboard first.` 
      });
    }

    // Fetch prices for this product
    const prices = await stripe.prices.list({
      product: product.id,
      active: true,
    });

    // Find the appropriate price based on billing interval
    const targetInterval = isYearly ? 'year' : 'month';
    const price = prices.data.find(p => 
      p.recurring && p.recurring.interval === targetInterval
    );

    if (!price) {
      return res.status(400).json({ 
        message: `No ${targetInterval}ly price found for plan '${planId}'. Please create the price in Stripe Dashboard.` 
      });
    }

    // Create checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price: price.id,
          quantity: 1,
        },
      ],
      mode: 'subscription',
      success_url: successUrl || `${process.env.FLUTTER_APP_SCHEME}://subscription-success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: cancelUrl || `${process.env.FLUTTER_APP_SCHEME}://subscription-cancel`,
      client_reference_id: userId,
      metadata: {
        planId: planId,
        userId: userId,
        isYearly: isYearly.toString(),
        productId: product.id,
        priceId: price.id,
      },
    });

    res.json({ 
      checkoutUrl: session.url,
      sessionId: session.id,
      productName: product.name,
      priceAmount: price.unit_amount,
      currency: price.currency,
      interval: price.recurring.interval,
    });

  } catch (error) {
    console.error('Error creating checkout session:', error);
    res.status(500).json({ 
      message: 'Error creating checkout session',
      error: error.message 
    });
  }
});

module.exports = router;
