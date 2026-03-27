import type { FastifyInstance } from 'fastify'
import { z } from 'zod'
import * as postService from '../services/post.service.js'
import * as socialService from '../services/social.service.js'
import { authenticate } from '../middleware/authenticate.js'

const createPostBody = z.object({
  content:          z.string().min(1).max(3000),
  platforms:        z.array(z.enum(['linkedin', 'threads'])).min(1),
  platformVariants: z.record(z.string()).optional(),
  scheduledAt:      z.string().datetime().optional(),
  hashtags:         z.array(z.string()).optional(),
  isDraft:          z.boolean().optional(),
})

const updatePostBody = z.object({
  content:     z.string().min(1).max(3000).optional(),
  platforms:   z.array(z.enum(['linkedin', 'threads'])).optional(),
  scheduledAt: z.string().datetime().nullable().optional(),
  hashtags:    z.array(z.string()).optional(),
  isDraft:     z.boolean().optional(),
})

const scheduleBody = z.object({
  scheduledAt: z.string().datetime(),
})

const connectBody = z.object({
  accessToken: z.string().min(1),
  platform:    z.string().min(1),
})

export async function postsRoutes(fastify: FastifyInstance): Promise<void> {
  // POST /posts
  fastify.post('/posts', { preHandler: [authenticate] }, async (req, reply) => {
    const body = createPostBody.parse(req.body)
    const post = await postService.createPost(req.userId, body)
    reply.status(201).send(post)
  })

  // GET /posts?status=
  fastify.get('/posts', { preHandler: [authenticate] }, async (req, reply) => {
    const { status } = req.query as { status?: string }
    const posts = await postService.getPosts(req.userId, status)
    reply.send(posts)
  })

  // GET /posts/:id
  fastify.get('/posts/:id', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }
    reply.send(await postService.getPost(req.userId, id))
  })

  // PUT /posts/:id
  fastify.put('/posts/:id', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }
    const body   = updatePostBody.parse(req.body)
    reply.send(await postService.updatePost(req.userId, id, body))
  })

  // DELETE /posts/:id
  fastify.delete('/posts/:id', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }
    await postService.deletePost(req.userId, id)
    reply.status(204).send()
  })

  // POST /posts/:id/publish
  fastify.post('/posts/:id/publish', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }
    reply.send(await postService.publishPost(req.userId, id))
  })

  // POST /posts/:id/schedule  (body: { scheduledAt })
  fastify.post('/posts/:id/schedule', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }
    const { scheduledAt } = scheduleBody.parse(req.body)
    reply.send(await postService.schedulePost(req.userId, id, scheduledAt))
  })

  // GET /posts/:id/analytics
  fastify.get('/posts/:id/analytics', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }
    reply.send(await postService.getPostAnalytics(req.userId, id))
  })

  // POST /social/connect/:platform
  fastify.post('/social/connect/:platform', { preHandler: [authenticate] }, async (req, reply) => {
    const { platform } = req.params as { platform: string }
    const { accessToken } = connectBody.parse(req.body)
    const account = await socialService.connectAccount(req.userId, platform as any, accessToken)
    reply.status(201).send(account)
  })

  // DELETE /social/disconnect/:platform
  fastify.delete('/social/disconnect/:platform', { preHandler: [authenticate] }, async (req, reply) => {
    const { platform } = req.params as { platform: string }
    await socialService.disconnectAccount(req.userId, platform)
    reply.status(204).send()
  })

  // GET /social/accounts
  fastify.get('/social/accounts', { preHandler: [authenticate] }, async (req, reply) => {
    const accounts = await socialService.getConnectedAccounts(req.userId)
    reply.send({ accounts })
  })
}
