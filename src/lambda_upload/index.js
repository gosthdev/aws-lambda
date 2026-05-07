'use strict';

const AWS = require('aws-sdk');
const crypto = require('crypto');

const s3 = new AWS.S3({ signatureVersion: 'v4' });

const MAX_BYTES = 10 * 1024 * 1024;
const ALLOWED_CONTENT_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp'
]);

const normalizeHeaderKey = (headers, key) => {
  if (!headers) {
    return undefined;
  }

  const lowerKey = key.toLowerCase();
  return headers[key] || headers[lowerKey];
};

const respond = (statusCode, body) => ({
  statusCode,
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify(body)
});

const parseMultipart = (bodyBuffer, contentType) => {
  const match = /boundary=([^;]+)/i.exec(contentType || '');
  if (!match) {
    return { error: 'Missing multipart boundary.' };
  }

  const boundary = `--${match[1]}`;
  const boundaryBuffer = Buffer.from(boundary);

  let cursor = bodyBuffer.indexOf(boundaryBuffer, 0);
  while (cursor !== -1) {
    const next = bodyBuffer.indexOf(boundaryBuffer, cursor + boundaryBuffer.length);
    if (next === -1) {
      break;
    }

    let partStart = cursor + boundaryBuffer.length;
    if (bodyBuffer.slice(partStart, partStart + 2).toString('latin1') === '\r\n') {
      partStart += 2;
    }

    const headerEnd = bodyBuffer.indexOf(Buffer.from('\r\n\r\n'), partStart);
    if (headerEnd === -1 || headerEnd > next) {
      cursor = next;
      continue;
    }

    const headerText = bodyBuffer.slice(partStart, headerEnd).toString('latin1');
    const headers = headerText.split('\r\n').reduce((acc, line) => {
      const [name, ...rest] = line.split(':');
      if (!name || rest.length === 0) {
        return acc;
      }
      acc[name.trim().toLowerCase()] = rest.join(':').trim();
      return acc;
    }, {});

    const disposition = headers['content-disposition'] || '';
    const filenameMatch = /filename="([^"]+)"/i.exec(disposition);
    const isFilePart = filenameMatch && filenameMatch[1];

    const bodyStart = headerEnd + 4;
    let bodyEnd = next - 2;
    if (bodyEnd < bodyStart) {
      bodyEnd = bodyStart;
    }

    if (isFilePart) {
      return {
        filename: filenameMatch[1],
        contentType: headers['content-type'],
        body: bodyBuffer.slice(bodyStart, bodyEnd)
      };
    }

    cursor = next;
  }

  return { error: 'No file part found.' };
};

const parseJsonBase64 = (bodyString) => {
  let payload;
  try {
    payload = JSON.parse(bodyString);
  } catch (error) {
    return { error: 'Invalid JSON body.' };
  }

  const dataBase64 = payload.dataBase64 || payload.file || payload.body;
  if (!dataBase64) {
    return { error: 'Missing dataBase64 in JSON body.' };
  }

  const filename = payload.filename || payload.name || 'upload';
  const contentType = payload.contentType || payload.mimeType || 'application/octet-stream';

  return {
    filename,
    contentType,
    body: Buffer.from(dataBase64, 'base64')
  };
};

exports.handler = async (event) => {
  const bucket = process.env.S3_BUCKET;
  const prefix = process.env.UPLOAD_PREFIX || 'uploads/';
  const requestId = event?.requestContext?.requestId;

  if (!bucket) {
    return respond(500, { message: 'S3_BUCKET is not configured.' });
  }

  const headers = event?.headers || {};
  const contentType = normalizeHeaderKey(headers, 'content-type') || '';
  const isMultipart = contentType.toLowerCase().startsWith('multipart/form-data');
  const isJson = contentType.toLowerCase().includes('application/json');

  if (!event?.body) {
    return respond(400, { message: 'Missing request body.' });
  }

  let file;
  if (isMultipart) {
    const bodyBuffer = event.isBase64Encoded
      ? Buffer.from(event.body, 'base64')
      : Buffer.from(event.body, 'latin1');
    file = parseMultipart(bodyBuffer, contentType);
  } else if (isJson) {
    const jsonBody = event.isBase64Encoded
      ? Buffer.from(event.body, 'base64').toString('utf8')
      : event.body;
    file = parseJsonBase64(jsonBody);
  } else {
    return respond(415, { message: 'Unsupported content-type.' });
  }

  if (file?.error) {
    return respond(400, { message: file.error });
  }

  if (!file?.body || !file?.body.length) {
    return respond(400, { message: 'Empty file.' });
  }

  if (file.body.length > MAX_BYTES) {
    return respond(413, { message: 'File exceeds 10MB limit.' });
  }

  const fileContentType = (file.contentType || '').toLowerCase();
  if (!ALLOWED_CONTENT_TYPES.has(fileContentType)) {
    return respond(415, { message: 'Unsupported file type.' });
  }

  const fileId = crypto.randomUUID();
  const safePrefix = prefix.endsWith('/') ? prefix : `${prefix}/`;
  const key = `${safePrefix}${fileId}`;

  try {
    await s3
      .putObject({
        Bucket: bucket,
        Key: key,
        Body: file.body,
        ContentType: fileContentType
      })
      .promise();

    console.log('upload-lambda stored file', { requestId, key, contentType: fileContentType });

    return respond(200, {
      message: 'Uploaded',
      key,
      bucket
    });
  } catch (error) {
    console.error('upload-lambda failed', { requestId, error });
    return respond(500, { message: 'Failed to upload file.' });
  }
};
