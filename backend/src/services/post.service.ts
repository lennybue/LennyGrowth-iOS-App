import { prisma } from '../config/database.js'
import * as socialService from './social.service.js'
import type { PostResponse, PostMetricsResponse } from '../types/index.js'

// ─── Serializer ───────────────────────────────────────────────────────────────

function serializePost(post: any): PostResponse {
  return {
    id:              post.id,
    content:         post.content,
    platforms:       post.platforms,
    status:          post.status,
    scheduledAt:     post.scheduledAt?.toISOString()  ?? null,
    publishedAt:     post.publishedAt?.toISOString()  ?? null,
    createdAt:       post.createdAt.toISOString(),
    updatedAt:       post.updatedAt?.toISOString()    ?? null,
    mediaAttachments: (post.mediaAttachments ?? []).map((m: any) => ({
      id:           m.id,
      type:         m.type,
      url:          m.url          ?? null,
      thumbnailUrl: m.thumbnailUrl ?? null,
      altText:      m.altText      ?? null,
      fileSize:     m.fileSize     ?? null,
      width:        m.width        ?? null,
      height:       m.height       ?? null,
    })),
    platformVariants: (post.platformVariants as Record<string, string>) ?? {},
    metrics:         post.metrics ? serializeMetrics(post.metrics) : null,
    linkedArticleId: null,
    linkedProductId: null,
    hashtags:        post.hashtags ?? [],
    isDraft:         post.isDraft,
  }
}

function serializeMetrics(m: any): PostMetricsResponse {
  return {
    impressions:    m.impressions,
    reach:          m.reach,
    likes:          m.likes,
    comments:       m.comments,
    shares:         m.shares,
    clicks:         m.clicks,
    engagementRate: parseFloat(m.engagementRate.toString()),
  }
}

const postInclude = {
  mediaAttachments: true,
  metrics:          true,
}

// ─── CRUD ─────────────────────────────────────────────────────────────────────

export async function createPost(userId: string, data: {
  content: string
  platforms: string[]
  platformVariants?: Record<string, string>
  scheduledAt?: string
  hashtags?: string[]
  isDraft?: boolean
}): Promise<PostResponse> {
  const post = await prisma.post.create({
    data: {
      userId,
      content:         data.content,
      platforms:       data.platforms,
      platformVariants: data.platformVariants ?? {},
      scheduledAt:     data.scheduledAt ? new Date(data.scheduledAt) : null,
      hashtags:        data.hashtags ?? [],
      isDraft:         data.isDraft ?? true,
      status:          data.isDraft ? 'draft' : (data.scheduledAt ? 'scheduled' : 'draft'),
    },
    include: postInclude,
  })
  return serializePost(post)
}

export async function getPosts(userId: string, status?: string): Promise<PostResponse[]> {
  const posts = await prisma.post.findMany({
    where: { userId, ...(status ? { status } : {}) },
    orderBy: [{ scheduledAt: 'asc' }, { createdAt: 'desc' }],
    include: postInclude,
  })
  return posts.map(serializePost)
}

export async function getPost(userId: string, id: string): Promise<PostResponse> {
  const post = await prisma.post.findFirst({
    where: { id, userId },
    include: postInclude,
  })
  if (!post) throw Object.assign(new Error('Post not found'), { statusCode: 404 })
  return serializePost(post)
}

export async function updatePost(userId: string, id: string, data: {
  content?: string
  platforms?: string[]
  scheduledAt?: string | null
  hashtags?: string[]
  isDraft?: boolean
}): Promise<PostResponse> {
  const existing = await prisma.post.findFirst({ where: { id, userId } })
  if (!existing) throw Object.assign(new Error('Post not found'), { statusCode: 404 })

  const scheduledAt = data.scheduledAt === null ? null
    : data.scheduledAt ? new Date(data.scheduledAt)
    : undefined

  const status = data.isDraft ? 'draft'
    : scheduledAt ? 'scheduled'
    : existing.status

  const post = await prisma.post.update({
    where: { id },
    data: {
      ...(data.content    !== undefined && { content: data.content }),
      ...(data.platforms  !== undefined && { platforms: data.platforms }),
      ...(data.hashtags   !== undefined && { hashtags: data.hashtags }),
      ...(data.isDraft    !== undefined && { isDraft: data.isDraft }),
      ...(scheduledAt     !== undefined && { scheduledAt }),
      status,
      updatedAt: new Date(),
    },
    include: postInclude,
  })
  return serializePost(post)
}

export async function deletePost(userId: string, id: string): Promise<void> {
  const existing = await prisma.post.findFirst({ where: { id, userId } })
  if (!existing) throw Object.assign(new Error('Post not found'), { statusCode: 404 })
  await prisma.post.delete({ where: { id } })
}

export async function schedulePost(userId: string, id: string, scheduledAt: string): Promise<PostResponse> {
  const existing = await prisma.post.findFirst({ where: { id, userId } })
  if (!existing) throw Object.assign(new Error('Post not found'), { statusCode: 404 })

  const post = await prisma.post.update({
    where: { id },
    data: { scheduledAt: new Date(scheduledAt), status: 'scheduled', isDraft: false, updatedAt: new Date() },
    include: postInclude,
  })
  return serializePost(post)
}

export async function publishPost(userId: string, id: string): Promise<PostResponse> {
  const existing = await prisma.post.findFirst({ where: { id, userId } })
  if (!existing) throw Object.assign(new Error('Post not found'), { statusCode: 404 })

  await prisma.post.update({
    where: { id },
    data: { status: 'publishing', updatedAt: new Date() },
  })

  try {
    const platformVariants = (existing.platformVariants ?? {}) as Record<string, string>
    for (const platform of existing.platforms) {
      if (platform === 'linkedin') {
        await socialService.publishToLinkedIn(userId, existing.content, platformVariants)
      } else if (platform === 'threads') {
        await socialService.publishToThreads(userId, existing.content, platformVariants)
      }
    }
  } catch (err) {
    await prisma.post.update({
      where: { id },
      data: { status: 'failed', errorMessage: err instanceof Error ? err.message : 'Publish failed', updatedAt: new Date() },
    })
    throw err
  }

  const published = await prisma.post.update({
    where: { id },
    data: { status: 'published', publishedAt: new Date(), updatedAt: new Date() },
    include: postInclude,
  })
  return serializePost(published)
}

export async function getPostAnalytics(userId: string, id: string): Promise<PostMetricsResponse> {
  const post = await prisma.post.findFirst({
    where: { id, userId },
    include: { metrics: true },
  })
  if (!post) throw Object.assign(new Error('Post not found'), { statusCode: 404 })
  if (!post.metrics) {
    return { impressions: 0, reach: 0, likes: 0, comments: 0, shares: 0, clicks: 0, engagementRate: 0 }
  }
  return serializeMetrics(post.metrics)
}

// ─── Scheduler (called by cron job) ──────────────────────────────────────────

export async function processScheduledPosts(): Promise<void> {
  const now = new Date()
  const duePosts = await prisma.post.findMany({
    where: { status: 'scheduled', scheduledAt: { lte: now } },
    include: { user: { include: { connectedAccounts: true } } },
  })

  for (const post of duePosts) {
    try {
      await prisma.post.update({
        where: { id: post.id },
        data: { status: 'publishing', updatedAt: now },
      })

      const platformVariants = (post.platformVariants ?? {}) as Record<string, string>
      for (const platform of post.platforms) {
        if (platform === 'linkedin') {
          await socialService.publishToLinkedIn(post.userId, post.content, platformVariants)
        } else if (platform === 'threads') {
          await socialService.publishToThreads(post.userId, post.content, platformVariants)
        }
      }
      await prisma.post.update({
        where: { id: post.id },
        data: { status: 'published', publishedAt: now, updatedAt: now },
      })

      // Create empty metrics record
      await prisma.postMetrics.upsert({
        where: { postId: post.id },
        create: { postId: post.id },
        update: {},
      })
    } catch (err) {
      await prisma.post.update({
        where: { id: post.id },
        data: {
          status: 'failed',
          errorMessage: err instanceof Error ? err.message : 'Unknown error',
          updatedAt: now,
        },
      })
    }
  }
}
