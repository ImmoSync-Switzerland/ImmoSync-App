/**
 * Backfill script to fix messages that have receiverId missing or incorrectly set equal to senderId.
 * Heuristic: For each affected message, look up its conversation; pick the OTHER participant
 * (from participants array or landlordId/tenantId fields) and set receiverId to that value.
 * Skips updates if a plausible other participant cannot be resolved.
 */

require('dotenv').config();
const { MongoClient, ObjectId } = require('mongodb');

const uri = process.env.MONGO_URI || process.env.DB_URI || 'mongodb://localhost:27017';
const dbName = process.env.DB_NAME || 'immolink_db';

async function run() {
  const client = new MongoClient(uri);
  try {
    await client.connect();
    const db = client.db(dbName);
    console.log('[Backfill] Connected to DB');

    // Find candidate messages (receiverId missing OR receiverId == senderId) limited batch
    const cursor = db.collection('messages').find({
      $or: [
        { receiverId: { $exists: false } },
        { receiverId: null },
        { $expr: { $eq: ['$receiverId', '$senderId'] } }
      ]
    }, { projection: { conversationId: 1, senderId: 1, receiverId: 1 } });

    let processed = 0, updated = 0, skipped = 0;
    while (await cursor.hasNext()) {
      const msg = await cursor.next();
      processed++;
      if (!msg.conversationId || !ObjectId.isValid(msg.conversationId)) { skipped++; continue; }
      const conv = await db.collection('conversations').findOne({ _id: new ObjectId(msg.conversationId) }, { projection: { participants: 1, landlordId: 1, tenantId: 1 } });
      if (!conv) { skipped++; continue; }
      let participants = Array.isArray(conv.participants) ? conv.participants.map(p => p && p.toString()) : [];
      if (participants.length !== 2) {
        // Fallback to landlord / tenant fields
        participants = [conv.landlordId, conv.tenantId].filter(Boolean).map(p => p.toString());
      }
      if (participants.length !== 2) { skipped++; continue; }
      const other = participants.find(p => p !== msg.senderId);
      if (!other || other === msg.receiverId) { skipped++; continue; }
      const res = await db.collection('messages').updateOne({ _id: msg._id }, { $set: { receiverId: other } });
      if (res.modifiedCount === 1) {
        updated++;
        console.log('[Backfill] Updated message %s -> receiverId=%s', msg._id.toString(), other);
      } else {
        skipped++;
      }
    }
    console.log(`[Backfill] Done processed=${processed} updated=${updated} skipped=${skipped}`);
  } catch (e) {
    console.error('[Backfill] Error', e);
  } finally {
    await client.close();
  }
}

run();
