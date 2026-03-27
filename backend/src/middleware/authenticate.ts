import type { FastifyRequest, FastifyReply } from 'fastify'
import type { JwtPayload } from '../types/index.js'

export async function authenticate(request: FastifyRequest, reply: FastifyReply): Promise<void> {
  try {
    const payload = await request.jwtVerify<JwtPayload>()
    request.userId    = payload.sub
    request.userEmail = payload.email
    request.userTier  = payload.tier
  } catch {
    reply.status(401).send({ statusCode: 401, error: 'Unauthorized', message: 'Invalid or expired token' })
  }
}
