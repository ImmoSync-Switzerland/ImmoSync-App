/**
 * GraphQL API Test Script
 * 
 * This script demonstrates how to use the GraphQL API for support requests.
 * It includes examples of queries and mutations.
 * 
 * Usage: node test-graphql.js [API_URL] [SESSION_TOKEN]
 * Example: node test-graphql.js http://localhost:3000/api/graphql abc123token
 */

const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

const API_URL = process.argv[2] || 'http://localhost:3000/api/graphql';
const SESSION_TOKEN = process.argv[3] || null;

// Example GraphQL queries and mutations
const QUERIES = {
  // Query to list all support requests
  listSupportRequests: `
    query ListSupportRequests {
      supportRequests {
        id
        subject
        category
        priority
        status
        createdAt
      }
    }
  `,
  
  // Query to list support requests filtered by status
  listOpenRequests: `
    query ListOpenRequests {
      supportRequests(status: "open") {
        id
        subject
        category
        priority
        status
        createdAt
      }
    }
  `,
  
  // Query to get a specific support request by ID
  getSupportRequest: (id) => `
    query GetSupportRequest {
      supportRequest(id: "${id}") {
        id
        subject
        message
        category
        priority
        status
        userId
        notes {
          body
          author
          createdAt
        }
        meta
        createdAt
        updatedAt
      }
    }
  `,
};

const MUTATIONS = {
  // Mutation to create a new support request
  createSupportRequest: `
    mutation CreateSupportRequest {
      createSupportRequest(input: {
        subject: "GraphQL Test Request"
        message: "This is a test support request created via GraphQL API"
        category: "Feature Request"
        priority: "Medium"
      }) {
        success
        id
        message
      }
    }
  `,
  
  // Mutation to update a support request
  updateSupportRequest: (id) => `
    mutation UpdateSupportRequest {
      updateSupportRequest(
        id: "${id}"
        input: {
          note: "Added a note via GraphQL API"
        }
      ) {
        success
        updated
        message
      }
    }
  `,
  
  // Mutation to change status
  changeStatus: (id, status) => `
    mutation ChangeStatus {
      updateSupportRequest(
        id: "${id}"
        input: {
          status: "${status}"
        }
      ) {
        success
        updated
        message
      }
    }
  `,
};

// Helper function to make GraphQL requests
async function graphqlRequest(query, description) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`Testing: ${description}`);
  console.log(`${'='.repeat(60)}`);
  
  const headers = {
    'Content-Type': 'application/json',
  };
  
  if (SESSION_TOKEN) {
    headers['Authorization'] = `Bearer ${SESSION_TOKEN}`;
  }
  
  try {
    const response = await fetch(API_URL, {
      method: 'POST',
      headers,
      body: JSON.stringify({ query }),
    });
    
    const result = await response.json();
    
    if (result.errors) {
      console.error('❌ GraphQL Errors:');
      result.errors.forEach(error => {
        console.error(`  - ${error.message}`);
      });
    }
    
    if (result.data) {
      console.log('✅ Success! Response:');
      console.log(JSON.stringify(result.data, null, 2));
    }
    
    return result;
  } catch (error) {
    console.error('❌ Request failed:', error.message);
    return null;
  }
}

// Main test function
async function runTests() {
  console.log('\n');
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║         GraphQL API Test Suite - Support Requests         ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log(`\nAPI URL: ${API_URL}`);
  console.log(`Auth Token: ${SESSION_TOKEN ? '✓ Provided' : '✗ Not provided (will fail)'}`);
  
  if (!SESSION_TOKEN) {
    console.log('\n⚠️  WARNING: No session token provided!');
    console.log('   GraphQL mutations require authentication.');
    console.log('   Please provide a session token as the second argument.\n');
    console.log('   Usage: node test-graphql.js <API_URL> <SESSION_TOKEN>\n');
  }
  
  // Test 1: Create a support request
  const createResult = await graphqlRequest(
    MUTATIONS.createSupportRequest,
    'Create Support Request (Mutation)'
  );
  
  let createdId = null;
  if (createResult?.data?.createSupportRequest?.id) {
    createdId = createResult.data.createSupportRequest.id;
  }
  
  // Test 2: List all support requests
  await graphqlRequest(
    QUERIES.listSupportRequests,
    'List All Support Requests (Query)'
  );
  
  // Test 3: List only open requests
  await graphqlRequest(
    QUERIES.listOpenRequests,
    'List Open Support Requests (Query)'
  );
  
  // Test 4: Get specific support request (if we created one)
  if (createdId) {
    await graphqlRequest(
      QUERIES.getSupportRequest(createdId),
      'Get Specific Support Request (Query)'
    );
    
    // Test 5: Add a note to the support request
    await graphqlRequest(
      MUTATIONS.updateSupportRequest(createdId),
      'Add Note to Support Request (Mutation)'
    );
    
    // Test 6: Change status to 'in-progress'
    await graphqlRequest(
      MUTATIONS.changeStatus(createdId, 'in-progress'),
      'Change Request Status (Mutation)'
    );
  } else {
    console.log('\n⚠️  Skipping tests that require a created request ID');
  }
  
  console.log('\n');
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║                     Tests Completed                        ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('\n');
  console.log('Example GraphQL queries you can use:');
  console.log('\n1. List all support requests:');
  console.log(QUERIES.listSupportRequests);
  console.log('\n2. Create a support request:');
  console.log(MUTATIONS.createSupportRequest);
  console.log('\n');
}

// Run the tests
runTests().catch(console.error);
