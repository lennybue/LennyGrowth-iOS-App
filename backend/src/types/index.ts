import type { FastifyRequest } from 'fastify'

// ─── Auth ────────────────────────────────────────────────────────────────────

export interface JwtPayload {
  sub: string    // userId
  email: string
  tier: string   // free | pro
  iat?: number
  exp?: number
}

// Augment Fastify to include authenticated user on request
declare module 'fastify' {
  interface FastifyRequest {
    userId: string
    userEmail: string
    userTier: string
  }
}

// ─── API Response shapes ───────────────────────────────────────────────────

export interface PaginatedResponse<T> {
  items: T[]
  totalCount: number
  currentPage: number
  pageSize: number
}

export interface ApiError {
  statusCode: number
  error: string
  message: string
}

// ─── Domain types (mirror iOS domain models) ──────────────────────────────

export type SubscriptionTier = 'free' | 'pro'
export type Platform         = 'linkedin' | 'threads'
export type PostStatus       = 'draft' | 'scheduled' | 'publishing' | 'published' | 'failed'
export type ArticleCategory  = 'marketing' | 'social_media' | 'content_creation' | 'analytics' | 'seo' | 'email_marketing' | 'branding' | 'growth'

export interface UserResponse {
  id: string
  email: string
  displayName: string
  avatarUrl: string | null
  bio: string | null
  subscriptionTier: SubscriptionTier
  connectedAccounts: ConnectedAccountResponse[]
  createdAt: string
}

export interface ConnectedAccountResponse {
  id: string
  platform: Platform
  username: string
  profileImageUrl: string | null
  isConnected: boolean
  followerCount: number | null
  lastSyncedAt: string | null
}

export interface AuthResponse {
  accessToken: string
  refreshToken: string
  expiresIn: number
  user: UserResponse
}

export interface PostResponse {
  id: string
  content: string
  platforms: Platform[]
  status: PostStatus
  scheduledAt: string | null
  publishedAt: string | null
  createdAt: string
  updatedAt: string | null
  mediaAttachments: MediaAttachmentResponse[]
  platformVariants: Record<string, string>
  metrics: PostMetricsResponse | null
  linkedArticleId: string | null
  linkedProductId: string | null
  hashtags: string[]
  isDraft: boolean
}

export interface MediaAttachmentResponse {
  id: string
  type: string
  url: string | null
  thumbnailUrl: string | null
  altText: string | null
  fileSize: number | null
  width: number | null
  height: number | null
}

export interface PostMetricsResponse {
  impressions: number
  reach: number
  likes: number
  comments: number
  shares: number
  clicks: number
  engagementRate: number
}
