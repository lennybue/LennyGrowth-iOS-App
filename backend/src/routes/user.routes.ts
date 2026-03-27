import type { FastifyInstance } from 'fastify'
import { z } from 'zod'
import * as authService from '../services/auth.service.js'
import * as contentService from '../services/content.service.js'
import { authenticate } from '../middleware/authenticate.js'

const updateProfileBody = z.object({
  displayName: z.string().min(1).max(80).optional(),
  bio:         z.string().max(300).nullable().optional(),
  avatarUrl:   z.string().url().nullable().optional(),
})

export async function userRoutes(fastify: FastifyInstance): Promise<void> {
  // GET /user/profile
  fastify.get('/user/profile', { preHandler: [authenticate] }, async (req, reply) => {
    reply.send(await authService.getUser(req.userId))
  })

  // PUT /user/profile
  fastify.put('/user/profile', { preHandler: [authenticate] }, async (req, reply) => {
    const body = updateProfileBody.parse(req.body)
    reply.send(await authService.updateUser(req.userId, {
      displayName: body.displayName,
      bio:         body.bio ?? undefined,
      avatarUrl:   body.avatarUrl ?? undefined,
    }))
  })

  // GET /user/purchases  (products downloaded/purchased)
  fastify.get('/user/purchases', { preHandler: [authenticate] }, async (req, reply) => {
    reply.send(await contentService.getUserDownloads(req.userId))
  })

  // GET /user/downloads  (alias)
  fastify.get('/user/downloads', { preHandler: [authenticate] }, async (req, reply) => {
    reply.send(await contentService.getUserDownloads(req.userId))
  })

  // DELETE /user/account
  fastify.delete('/user/account', { preHandler: [authenticate] }, async (req, reply) => {
    await authService.deleteUser(req.userId)
    reply.status(204).send()
  })
}
