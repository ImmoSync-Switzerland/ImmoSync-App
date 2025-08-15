// Test script for 2FA SMS functionality
const axios = require('axios');

const API_BASE = 'http://localhost:3000/api/auth/2fa';

async function test2FA() {
  console.log('Testing 2FA SMS Functionality...\n');

  try {
    // 1. Check SMS service status
    console.log('1. Checking SMS service status...');
    const statusResponse = await axios.get(`${API_BASE}/sms-status`);
    console.log('SMS Status:', statusResponse.data);
    console.log('');

    // 2. Test 2FA setup
    console.log('2. Testing 2FA setup...');
    const setupResponse = await axios.post(`${API_BASE}/setup-2fa`, {
      userId: 'test_user_123',
      phoneNumber: '+1234567890' // Use a test phone number
    });
    console.log('Setup Response:', setupResponse.data);
    console.log('');

    // 3. Check 2FA status
    console.log('3. Checking 2FA status...');
    const userStatusResponse = await axios.get(`${API_BASE}/status/test_user_123`);
    console.log('User 2FA Status:', userStatusResponse.data);
    console.log('');

    console.log('✅ 2FA SMS test completed successfully!');
    console.log('\nTo complete testing:');
    console.log('1. Use the verification code from the console/SMS');
    console.log('2. Call POST /api/auth/2fa/verify-2fa-setup with the code');
    
  } catch (error) {
    console.error('❌ Error testing 2FA:', error.response?.data || error.message);
  }
}

// Run the test
if (require.main === module) {
  test2FA();
}

module.exports = { test2FA };
