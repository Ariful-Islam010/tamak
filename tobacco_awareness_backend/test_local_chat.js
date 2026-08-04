const http = require('http');
const jwt = require('jsonwebtoken');

const token = jwt.sign(
  { sub: 'b0912977-1acd-44b7-b753-db214594e978', email: 'test@example.com' },
  'your_super_secret_jwt_key',
  { expiresIn: '1d' }
);

const postData = JSON.stringify({
  sender_id: 'b0912977-1acd-44b7-b753-db214594e978',
  content: 'Hello from test script'
});

const req = http.request({
  hostname: 'localhost',
  port: 8000,
  path: '/api/chat/messages',
  method: 'POST',
  headers: {
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData)
  }
}, (res) => {
  console.log('POST STATUS:', res.statusCode);
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('POST BODY:', data);
    process.exit(0);
  });
});

req.on('error', (e) => {
  console.error(`POST error: ${e.message}`);
  process.exit(1);
});

req.write(postData);
req.end();
