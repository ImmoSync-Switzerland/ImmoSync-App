# GraphQL API Architecture

This document describes the architecture of the GraphQL API implementation in ImmoSync.

## Overview

The GraphQL API is built on top of Apollo Server v5 and provides an alternative interface to the existing REST API for managing support requests.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                      │
│  (Flutter App, Web App, Mobile App, CLI Tools, etc.)      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTP POST /api/graphql
                         │ { query, variables, operationName }
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    Express Server                           │
│                    (server.js)                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │
┌────────────────────────▼────────────────────────────────────┐
│              GraphQL Handler (graphql/index.js)             │
│  • Parses request body                                      │
│  • Extracts authentication token                            │
│  • Creates context with user info                           │
│  • Executes GraphQL operation                               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │
┌────────────────────────▼────────────────────────────────────┐
│           Apollo Server (graphql/index.js)                  │
│  • Validates query against schema                           │
│  • Resolves requested fields                                │
│  • Handles errors                                            │
└────────────────────────┬────────────────────────────────────┘
                         │
            ┌────────────┴─────────────┐
            │                          │
┌───────────▼────────┐      ┌─────────▼──────────┐
│  Schema            │      │  Resolvers         │
│  (schema.js)       │      │  (resolvers.js)    │
│                    │      │                    │
│  • Type Definitions│      │  • Query resolvers │
│  • Input Types     │      │  • Mutation        │
│  • Return Types    │      │    resolvers       │
│                    │      │  • Authorization   │
│                    │      │  • Business logic  │
└────────────────────┘      └──────────┬─────────┘
                                       │
                                       │
                          ┌────────────▼──────────────┐
                          │   MongoDB Database        │
                          │   (supportRequests)       │
                          │                           │
                          │   • CRUD operations       │
                          │   • Data persistence      │
                          └───────────────────────────┘
```

## Components

### 1. GraphQL Handler (`graphql/index.js`)

**Responsibilities:**
- Create and configure Apollo Server instance
- Extract authentication token from request headers
- Build context object with authenticated user
- Execute GraphQL operations
- Handle errors and format responses

**Key Functions:**
- `createApolloServer()` - Initializes Apollo Server
- `getContext(req)` - Extracts user from auth token
- `createGraphQLHandler(apolloServer)` - Creates Express middleware

### 2. Schema (`graphql/schema.js`)

**Responsibilities:**
- Define GraphQL types
- Specify available queries and mutations
- Define input/output types

**Types:**
- `SupportRequest` - Main entity type
- `Note` - Sub-entity for request notes
- `CreateSupportRequestInput` - Input for creating requests
- `UpdateSupportRequestInput` - Input for updating requests
- `CreateSupportRequestPayload` - Response for create mutation
- `UpdateSupportRequestPayload` - Response for update mutation
- `JSON` - Custom scalar for arbitrary JSON data

### 3. Resolvers (`graphql/resolvers.js`)

**Responsibilities:**
- Implement business logic for queries and mutations
- Validate user authorization
- Interact with MongoDB database
- Send notifications
- Handle errors

**Query Resolvers:**
- `supportRequests` - List all support requests (filtered by role)
- `supportRequest` - Get a specific support request by ID

**Mutation Resolvers:**
- `createSupportRequest` - Create a new support request
- `updateSupportRequest` - Update status or add notes

## Data Flow

### Query Flow Example: `supportRequests`

1. Client sends POST request to `/api/graphql` with query
2. Express routes to GraphQL handler
3. Handler extracts authentication token
4. Handler resolves user from token
5. Apollo Server validates query against schema
6. Apollo Server calls `supportRequests` resolver
7. Resolver checks user permissions
8. Resolver queries MongoDB
9. Resolver formats and returns data
10. Apollo Server serializes response
11. Client receives JSON response

### Mutation Flow Example: `createSupportRequest`

1. Client sends POST request with mutation and input
2. Express routes to GraphQL handler
3. Handler authenticates user
4. Apollo Server validates mutation
5. Apollo Server calls `createSupportRequest` resolver
6. Resolver validates input
7. Resolver creates document in MongoDB
8. Resolver sends notification
9. Resolver returns success response
10. Client receives confirmation with new request ID

## Authentication & Authorization

### Authentication
- JWT/Session token in `Authorization: Bearer TOKEN` header
- Token resolved to user document from MongoDB
- User attached to GraphQL context

### Authorization Rules

| Operation | Regular User | Admin/Support |
|-----------|-------------|---------------|
| List support requests | Own requests only | All requests |
| Get support request | Own requests only | All requests |
| Create support request | ✓ | ✓ |
| Add note | Own requests only | All requests |
| Change status | ✗ | ✓ |

## Error Handling

### GraphQL Errors

Errors are returned in standard GraphQL format:

```json
{
  "errors": [
    {
      "message": "Error message",
      "locations": [{ "line": 2, "column": 3 }],
      "path": ["fieldName"]
    }
  ],
  "data": null
}
```

### Common Error Types

1. **Authentication Errors**
   - `Unauthorized` - No token provided or invalid token

2. **Authorization Errors**
   - `Forbidden` - User doesn't have permission

3. **Validation Errors**
   - `Invalid id` - Malformed ObjectId
   - `Subject and message are required` - Missing required fields

4. **Not Found Errors**
   - `Not found` - Resource doesn't exist

## Integration with Existing REST API

The GraphQL API complements the existing REST API:

| Feature | REST Endpoint | GraphQL Equivalent |
|---------|--------------|-------------------|
| List requests | `GET /api/support-requests` | `query { supportRequests }` |
| Get request | `GET /api/support-requests/:id` | `query { supportRequest(id) }` |
| Create request | `POST /api/support-requests` | `mutation { createSupportRequest }` |
| Update request | `PUT /api/support-requests/:id` | `mutation { updateSupportRequest }` |

### Benefits of GraphQL over REST

1. **Flexible Queries** - Request only needed fields
2. **Type Safety** - Schema validation at runtime
3. **Single Endpoint** - All operations through `/api/graphql`
4. **Self-Documenting** - Introspection reveals full API
5. **Efficient** - Reduce over-fetching and under-fetching
6. **Versioning** - Schema evolution without breaking changes

## Performance Considerations

### Optimization Strategies

1. **Field Selection** - Clients specify exact fields needed
2. **Connection Pooling** - MongoDB client manages connections
3. **Caching** - Client-side caching with Apollo Client
4. **Batching** - Multiple operations in single request
5. **Pagination** - Limit query results (currently 200 max)

### Monitoring

- GraphQL errors logged to console
- Request/response logged in development
- Use Apollo Studio for production monitoring

## Future Enhancements

1. **DataLoader** - Batch and cache database requests
2. **Subscriptions** - Real-time updates via WebSocket
3. **Federation** - Split schema across multiple services
4. **Persisted Queries** - Reduce bandwidth for repeated queries
5. **Rate Limiting** - Protect against abusive queries
6. **More Entities** - Extend GraphQL to other resources (properties, users, etc.)
7. **File Uploads** - Support attachments in support requests
8. **Pagination** - Implement cursor-based pagination

## Testing

### Unit Tests
- Test resolvers independently
- Mock MongoDB connections
- Verify authorization logic

### Integration Tests
- Test full GraphQL operations
- Use test database
- Verify end-to-end flow

### Test Script
```bash
node backend/test-graphql.js http://localhost:3000/api/graphql TOKEN
```

## Security Best Practices

1. **Authentication Required** - All operations require valid token
2. **Authorization Checks** - Role-based access control
3. **Input Validation** - Sanitize and validate all inputs
4. **Query Depth Limiting** - Prevent deeply nested queries
5. **Query Complexity** - Analyze and limit expensive queries
6. **HTTPS Only** - Enforce encryption in production
7. **CORS Configuration** - Restrict allowed origins

## Deployment

### Environment Variables

None required - uses existing MongoDB configuration from `config.js`:
- `MONGODB_URI` - MongoDB connection string
- `MONGODB_DB_NAME` - Database name

### Production Checklist

- [ ] Set `introspection: false` in production
- [ ] Configure Apollo Studio for monitoring
- [ ] Enable query complexity analysis
- [ ] Set up error reporting (Sentry, etc.)
- [ ] Configure CORS properly
- [ ] Enable HTTPS
- [ ] Add rate limiting
- [ ] Set up logging and monitoring

## Resources

- [Apollo Server Documentation](https://www.apollographql.com/docs/apollo-server/)
- [GraphQL Specification](https://spec.graphql.org/)
- [GraphQL Best Practices](https://graphql.org/learn/best-practices/)
- [Backend GraphQL README](./README.md)
- [Backend GraphQL Examples](./examples.md)
