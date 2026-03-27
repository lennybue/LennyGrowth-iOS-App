import crypto from 'crypto'
import { prisma } from '../config/database.js'
import { env } from '../config/env.js'
import type { ConnectedAccountResponse, Platform } from '../types/index.js'

// ─── Encryption helpers (AES-256-GCM) ────────────────────────────────────────
// Social platform OAuth tokens are encrypted at rest — never sent to the device.

const ALGORITHM = 'aes-256-gcm'
const KEY = Buffer.from(env.ENCRYPTION_KEY, 'hex')

function encrypt(plaintext: string): string {
  const iv  = crypto.randomBytes(12)
  const cipher = crypto.createCipheriv(ALGORITHM, KEY, iv)
  const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()])
  const tag = cipher.getAuthTag()
  return [iv.toString('hex'), tag.toString('hex'), encrypted.toString('hex')].join(':')
}

function decrypt(ciphertext: string): string {
  const [ivHex, tagHex, dataHex] = ciphertext.split(':')
  const iv        = Buffer.from(ivHex, 'hex')
  const tag       = Buffer.from(tagHex, 'hex')
  const encrypted = Buffer.from(dataHex, 'hex')
  const decipher  = crypto.createDecipheriv(ALGORITHM, KEY, iv)
  decipher.setAuthTag(tag)
  return Buffer.concat([decipher.update(encrypted), decipher.final()]).toString('utf8')
}

// ─── Serializer ───────────────────────────────────────────────────────────────

function serializeAccount(a: any): ConnectedAccountResponse {
  return {
    id:              a.id,
    platform:        a.platform,
    username:        a.username,
    profileImageUrl: a.profileImageUrl ?? null,
    isConnected:     a.isConnected,
    followerCount:   a.followerCount   ?? null,
    lastSyncedAt:    a.lastSyncedAt?.toISOString() ?? null,
  }
}

// ─── Service functions ────────────────────────────────────────────────────────

/**
 * Exchange an OAuth authorization code for platform tokens (server-side only).
 * The iOS app sends the auth code via /social/connect/:platform.
 * The server completes the OAuth exchange and stores encrypted tokens.
 */
export async function connectAccount(
  userId: string,
  platform: Platform,
  authCode: string
): Promise<ConnectedAccountResponse> {
  let username = 'lennybue'
  let followerCount: number | undefined
  let platformUserId: string | undefined
  let accessToken = authCode
  let profileImageUrl: string | undefined

  if (platform === 'linkedin') {
    const result = await exchangeLinkedInCode(authCode)
    username       = result.username
    followerCount  = result.followerCount
    platformUserId = result.platformUserId
    accessToken    = result.accessToken
    profileImageUrl = result.profileImageUrl
  } else if (platform === 'threads') {
    const result = await exchangeThreadsCode(authCode)
    username       = result.username
    followerCount  = result.followerCount
    platformUserId = result.platformUserId
    accessToken    = result.accessToken
    profileImageUrl = result.profileImageUrl
  }

  const account = await prisma.connectedAccount.upsert({
    where: { userId_platform: { userId, platform } },
    create: {
      userId,
      platform,
      username,
      followerCount,
      platformUserId,
      profileImageUrl,
      isConnected: true,
      encryptedAccessToken: encrypt(accessToken),
      lastSyncedAt: new Date(),
    },
    update: {
      username,
      followerCount,
      platformUserId,
      profileImageUrl,
      isConnected: true,
      encryptedAccessToken: encrypt(accessToken),
      lastSyncedAt: new Date(),
    },
  })
  return serializeAccount(account)
}

export async function disconnectAccount(userId: string, platform: string): Promise<void> {
  await prisma.connectedAccount.updateMany({
    where: { userId, platform },
    data: { isConnected: false, encryptedAccessToken: null, encryptedRefreshToken: null },
  })
}

export async function getConnectedAccounts(userId: string): Promise<ConnectedAccountResponse[]> {
  const accounts = await prisma.connectedAccount.findMany({
    where: { userId, isConnected: true },
  })
  return accounts.map(serializeAccount)
}

/**
 * Retrieve a decrypted access token for publishing.
 * Only called server-side by the post scheduler.
 */
export async function getDecryptedToken(userId: string, platform: Platform): Promise<string | null> {
  const account = await prisma.connectedAccount.findUnique({
    where: { userId_platform: { userId, platform } },
  })
  if (!account?.encryptedAccessToken || !account.isConnected) return null
  return decrypt(account.encryptedAccessToken)
}

// ─── LinkedIn OAuth ───────────────────────────────────────────────────────────

async function exchangeLinkedInCode(authCode: string): Promise<{
  accessToken: string; username: string; followerCount: number; platformUserId: string; profileImageUrl: string | undefined
}> {
  if (!env.LINKEDIN_CLIENT_ID || !env.LINKEDIN_CLIENT_SECRET || !env.LINKEDIN_REDIRECT_URI) {
    // Development fallback
    return { accessToken: authCode, username: 'lennybue', followerCount: 4200, platformUserId: 'li_dev', profileImageUrl: undefined }
  }

  // Exchange authorization code for access token
  const tokenRes = await fetch('https://www.linkedin.com/oauth/v2/accessToken', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type:    'authorization_code',
      code:          authCode,
      redirect_uri:  env.LINKEDIN_REDIRECT_URI,
      client_id:     env.LINKEDIN_CLIENT_ID,
      client_secret: env.LINKEDIN_CLIENT_SECRET,
    }),
  })
  const tokenData = await tokenRes.json() as any
  if (!tokenData.access_token) throw Object.assign(new Error('LinkedIn OAuth failed'), { statusCode: 400 })

  // Fetch profile
  const profileRes = await fetch('https://api.linkedin.com/v2/userinfo', {
    headers: { Authorization: `Bearer ${tokenData.access_token}` },
  })
  const profile = await profileRes.json() as any

  return {
    accessToken:     tokenData.access_token,
    username:        profile.name ?? profile.email ?? 'linkedin_user',
    followerCount:   0, // follower count requires LinkedIn Pages API
    platformUserId:  profile.sub,
    profileImageUrl: profile.picture,
  }
}

// ─── Threads / Meta OAuth ─────────────────────────────────────────────────────

async function exchangeThreadsCode(authCode: string): Promise<{
  accessToken: string; username: string; followerCount: number; platformUserId: string; profileImageUrl: string | undefined
}> {
  if (!env.THREADS_APP_ID || !env.THREADS_APP_SECRET || !env.THREADS_REDIRECT_URI) {
    return { accessToken: authCode, username: 'lennybue', followerCount: 1200, platformUserId: 'th_dev', profileImageUrl: undefined }
  }

  const tokenRes = await fetch('https://graph.threads.net/oauth/access_token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id:     env.THREADS_APP_ID,
      client_secret: env.THREADS_APP_SECRET,
      redirect_uri:  env.THREADS_REDIRECT_URI,
      code:          authCode,
      grant_type:    'authorization_code',
    }),
  })
  const tokenData = await tokenRes.json() as any
  if (!tokenData.access_token) throw Object.assign(new Error('Threads OAuth failed'), { statusCode: 400 })

  const profileRes = await fetch(
    `https://graph.threads.net/v1.0/me?fields=id,username,threads_profile_picture_url,followers_count&access_token=${tokenData.access_token}`
  )
  const profile = await profileRes.json() as any

  return {
    accessToken:     tokenData.access_token,
    username:        profile.username ?? 'threads_user',
    followerCount:   profile.followers_count ?? 0,
    platformUserId:  profile.id,
    profileImageUrl: profile.threads_profile_picture_url,
  }
}
