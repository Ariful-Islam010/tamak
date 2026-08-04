const { S3Client, CreateBucketCommand, PutBucketPolicyCommand, ListBucketsCommand } = require('@aws-sdk/client-s3');
const config = require('./config');

const s3Client = new S3Client({
  endpoint: 'http://163.227.239.97:9000',
  region: 'us-east-1',
  credentials: {
    accessKeyId: config.MINIO_ACCESS_KEY,
    secretAccessKey: config.MINIO_SECRET_KEY,
  },
  forcePathStyle: true,
});

async function run() {
  try {
    const buckets = await s3Client.send(new ListBucketsCommand({}));
    console.log('Buckets:', buckets.Buckets.map(b => b.Name));
  } catch (e) {
    console.log('Error:', e.message);
  }
}

run();
