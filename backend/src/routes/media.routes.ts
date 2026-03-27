import type { FastifyInstance } from 'fastify'
import multipart from '@fastify/multipart'
import { prisma } from '../config/database.js'
import * as mediaService from '../services/media.service.js'
import { authenticate } from '../middleware/authenticate.js'

const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4',
])
const MAX_FILE_SIZE = 10 * 1024 * 1024 // 10 MB

export async function mediaRoutes(fastify: FastifyInstance): Promise<void> {
  // Register multipart plugin scoped to this route plugin
  await fastify.register(multipart, {
    limits: { fileSize: MAX_FILE_SIZE, files: 1 },
  })

  // POST /media/upload
  fastify.post('/media/upload', { preHandler: [authenticate] }, async (req, reply) => {
    const file = await req.file()
    if (!file) {
      return reply.status(400).send({ statusCode: 400, error: 'Bad Request', message: 'No file uploaded' })
    }

    const mimeType = file.mimetype
    if (!ALLOWED_MIME_TYPES.has(mimeType)) {
      return reply.status(415).send({
        statusCode: 415,
        error: 'Unsupported Media Type',
        message: `Dateityp nicht erlaubt. Erlaubt: ${[...ALLOWED_MIME_TYPES].join(', ')}`,
      })
    }

    // Read file buffer
    const chunks: Buffer[] = []
    for await (const chunk of file.file) chunks.push(chunk)
    const buffer = Buffer.concat(chunks)

    if (buffer.length > MAX_FILE_SIZE) {
      return reply.status(413).send({ statusCode: 413, error: 'Payload Too Large', message: 'Maximale Dateigröße: 10 MB' })
    }

    const storageKey = mediaService.generateStorageKey(req.userId, file.filename)
    const fileType   = mediaService.mimeToType(mimeType)

    const { url, key } = await mediaService.uploadFile(buffer, storageKey, mimeType)
    const record = await mediaService.saveMediaRecord(req.userId, {
      url,
      key,
      type:     fileType,
      fileSize: buffer.length,
      mimeType,
    })

    reply.status(201).send(record)
  })

  // DELETE /media/:id
  fastify.delete('/media/:id', { preHandler: [authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string }

    const record = await prisma.mediaUpload.findFirst({ where: { id, userId: req.userId } })
    if (!record) {
      return reply.status(404).send({ statusCode: 404, error: 'Not Found', message: 'Medium nicht gefunden' })
    }

    await mediaService.deleteFile(record.storageKey)
    await prisma.mediaUpload.delete({ where: { id } })
    reply.status(204).send()
  })
}
