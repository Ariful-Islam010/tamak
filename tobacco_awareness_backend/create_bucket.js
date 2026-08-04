const { S3Client, CreateBucketCommand, PutBucketPolicyCommand } = require('@aws-sdk/client-s3');
const config = require('./config');

const s3Client = new S3Client({
  endpoint: 'http://o12bztxe41lfi8e0e8nj090h.163.227.239.97.sslip.io:80',
  region: 'us-east-1',
  credentials: {
    accessKeyId: config.MINIO_ACCESS_KEY,
    secretAccessKey: config.MINIO_SECRET_KEY,
  },
  forcePathStyle: true,
});

const BUCKET_NAME = config.MINIO_BUCKET_NAME || 'tamak';

async function setupBucket() {
  try {
    await s3Client.send(new CreateBucketCommand({ Bucket: BUCKET_NAME }));
    console.log('Bucket created!');
  } catch (e) {
    console.log('Error creating bucket (may already exist):', e.message);
  }

  try {
    const policy = {
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: "*",
          Action: ["s3:GetObject"],
          Resource: [`arn:aws:s3:::${BUCKET_NAME}/*`]
        }
      ]
    };
    await s3Client.send(new PutBucketPolicyCommand({
      Bucket: BUCKET_NAME,
      Policy: JSON.stringify(policy)
    }));
    console.log('Bucket policy set to public read!');
  } catch (e) {
    console.log('Error setting policy:', e.message);
  }
}

setupBucket();
