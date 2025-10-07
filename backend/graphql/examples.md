# GraphQL API Examples

This file contains practical examples of using the ImmoSync GraphQL API.

## Table of Contents
- [Authentication](#authentication)
- [Queries](#queries)
- [Mutations](#mutations)
- [Error Handling](#error-handling)
- [Using with Different Clients](#using-with-different-clients)

## Authentication

All requests require a session token in the Authorization header:

```bash
Authorization: Bearer YOUR_SESSION_TOKEN
```

You can obtain a session token by logging in through the REST API:

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'
```

## Queries

### 1. List All Support Requests

**Basic Query:**
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

**cURL Example:**
```bash
curl -X POST http://localhost:3000/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "query": "{ supportRequests { id subject status } }"
  }'
```

### 2. Filter Support Requests by Status

**Query:**
```graphql
query GetOpenRequests {
  supportRequests(status: "open") {
    id
    subject
    category
    priority
    createdAt
  }
}
```

**JavaScript Example:**
```javascript
const response = await fetch('http://localhost:3000/api/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${sessionToken}`
  },
  body: JSON.stringify({
    query: `
      query GetOpenRequests {
        supportRequests(status: "open") {
          id
          subject
          category
        }
      }
    `
  })
});

const result = await response.json();
console.log(result.data.supportRequests);
```

### 3. Get a Specific Support Request with Notes

**Query:**
```graphql
query GetRequestDetails {
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
    meta
    createdAt
    updatedAt
  }
}
```

**Python Example:**
```python
import requests

query = """
query GetRequestDetails {
  supportRequest(id: "507f1f77bcf86cd799439011") {
    id
    subject
    status
    notes {
      body
      createdAt
    }
  }
}
"""

response = requests.post(
    'http://localhost:3000/api/graphql',
    json={'query': query},
    headers={
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {session_token}'
    }
)

data = response.json()
print(data['data']['supportRequest'])
```

## Mutations

### 1. Create a Support Request

**Mutation:**
```graphql
mutation CreateRequest {
  createSupportRequest(input: {
    subject: "Feature Request: Dark Mode"
    message: "It would be great to have a dark mode option in the app"
    category: "Feature Request"
    priority: "Low"
  }) {
    success
    id
    message
  }
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:3000/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "query": "mutation { createSupportRequest(input: { subject: \"Dark Mode\", message: \"Please add dark mode\", category: \"Feature Request\", priority: \"Low\" }) { success id message } }"
  }'
```

### 2. Add a Note to Support Request

**Mutation:**
```graphql
mutation AddNote {
  updateSupportRequest(
    id: "507f1f77bcf86cd799439011"
    input: {
      note: "I have reviewed this request and it's being considered for the next release."
    }
  ) {
    success
    updated
    message
  }
}
```

**JavaScript Example (with variables):**
```javascript
const mutation = `
  mutation AddNote($requestId: ID!, $noteText: String!) {
    updateSupportRequest(
      id: $requestId
      input: { note: $noteText }
    ) {
      success
      message
    }
  }
`;

const variables = {
  requestId: "507f1f77bcf86cd799439011",
  noteText: "Adding additional information..."
};

const response = await fetch('http://localhost:3000/api/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${sessionToken}`
  },
  body: JSON.stringify({ query: mutation, variables })
});

const result = await response.json();
```

### 3. Change Support Request Status

**Mutation:**
```graphql
mutation ChangeStatus {
  updateSupportRequest(
    id: "507f1f77bcf86cd799439011"
    input: { status: "in-progress" }
  ) {
    success
    updated
    message
  }
}
```

**Note:** Only users with `admin` or `support` roles can change the status of support requests.

### 4. Update Both Status and Add Note

**Mutation:**
```graphql
mutation UpdateRequest {
  updateSupportRequest(
    id: "507f1f77bcf86cd799439011"
    input: {
      status: "resolved"
      note: "This issue has been resolved in version 2.1.0"
    }
  ) {
    success
    updated
    message
  }
}
```

## Error Handling

### Common Errors

**1. Unauthorized (No Token):**
```json
{
  "errors": [
    {
      "message": "Unauthorized",
      "path": ["supportRequests"]
    }
  ],
  "data": null
}
```

**2. Forbidden (Insufficient Permissions):**
```json
{
  "errors": [
    {
      "message": "Forbidden",
      "path": ["supportRequest"]
    }
  ],
  "data": null
}
```

**3. Not Found:**
```json
{
  "errors": [
    {
      "message": "Not found",
      "path": ["supportRequest"]
    }
  ],
  "data": null
}
```

**4. Invalid Input:**
```json
{
  "data": {
    "createSupportRequest": {
      "success": false,
      "id": null,
      "message": "Subject and message are required"
    }
  }
}
```

## Using with Different Clients

### Apollo Client (React)

```javascript
import { ApolloClient, InMemoryCache, gql } from '@apollo/client';

const client = new ApolloClient({
  uri: 'http://localhost:3000/api/graphql',
  cache: new InMemoryCache(),
  headers: {
    Authorization: `Bearer ${sessionToken}`
  }
});

// Query
const { data } = await client.query({
  query: gql`
    query GetRequests {
      supportRequests {
        id
        subject
        status
      }
    }
  `
});

// Mutation
const { data } = await client.mutate({
  mutation: gql`
    mutation CreateRequest($input: CreateSupportRequestInput!) {
      createSupportRequest(input: $input) {
        success
        id
      }
    }
  `,
  variables: {
    input: {
      subject: "New Request",
      message: "Request details...",
      category: "General",
      priority: "Medium"
    }
  }
});
```

### GraphQL Request (Node.js)

```javascript
const { request } = require('graphql-request');

const endpoint = 'http://localhost:3000/api/graphql';

const query = `
  query {
    supportRequests {
      id
      subject
    }
  }
`;

const data = await request({
  url: endpoint,
  document: query,
  requestHeaders: {
    Authorization: `Bearer ${sessionToken}`
  }
});
```

### Postman

1. Create a new POST request to `http://localhost:3000/api/graphql`
2. Add header: `Authorization: Bearer YOUR_TOKEN`
3. Set body to raw JSON:
```json
{
  "query": "{ supportRequests { id subject status } }"
}
```

### Flutter/Dart (graphql_flutter package)

```dart
import 'package:graphql_flutter/graphql_flutter.dart';

final HttpLink httpLink = HttpLink('http://localhost:3000/api/graphql');

final AuthLink authLink = AuthLink(
  getToken: () => 'Bearer $sessionToken',
);

final Link link = authLink.concat(httpLink);

final GraphQLClient client = GraphQLClient(
  cache: GraphQLCache(),
  link: link,
);

// Query
const String query = '''
  query {
    supportRequests {
      id
      subject
      status
    }
  }
''';

final QueryResult result = await client.query(
  QueryOptions(document: gql(query)),
);
```

## Advanced Examples

### Introspection Query (Explore Schema)

```graphql
query IntrospectionQuery {
  __schema {
    types {
      name
      kind
      description
    }
  }
}
```

### Type Details

```graphql
query GetTypeDetails {
  __type(name: "SupportRequest") {
    name
    fields {
      name
      type {
        name
        kind
      }
    }
  }
}
```

## Best Practices

1. **Use Variables:** Instead of string interpolation, use GraphQL variables for dynamic values
2. **Request Only What You Need:** GraphQL allows you to request only the fields you need
3. **Handle Errors:** Always check for both `errors` and `data` in the response
4. **Batch Requests:** Consider using GraphQL batching for multiple operations
5. **Use Aliases:** When querying the same field multiple times with different arguments
6. **Cache Results:** Implement caching on the client side for better performance

## Testing

Run the comprehensive test script:

```bash
node backend/test-graphql.js http://localhost:3000/api/graphql YOUR_SESSION_TOKEN
```

This will execute various queries and mutations to verify the GraphQL API functionality.
