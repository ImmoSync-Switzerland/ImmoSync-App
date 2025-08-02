const http = require('http');

// Simple script to consolidate conversations
async function consolidateConversations() {
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/conversations/consolidate',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    }
  };

  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          console.log('Consolidation result:', result);
          resolve(result);
        } catch (e) {
          console.error('Error parsing response:', e);
          reject(e);
        }
      });
    });

    req.on('error', (e) => {
      console.error('Error making request:', e);
      reject(e);
    });

    req.end();
  });
}

// Check if this script is being run directly
if (require.main === module) {
  console.log('Starting conversation consolidation...');
  consolidateConversations()
    .then(() => {
      console.log('Consolidation completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Consolidation failed:', error);
      process.exit(1);
    });
}

module.exports = { consolidateConversations };
