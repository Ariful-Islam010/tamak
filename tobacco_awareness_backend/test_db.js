const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgres://postgres:tamak_secure_password_123@163.227.239.97:5434/tamak'
});

client.connect()
  .then(() => {
    console.log('Successfully connected to the database.');
    return client.query('SELECT NOW()');
  })
  .then((res) => {
    console.log('Query result:', res.rows[0]);
    return client.end();
  })
  .catch((err) => {
    console.error('Database connection error:', err);
    process.exit(1);
  });
