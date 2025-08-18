const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/documents/'); // Make sure this directory exists
  },
  filename: function (req, file, cb) {
    // Generate unique filename
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: function (req, file, cb) {
    // Allow only specific file types
    const allowedTypes = ['.pdf', '.doc', '.docx', '.txt', '.png', '.jpg', '.jpeg'];
    const fileExt = path.extname(file.originalname).toLowerCase();
    
    if (allowedTypes.includes(fileExt)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only PDF, DOC, DOCX, TXT, PNG, JPG, JPEG files are allowed.'));
    }
  }
});

// Get all documents for a landlord
router.get('/landlord/:landlordId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const landlordId = req.params.landlordId;
    
    const documents = await db.collection('documents')
      .find({ uploadedBy: landlordId })
      .sort({ uploadDate: -1 })
      .toArray();
    
    res.json(documents);
  } catch (error) {
    console.error('Error fetching landlord documents:', error);
    res.status(500).json({ message: 'Error fetching documents' });
  } finally {
    await client.close();
  }
});

// Get documents for a specific tenant
router.get('/tenant/:tenantId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const tenantId = req.params.tenantId;
    console.log(`\n=== Fetching documents for tenant: ${tenantId} ===`);
    
    // First, get the tenant's information
    const tenant = await db.collection('users')
      .findOne({ _id: new ObjectId(tenantId) });
    
    console.log('Tenant found:', tenant ? {
      id: tenant._id,
      name: tenant.fullName || tenant.name,
      propertyId: tenant.propertyId,
      role: tenant.role
    } : 'null');
    
    let propertyIds = [];
    
    // Method 1: Check if tenant has propertyId field
    if (tenant && tenant.propertyId) {
      const propertyId = tenant.propertyId.toString();
      propertyIds.push(propertyId);
      propertyIds.push(tenant.propertyId);
    }
    
    // Method 2: Find properties where this tenant is in tenantIds array
    const propertiesWithTenant = await db.collection('properties')
      .find({ tenantIds: { $in: [tenantId] } })
      .toArray();
    
    console.log(`Found ${propertiesWithTenant.length} properties where tenant is assigned:`);
    propertiesWithTenant.forEach(prop => {
      const propId = prop._id.toString();
      if (!propertyIds.includes(propId)) {
        propertyIds.push(propId);
        propertyIds.push(prop._id); // Also add ObjectId format
      }
      console.log(`- Property: ${prop.address?.street || prop._id} (${propId})`);
    });
    
    console.log('All property IDs to search for:', propertyIds);
    
    // Find documents assigned to this tenant, their properties, or global documents
    const documents = await db.collection('documents')
      .find({
        $or: [
          { assignedTenantIds: tenantId },
          { assignedTenantIds: { $in: [tenantId, tenantId.toString()] } },
          { propertyIds: { $in: propertyIds } },
          { assignedTenantIds: { $size: 0 } }, // Global documents
          { assignedTenantIds: { $exists: false } },
          { propertyIds: { $size: 0 } }, // Global documents
          { propertyIds: { $exists: false } }
        ]
      })
      .sort({ uploadDate: -1 })
      .toArray();
    
    console.log(`Found ${documents.length} documents`);
    documents.forEach(doc => {
      console.log(`- Document: ${doc.name}, assigned to tenants: [${doc.assignedTenantIds?.join(', ') || 'none'}], assigned to properties: [${doc.propertyIds?.join(', ') || 'none'}]`);
    });
    
    console.log(`=== End tenant documents fetch ===\n`);
    res.json(documents);
  } catch (error) {
    console.error('Error fetching tenant documents:', error);
    res.status(500).json({ message: 'Error fetching documents' });
  } finally {
    await client.close();
  }
});

// Get documents for a specific property
router.get('/property/:propertyId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const propertyId = req.params.propertyId;
    
    const documents = await db.collection('documents')
      .find({
        $or: [
          { propertyIds: propertyId },
          { propertyIds: { $size: 0 } }, // Global documents
          { propertyIds: { $exists: false } }
        ]
      })
      .sort({ uploadDate: -1 })
      .toArray();
    
    res.json(documents);
  } catch (error) {
    console.error('Error fetching property documents:', error);
    res.status(500).json({ message: 'Error fetching documents' });
  } finally {
    await client.close();
  }
});

// Upload a new document
router.post('/upload', upload.single('document'), async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    await client.connect();
    const db = client.db(dbName);
    
    const {
      name,
      description,
      category,
      uploadedBy,
      assignedTenantIds,
      propertyIds,
      expiryDate
    } = req.body;

    // Parse JSON arrays if they're strings
    let parsedTenantIds = [];
    let parsedPropertyIds = [];
    
    try {
      parsedTenantIds = assignedTenantIds ? JSON.parse(assignedTenantIds) : [];
    } catch (e) {
      parsedTenantIds = assignedTenantIds ? [assignedTenantIds] : [];
    }
    
    try {
      parsedPropertyIds = propertyIds ? JSON.parse(propertyIds) : [];
    } catch (e) {
      parsedPropertyIds = propertyIds ? [propertyIds] : [];
    }

    const document = {
      name: name || req.file.originalname,
      description: description || '',
      category: category || 'Other',
      filePath: req.file.path,
      fileName: req.file.filename,
      originalName: req.file.originalname,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
      uploadDate: new Date(),
      uploadedBy: uploadedBy,
      assignedTenantIds: parsedTenantIds,
      propertyIds: parsedPropertyIds,
      expiryDate: expiryDate ? new Date(expiryDate) : null,
      status: 'active'
    };

    const result = await db.collection('documents').insertOne(document);
    
    res.status(201).json({
      message: 'Document uploaded successfully',
      documentId: result.insertedId,
      document: { ...document, _id: result.insertedId }
    });
  } catch (error) {
    console.error('Error uploading document:', error);
    res.status(500).json({ message: 'Error uploading document' });
  } finally {
    await client.close();
  }
});

// Update document metadata
router.put('/:documentId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const documentId = req.params.documentId;
    
    if (!ObjectId.isValid(documentId)) {
      return res.status(400).json({ message: 'Invalid document ID' });
    }

    const updateData = {
      ...req.body,
      updatedDate: new Date()
    };

    // Remove fields that shouldn't be updated
    delete updateData._id;
    delete updateData.filePath;
    delete updateData.fileName;
    delete updateData.uploadDate;

    const result = await db.collection('documents').updateOne(
      { _id: new ObjectId(documentId) },
      { $set: updateData }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Document not found' });
    }

    res.json({ message: 'Document updated successfully' });
  } catch (error) {
    console.error('Error updating document:', error);
    res.status(500).json({ message: 'Error updating document' });
  } finally {
    await client.close();
  }
});

// Delete a document
router.delete('/:documentId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const documentId = req.params.documentId;
    
    if (!ObjectId.isValid(documentId)) {
      return res.status(400).json({ message: 'Invalid document ID' });
    }

    // Get document info first to delete file
    const document = await db.collection('documents').findOne({ _id: new ObjectId(documentId) });
    
    if (!document) {
      return res.status(404).json({ message: 'Document not found' });
    }

    // Delete from database
    await db.collection('documents').deleteOne({ _id: new ObjectId(documentId) });

    // TODO: Delete file from filesystem
    // fs.unlinkSync(document.filePath);

    res.json({ message: 'Document deleted successfully' });
  } catch (error) {
    console.error('Error deleting document:', error);
    res.status(500).json({ message: 'Error deleting document' });
  } finally {
    await client.close();
  }
});

// Download a document
router.get('/download/:documentId', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const documentId = req.params.documentId;
    
    if (!ObjectId.isValid(documentId)) {
      return res.status(400).json({ message: 'Invalid document ID' });
    }

    const document = await db.collection('documents').findOne({ _id: new ObjectId(documentId) });
    
    if (!document) {
      return res.status(404).json({ message: 'Document not found' });
    }

    // Set headers for file download
    res.setHeader('Content-Disposition', `attachment; filename="${document.originalName}"`);
    res.setHeader('Content-Type', document.mimeType);
    
    // Send file
    res.sendFile(path.resolve(document.filePath));
  } catch (error) {
    console.error('Error downloading document:', error);
    res.status(500).json({ message: 'Error downloading document' });
  } finally {
    await client.close();
  }
});

// Assign document to tenants
router.post('/:documentId/assign-tenants', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const documentId = req.params.documentId;
    const { tenantIds } = req.body;
    
    if (!ObjectId.isValid(documentId)) {
      return res.status(400).json({ message: 'Invalid document ID' });
    }

    const result = await db.collection('documents').updateOne(
      { _id: new ObjectId(documentId) },
      { $set: { assignedTenantIds: tenantIds, updatedDate: new Date() } }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Document not found' });
    }

    res.json({ message: 'Document assigned to tenants successfully' });
  } catch (error) {
    console.error('Error assigning document to tenants:', error);
    res.status(500).json({ message: 'Error assigning document' });
  } finally {
    await client.close();
  }
});

// Assign document to properties
router.post('/:documentId/assign-properties', async (req, res) => {
  const client = new MongoClient(dbUri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    
    const documentId = req.params.documentId;
    const { propertyIds } = req.body;
    
    if (!ObjectId.isValid(documentId)) {
      return res.status(400).json({ message: 'Invalid document ID' });
    }

    const result = await db.collection('documents').updateOne(
      { _id: new ObjectId(documentId) },
      { $set: { propertyIds: propertyIds, updatedDate: new Date() } }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Document not found' });
    }

    res.json({ message: 'Document assigned to properties successfully' });
  } catch (error) {
    console.error('Error assigning document to properties:', error);
    res.status(500).json({ message: 'Error assigning document' });
  } finally {
    await client.close();
  }
});

module.exports = router;
