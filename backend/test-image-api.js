const { MongoClient } = require('mongodb');
const express = require('express');

// Test the image API endpoint directly
async function testImageAPI() {
  try {
    const response = await fetch('http://localhost:3000/api/images/684f1100fdc21639e66dd4c6');
    console.log('Status:', response.status);
    console.log('Content-Type:', response.headers.get('content-type'));
    console.log('Content-Length:', response.headers.get('content-length'));
    
    if (response.ok) {
      const buffer = await response.arrayBuffer();
      console.log('Image data received:', buffer.byteLength, 'bytes');
      console.log('Image appears to be loading correctly from the backend');
    } else {
      console.log('Error response:', await response.text());
    }
  } catch (error) {
    console.error('Error testing image API:', error.message);
  }
  
  // Also test the base64 endpoint
  try {
    const response = await fetch('http://localhost:3000/api/images/base64/684f1100fdc21639e66dd4c6');
    console.log('\nBase64 API Status:', response.status);
    
    if (response.ok) {
      const data = await response.json();
      console.log('Base64 data URL length:', data.dataUrl ? data.dataUrl.length : 'No dataUrl field');
      console.log('Base64 API appears to be working correctly');
    } else {
      console.log('Base64 API Error:', await response.text());
    }
  } catch (error) {
    console.error('Error testing base64 API:', error.message);
  }
}

testImageAPI();
