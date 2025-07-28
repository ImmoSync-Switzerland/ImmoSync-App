#!/bin/bash

# Basic backend API testing script
BASE_URL="http://localhost:3000/api"

echo "Testing ImmoLink Backend API..."
echo "================================"

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s "$BASE_URL/health" | head -c 200
echo ""
echo ""

# Test auth register endpoint (should fail without MongoDB but return proper error)
echo "2. Testing auth register endpoint..."
curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","fullName":"Test User","role":"tenant","birthDate":"1990-01-01"}' | head -c 200
echo ""
echo ""

# Test properties endpoint
echo "3. Testing properties endpoint..."
curl -s "$BASE_URL/properties/landlord/test123" | head -c 200
echo ""
echo ""

echo "Backend API tests completed."
echo "Note: Some endpoints may fail due to missing MongoDB connection, but they should return proper error messages."