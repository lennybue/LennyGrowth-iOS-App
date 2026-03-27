import type { FastifyInstance } from 'fastify'
import { z } from 'zod'
import * as authService from '../services/auth.service.js'
import { authenticate } from '../middleware/authenticate.js'

const loginBody = z.object({
  email:    z.string().email(),
  password: z.string().min(6),
})

const registerBody = z.object({
  email:       z.string().email(),
  password:    z.string().min(8),
  displayName: z.string().min(1).max(80),
})

const appleBody = z.object({
  identityToken:    z.string().min(1),
  authorizationCode: z.string().min(1),
  fullName:         z.string().nullish(),
})

const refreshBody = z.object({
  refreshToken: z.string().min(1),
})

const resetBody = z.object({
  email: z.string().email(),
})

export async function authRoutes(fastify: FastifyInstance): Promise<void> {
  // POST /auth/register
  fastify.post('/register', async (req, reply) => {
    const body = registerBody.parse(req.body)
    const result = await authService.registerUser(fastify, body.email, body.password, body.displayName)
    reply.status(201).send(result)
  })

  // POST /auth/login
  fastify.post('/login', async (req, reply) => {
    const body = loginBody.parse(req.body)
    const result = await authService.loginUser(fastify, body.email, body.password)
    reply.send(result)
  })

  // POST /auth/apple
  fastify.post('/apple', async (req, reply) => {
    const body = appleBody.parse(req.body)
    const result = await authService.loginWithApple(fastify, body.identityToken, body.authorizationCode, body.fullName)
    reply.send(result)
  })

  // POST /auth/refresh
  fastify.post('/refresh', async (req, reply) => {
    const body = refreshBody.parse(req.body)
    const result = await authService.refreshAccessToken(fastify, body.refreshToken)
    reply.send(result)
  })

  // DELETE /auth/logout  (requires auth)
  fastify.delete('/logout', { preHandler: [authenticate] }, async (req, reply) => {
    const body = req.body as any
    await authService.logoutUser(req.userId, body?.refreshToken)
    reply.status(204).send()
  })

  // POST /auth/reset-password  (request reset link via email)
  fastify.post('/reset-password', async (req, reply) => {
    const { email } = resetBody.parse(req.body)
    await authService.requestPasswordReset(email)
    reply.send({ message: 'Falls diese E-Mail registriert ist, wurde ein Reset-Link gesendet.' })
  })

  // POST /auth/reset-password/confirm  (submit new password)
  const confirmResetBody = z.object({
    token:       z.string().min(1),
    newPassword: z.string().min(8),
  })
  fastify.post('/reset-password/confirm', async (req, reply) => {
    const body = confirmResetBody.parse(req.body)
    await authService.confirmPasswordReset(body.token, body.newPassword)
    reply.send({ message: 'Passwort erfolgreich zurückgesetzt.' })
  })
}
