require('dotenv').config();
const express = require('express');
const app = express();

// Initialize Stripe
let stripe = null;
if (process.env.STRIPE_SECRET_KEY) {
  stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
  console.log('✅ Stripe initialized successfully');
} else {
  console.log('❌ STRIPE_SECRET_KEY not found');
}

app.use(express.json());

// Test endpoint
app.get('/test-plans', async (req, res) => {
  console.log('📋 Testing subscription plans endpoint...');
  
  try {
    if (!stripe) {
      return res.status(500).json({ error: 'Stripe not configured' });
    }

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
        if (product.description && product.description !== 'Lorem Ipsum') {
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

    console.log(`🎉 Successfully created ${plans.length} plans`);
    res.json(plans);

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Stack:', error.stack);
    res.status(500).json({ 
      message: 'Error fetching subscription plans',
      error: error.message 
    });
  }
});

const port = 3001;
app.listen(port, () => {
  console.log(`🚀 Test server running on port ${port}`);
  console.log(`📋 Test endpoint: http://localhost:${port}/test-plans`);
});
