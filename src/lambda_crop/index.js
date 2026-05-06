'use strict';

const AWS = require('aws-sdk');
const sharp = require('sharp');

const s3 = new AWS.S3({ signatureVersion: 'v4' });

const SIZE = 40;

const respondBatch = (failures) => ({
  batchItemFailures: failures
});

const parseS3Event = (record) => {
  if (!record?.body) {
    return { error: 'Missing SQS body.' };
  }

  let payload;
  try {
    payload = JSON.parse(record.body);
  } catch (error) {
    return { error: 'Invalid SQS body JSON.' };
  }

  const s3Record = payload?.Records?.[0]?.s3;
  const bucket = s3Record?.bucket?.name;
  const key = s3Record?.object?.key;

  if (!bucket || !key) {
    return { error: 'Missing S3 bucket or key.' };
  }

  return {
    bucket,
    key: decodeURIComponent(key.replace(/\+/g, ' '))
  };
};

const buildCircleMask = () => {
  const radius = SIZE / 2;
  return Buffer.from(
    `<svg width="${SIZE}" height="${SIZE}" viewBox="0 0 ${SIZE} ${SIZE}" xmlns="http://www.w3.org/2000/svg">` +
      `<circle cx="${radius}" cy="${radius}" r="${radius}" fill="white"/>` +
    `</svg>`
  );
};

exports.handler = async (event) => {
  const bucketOverride = process.env.S3_BUCKET;
  const processedPrefix = process.env.PROCESSED_PREFIX || 'processed/';
  const records = event?.Records || [];

  console.log('crop-lambda invoked', { recordCount: records.length });

  if (!bucketOverride) {
    console.error('S3_BUCKET is not configured.');
    return respondBatch(records.map((record) => ({ itemIdentifier: record.messageId })));
  }

  const failures = [];
  const circleMask = buildCircleMask();

  for (const record of records) {
    const { bucket, key, error } = parseS3Event(record);
    if (error) {
      console.error('Invalid S3 event payload', { error, messageId: record.messageId });
      failures.push({ itemIdentifier: record.messageId });
      continue;
    }

    const sourceBucket = bucketOverride || bucket;
    const safePrefix = processedPrefix.endsWith('/') ? processedPrefix : `${processedPrefix}/`;
    const baseName = key.split('/').pop() || key;
    const targetKey = `${safePrefix}${baseName.replace(/\.[^.]+$/, '')}.png`;

    try {
      const sourceObject = await s3
        .getObject({
          Bucket: sourceBucket,
          Key: key
        })
        .promise();

      const processedBuffer = await sharp(sourceObject.Body)
        .resize(SIZE, SIZE, { fit: 'cover' })
        .composite([{ input: circleMask, blend: 'dest-in' }])
        .png()
        .toBuffer();

      await s3
        .putObject({
          Bucket: sourceBucket,
          Key: targetKey,
          Body: processedBuffer,
          ContentType: 'image/png'
        })
        .promise();

      console.log('crop-lambda processed file', {
        messageId: record.messageId,
        source: key,
        target: targetKey
      });
    } catch (err) {
      console.error('crop-lambda failed', {
        messageId: record.messageId,
        error: err?.message || err
      });
      failures.push({ itemIdentifier: record.messageId });
    }
  }

  return respondBatch(failures);
};
