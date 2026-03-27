import { buildApp } from './app.js'
import { env } from './config/env.js'
import { connectDatabase, disconnectDatabase } from './config/database.js'
import { startPostScheduler } from './scheduler/postScheduler.js'

async function main() {
  const app = await buildApp()

  await connectDatabase()
  console.log('✅ Database connected')

  startPostScheduler()

  await app.listen({ port: env.PORT, host: env.HOST })
  console.log(`🚀 LennyGrowth API running at http://${env.HOST}:${env.PORT}`)

  // Graceful shutdown
  const shutdown = async (signal: string) => {
    console.log(`\n${signal} received — shutting down gracefully...`)
    await app.close()
    await disconnectDatabase()
    process.exit(0)
  }

  process.on('SIGINT',  () => shutdown('SIGINT'))
  process.on('SIGTERM', () => shutdown('SIGTERM'))
}

main().catch(err => {
  console.error('Fatal error during startup:', err)
  process.exit(1)
})
