import Fastify from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import jwt from '@fastify/jwt'
import rateLimit from '@fastify/rate-limit'
import { env } from './config/env.js'
import { authRoutes } from './routes/auth.routes.js'
import { contentRoutes } from './routes/content.routes.js'
import { postsRoutes } from './routes/posts.routes.js'
import { aiRoutes } from './routes/ai.routes.js'
import { userRoutes } from './routes/user.routes.js'

export async function buildApp() {
  const app = Fastify({
    logger: {
      level: env.NODE_ENV === 'production' ? 'warn' : 'info',
      transport: env.NODE_ENV !== 'production' ? { target: 'pino-pretty' } : undefined,
    },
  })

  // ─── Security ──────────────────────────────────────────────────────────────

  await app.register(helmet, {
    contentSecurityPolicy: false, // API only, no HTML
  })

  await app.register(cors, {
    origin: env.ALLOWED_ORIGINS
      ? env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
      : true, // allow all in development
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'If-Modified-Since'],
  })

  // ─── Rate limiting ─────────────────────────────────────────────────────────

  await app.register(rateLimit, {
    max: 200,
    timeWindow: '1 minute',
    // Stricter limits on auth endpoints
    keyGenerator: (req) => {
      const ip = req.ip
      if (req.url.startsWith('/v1/auth')) return `auth:${ip}`
      const userId = (req as any).userId
      return userId ? `user:${userId}` : `ip:${ip}`
    },
  })

  // ─── JWT ───────────────────────────────────────────────────────────────────

  await app.register(jwt, {
    secret: env.JWT_ACCESS_SECRET,
    sign: { expiresIn: env.JWT_ACCESS_EXPIRES_IN },
  })

  // ─── Error handler ─────────────────────────────────────────────────────────

  app.setErrorHandler((error, _req, reply) => {
    const statusCode = (error as any).statusCode ?? error.statusCode ?? 500

    if (error.name === 'ZodError') {
      return reply.status(400).send({
        statusCode: 400,
        error: 'Bad Request',
        message: 'Validation error',
        details: (error as any).errors,
      })
    }

    app.log.error(error)
    reply.status(statusCode).send({
      statusCode,
      error: statusCode === 500 ? 'Internal Server Error' : error.message,
      message: statusCode === 500 ? 'An unexpected error occurred' : error.message,
    })
  })

  // ─── Health check ──────────────────────────────────────────────────────────

  app.get('/health', async () => ({ status: 'ok', ts: new Date().toISOString() }))

  // ─── Routes under /v1 ──────────────────────────────────────────────────────

  app.register(async (v1) => {
    v1.register(authRoutes, { prefix: '/auth' })
    v1.register(contentRoutes)   // /articles, /products
    v1.register(postsRoutes)     // /posts, /social/*
    v1.register(aiRoutes)        // /ai/*
    v1.register(userRoutes)      // /user/*
  }, { prefix: '/v1' })

  return app
}
