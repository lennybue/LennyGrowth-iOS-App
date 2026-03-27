import { PrismaClient } from '@prisma/client'
import { env } from './env.js'

export const prisma = new PrismaClient({
  log: env.NODE_ENV === 'development' ? ['query', 'warn', 'error'] : ['warn', 'error'],
})

export async function connectDatabase(): Promise<void> {
  await prisma.$connect()
}

export async function disconnectDatabase(): Promise<void> {
  await prisma.$disconnect()
}
