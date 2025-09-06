const express = require('express');
const multer = require('multer');
const { GridFSBucket, ObjectId } = require('mongodb');
const { getDB } = require('../database');
const router = express.Router();

// Memory storage: we receive ALREADY ENCRYPTED bytes from client (ciphertext only)
const MAX_MB = parseInt(process.env.CHAT_MAX_ATTACHMENT_MB || process.env.MAX_ATTACHMENT_MB || '20', 10);
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_MB * 1024 * 1024 } // configurable cap (default 20MB)
});

// POST /api/chat/attachments/:conversationId
// Fields: senderId, receiverId(optional), messageType(image|file), fileName, iv, tag, v, size(optional)
// File field: file (ciphertext bytes). Server does NOT decrypt; stores as-is.
router.post('/attachments/:conversationId', upload.single('file'), async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { senderId, receiverId, messageType = 'file', fileName, iv, tag, v } = req.body;
    if (!senderId || !conversationId || !req.file || !fileName || !iv || !tag || !v) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    const db = getDB();
    const bucket = new GridFSBucket(db, { bucketName: 'chat_attachments' });
    const filename = `${Date.now()}-${fileName}`;
    const uploadStream = bucket.openUploadStream(filename, {
      metadata: {
        originalName: fileName,
        mimeType: req.file.mimetype || 'application/octet-stream',
        encrypted: true,
        iv, tag, v: parseInt(v, 10) || 1,
        uploadDate: new Date(),
      }
    });
    uploadStream.end(req.file.buffer);
    uploadStream.on('error', (e) => {
      console.error('[ChatAttachment][Upload][Error]', e);
      if (!res.headersSent) res.status(500).json({ message: 'Upload failed' });
    });
    uploadStream.on('finish', async () => {
      try {
        const message = {
          conversationId,
          senderId,
          receiverId: receiverId || null,
          content: fileName, // show file name (plaintext is not stored)
          timestamp: new Date(),
          messageType,
          isRead: false,
          attachments: [],
          metadata: {
            fileName,
            fileId: uploadStream.id.toString(),
            bucket: 'chat_attachments',
            mimeType: req.file.mimetype || 'application/octet-stream',
            fileSize: req.file.size,
            ciphertextStored: true,
            iv, tag, encVersion: parseInt(v,10) || 1,
          },
          e2ee: { ciphertext: '<gridfs>', iv, tag, v: parseInt(v,10) || 1, type: messageType },
          isEncrypted: true,
          deliveredAt: new Date(),
          readAt: null
        };
        const result = await db.collection('messages').insertOne(message);
        await db.collection('conversations').updateOne(
          { _id: new ObjectId(conversationId) },
          { $set: { lastMessage: `[${messageType}]`, lastMessageTime: new Date(), updatedAt: new Date() } }
        );
        res.status(201).json({ message: 'Attachment stored', stored: { ...message, _id: result.insertedId } });
      } catch (e) {
        console.error('[ChatAttachment][Persist][Error]', e);
        if (!res.headersSent) res.status(500).json({ message: 'Failed to persist message' });
      }
    });
  } catch (e) {
    console.error('[ChatAttachment][Route][Error]', e);
    if (!res.headersSent) res.status(500).json({ message: 'Server error' });
  }
});

// Download raw encrypted file (client will decrypt) by fileId
router.get('/attachments/file/:id', async (req, res) => {
  try {
    const { id } = req.params;
    if (!ObjectId.isValid(id)) return res.status(400).json({ message: 'Invalid id' });
    const db = getDB();
    const bucket = new GridFSBucket(db, { bucketName: 'chat_attachments' });
    const fileId = new ObjectId(id);
    const files = await bucket.find({ _id: fileId }).toArray();
    if (!files.length) return res.status(404).json({ message: 'Not found' });
    res.set({
      'Content-Type': files[0].metadata?.mimeType || 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${files[0].metadata?.originalName || 'file'}"`
    });
    bucket.openDownloadStream(fileId).pipe(res);
  } catch (e) {
    console.error('[ChatAttachment][Download][Error]', e);
    if (!res.headersSent) res.status(500).json({ message: 'Download failed' });
  }
});

module.exports = router;