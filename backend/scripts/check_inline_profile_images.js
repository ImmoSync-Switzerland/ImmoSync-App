// Checks users for inline profile images and reports sizes/mime
require('dotenv').config();
const { MongoClient } = require('mongodb');
const { dbUri, dbName } = require('../config');

(async function run() {
  const client = new MongoClient(dbUri);
  try {
    await client.connect();
    const db = client.db(dbName);
    const users = await db.collection('users').find({ 'profileImageInline.data': { $exists: true } }, { projection: { _id: 1, email: 1, fullName: 1, profileImageInline: 1 } }).toArray();
    console.log(`Users with inline images: ${users.length}`);
    for (const u of users) {
      const bytes = u.profileImageInline?.data?.length || u.profileImageInline?.data?.buffer?.length || 0;
      console.log(`${u._id.toString()} ${u.email || ''} ${u.fullName || ''} -> ${bytes} bytes, type=${u.profileImageInline?.contentType}`);
    }
  } catch (e) {
    console.error(e);
  } finally {
    await client.close();
  }
})();
