# GraphQL API Quick Start Guide

This guide will help you get started with the ImmoSync GraphQL API in 5 minutes.

## 🚀 Start the Server

```bash
cd backend
npm install
node server.js
```

The GraphQL endpoint will be available at: `http://localhost:3000/api/graphql`

## 🔑 Get Authentication Token

First, login via REST API to get a session token:

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "password": "your-password"
  }'
```

Save the `sessionToken` from the response.

## 📊 Your First Query

List all your support requests:

```bash
curl -X POST http://localhost:3000/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -d '{
    "query": "{ supportRequests { id subject status createdAt } }"
  }'
```

## ✏️ Your First Mutation

Create a new support request:

```bash
curl -X POST http://localhost:3000/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -d '{
    "query": "mutation { createSupportRequest(input: { subject: \"My First Request\", message: \"This is a test\", category: \"General\", priority: \"Low\" }) { success id message } }"
  }'
```

## 🧪 Run Tests

Test the API with the included test script:

```bash
node test-graphql.js http://localhost:3000/api/graphql YOUR_SESSION_TOKEN
```

## 🔍 Explore the Schema

Introspection query to see all available types:

```bash
curl -X POST http://localhost:3000/api/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __schema { types { name kind } } }"
  }'
```

## 📚 Common Queries

### Get a specific support request

```graphql
query {
  supportRequest(id: "YOUR_REQUEST_ID") {
    id
    subject
    message
    status
    notes {
      body
      author
      createdAt
    }
  }
}
```

### Filter by status

```graphql
query {
  supportRequests(status: "open") {
    id
    subject
    priority
  }
}
```

## 📝 Common Mutations

### Add a note

```graphql
mutation {
  updateSupportRequest(
    id: "YOUR_REQUEST_ID"
    input: {
      note: "Adding more details..."
    }
  ) {
    success
    message
  }
}
```

### Change status (admin/support only)

```graphql
mutation {
  updateSupportRequest(
    id: "YOUR_REQUEST_ID"
    input: {
      status: "resolved"
    }
  ) {
    success
    message
  }
}
```

## 🔧 Use with GraphQL Client

### JavaScript/Node.js

```javascript
const fetch = require('node-fetch');

async function listRequests(token) {
  const response = await fetch('http://localhost:3000/api/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      query: `
        query {
          supportRequests {
            id
            subject
            status
          }
        }
      `
    })
  });
  
  const result = await response.json();
  return result.data.supportRequests;
}
```

### Python

```python
import requests

def list_requests(token):
    query = """
    query {
      supportRequests {
        id
        subject
        status
      }
    }
    """
    
    response = requests.post(
        'http://localhost:3000/api/graphql',
        json={'query': query},
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {token}'
        }
    )
    
    return response.json()['data']['supportRequests']
```

### Flutter/Dart

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<dynamic>> listRequests(String token) async {
  final response = await http.post(
    Uri.parse('http://localhost:3000/api/graphql'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'query': '''
        query {
          supportRequests {
            id
            subject
            status
          }
        }
      '''
    }),
  );
  
  final result = jsonDecode(response.body);
  return result['data']['supportRequests'];
}
```

## 📖 Next Steps

1. **Read the full documentation**: [README.md](./README.md)
2. **See more examples**: [examples.md](./examples.md)
3. **Understand the architecture**: [ARCHITECTURE.md](./ARCHITECTURE.md)
4. **Explore the schema**: Use introspection or GraphQL Playground

## ⚠️ Important Notes

- **Authentication is required** for all operations
- **Regular users** can only access their own support requests
- **Admin/support users** can access all requests and change statuses
- **All requests** use the same endpoint: `/api/graphql`

## 🐛 Troubleshooting

### "Unauthorized" Error
- Make sure you included the `Authorization` header
- Verify your session token is valid (not expired)
- Check that you're using `Bearer TOKEN` format

### "Forbidden" Error
- You're trying to access a resource you don't own
- Only admin/support users can change request statuses

### "Not found" Error
- The requested ID doesn't exist
- Verify the ID format (must be a valid MongoDB ObjectId)

### Connection Refused
- Make sure the backend server is running
- Check the port number (default is 3000)
- Verify the URL is correct

## 💡 Tips

1. **Request only what you need** - GraphQL lets you specify exact fields
2. **Use variables** - Instead of string interpolation for dynamic values
3. **Check for errors** - Always examine both `errors` and `data` in responses
4. **Leverage introspection** - Explore the schema dynamically
5. **Use GraphQL Playground** - For interactive testing during development

## 🎯 Quick Reference

| Action | Method | Endpoint |
|--------|--------|----------|
| List requests | POST | /api/graphql |
| Get request | POST | /api/graphql |
| Create request | POST | /api/graphql |
| Update request | POST | /api/graphql |
| Schema introspection | POST | /api/graphql |

All operations use the same endpoint with different GraphQL queries/mutations!

## 📞 Support

For issues or questions:
- Check the [documentation](./README.md)
- Review [examples](./examples.md)
- Understand the [architecture](./ARCHITECTURE.md)
- Run the test script: `node test-graphql.js`

---

**Happy coding! 🚀**
