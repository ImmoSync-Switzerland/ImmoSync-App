// Script to normalize landlordId field in properties collection to always be a string
// Usage (PowerShell): node backend/scripts/normalize_landlord_ids.js

const { MongoClient, ObjectId } = require('mongodb');
const { dbUri, dbName } = require('../config');

(async () => {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const collection = db.collection('properties');

    console.log('[Normalize] Scanning for properties with ObjectId landlordId...');

    const cursor = collection.find({ landlordId: { $type: 'objectId' } });
    let updated = 0;
    while (await cursor.hasNext()) {
      const doc = await cursor.next();
      const legacyId = doc.landlordId;
      if (legacyId instanceof ObjectId) {
        await collection.updateOne({ _id: doc._id }, { $set: { landlordId: legacyId.toString() } });
        updated++;
      }
    }

    console.log(`[Normalize] Updated ${updated} documents.`);
    console.log('[Normalize] Verifying...');
    const remaining = await collection.countDocuments({ landlordId: { $type: 'objectId' } });
    console.log(`[Normalize] Remaining ObjectId landlordId docs: ${remaining}`);

    console.log('[Normalize] Done.');
  } catch (e) {
    console.error('[Normalize] Error:', e);
    process.exitCode = 1;
  } finally {
    await client.close();
  }
})();
