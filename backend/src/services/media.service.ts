import crypto from 'crypto'
import { prisma } from '../config/database.js'
import { env } from '../config/env.js'

export interface MediaUploadRecord {
  id: string
  url: string
  thumbnailUrl: string | null
  type: string
  fileSize: number
  width: number | null
  height: number | null
}

// ─── AWS Signature V4 (for Cloudflare R2 / S3-compatible) ────────────────────

function sign(key: Buffer, msg: string): Buffer {
  return crypto.createHmac('sha256', key).update(msg).digest()
}

function getSigningKey(secretKey: string, date: string, region: string, service: string): Buffer {
  const kDate    = sign(Buffer.from(`AWS4${secretKey}`), date)
  const kRegion  = sign(kDate, region)
  const kService = sign(kRegion, service)
  return sign(kService, 'aws4_request')
}

function sha256Hex(data: Buffer | string): string {
  return crypto.createHash('sha256').update(data).digest('hex')
}

// ─── Upload to R2 ─────────────────────────────────────────────────────────────

export async function uploadFile(
  buffer: Buffer,
  key: string,
  mimeType: string
): Promise<{ url: string; key: string }> {
  // Fallback: no R2 configured (dev/test)
  if (!env.R2_ACCOUNT_ID || !env.R2_ACCESS_KEY_ID || !env.R2_SECRET_ACCESS_KEY || !env.R2_BUCKET_NAME) {
    const mockUrl = `/mock-media/${key}`
    console.log(`[media] R2 not configured — mock URL: ${mockUrl}`)
    return { url: mockUrl, key }
  }

  const bucket   = env.R2_BUCKET_NAME
  const endpoint = `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`
  const host     = `${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`
  const region   = 'auto'
  const service  = 's3'

  const now       = new Date()
  const amzDate   = now.toISOString().replace(/[:\-]|\.\d{3}/g, '').slice(0, 15) + 'Z'
  const dateStamp = amzDate.slice(0, 8)
  const payloadHash = sha256Hex(buffer)

  const canonicalRequest = [
    'PUT',
    `/${bucket}/${key}`,
    '',
    `content-type:${mimeType}\nhost:${host}\nx-amz-content-sha256:${payloadHash}\nx-amz-date:${amzDate}\n`,
    'content-type;host;x-amz-content-sha256;x-amz-date',
    payloadHash,
  ].join('\n')

  const credScope   = `${dateStamp}/${region}/${service}/aws4_request`
  const stringToSign = `AWS4-HMAC-SHA256\n${amzDate}\n${credScope}\n${sha256Hex(canonicalRequest)}`
  const signingKey   = getSigningKey(env.R2_SECRET_ACCESS_KEY, dateStamp, region, service)
  const signature    = crypto.createHmac('sha256', signingKey).update(stringToSign).digest('hex')

  const authorization = `AWS4-HMAC-SHA256 Credential=${env.R2_ACCESS_KEY_ID}/${credScope}, SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date, Signature=${signature}`

  const res = await fetch(`${endpoint}/${bucket}/${key}`, {
    method: 'PUT',
    headers: {
      'Content-Type': mimeType,
      'Host': host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      'Authorization': authorization,
    },
    body: buffer,
  })

  if (!res.ok) {
    throw Object.assign(new Error(`R2 upload failed: ${res.status} ${await res.text()}`), { statusCode: 502 })
  }

  const publicUrl = env.R2_PUBLIC_URL ? `${env.R2_PUBLIC_URL}/${key}` : `${endpoint}/${bucket}/${key}`
  return { url: publicUrl, key }
}

// ─── Delete from R2 ───────────────────────────────────────────────────────────

export async function deleteFile(key: string): Promise<void> {
  if (!env.R2_ACCOUNT_ID || !env.R2_ACCESS_KEY_ID || !env.R2_SECRET_ACCESS_KEY || !env.R2_BUCKET_NAME) {
    return
  }

  const bucket   = env.R2_BUCKET_NAME
  const endpoint = `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`
  const host     = `${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`
  const region   = 'auto'
  const service  = 's3'

  const now       = new Date()
  const amzDate   = now.toISOString().replace(/[:\-]|\.\d{3}/g, '').slice(0, 15) + 'Z'
  const dateStamp = amzDate.slice(0, 8)
  const payloadHash = sha256Hex(Buffer.alloc(0))

  const canonicalRequest = [
    'DELETE',
    `/${bucket}/${key}`,
    '',
    `host:${host}\nx-amz-content-sha256:${payloadHash}\nx-amz-date:${amzDate}\n`,
    'host;x-amz-content-sha256;x-amz-date',
    payloadHash,
  ].join('\n')

  const credScope    = `${dateStamp}/${region}/${service}/aws4_request`
  const stringToSign = `AWS4-HMAC-SHA256\n${amzDate}\n${credScope}\n${sha256Hex(canonicalRequest)}`
  const signingKey   = getSigningKey(env.R2_SECRET_ACCESS_KEY, dateStamp, region, service)
  const signature    = crypto.createHmac('sha256', signingKey).update(stringToSign).digest('hex')

  const authorization = `AWS4-HMAC-SHA256 Credential=${env.R2_ACCESS_KEY_ID}/${credScope}, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=${signature}`

  await fetch(`${endpoint}/${bucket}/${key}`, {
    method: 'DELETE',
    headers: {
      'Host': host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      'Authorization': authorization,
    },
  })
}

// ─── DB record ────────────────────────────────────────────────────────────────

export async function saveMediaRecord(
  userId: string,
  params: {
    url: string
    key: string
    type: string
    fileSize: number
    width?: number
    height?: number
    mimeType: string
    postId?: string
  }
): Promise<MediaUploadRecord> {
  const record = await prisma.mediaUpload.create({
    data: {
      userId,
      url:        params.url,
      storageKey: params.key,
      type:       params.type,
      fileSize:   params.fileSize,
      width:      params.width  ?? null,
      height:     params.height ?? null,
      mimeType:   params.mimeType,
      postId:     params.postId ?? null,
    },
  })
  return {
    id:          record.id,
    url:         record.url,
    thumbnailUrl: record.thumbnailUrl,
    type:        record.type,
    fileSize:    record.fileSize,
    width:       record.width,
    height:      record.height,
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

export function generateStorageKey(userId: string, filename: string): string {
  const ext   = filename.split('.').pop() ?? 'bin'
  const ts    = Date.now()
  const rand  = crypto.randomBytes(4).toString('hex')
  return `uploads/${userId}/${ts}-${rand}.${ext}`
}

export function mimeToType(mimeType: string): string {
  if (mimeType.startsWith('video/')) return 'video'
  if (mimeType === 'image/gif') return 'gif'
  return 'image'
}
