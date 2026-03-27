import type { FastifyInstance } from 'fastify'
import { z } from 'zod'
import * as aiService from '../services/ai.service.js'
import { authenticate } from '../middleware/authenticate.js'

const generateBody = z.object({
  prompt:    z.string().min(1).max(2000),
  tone:      z.string().default('professional'),
  platforms: z.array(z.string()).min(1),
  context:   z.string().nullable().optional(),
  stream:    z.boolean().default(false),
})

const rewriteBody = z.object({
  content:     z.string().min(1).max(3500),
  tone:        z.string().default('professional'),
  instruction: z.string().default('Verbessere den Text'),
})

const hashtagsBody = z.object({
  content:   z.string().min(1).max(3500),
  platforms: z.array(z.string()).min(1),
})

export async function aiRoutes(fastify: FastifyInstance): Promise<void> {
  // POST /ai/generate  — streaming or non-streaming
  fastify.post('/ai/generate', { preHandler: [authenticate] }, async (req, reply) => {
    const body = generateBody.parse(req.body)

    if (body.stream) {
      // SSE streaming — bypass Fastify's serialization and write to raw stream
      await aiService.generateContentStream(
        req.userId,
        req.userTier,
        body.prompt,
        body.tone,
        body.platforms,
        body.context,
        reply
      )
      return
    }

    const result = await aiService.generateContent(
      req.userId,
      req.userTier,
      body.prompt,
      body.tone,
      body.platforms,
      body.context
    )
    reply.send(result)
  })

  // POST /ai/rewrite
  fastify.post('/ai/rewrite', { preHandler: [authenticate] }, async (req, reply) => {
    const body = rewriteBody.parse(req.body)
    const text = await aiService.rewriteContent(req.userId, req.userTier, body.content, body.tone, body.instruction)
    // Wrap in generate response shape for iOS client consistency
    reply.send({
      mainContent: text,
      platformVariants: {},
      suggestedHashtags: [],
      estimatedEngagement: null,
      alternativeVersions: [],
    })
  })

  // POST /ai/hashtags
  fastify.post('/ai/hashtags', { preHandler: [authenticate] }, async (req, reply) => {
    const body = hashtagsBody.parse(req.body)
    const hashtags = await aiService.generateHashtags(req.userId, req.userTier, body.content, body.platforms)
    reply.send({ hashtags })
  })

  // GET /ai/usage  — how many generations used today
  fastify.get('/ai/usage', { preHandler: [authenticate] }, async (req, reply) => {
    reply.send(await aiService.getUsageToday(req.userId))
  })
}
