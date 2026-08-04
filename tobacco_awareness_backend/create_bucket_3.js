const { S3Client, CreateBucketCommand, PutBucketPolicyCommand, ListBucketsCommand } = require('@aws-sdk/client-s3');

const s3Client = new S3Client({
  endpoint: 'http://163.227.239.97:9000',
  region: 'us-east-1',
  credentials: {
    accessKeyId: '8922aafdca5f5e996e60a920',
    secretAccessKey: '26328691fcb53b5f033f128e9176beb5dee452024cc7f699',
  },
  forcePathStyle: true,
});

async function run() {
  try {
    const buckets = await s3Client.send(new ListBucketsCommand({}));
    const bucketNames = buckets.Buckets.map(b => b.Name);
    console.log('Buckets:', bucketNames);
    if (!bucketNames.includes('tamak')) {
      await s3Client.send(new CreateBucketCommand({ Bucket: 'tamak' }));
      console.log('Created tamak bucket');
      
      const policy = {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: { AWS: ['*'] },
            Action: ['s3:GetObject'],
            Resource: ['arn:aws:s3:::tamak/*'],
          },
        ],
      };
      
      await s3Client.send(new PutBucketPolicyCommand({
        Bucket: 'tamak',
        Policy: JSON.stringify(policy),
      }));
      console.log('Set tamak bucket to public');
    }
  } catch (e) {
    console.log('Error:', e.message);
  }
}

run();
