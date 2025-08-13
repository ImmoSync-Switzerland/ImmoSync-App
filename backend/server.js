const express = require('express');
const cors = require('cors');
const path = require('path');
const { connectDB } = require('./database');
const app = express();
const authRoutes = require('./routes/auth');
const auth2faRoutes = require('./routes/auth-2fa');
const propertyRoutes = require('./routes/properties');
const usersRouter = require('./routes/users');
const contactsRoutes = require('./routes/contacts');
const conversationsRoutes = require('./routes/conversations');
const chatRoutes = require('./routes/chat');
const invitationsRoutes = require('./routes/invitations');
const uploadRoutes = require('./routes/upload');
const imagesRoutes = require('./routes/images');
const maintenanceRoutes = require('./routes/maintenance');
const maintenanceRequestsRoutes = require('./routes/maintenance-requests');
const emailRoutes = require('./routes/email');
const notificationRoutes = require('./routes/notifications');
const servicesRoutes = require('./routes/services');
const ticketsRoutes = require('./routes/tickets');

// Enable CORS for all routes
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Mount auth routes
app.use('/api/auth', authRoutes);
app.use('/api/auth/2fa', auth2faRoutes);

// Mount routes
app.use('/api/properties', propertyRoutes);

app.use('/api/users', usersRouter);

app.use('/api/contacts', contactsRoutes);

app.use('/api/conversations', conversationsRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/invitations', invitationsRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/images', imagesRoutes);
app.use('/api/maintenance', maintenanceRoutes);
app.use('/api/maintenance-requests', maintenanceRequestsRoutes);
app.use('/api/email', emailRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/services', servicesRoutes);
app.use('/api/tickets', ticketsRoutes);

// Add specific route for /api/tenants that points to users/tenants
app.use('/api/tenants', (req, res, next) => {
  // Redirect /api/tenants to /api/users/tenants
  req.url = '/tenants' + req.url;
  usersRouter(req, res, next);
});

const PORT = process.env.PORT || 3000;

// Initialize database connection and start server
async function startServer() {
  try {
    await connectDB();
    console.log('Database connected successfully');
  } catch (error) {
    console.warn('Database connection failed - running in development mode:', error.message);
    console.log('Server will start without database connection');
  }
  
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/api/health`);
  });
}

startServer();