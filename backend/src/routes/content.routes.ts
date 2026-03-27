import type { FastifyInstance } from 'fastify'
import { z } from 'zod'
import * as contentService from '../services/content.service.js'
import { authenticate } from '../middleware/authenticate.js'

export async function contentRoutes(fastify: FastifyInstance): Promise<void> {
  // GET /articles
  fastify.get('/articles', { preHandler: [authenticate] }, async (req, reply) => {
    const query = req.query as any
    const page     = Math.max(1, parseInt(query.page     ?? '1'))
    const pageSize = Math.min(50, parseInt(query.pageSize ?? '10'))

    // Handle If-Modified-Since for 304 caching
    const ifModifiedSince = req.headers['if-modified-since']
    if (ifModifiedSince && page === 1 && !query.search) {
      const since = new Date(ifModifiedSince)
      const latest = await fastify.prisma?.article.findFirst({
        where: { isPublished: true },
        orderBy: { updatedAt: 'desc' },
        select: { updatedAt: true },
      })
      if (latest?.updatedAt && latest.updatedAt <= since) {
        return reply.status(304).send()
      }
    }

    const result = await contentService.getArticles(
      page, pageSize,
      query.category,
      query.search,
      req.userId
    )
    reply.send(result)
  })

  // GET /articles/:id
  fastify.get('/articles/:id', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }
    const article = await contentService.getArticle(id, req.userId)
    reply.send(article)
  })

  // POST /articles/:id/bookmark  (toggle)
  fastify.post('/articles/:id/bookmark', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }
    const article = await contentService.toggleBookmark(req.userId, id)
    reply.send(article)
  })

  // GET /articles/bookmarked
  fastify.get('/articles/bookmarked', { preHandler: [authenticate] }, async (req, reply) => {
    const articles = await contentService.getBookmarkedArticles(req.userId)
    reply.send(articles)
  })

  // GET /products
  fastify.get('/products', { preHandler: [authenticate] }, async (req, reply) => {
    const query    = req.query as any
    const page     = Math.max(1, parseInt(query.page     ?? '1'))
    const pageSize = Math.min(50, parseInt(query.pageSize ?? '10'))
    const isFree   = query.isFree !== undefined ? query.isFree === 'true' : undefined
    const result   = await contentService.getProducts(page, pageSize, query.category, isFree)
    reply.send(result)
  })

  // GET /products/:id
  fastify.get('/products/:id', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }
    reply.send(await contentService.getProduct(id))
  })

  // POST /products/:id/download
  fastify.post('/products/:id/download', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }
    const result = await contentService.trackDownload(req.userId, id)
    reply.send(result)
  })
}
