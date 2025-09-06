# ImmoLink Backend - Complete API Setup

This document describes the complete backend setup for ImmoLink, including all API endpoints, database setup, and payment integration.

## New Features Added

### 🏦 Payment System (Stripe + Bank Transfer)
- Complete payment processing with Stripe integration
- Bank transfer support with manual verification
- Recurring payment support
- Payment receipts and tracking
- Multiple currency support (CHF, EUR)

### 📊 Activity Tracking System
- User activity logging
- Real-time activity feeds
- Activity statistics and analytics
- Read/unread status tracking

### 💬 Enhanced Chat System
- Find-or-create conversation endpoints
- Document and image sharing
- Message status tracking

### 🔐 Authentication Enhancements
- Password change functionality
- Enhanced 2FA support
- Session management

## API Endpoints

### Payments API (`/api/payments`)
```
GET    /tenant/:tenantId              - Get payments by tenant
GET    /property/:propertyId          - Get payments by property  
GET    /landlord/:landlordId          - Get payments by landlord
GET    /:id                          - Get payment by ID
GET    /:paymentId/receipt           - Get payment receipt
POST   /                             - Create new payment
POST   /:id/process-stripe           - Process Stripe payment
POST   /:id/process-bank-transfer    - Process bank transfer
POST   /stripe-webhook               - Stripe webhook handler
PUT    /:id                          - Update payment
PATCH  /:id/cancel                   - Cancel payment
DELETE /:id                          - Delete payment
```

### Activities API (`/api/activities`)
```
GET    /user/:userId                 - Get user activities
GET    /landlord/:landlordId         - Get landlord activities (includes tenants)
GET    /user/:userId/stats           - Get activity statistics
POST   /                             - Create new activity
PATCH  /:activityId/read             - Mark activity as read
PATCH  /user/:userId/mark-all-read   - Mark all activities as read
DELETE /:activityId                  - Delete activity
DELETE /cleanup/:userId              - Cleanup old activities
```

### Enhanced Conversations API (`/api/conversations`)
```
POST   /find-or-create               - Find or create conversation
GET    /user/current                 - Get current user conversations
```

### Enhanced Auth API (`/api/auth`)
```
PATCH  /change-password              - Change user password
```

## Database Setup

### SQL Database (Primary)
Run the provided `database_setup.sql` file to create the complete database structure:

```sql
mysql -u root -p < database_setup.sql
```

This creates:
- 16 core tables with proper relationships
- Indexes for optimal performance
- Views for common queries
- Stored procedures for complex operations
- Triggers for automatic data updates
- Default admin user and sample data

### MongoDB (Current/Fallback)
The existing MongoDB setup continues to work as a fallback system.

## Environment Configuration

Copy `immolink.env.example` to `.env` and configure:

```env
# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_your_key
STRIPE_SECRET_KEY=sk_test_your_key
STRIPE_WEBHOOK_SECRET=whsec_your_secret

# Database
DB_HOST=localhost
DB_USER=immolink_app
DB_PASSWORD=your_password
DB_NAME=immolink_db

# Security
JWT_SECRET=your_jwt_secret
BCRYPT_ROUNDS=10
```

## Payment Integration

### Stripe Setup
1. Create a Stripe account
2. Get API keys from dashboard
3. Set up webhook endpoint: `/api/payments/stripe-webhook`
4. Configure webhook events:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`

### Bank Transfer Support
- Manual verification workflow
- Reference number tracking
- Bank account validation
- Transfer confirmation system

## Key Features

### 🔄 Recurring Payments
- Automatic monthly/quarterly/yearly payments
- Parent-child payment relationships
- Configurable intervals

### 📈 Activity Tracking
- Automatic activity creation via triggers
- User action logging
- Performance analytics
- Cleanup procedures

### 🔒 Security Features
- Password hashing with bcrypt
- JWT token authentication
- Rate limiting support
- Audit logging

### 📊 Database Optimization
- Proper indexing strategy
- Full-text search capabilities
- Composite indexes for complex queries
- Partitioning ready structure

## Installation

1. **Install Dependencies**:
   ```bash
   cd backend
   npm install
   ```

2. **Database Setup**:
   ```bash
   # For MySQL
   mysql -u root -p < database_setup.sql
   
   # For MongoDB (existing)
   node scripts/init_db.js
   ```

3. **Environment Configuration**:
   ```bash
   cp immolink.env.example .env
   # Edit .env with your configuration
   ```

4. **Start Server**:
   ```bash
   npm start
   ```

## Nginx reverse proxy for API (413 fix)

If your API is behind Nginx and large encrypted uploads fail with 413, configure the reverse proxy for bigger bodies and streaming:

1. Copy `backend/nginx/api.conf` to `/etc/nginx/sites-available/immolink-api` and adjust `server_name` and `proxy_pass`.
2. Enable and reload:
   ```bash
   sudo ln -s /etc/nginx/sites-available/immolink-api /etc/nginx/sites-enabled/immolink-api
   sudo nginx -t && sudo systemctl reload nginx
   ```
3. Align backend limit via env:
   ```env
   CHAT_MAX_ATTACHMENT_MB=50
   ```
4. Restart the backend service to apply the new env.

## Testing the Payment System

### Test Stripe Payments
Use Stripe test cards:
- Success: `4242424242424242`
- Decline: `4000000000000002`
- 3D Secure: `4000002500003155`

### Test Bank Transfers
1. Create payment with `bank_transfer` method
2. Submit bank transfer details
3. Manually verify in admin panel
4. Update status to `completed`

## Database Tables Overview

| Table | Purpose |
|-------|---------|
| `users` | User accounts and authentication |
| `properties` | Property listings and details |
| `payments` | Payment transactions and history |
| `maintenance_requests` | Maintenance and repair requests |
| `conversations` | Chat conversations |
| `messages` | Individual chat messages |
| `activities` | User activity tracking |
| `invitations` | Property and tenant invitations |
| `notifications` | System notifications |
| `services` | Landlord services management |

## Performance Considerations

### Indexing Strategy
- Primary keys on all tables
- Foreign key indexes
- Composite indexes for common queries
- Full-text search indexes

### Caching
- Consider Redis for session storage
- Cache frequently accessed data
- Implement query result caching

### Scaling
- Database connection pooling
- Horizontal scaling ready
- Microservice architecture compatible

## Security Best Practices

1. **Input Validation**: All inputs sanitized and validated
2. **SQL Injection Prevention**: Parameterized queries only
3. **Authentication**: JWT tokens with expiration
4. **Authorization**: Role-based access control
5. **Data Encryption**: Sensitive data encrypted at rest
6. **Audit Logging**: All actions logged for compliance

## Monitoring and Maintenance

### Health Checks
- Database connectivity
- External service availability
- Payment processor status

### Backup Strategy
- Daily automated backups
- Point-in-time recovery
- Cross-region replication

### Log Management
- Centralized logging
- Error tracking
- Performance monitoring

## Support and Documentation

For additional support:
1. Check the API documentation in `/docs`
2. Review error logs in `/logs`
3. Monitor health endpoint: `/api/health`
4. Contact system administrator

## Migration from MongoDB

A migration script is available to transfer data from MongoDB to SQL:
```bash
node scripts/migrate_mongo_to_sql.js
```

This ensures seamless transition while maintaining data integrity.
