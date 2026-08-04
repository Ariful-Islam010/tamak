const fs = require('fs');
const http = require('http');
const path = require('path');
const jwt = require('jsonwebtoken');

const token = jwt.sign({ sub: 1, email: 'test@example.com' }, 'your_super_secret_jwt_key', { expiresIn: '1d' });

const filePath = '/home/alvee/Pictures/drive.png';
const stat = fs.statSync(filePath);
const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';

const req = http.request({
  hostname: 'localhost',
  port: 8000,
  path: '/api/upload',
  method: 'POST',
  headers: {
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'multipart/form-data; boundary=' + boundary
  }
}, (res) => {
  console.log('STATUS:', res.statusCode);
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => console.log('BODY:', data));
});

req.on('error', (e) => {
  console.error(`problem with request: ${e.message}`);
});

const pre = `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="drive.png"\r\nContent-Type: image/png\r\n\r\n`;
const post = `\r\n--${boundary}--\r\n`;

req.write(pre);
const stream = fs.createReadStream(filePath);
stream.on('data', chunk => req.write(chunk));
stream.on('end', () => {
  req.write(post);
  req.end();
});
