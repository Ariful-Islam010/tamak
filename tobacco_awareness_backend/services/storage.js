const { S3Client, PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const config = require('../config');

// Ensure the internal endpoint has a protocol
let minioEndpoint = config.MINIO_ENDPOINT;
if (!minioEndpoint.startsWith('http://') && !minioEndpoint.startsWith('https://')) {
  minioEndpoint = 'http://' + minioEndpoint;
}

const s3Client = new S3Client({
  endpoint: minioEndpoint,
  region: 'us-east-1', // MinIO default
  credentials: {
    accessKeyId: config.MINIO_ACCESS_KEY,
    secretAccessKey: config.MINIO_SECRET_KEY,
  },
  forcePathStyle: true, // Required for MinIO
});

const BUCKET_NAME = config.MINIO_BUCKET_NAME || 'tamak';

async function uploadFile(fileBuffer, fileName, mimetype) {
  const params = {
    Bucket: BUCKET_NAME,
    Key: fileName,
    Body: fileBuffer,
    ContentType: mimetype,
  };

  await s3Client.send(new PutObjectCommand(params));
  
  // Return the public URL
  // Remove trailing slash if present from public URL, then append bucket and filename
  const pubUrl = config.MINIO_PUBLIC_URL.replace(/\/$/, '');
  let finalPubUrl = pubUrl;
  if (!pubUrl.startsWith('http://') && !pubUrl.startsWith('https://')) {
    finalPubUrl = 'http://' + pubUrl;
  }
  return `${finalPubUrl}/${BUCKET_NAME}/${fileName}`;
}

async function deleteFile(fileName) {
  const params = {
    Bucket: BUCKET_NAME,
    Key: fileName,
  };

  await s3Client.send(new DeleteObjectCommand(params));
}

module.exports = {
  s3Client,
  uploadFile,
  deleteFile,
  BUCKET_NAME
};
