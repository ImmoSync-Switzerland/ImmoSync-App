const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');
const multer = require('multer');
const path = require('path');
const notifications = require('./notifications');
const fs = require('fs');

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

// Get all documents for a landlord (by direct upload OR by properties owned)
router.get('/landlord/:landlordId', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const landlordId = req.params.landlordId;
  const debug = req.query.debug === '1' || req.query.debug === 'true';

    const validObjectId = ObjectId.isValid(landlordId) ? new ObjectId(landlordId) : null;
    // Fetch property ids owned by landlord (string + ObjectId forms)
    const properties = await db.collection('properties').find({
      $or: [
        { landlordId: landlordId },
        validObjectId ? { landlordId: validObjectId } : { _never: true }
      ]
    }, { projection: { _id: 1 } }).toArray();
    const propertyIdStrings = properties.map(p => p._id.toString());
    const propertyObjectIds = properties.map(p => p._id);

    const query = {
      $or: [
        { uploadedBy: landlordId },
        { uploadedBy: landlordId.toString() },
        // Documents missing uploadedBy but referencing landlord's properties
        { $and: [ { uploadedBy: { $exists: false } }, { propertyIds: { $in: propertyIdStrings } } ] },
        { propertyIds: { $in: propertyIdStrings } },
        { propertyIds: { $in: propertyObjectIds } }
      ]
    };

    if (debug) {
      console.log('[documents][landlord] landlordId=', landlordId, 'properties count=', properties.length);
      console.log('[documents][landlord] propertyIdStrings=', propertyIdStrings);
      console.log('[documents][landlord] query=', JSON.stringify(query));
    }

    let rawDocs = await db.collection('documents').find(query).sort({ uploadDate: -1 }).toArray();

    // Fallback: if none, try documents with no uploadedBy and no propertyIds (global) just to validate visibility
    if (rawDocs.length === 0) {
      const fallback = await db.collection('documents').find({ uploadedBy: { $exists: false } }).limit(5).toArray();
      if (debug) {
        console.log('[documents][landlord] primary query returned 0; fallback(no uploadedBy) size=', fallback.length);
      }
      rawDocs = rawDocs.concat(fallback);
    }
    // Deduplicate by _id
    const seen = new Set();
    const documents = [];
    for (const d of rawDocs) {
      const idStr = d._id.toString();
      if (!seen.has(idStr)) { seen.add(idStr); documents.push(d); }
    }
    if (debug) {
      console.log('[documents][landlord] final.documents.count=', documents.length);
      documents.slice(0,5).forEach(d=>console.log('[documents][landlord] sample doc', d._id.toString(), {uploadedBy:d.uploadedBy, propertyIds:d.propertyIds}));
    }
    res.json(debug ? { count: documents.length, documents } : documents);
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
    
    // First, get the tenant's property information
    const tenant = await db.collection('users')
      .findOne({ _id: new ObjectId(tenantId) });
    
    console.log('Tenant found:', tenant ? {
      id: tenant._id,
      name: tenant.fullName || tenant.name,
      propertyId: tenant.propertyId,
      role: tenant.role
    } : 'null');
    
    let propertyIds = [];
    if (tenant && tenant.propertyId) {
      // Handle both string and ObjectId formats
      const propertyId = tenant.propertyId.toString();
      propertyIds.push(propertyId);
      propertyIds.push(tenant.propertyId); // Also try the original format
    }
    
    console.log('Property IDs to search for:', propertyIds);
    
    // Find documents assigned to this tenant, their property, or global documents
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

    // Notify assigned tenants
    if (parsedTenantIds && parsedTenantIds.length) {
      parsedTenantIds.forEach(tid => notifications.sendDomainNotification(tid, {
        title: 'New Document Assigned',
        body: document.name,
        type: 'document_assigned',
        data: { documentId: result.insertedId.toString() }
      }));
    }
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
    // If stored as binary in DB (fileData), stream directly
    if (!document.filePath && document.fileData) {
      try {
        const bin = document.fileData; // Could be BSON Binary or base64 string
        let buffer;
        if (bin && bin.buffer) {
          buffer = Buffer.from(bin.buffer);
        } else if (typeof bin === 'string') {
          buffer = Buffer.from(bin, 'base64');
        }
        if (buffer) {
          res.setHeader('Content-Disposition', `attachment; filename="${document.originalName || 'file'}"`);
          res.setHeader('Content-Type', document.mimeType || 'application/octet-stream');
          res.setHeader('Content-Length', buffer.length);
          return res.end(buffer);
        }
      } catch (e) {
        console.warn('[documents/download] binary fallback error', e.message);
      }
    }

    if (!document.filePath) {
      return res.status(404).json({ message: 'File path missing' });
    }

    const resolved = path.resolve(document.filePath);
    if (!fs.existsSync(resolved)) {
      return res.status(404).json({ message: 'File not found on disk' });
    }

    res.setHeader('Content-Disposition', `attachment; filename="${document.originalName}"`);
    res.setHeader('Content-Type', document.mimeType || 'application/octet-stream');
    res.sendFile(resolved);
  } catch (error) {
    console.error('Error downloading document:', error);
    res.status(500).json({ message: 'Error downloading document' });
  } finally {
    await client.close();
  }
});

// Serve raw document content inline (e.g., for images) at /api/documents/:documentId/raw
router.get('/:documentId/raw', async (req, res) => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const documentId = req.params.documentId;
    const debug = req.query.debug === '1' || req.query.debug === 'true';

    if (!ObjectId.isValid(documentId)) {
      return res.status(400).json({ message: 'Invalid document ID' });
    }

    const document = await db.collection('documents').findOne({ _id: new ObjectId(documentId) });
    if (!document) {
      return res.status(404).json({ message: 'Document not found' });
    }
    const attempts = [];
    const recordDetails = {
      hasFilePath: Boolean(document.filePath),
      hasFileName: Boolean(document.fileName),
      filePath: document.filePath,
      fileName: document.fileName,
  mimeType: document.mimeType,
  cwd: process.cwd()
    };

    function consider(label, candidate) {
      const exists = candidate && fs.existsSync(candidate);
      attempts.push({ label, candidate, exists });
      return exists;
    }

    const rootDir = path.resolve(__dirname, '..'); // backend directory
    const uploadsDir = path.join(rootDir, 'uploads', 'documents');
  const cwdUploadsDir = path.join(process.cwd(), 'uploads', 'documents');
  const parentUploadsDir = path.join(rootDir, '..', 'uploads', 'documents');
    let absPath = null;

    // 1. Direct stored filePath (as-is, resolved)
    if (document.filePath) {
      const direct = path.isAbsolute(document.filePath)
        ? document.filePath
        : path.resolve(document.filePath);
      if (consider('stored.filePath', direct)) {
        absPath = direct;
      }
    }
    // 2. Stored filePath joined with backend root (covers relative persisted from diff CWD)
    if (!absPath && document.filePath && !path.isAbsolute(document.filePath)) {
      const joinedRoot = path.join(rootDir, document.filePath);
      if (consider('root+filePath', joinedRoot)) {
        absPath = joinedRoot;
      }
    }
    // 3. Reconstruct from fileName inside uploads/documents (expected normal case)
    if (!absPath && document.fileName) {
      const reconstructed = path.join(uploadsDir, document.fileName);
      if (consider('uploadsDir+fileName', reconstructed)) {
        absPath = reconstructed;
      }
    }
    // 3b. Reconstruct from process.cwd()/uploads/documents (if server started one level above backend)
    if (!absPath && document.fileName) {
      const cwdPath = path.join(cwdUploadsDir, document.fileName);
      if (consider('cwdUploadsDir+fileName', cwdPath)) {
        absPath = cwdPath;
      }
    }
    // 3c. Reconstruct from parent of backend (../uploads/documents)
    if (!absPath && document.fileName) {
      const parentPath = path.join(parentUploadsDir, document.fileName);
      if (consider('parentUploadsDir+fileName', parentPath)) {
        absPath = parentPath;
      }
    }
    // 4. Try process.cwd() variant (in case server started above backend)
    if (!absPath && document.fileName) {
      const cwdVariant = path.join(process.cwd(), 'backend', 'uploads', 'documents', document.fileName);
      if (consider('cwd+backend+uploads+fileName', cwdVariant)) {
        absPath = cwdVariant;
      }
    }
    // 5. If fileName has different casing / look for any file starting with base name
    if (!absPath && document.fileName) {
      try {
        const base = path.parse(document.fileName).name; // without extension
        if (fs.existsSync(uploadsDir)) {
          const variants = fs.readdirSync(uploadsDir).filter(f => f.startsWith(base));
          if (variants.length === 1) {
            const variantPath = path.join(uploadsDir, variants[0]);
            if (consider('uploadsDir+detectedVariant', variantPath)) {
              absPath = variantPath;
            }
          } else if (variants.length > 1 && debug) {
            attempts.push({ label: 'variant.multiple', candidate: variants, exists: true });
          }
        }
      } catch (e) {
        console.warn('[documents/raw] variant scan error', e.message);
      }
    }

    // 6. In-DB binary fallback (fileData) if no file on disk
    let inDbBuffer = null;
    if (!absPath && document.fileData) {
      try {
        const bin = document.fileData;
        if (bin && bin.buffer) {
          inDbBuffer = Buffer.from(bin.buffer);
        } else if (typeof bin === 'string') {
          inDbBuffer = Buffer.from(bin, 'base64');
        }
        if (inDbBuffer) {
          attempts.push({ label: 'inlineBinary', candidate: 'mongodbBinary', exists: true });
        }
      } catch (e) {
        attempts.push({ label: 'inlineBinary.error', candidate: e.message, exists: false });
      }
    }

    if (!absPath && inDbBuffer) {
      if (debug) {
        console.log('[documents/raw] serving from Mongo binary for', documentId, 'size', inDbBuffer.length);
      }
      res.setHeader('Content-Type', document.mimeType || 'application/octet-stream');
      res.setHeader('Cache-Control', 'public, max-age=3600');
      res.setHeader('Content-Length', inDbBuffer.length);
      return res.end(inDbBuffer);
    }

    if (!absPath) {
      const errorPayload = { message: 'File path missing', attempts: debug ? attempts : undefined, record: debug ? recordDetails : undefined, note: 'No filesystem path resolved and no usable in-DB binary' };
      return res.status(404).json(errorPayload);
    }

    if (!fs.existsSync(absPath)) {
      return res.status(404).json({ message: 'File not found on disk', resolved: debug ? absPath : undefined });
    }

    if (debug) {
      console.log('[documents/raw] resolved path', absPath, 'attempts:', attempts);
    }

    // Set proper content-type for inline display
    res.setHeader('Content-Type', document.mimeType || 'application/octet-stream');
    res.setHeader('Cache-Control', 'public, max-age=3600');
    const stream = fs.createReadStream(absPath);
    stream.on('error', (err) => {
      console.error('Stream error serving raw document:', err);
      if (!res.headersSent) {
        res.status(500).json({ message: 'Error reading file' });
      }
    });
    stream.pipe(res);
  } catch (error) {
    console.error('Error serving raw document:', error);
    if (!res.headersSent) {
      res.status(500).json({ message: 'Error serving document' });
    }
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
