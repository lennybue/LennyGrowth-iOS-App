import bcrypt from 'bcryptjs'
import crypto from 'crypto'
import { createRemoteJWKSet, jwtVerify } from 'jose'
import { prisma } from '../config/database.js'
import { env } from '../config/env.js'
import * as emailService from './email.service.js'
import type { UserResponse, AuthResponse, ConnectedAccountResponse } from '../types/index.js'

const BCRYPT_ROUNDS = 12
const APPLE_JWKS_URI = new URL('https://appleid.apple.com/auth/keys')
const appleJWKS = createRemoteJWKSet(APPLE_JWKS_URI)

// ─── Token helpers ────────────────────────────────────────────────────────────

function generateTokens(fastify: any, userId: string, email: string, tier: string) {
  const accessToken = fastify.jwt.sign(
    { sub: userId, email, tier },
    { expiresIn: env.JWT_ACCESS_EXPIRES_IN }
  )
  const refreshToken = fastify.jwt.sign(
    { sub: userId },
    { secret: env.JWT_REFRESH_SECRET, expiresIn: env.JWT_REFRESH_EXPIRES_IN }
  )
  return { accessToken, refreshToken }
}

async function storeRefreshToken(userId: string, token: string): Promise<void> {
  const expiresAt = new Date(Date.now() + env.JWT_REFRESH_EXPIRES_IN * 1000)
  await prisma.refreshToken.create({ data: { token, userId, expiresAt } })
}

// ─── User serializer ──────────────────────────────────────────────────────────

function serializeUser(user: any): UserResponse {
  return {
    id:               user.id,
    email:            user.email,
    displayName:      user.displayName,
    avatarUrl:        user.avatarUrl ?? null,
    bio:              user.bio ?? null,
    subscriptionTier: user.subscriptionTier as 'free' | 'pro',
    connectedAccounts: (user.connectedAccounts ?? []).map((a: any): ConnectedAccountResponse => ({
      id:             a.id,
      platform:       a.platform,
      username:       a.username,
      profileImageUrl: a.profileImageUrl ?? null,
      isConnected:    a.isConnected,
      followerCount:  a.followerCount ?? null,
      lastSyncedAt:   a.lastSyncedAt?.toISOString() ?? null,
    })),
    createdAt: user.createdAt.toISOString(),
  }
}

function buildAuthResponse(fastify: any, user: any, refreshToken: string): AuthResponse {
  const tokens = generateTokens(fastify, user.id, user.email, user.subscriptionTier)
  return {
    accessToken:  tokens.accessToken,
    refreshToken,
    expiresIn:    env.JWT_ACCESS_EXPIRES_IN,
    user:         serializeUser(user),
  }
}

const userWithAccounts = {
  include: { connectedAccounts: { where: { isConnected: true } } },
}

// ─── Public service functions ─────────────────────────────────────────────────

export async function registerUser(
  fastify: any,
  email: string,
  password: string,
  displayName: string
): Promise<AuthResponse> {
  const existing = await prisma.user.findUnique({ where: { email: email.toLowerCase() } })
  if (existing) throw Object.assign(new Error('Email already registered'), { statusCode: 409 })

  const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS)
  const user = await prisma.user.create({
    data: { email: email.toLowerCase(), passwordHash, displayName },
    ...userWithAccounts,
  })

  const { refreshToken } = generateTokens(fastify, user.id, user.email, user.subscriptionTier)
  await storeRefreshToken(user.id, refreshToken)
  // Non-blocking welcome email
  emailService.sendWelcomeEmail(user.email, user.displayName).catch(console.error)
  return buildAuthResponse(fastify, user, refreshToken)
}

export async function loginUser(fastify: any, email: string, password: string): Promise<AuthResponse> {
  const user = await prisma.user.findUnique({
    where: { email: email.toLowerCase() },
    ...userWithAccounts,
  })
  if (!user || !user.passwordHash) {
    throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 })
  }

  const valid = await bcrypt.compare(password, user.passwordHash)
  if (!valid) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 })

  const { refreshToken } = generateTokens(fastify, user.id, user.email, user.subscriptionTier)
  await storeRefreshToken(user.id, refreshToken)
  return buildAuthResponse(fastify, user, refreshToken)
}

export async function loginWithApple(
  fastify: any,
  identityToken: string,
  _authorizationCode: string,
  fullName?: string | null
): Promise<AuthResponse> {
  // Verify Apple identity token via Apple's JWKS
  let appleUserId: string
  let appleEmail: string | undefined
  try {
    const { payload } = await jwtVerify(identityToken, appleJWKS, {
      issuer: 'https://appleid.apple.com',
      audience: env.APPLE_CLIENT_ID,
    })
    appleUserId = payload.sub as string
    appleEmail  = payload.email as string | undefined
  } catch {
    throw Object.assign(new Error('Invalid Apple identity token'), { statusCode: 401 })
  }

  // Find or create user
  let user = await prisma.user.findUnique({
    where: { appleUserId },
    ...userWithAccounts,
  })

  if (!user) {
    const email = appleEmail ?? `${appleUserId}@privaterelay.appleid.com`
    user = await prisma.user.create({
      data: {
        email,
        appleUserId,
        displayName: fullName ?? 'Apple Nutzer',
      },
      ...userWithAccounts,
    })
  }

  const { refreshToken } = generateTokens(fastify, user.id, user.email, user.subscriptionTier)
  await storeRefreshToken(user.id, refreshToken)
  return buildAuthResponse(fastify, user, refreshToken)
}

export async function refreshAccessToken(fastify: any, refreshToken: string): Promise<{ accessToken: string; refreshToken: string; expiresIn: number }> {
  // Verify refresh token signature
  let payload: { sub: string }
  try {
    payload = fastify.jwt.verify(refreshToken, { secret: env.JWT_REFRESH_SECRET }) as { sub: string }
  } catch {
    throw Object.assign(new Error('Invalid refresh token'), { statusCode: 401 })
  }

  // Check token is in DB (not revoked)
  const stored = await prisma.refreshToken.findUnique({ where: { token: refreshToken } })
  if (!stored || stored.expiresAt < new Date()) {
    throw Object.assign(new Error('Refresh token expired or revoked'), { statusCode: 401 })
  }

  const user = await prisma.user.findUnique({ where: { id: payload.sub } })
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 401 })

  // Rotate: delete old, create new
  await prisma.refreshToken.delete({ where: { token: refreshToken } })
  const tokens = generateTokens(fastify, user.id, user.email, user.subscriptionTier)
  await storeRefreshToken(user.id, tokens.refreshToken)

  return { accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, expiresIn: env.JWT_ACCESS_EXPIRES_IN }
}

export async function logoutUser(userId: string, refreshToken?: string): Promise<void> {
  if (refreshToken) {
    await prisma.refreshToken.deleteMany({ where: { token: refreshToken } })
  } else {
    // Revoke all refresh tokens for this user
    await prisma.refreshToken.deleteMany({ where: { userId } })
  }
}

export async function getUser(userId: string): Promise<UserResponse> {
  const user = await prisma.user.findUniqueOrThrow({
    where: { id: userId },
    ...userWithAccounts,
  })
  return serializeUser(user)
}

export async function updateUser(userId: string, data: { displayName?: string; bio?: string; avatarUrl?: string }): Promise<UserResponse> {
  const user = await prisma.user.update({
    where: { id: userId },
    data: {
      ...(data.displayName !== undefined && { displayName: data.displayName }),
      ...(data.bio !== undefined && { bio: data.bio }),
      ...(data.avatarUrl !== undefined && { avatarUrl: data.avatarUrl }),
    },
    ...userWithAccounts,
  })
  return serializeUser(user)
}

export async function deleteUser(userId: string): Promise<void> {
  await prisma.user.delete({ where: { id: userId } })
}

export async function requestPasswordReset(email: string): Promise<void> {
  const user = await prisma.user.findUnique({ where: { email: email.toLowerCase() } })
  if (!user) return // Don't reveal whether email exists

  // Invalidate any existing tokens
  await prisma.passwordResetToken.deleteMany({ where: { userId: user.id } })

  const token     = crypto.randomBytes(32).toString('hex')
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000) // 1 hour
  await prisma.passwordResetToken.create({ data: { token, userId: user.id, expiresAt } })
  await emailService.sendPasswordResetEmail(user.email, token, user.displayName)
}

export async function confirmPasswordReset(token: string, newPassword: string): Promise<void> {
  const record = await prisma.passwordResetToken.findUnique({ where: { token } })
  if (!record || record.used || record.expiresAt < new Date()) {
    throw Object.assign(new Error('Ungültiger oder abgelaufener Reset-Token'), { statusCode: 400 })
  }

  const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS)
  await prisma.user.update({ where: { id: record.userId }, data: { passwordHash } })
  await prisma.passwordResetToken.update({ where: { token }, data: { used: true } })
  // Revoke all refresh tokens for security
  await prisma.refreshToken.deleteMany({ where: { userId: record.userId } })
}
