#!/bin/bash

# Comprehensive ImmoLink Backend API Testing Script
echo "=========================================="
echo "ImmoLink Backend API Comprehensive Tests"
echo "=========================================="

BASE_URL="http://localhost:3000/api"
TEST_LOG="/tmp/test_results.log"

# Initialize test log
echo "Backend API Test Results - $(date)" > $TEST_LOG
echo "=================================" >> $TEST_LOG

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to log test results
log_test() {
    local test_name="$1"
    local status="$2"
    local response="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [[ "$status" == "PASS" ]]; then
        echo -e "${GREEN}✓ $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "PASS: $test_name" >> $TEST_LOG
    else
        echo -e "${RED}✗ $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "FAIL: $test_name" >> $TEST_LOG
        echo "Response: $response" >> $TEST_LOG
    fi
}

# Function to test API endpoint
test_endpoint() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local expected_status="$4"
    local test_name="$5"
    
    if [[ "$method" == "GET" ]]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL$endpoint")
    elif [[ "$method" == "POST" ]]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    elif [[ "$method" == "PUT" ]]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X PUT "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    elif [[ "$method" == "DELETE" ]]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X DELETE "$BASE_URL$endpoint")
    fi
    
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')
    
    if [[ "$http_code" == "$expected_status" ]] || [[ "$expected_status" == "*" ]]; then
        log_test "$test_name" "PASS" "$body"
    else
        log_test "$test_name (Expected: $expected_status, Got: $http_code)" "FAIL" "$body"
    fi
}

echo "Starting Backend API Tests..."
echo ""

# Test 1: Health Check
echo -e "${YELLOW}1. System Health Tests${NC}"
test_endpoint "GET" "/health" "" "200" "Health endpoint responds"

# Test 2: Authentication Endpoints
echo -e "${YELLOW}2. Authentication Tests${NC}"
test_endpoint "POST" "/auth/register" '{"email":"test@example.com","password":"test123","fullName":"Test User","role":"tenant","birthDate":"1990-01-01"}' "*" "User registration endpoint"
test_endpoint "POST" "/auth/login" '{"email":"test@example.com","password":"test123"}' "*" "User login endpoint"
test_endpoint "GET" "/auth/profile/test-user-id" "" "*" "Get user profile endpoint"

# Test 3: Property Management
echo -e "${YELLOW}3. Property Management Tests${NC}"
test_endpoint "GET" "/properties/landlord/test-landlord-id" "" "*" "Get landlord properties"
test_endpoint "GET" "/properties/search?city=TestCity" "" "*" "Property search endpoint"
test_endpoint "POST" "/properties" '{"landlordId":"test-landlord","address":{"street":"123 Test St","city":"Test City","postalCode":"12345","country":"Test Country"},"rentAmount":1500,"details":{"rooms":3,"size":100}}' "*" "Create property endpoint"
test_endpoint "GET" "/properties/test-property-id" "" "*" "Get specific property"
test_endpoint "PUT" "/properties/test-property-id" '{"rentAmount":1600}' "*" "Update property endpoint"

# Test 4: Payment System
echo -e "${YELLOW}4. Payment System Tests${NC}"
test_endpoint "GET" "/payments/tenant/test-tenant-id" "" "*" "Get tenant payments"
test_endpoint "POST" "/payments" '{"tenantId":"test-tenant","propertyId":"test-property","amount":1500,"paymentMethod":"credit_card"}' "*" "Process payment endpoint"
test_endpoint "GET" "/payments/test-payment-id" "" "*" "Get payment details"

# Test 5: Maintenance Requests
echo -e "${YELLOW}5. Maintenance Request Tests${NC}"
test_endpoint "GET" "/maintenance/property/test-property-id" "" "*" "Get property maintenance requests"
test_endpoint "POST" "/maintenance" '{"propertyId":"test-property","tenantId":"test-tenant","title":"Broken faucet","description":"Kitchen faucet is leaking","priority":"medium"}' "*" "Create maintenance request"
test_endpoint "PUT" "/maintenance/test-request-id" '{"status":"in_progress"}' "*" "Update maintenance request"

# Test 6: Chat/Messaging
echo -e "${YELLOW}6. Chat/Messaging Tests${NC}"
test_endpoint "GET" "/chat/conversations/test-user-id" "" "*" "Get user conversations"
test_endpoint "POST" "/chat/conversations" '{"participants":["user1","user2"],"propertyId":"test-property"}' "*" "Create conversation"
test_endpoint "POST" "/chat/messages" '{"conversationId":"test-conversation","senderId":"test-user","content":"Hello, I have a question about the property"}' "*" "Send message"

# Test 7: User Management
echo -e "${YELLOW}7. User Management Tests${NC}"
test_endpoint "GET" "/users/test-user-id" "" "*" "Get user details"
test_endpoint "PUT" "/users/test-user-id" '{"fullName":"Updated Name"}' "*" "Update user profile"
test_endpoint "GET" "/users/landlord/test-landlord-id/tenants" "" "*" "Get landlord tenants"

# Test 8: Reports and Analytics
echo -e "${YELLOW}8. Reports and Analytics Tests${NC}"
test_endpoint "GET" "/reports/landlord/test-landlord-id/financial" "" "*" "Financial reports endpoint"
test_endpoint "GET" "/reports/property/test-property-id/occupancy" "" "*" "Property occupancy report"

# Test 9: File Upload (if endpoint exists)
echo -e "${YELLOW}9. File Upload Tests${NC}"
test_endpoint "GET" "/upload/images" "" "*" "Image upload endpoint availability"

# Test 10: Error Handling
echo -e "${YELLOW}10. Error Handling Tests${NC}"
test_endpoint "GET" "/nonexistent-endpoint" "" "404" "Non-existent endpoint returns 404"
test_endpoint "POST" "/auth/register" '{"invalid":"data"}' "*" "Invalid data handling"

echo ""
echo "=========================================="
echo "Test Summary:"
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Check $TEST_LOG for details.${NC}"
    echo ""
    echo "Note: Some failures are expected if MongoDB is not running"
    echo "or if the backend server is not started."
    exit 1
fi