# ImmoLink

A modern property management application built with Flutter that connects landlords and tenants.

## Features

- **User Authentication**
  - Secure login/registration system
  - Role-based access (Landlord/Tenant)
  - Session management

- **Landlord Dashboard**
  - Property portfolio overview
  - Tenant management
  - Rent collection tracking
  - Maintenance request handling
  - Financial analytics

- **Tenant Dashboard**
  - Rent payment system
  - Maintenance request submission
  - Property information
  - Communication with landlord
  - Payment history

## Tech Stack

- Frontend: Flutter
- Backend: Node.js with Express
- Database: MongoDB
- API: REST + GraphQL (Apollo Server)
- State Management: Riverpod
- Navigation: GoRouter
- Authentication: Firebase Auth
- Cloud Storage: Firebase Storage

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/FabianBoni/ImmoLink.git
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up environment variables: Create ```bashlib/config/immolink.env``` with:
```bash
API_URL=your_api_url
MONGODB_URI=your_mongodb_uri
MONGODB_DB_NAME=your_db_name
```

4. Run the app:
```bash
flutter run
```

## API Documentation

ImmoSync provides both REST and GraphQL APIs for accessing backend services.

### GraphQL API

The GraphQL API is available at `/api/graphql` and provides a flexible, type-safe way to query and mutate data.

**Example Query:**
```graphql
query {
  supportRequests(status: "open") {
    id
    subject
    category
    priority
    status
    createdAt
  }
}
```

**Example Mutation:**
```graphql
mutation {
  createSupportRequest(input: {
    subject: "Need assistance"
    message: "Please help with..."
    category: "General"
    priority: "Medium"
  }) {
    success
    id
  }
}
```

For detailed GraphQL documentation, see [`backend/graphql/README.md`](backend/graphql/README.md).

To test the GraphQL API:
```bash
node backend/test-graphql.js http://localhost:3000/api/graphql YOUR_SESSION_TOKEN
```