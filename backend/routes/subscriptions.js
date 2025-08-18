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

// Get available subscription plans
router.get('/plans', async (req, res) => {
  try {
    // Default subscription plans
    const plans = [
      {
        id: 'basic',
        name: 'Basic',
        description: 'Perfect for individual landlords',
        monthlyPrice: 9.99,
        yearlyPrice: 99.99,
        features: [
          'Up to 3 properties',
          'Basic tenant management',
          'Payment tracking',
          'Email support',
        ],
        isPopular: false,
        stripePriceIdMonthly: process.env.STRIPE_BASIC_MONTHLY_PRICE_ID || 'price_basic_monthly',
        stripePriceIdYearly: process.env.STRIPE_BASIC_YEARLY_PRICE_ID || 'price_basic_yearly',
      },
      {
        id: 'pro',
        name: 'Professional',
        description: 'Best for growing property portfolios',
        monthlyPrice: 19.99,
        yearlyPrice: 199.99,
        features: [
          'Up to 15 properties',
          'Advanced tenant management',
          'Automated rent collection',
          'Maintenance request tracking',
          'Financial reports',
          'Priority support',
        ],
        isPopular: true,
        stripePriceIdMonthly: process.env.STRIPE_PRO_MONTHLY_PRICE_ID || 'price_pro_monthly',
        stripePriceIdYearly: process.env.STRIPE_PRO_YEARLY_PRICE_ID || 'price_pro_yearly',
      },
      {
        id: 'enterprise',
        name: 'Enterprise',
        description: 'For large property management companies',
        monthlyPrice: 49.99,
        yearlyPrice: 499.99,
        features: [
          'Unlimited properties',
          'Multi-user accounts',
          'Advanced analytics',
          'API access',
          'Custom integrations',
          'Dedicated support',
        ],
        isPopular: false,
        stripePriceIdMonthly: process.env.STRIPE_ENTERPRISE_MONTHLY_PRICE_ID || 'price_enterprise_monthly',
        stripePriceIdYearly: process.env.STRIPE_ENTERPRISE_YEARLY_PRICE_ID || 'price_enterprise_yearly',
      },
    ];

    res.json(plans);
  } catch (error) {
    console.error('Error fetching subscription plans:', error);
    res.status(500).json({ message: 'Error fetching subscription plans' });
  }
});

// Get user's current subscription
router.get('/user/:userId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const userId = req.params.userId;
    
    const subscription = await db.collection('subscriptions')
      .findOne({ userId: userId, status: { $ne: 'canceled' } });
    
    if (!subscription) {
      return res.status(404).json({ message: 'No active subscription found' });
    }
    
    res.json(subscription);
  } catch (error) {
    console.error('Error fetching user subscription:', error);
    res.status(500).json({ message: 'Error fetching user subscription' });
  } finally {
    await client.close();
  }
});

// Create new subscription
router.post('/create', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const { userId, planId, billingInterval, paymentMethodId } = req.body;
    
    if (!userId || !planId || !billingInterval) {
      return res.status(400).json({ 
        message: 'Missing required fields: userId, planId, billingInterval' 
      });
    }

    // Get the plan details (in a real app, these would be in the database)
    const plans = {
      'basic': { monthly: 9.99, yearly: 99.99 },
      'pro': { monthly: 19.99, yearly: 199.99 },
      'enterprise': { monthly: 49.99, yearly: 499.99 }
    };

    const plan = plans[planId];
    if (!plan) {
      return res.status(400).json({ message: 'Invalid plan ID' });
    }

    const amount = billingInterval === 'yearly' ? plan.yearly : plan.monthly;

    // Get or create Stripe customer
    let customer;
    const user = await db.collection('users').findOne({ _id: new ObjectId(userId) });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.stripeCustomerId) {
      customer = await stripe.customers.retrieve(user.stripeCustomerId);
    } else {
      customer = await stripe.customers.create({
        email: user.email,
        name: user.fullName,
        metadata: {
          userId: userId
        }
      });
      
      // Save Stripe customer ID to user
      await db.collection('users').updateOne(
        { _id: new ObjectId(userId) },
        { $set: { stripeCustomerId: customer.id } }
      );
    }

    // Create Stripe subscription
    const priceId = billingInterval === 'yearly' 
      ? process.env[`STRIPE_${planId.toUpperCase()}_YEARLY_PRICE_ID`]
      : process.env[`STRIPE_${planId.toUpperCase()}_MONTHLY_PRICE_ID`];

    let stripeSubscription;
    
    if (priceId) {
      // Use Stripe Price IDs if configured
      stripeSubscription = await stripe.subscriptions.create({
        customer: customer.id,
        items: [{ price: priceId }],
        payment_behavior: 'default_incomplete',
        payment_settings: { save_default_payment_method: 'on_subscription' },
        expand: ['latest_invoice.payment_intent'],
      });
    } else {
      // Fallback: create one-time payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency: 'usd',
        customer: customer.id,
        metadata: {
          userId: userId,
          planId: planId,
          billingInterval: billingInterval
        }
      });

      // Create subscription record in database
      const subscription = {
        userId: userId,
        planId: planId,
        status: 'incomplete',
        startDate: new Date(),
        billingInterval: billingInterval,
        stripeSubscriptionId: paymentIntent.id,
        stripeCustomerId: customer.id,
        amount: amount,
        nextBillingDate: new Date(Date.now() + (billingInterval === 'yearly' ? 365 : 30) * 24 * 60 * 60 * 1000),
        createdAt: new Date(),
        updatedAt: new Date()
      };

      const result = await db.collection('subscriptions').insertOne(subscription);
      const createdSubscription = await db.collection('subscriptions')
        .findOne({ _id: result.insertedId });

      return res.json({
        subscription: createdSubscription,
        clientSecret: paymentIntent.client_secret
      });
    }

    // If using Stripe subscriptions
    const subscription = {
      userId: userId,
      planId: planId,
      status: stripeSubscription.status,
      startDate: new Date(),
      billingInterval: billingInterval,
      stripeSubscriptionId: stripeSubscription.id,
      stripeCustomerId: customer.id,
      amount: amount,
      nextBillingDate: new Date(stripeSubscription.current_period_end * 1000),
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const result = await db.collection('subscriptions').insertOne(subscription);
    const createdSubscription = await db.collection('subscriptions')
      .findOne({ _id: result.insertedId });

    res.json({
      subscription: createdSubscription,
      clientSecret: stripeSubscription.latest_invoice.payment_intent.client_secret
    });

  } catch (error) {
    console.error('Error creating subscription:', error);
    res.status(500).json({ message: 'Error creating subscription' });
  } finally {
    await client.close();
  }
});

// Create payment intent for subscription
router.post('/create-payment-intent', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  try {
    const { amount, currency, customerId } = req.body;
    
    if (!amount || !currency) {
      return res.status(400).json({ 
        message: 'Missing required fields: amount, currency' 
      });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount), // Amount should already be in cents
      currency: currency || 'usd',
      customer: customerId,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      clientSecret: paymentIntent.client_secret
    });

  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ message: 'Error creating payment intent' });
  }
});

// Update subscription
router.put('/:subscriptionId', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const subscriptionId = req.params.subscriptionId;
    const { planId, billingInterval } = req.body;
    
    const subscription = await db.collection('subscriptions')
      .findOne({ _id: new ObjectId(subscriptionId) });
    
    if (!subscription) {
      return res.status(404).json({ message: 'Subscription not found' });
    }

    // Update Stripe subscription if it exists
    if (subscription.stripeSubscriptionId && subscription.stripeSubscriptionId.startsWith('sub_')) {
      // This is a real Stripe subscription
      await stripe.subscriptions.update(subscription.stripeSubscriptionId, {
        items: [{
          id: subscription.stripeSubscriptionId,
          price: process.env[`STRIPE_${planId.toUpperCase()}_${billingInterval.toUpperCase()}_PRICE_ID`]
        }]
      });
    }

    // Update in database
    const updatedSubscription = await db.collection('subscriptions').findOneAndUpdate(
      { _id: new ObjectId(subscriptionId) },
      {
        $set: {
          planId: planId,
          billingInterval: billingInterval,
          updatedAt: new Date()
        }
      },
      { returnDocument: 'after' }
    );

    res.json({ subscription: updatedSubscription.value });

  } catch (error) {
    console.error('Error updating subscription:', error);
    res.status(500).json({ message: 'Error updating subscription' });
  } finally {
    await client.close();
  }
});

// Cancel subscription
router.delete('/:subscriptionId/cancel', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const subscriptionId = req.params.subscriptionId;
    
    const subscription = await db.collection('subscriptions')
      .findOne({ _id: new ObjectId(subscriptionId) });
    
    if (!subscription) {
      return res.status(404).json({ message: 'Subscription not found' });
    }

    // Cancel Stripe subscription if it exists
    if (subscription.stripeSubscriptionId && subscription.stripeSubscriptionId.startsWith('sub_')) {
      await stripe.subscriptions.cancel(subscription.stripeSubscriptionId);
    }

    // Update in database
    await db.collection('subscriptions').updateOne(
      { _id: new ObjectId(subscriptionId) },
      {
        $set: {
          status: 'canceled',
          endDate: new Date(),
          updatedAt: new Date()
        }
      }
    );

    res.json({ message: 'Subscription canceled successfully' });

  } catch (error) {
    console.error('Error canceling subscription:', error);
    res.status(500).json({ message: 'Error canceling subscription' });
  } finally {
    await client.close();
  }
});

// Stripe webhook handler for subscription events
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = process.env.STRIPE_SUBSCRIPTION_WEBHOOK_SECRET;
  
  let event;
  
  try {
    if (endpointSecret) {
      event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
    } else {
      console.warn('Warning: Running webhook without signature verification (development mode)');
      event = JSON.parse(req.body.toString());
    }
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    // Handle the event
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        const subscription = event.data.object;
        await db.collection('subscriptions').updateOne(
          { stripeSubscriptionId: subscription.id },
          {
            $set: {
              status: subscription.status,
              nextBillingDate: new Date(subscription.current_period_end * 1000),
              updatedAt: new Date()
            }
          }
        );
        break;
        
      case 'customer.subscription.deleted':
        const canceledSubscription = event.data.object;
        await db.collection('subscriptions').updateOne(
          { stripeSubscriptionId: canceledSubscription.id },
          {
            $set: {
              status: 'canceled',
              endDate: new Date(),
              updatedAt: new Date()
            }
          }
        );
        break;
        
      case 'invoice.payment_succeeded':
        const invoice = event.data.object;
        if (invoice.subscription) {
          await db.collection('subscriptions').updateOne(
            { stripeSubscriptionId: invoice.subscription },
            {
              $set: {
                status: 'active',
                nextBillingDate: new Date(invoice.period_end * 1000),
                updatedAt: new Date()
              }
            }
          );
        }
        break;
        
      case 'invoice.payment_failed':
        const failedInvoice = event.data.object;
        if (failedInvoice.subscription) {
          await db.collection('subscriptions').updateOne(
            { stripeSubscriptionId: failedInvoice.subscription },
            {
              $set: {
                status: 'past_due',
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
    res.status(500).json({ message: 'Error handling webhook' });
  } finally {
    await client.close();
  }
});

// Sync user subscriptions from Stripe
router.post('/sync/:userId', async (req, res) => {
  const stripeError = requireStripe(res);
  if (stripeError) return stripeError;

  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const userId = req.params.userId;
    console.log(`🔄 Syncing subscriptions for user: ${userId}`);
    
    // Get user from database to find their email or Stripe customer ID
    const user = await db.collection('users').findOne({ _id: new ObjectId(userId) });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    console.log(`👤 Found user: ${user.email}`);
    
    // Search for customers by email in Stripe
    const customers = await stripe.customers.list({
      email: user.email,
      limit: 10,
    });
    
    console.log(`🔍 Found ${customers.data.length} customers in Stripe`);
    
    if (customers.data.length === 0) {
      return res.status(404).json({ message: 'No Stripe customer found for this user' });
    }
    
    const customer = customers.data[0];
    console.log(`✅ Using Stripe customer: ${customer.id}`);
    
    // Get active subscriptions for this customer
    const subscriptions = await stripe.subscriptions.list({
      customer: customer.id,
      status: 'active',
      limit: 10,
    });
    
    console.log(`📋 Found ${subscriptions.data.length} active subscriptions in Stripe`);
    
    if (subscriptions.data.length === 0) {
      return res.status(404).json({ message: 'No active subscriptions found in Stripe' });
    }
    
    // Sync each subscription to local database
    const syncedSubscriptions = [];
    
    for (const stripeSubscription of subscriptions.data) {
      console.log(`🔄 Processing subscription: ${stripeSubscription.id}`);
      
      // Get the product information
      const priceId = stripeSubscription.items.data[0].price.id;
      const price = await stripe.prices.retrieve(priceId);
      const product = await stripe.products.retrieve(price.product);
      
      const planId = product.metadata.planId || product.name.toLowerCase().replace(/\s+/g, '_');
      
      const subscriptionData = {
        userId: userId,
        stripeSubscriptionId: stripeSubscription.id,
        stripeCustomerId: customer.id,
        planId: planId,
        status: stripeSubscription.status,
        billingInterval: price.recurring.interval,
        amount: price.unit_amount / 100,
        currency: price.currency,
        currentPeriodStart: new Date(stripeSubscription.current_period_start * 1000),
        currentPeriodEnd: new Date(stripeSubscription.current_period_end * 1000),
        createdAt: new Date(stripeSubscription.created * 1000),
        updatedAt: new Date(),
      };
      
      // Upsert subscription in database
      await db.collection('subscriptions').updateOne(
        { stripeSubscriptionId: stripeSubscription.id },
        { $set: subscriptionData },
        { upsert: true }
      );
      
      syncedSubscriptions.push(subscriptionData);
      console.log(`✅ Synced subscription: ${planId} (${stripeSubscription.status})`);
    }
    
    res.json({
      message: 'Subscriptions synced successfully',
      syncedCount: syncedSubscriptions.length,
      subscriptions: syncedSubscriptions,
    });
    
  } catch (error) {
    console.error('❌ Error syncing subscriptions:', error);
    res.status(500).json({ 
      message: 'Error syncing subscriptions',
      error: error.message 
    });
  } finally {
    await client.close();
  }
});

module.exports = router;
