const mongoose = require('mongoose');

const maintenanceRequestSchema = new mongoose.Schema({
  propertyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Property',
    required: true
  },
  tenantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  landlordId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  category: {
    type: String,
    enum: ['plumbing', 'electrical', 'heating', 'cooling', 'appliances', 'structural', 'cleaning', 'pest_control', 'other'],
    required: true
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'urgent'],
    default: 'medium'
  },
  status: {
    type: String,
    enum: ['pending', 'in_progress', 'completed', 'cancelled'],
    default: 'pending'
  },
  location: {
    type: String,
    required: true,
    trim: true
  },
  images: [{
    type: String // GridFS file IDs for maintenance request images
  }],
  notes: [{
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    content: {
      type: String,
      required: true
    },
    timestamp: {
      type: Date,
      default: Date.now
    }
  }],
  requestedDate: {
    type: Date,
    default: Date.now
  },
  scheduledDate: {
    type: Date
  },
  completedDate: {
    type: Date
  },
  urgencyLevel: {
    type: Number,
    min: 1,
    max: 5,
    default: 3
  },
  cost: {
    estimated: Number,
    actual: Number
  },
  contractorInfo: {
    name: String,
    contact: String,
    company: String
  }
}, {
  timestamps: true
});

// Indexes for better query performance
maintenanceRequestSchema.index({ propertyId: 1, status: 1 });
maintenanceRequestSchema.index({ landlordId: 1, priority: 1 });
maintenanceRequestSchema.index({ tenantId: 1, status: 1 });
maintenanceRequestSchema.index({ createdAt: -1 });

const MaintenanceRequest = mongoose.model('MaintenanceRequest', maintenanceRequestSchema);

module.exports = MaintenanceRequest;
