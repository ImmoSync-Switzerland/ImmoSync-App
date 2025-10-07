# GraphQL API Documentation

This directory contains the GraphQL API implementation for ImmoSync. The GraphQL API provides an alternative to the REST API for querying and mutating data.

## Endpoint

```
POST /api/graphql
```

## Authentication

All GraphQL requests require authentication. Include your session token in the request headers:

```
Authorization: Bearer YOUR_SESSION_TOKEN
```

Or:

```
x-session-token: YOUR_SESSION_TOKEN
```

## Schema

### Types

#### SupportRequest
```graphql
type SupportRequest {
  id: ID!
  subject: String!
  message: String!
  category: String!
  priority: String!
  status: String!
  userId: String
  notes: [Note!]!
  meta: JSON
  createdAt: String!
  updatedAt: String!
}
```

#### Note
```graphql
type Note {
  body: String!
  author: String!
  createdAt: String!
}
```

### Queries

#### Get all support requests
```graphql
query {
  supportRequests {
    id
    subject
    category
    priority
    status
    createdAt
  }
}
```

With filters:
```graphql
query {
  supportRequests(status: "open") {
    id
    subject
    status
  }
}
```

#### Get a specific support request
```graphql
query {
  supportRequest(id: "507f1f77bcf86cd799439011") {
    id
    subject
    message
    category
    priority
    status
    notes {
      body
      author
      createdAt
    }
    createdAt
    updatedAt
  }
}
```

### Mutations

#### Create a support request
```graphql
mutation {
  createSupportRequest(input: {
    subject: "Need help with feature"
    message: "I would like to request a new feature..."
    category: "Feature Request"
    priority: "Medium"
  }) {
    success
    id
    message
  }
}
```

#### Update a support request
```graphql
mutation {
  updateSupportRequest(
    id: "507f1f77bcf86cd799439011"
    input: {
      note: "Adding additional information..."
    }
  ) {
    success
    updated
    message
  }
}
```

Change status:
```graphql
mutation {
  updateSupportRequest(
    id: "507f1f77bcf86cd799439011"
    input: {
      status: "in-progress"
    }
  ) {
    success
    updated
    message
  }
}
```

## Using with curl

### List all support requests
```bash
curl -X POST http://localhost:3000/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "query": "{ supportRequests { id subject status } }"
  }'
```

### Create a support request
```bash
curl -X POST http://localhost:3000/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "query": "mutation { createSupportRequest(input: { subject: \"Test\", message: \"Test message\", category: \"General\", priority: \"Low\" }) { success id message } }"
  }'
```

## Using with GraphQL Playground

The GraphQL API includes introspection, so you can explore the schema using tools like:

- GraphQL Playground: Visit `http://localhost:3000/api/graphql` in your browser (if configured)
- Apollo Studio: Connect to your endpoint
- Postman: Use the GraphQL request type

## Testing

Run the test script to verify the GraphQL API:

```bash
node test-graphql.js http://localhost:3000/api/graphql YOUR_SESSION_TOKEN
```

## Error Handling

GraphQL errors are returned in the standard format:

```json
{
  "errors": [
    {
      "message": "Unauthorized",
      "locations": [{ "line": 2, "column": 3 }],
      "path": ["supportRequests"]
    }
  ]
}
```

Common errors:
- `Unauthorized` - No valid session token provided
- `Forbidden` - User doesn't have permission to access the resource
- `Not found` - Requested resource doesn't exist
- `Invalid id` - Provided ID is not a valid MongoDB ObjectId

## Authorization

- Regular users can only see their own support requests
- Users with `admin` or `support` roles can see all support requests
- Only staff members can change the status of support requests
- All authenticated users can create support requests and add notes to their own requests

## Files

- `schema.js` - GraphQL type definitions
- `resolvers.js` - Query and mutation resolvers
- `index.js` - Apollo Server configuration
- `README.md` - This documentation file
