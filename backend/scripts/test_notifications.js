#!/usr/bin/env node
/**
 * Notification system end-to-end exerciser.
 *
 * Usage (PowerShell):
 *   node backend/scripts/test_notifications.js --baseUrl=http://localhost:3000/api --user=USER1 --user=USER2 --topic=general
 *
 * What it does:
 * 1. Registers a mock FCM token for each provided user.
 * 2. Sends a direct notification to first user.
 * 3. Sends a bulk notification to all users.
 * 4. Sends a topic notification (if --topic given).
 * 5. Sends sample payment reminder & maintenance notifications (synthetic data).
 * 6. Lists notifications for each user and prints summaries.
 * 7. Marks all notifications as read for first user.
 */

const fetch = (...args) => import('node-fetch').then(({default: f}) => f(...args));
const crypto = require('crypto');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = { users: [], baseUrl: 'http://localhost:3000/api', topic: null };
  for (const a of args) {
    if (a.startsWith('--baseUrl=')) out.baseUrl = a.split('=')[1];
    else if (a.startsWith('--user=')) out.users.push(a.split('=')[1]);
    else if (a.startsWith('--topic=')) out.topic = a.split('=')[1];
  }
  if (out.users.length === 0) {
    console.error('At least one --user=ID required');
    process.exit(1);
  }
  return out;
}

async function post(url, body) {
  const resp = await fetch(url, { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(body)});
  const json = await resp.json().catch(()=>({ raw: true }));
  if (!resp.ok) throw new Error(`POST ${url} -> ${resp.status} ${JSON.stringify(json)}`);
  return json;
}

async function get(url) {
  const resp = await fetch(url);
  const json = await resp.json().catch(()=>({ raw: true }));
  if (!resp.ok) throw new Error(`GET ${url} -> ${resp.status} ${JSON.stringify(json)}`);
  return json;
}

async function registerTokens(baseUrl, users) {
  console.log('\n[1] Registering mock tokens');
  for (const u of users) {
    const token = 'mock_'+crypto.randomBytes(8).toString('hex');
    await post(`${baseUrl}/notifications/register-token`, { userId: u, token });
    console.log(`  user ${u} -> ${token}`);
  }
}

async function sendDirect(baseUrl, user) {
  console.log('\n[2] Direct notification');
  return post(`${baseUrl}/notifications/send-to-user`, {
    userId: user,
    title: 'Direct Test',
    body: 'Hello from test script',
    type: 'general',
    data: { origin: 'script', scenario: 'direct' }
  });
}

async function sendBulk(baseUrl, users) {
  console.log('\n[3] Bulk notification');
  return post(`${baseUrl}/notifications/send-to-users`, {
    userIds: users,
    title: 'Bulk Test',
    body: `Hello ${users.length} users`,
    type: 'general',
    data: { origin: 'script', scenario: 'bulk' }
  });
}

async function sendTopic(baseUrl, topic) {
  console.log('\n[4] Topic notification');
  return post(`${baseUrl}/notifications/send-to-topic`, {
    topic,
    title: 'Topic Test',
    body: `Message for topic ${topic}`,
    type: 'general',
    data: { origin: 'script', scenario: 'topic' }
  });
}

async function sendPaymentReminders(baseUrl, users) {
  console.log('\n[5] Payment reminders');
  const reminders = users.map((u,i)=>({
    userId: u,
    propertyAddress: `Sample Street ${i+1}`,
    amount: `$${(i+1)*100}`,
    dueDate: new Date(Date.now()+86400000).toISOString().slice(0,10)
  }));
  return post(`${baseUrl}/notifications/send-payment-reminders`, { reminders });
}

async function sendMaintenance(baseUrl, users) {
  console.log('\n[6] Maintenance updates');
  const notifications = users.map((u,i)=>({
    userId: u,
    requestId: 'REQ'+(1000+i),
    status: 'in_progress',
    propertyAddress: `Maint Ave ${i+1}`
  }));
  return post(`${baseUrl}/notifications/send-maintenance-notifications`, { notifications });
}

async function listForUsers(baseUrl, users) {
  console.log('\n[7] Listing notifications');
  const out = {};
  for (const u of users) {
    const json = await get(`${baseUrl}/notifications/list/${u}?limit=20`);
    out[u] = json.notifications || [];
    console.log(`  user ${u}: ${out[u].length} notifications (showing up to 3)`);
    out[u].slice(0,3).forEach(n=> console.log(`    - [${n.type}] ${n.title} :: ${n.body}`));
  }
  return out;
}

async function markAllRead(baseUrl, user) {
  console.log('\n[8] Mark all read for first user');
  return post(`${baseUrl}/notifications/mark-read`, { userId: user, all: true });
}

(async function main(){
  const { users, baseUrl, topic } = parseArgs();
  const summary = {};
  try {
    await registerTokens(baseUrl, users);
    summary.direct = await sendDirect(baseUrl, users[0]);
    summary.bulk = await sendBulk(baseUrl, users);
    if (topic) summary.topic = await sendTopic(baseUrl, topic);
    summary.payment = await sendPaymentReminders(baseUrl, users);
    summary.maintenance = await sendMaintenance(baseUrl, users);
    summary.lists = await listForUsers(baseUrl, users);
    summary.mark = await markAllRead(baseUrl, users[0]);
    console.log('\n[Summary] Completed notification test flow.');
  } catch (e) {
    console.error('Test script failed:', e.message);
    process.exitCode = 1;
  }
})();
