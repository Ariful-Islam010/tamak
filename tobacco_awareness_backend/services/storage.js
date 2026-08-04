const { S3Client, PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const config = require('../config');

const s3Client = new S3Client({
  endpoint: config.MINIO_ENDPOINT,
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
  return `${config.MINIO_ENDPOINT}/${BUCKET_NAME}/${fileName}`;
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
