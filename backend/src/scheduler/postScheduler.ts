import cron from 'node-cron'
import { processScheduledPosts } from '../services/post.service.js'

/**
 * Post scheduler — runs every minute and publishes any posts
 * whose scheduledAt timestamp is in the past.
 *
 * In production this cron job should be the only thing that calls
 * platform publish APIs (never the iOS device directly).
 */
export function startPostScheduler(): void {
  cron.schedule('* * * * *', async () => {
    try {
      await processScheduledPosts()
    } catch (err) {
      console.error('[Scheduler] Error processing scheduled posts:', err)
    }
  }, {
    timezone: 'Europe/Berlin',
  })

  console.log('[Scheduler] Post scheduler started (runs every minute, Europe/Berlin)')
}
