import Anthropic from '@anthropic-ai/sdk'
import type { FastifyReply } from 'fastify'
import { prisma } from '../config/database.js'
import { env } from '../config/env.js'

const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY })

// ─── Rate limiting ────────────────────────────────────────────────────────────

const FREE_DAILY_LIMIT = 20

async function checkAndIncrementUsage(userId: string, tier: string): Promise<void> {
  if (tier === 'pro') return // unlimited

  const today = new Date()
  today.setHours(0, 0, 0, 0)

  const usage = await prisma.aiUsage.upsert({
    where: { userId_date: { userId, date: today } },
    create: { userId, date: today, count: 1 },
    update: { count: { increment: 1 } },
  })

  if (usage.count > FREE_DAILY_LIMIT) {
    throw Object.assign(
      new Error(`Tägliches KI-Limit (${FREE_DAILY_LIMIT}) erreicht. Upgrade auf Pro für unbegrenzte Nutzung.`),
      { statusCode: 429 }
    )
  }
}

// ─── System prompt ────────────────────────────────────────────────────────────

function buildSystemPrompt(platform: string, tone: string): string {
  const platformRules = platform === 'linkedin'
    ? `Du schreibst für LinkedIn:
- Max. 3.000 Zeichen
- Professionell-locker, datengetrieben
- KEIN Link im Post-Body → erinnere den User daran, den Link in den ersten Kommentar zu setzen
- Optimales Format: Hook → Kontrast → 3 Learnings → CTA
- Emojis sparsam einsetzen
- Keine Hashtags (oder max. 3 am Ende)`
    : platform === 'threads'
    ? `Du schreibst für Threads:
- Max. 500 Zeichen — sehr kurz und prägnant
- Max. 5–6 Zeilen
- Keine Hashtags (sie erhöhen die Reichweite auf Threads nicht)
- Links NUR als "→ Link in Bio" Formulierung
- Casual, direkt, Meinung/Hook-getrieben`
    : 'Schreibe einen überzeugenden Social-Media-Post.'

  const toneMap: Record<string, string> = {
    professional: 'professionell und sachlich',
    casual:       'locker, persönlich und zugänglich',
    humorous:     'witzig und leicht humorvoll, aber nicht albern',
    inspirational: 'motivierend und inspirierend',
    educational:  'lehrreich, mit konkreten Daten und Fakten',
    promotional:  'überzeugend, mit klarem CTA, aber nicht aufdringlich',
  }

  return `Du bist Lennard Büssows persönlicher KI-Content-Assistent für Social Media.

Lennard Büssow ist Digital Marketing Specialist & IT-Consultant aus dem DACH-Raum.
Fokus: SEO, Google Ads, KI-Marketing, CRO, Content-Strategie.
Sprache: Deutsch (primär), Englisch nur wenn explizit angefragt.
Ton: ${toneMap[tone] ?? 'professionell-locker'}

${platformRules}

Wichtige Regeln:
- Keine Clickbait-Überschriften
- Zahlenformat: 2.500 EUR, 1,5 %
- Konkret und datengetrieben — keine leeren Phrasen
- Schreibe in der ersten Person (Ich-Perspektive)
- Gib NUR den fertigen Post aus, ohne Erklärungen oder Kommentare`
}

// ─── Generate (non-streaming) ─────────────────────────────────────────────────

export async function generateContent(
  userId: string,
  userTier: string,
  prompt: string,
  tone: string,
  platforms: string[],
  context?: string | null
) {
  await checkAndIncrementUsage(userId, userTier)

  const platform = platforms[0] ?? 'linkedin'
  const messages: Anthropic.MessageParam[] = [
    { role: 'user', content: context ? `${prompt}\n\nKontext: ${context}` : prompt }
  ]

  const response = await anthropic.messages.create({
    model:      env.ANTHROPIC_MODEL,
    max_tokens: 1024,
    system:     buildSystemPrompt(platform, tone),
    messages,
  })

  const mainContent = response.content[0].type === 'text' ? response.content[0].text : ''

  // Build platform variant if both platforms requested
  const platformVariants: Record<string, string> = {}
  if (platforms.includes('linkedin') && platforms.includes('threads')) {
    // Truncate to Threads limit
    platformVariants['linkedin'] = mainContent
    platformVariants['threads']  = mainContent.slice(0, 500)
  }

  return {
    mainContent,
    platformVariants,
    suggestedHashtags: extractHashtags(mainContent),
    estimatedEngagement: estimateEngagement(mainContent, platform),
    alternativeVersions: [],
  }
}

// ─── Generate (SSE streaming) ─────────────────────────────────────────────────

export async function generateContentStream(
  userId: string,
  userTier: string,
  prompt: string,
  tone: string,
  platforms: string[],
  context: string | null | undefined,
  reply: FastifyReply
): Promise<void> {
  await checkAndIncrementUsage(userId, userTier)

  const platform = platforms[0] ?? 'linkedin'

  reply.raw.writeHead(200, {
    'Content-Type':      'text/event-stream',
    'Cache-Control':     'no-cache',
    'Connection':        'keep-alive',
    'X-Accel-Buffering': 'no',
  })

  const stream = await anthropic.messages.stream({
    model:      env.ANTHROPIC_MODEL,
    max_tokens: 1024,
    system:     buildSystemPrompt(platform, tone),
    messages: [{ role: 'user', content: context ? `${prompt}\n\nKontext: ${context}` : prompt }],
  })

  for await (const chunk of stream) {
    if (chunk.type === 'content_block_delta' && chunk.delta.type === 'text_delta') {
      const text = chunk.delta.text.replace(/\n/g, '\\n')
      reply.raw.write(`data: ${text}\n\n`)
    }
  }

  reply.raw.write('data: [DONE]\n\n')
  reply.raw.end()
}

// ─── Rewrite ──────────────────────────────────────────────────────────────────

export async function rewriteContent(
  userId: string,
  userTier: string,
  content: string,
  tone: string,
  instruction: string
) {
  await checkAndIncrementUsage(userId, userTier)

  const response = await anthropic.messages.create({
    model:      env.ANTHROPIC_MODEL,
    max_tokens: 1024,
    system:     `Du bist ein Expert für Social-Media-Content-Optimierung. Schreibe den gegebenen Text um und beachte dabei: ${instruction}. Ton: ${tone}. Gib NUR den überarbeiteten Text aus.`,
    messages:   [{ role: 'user', content }],
  })

  return response.content[0].type === 'text' ? response.content[0].text : content
}

// ─── Hashtags ─────────────────────────────────────────────────────────────────

export async function generateHashtags(
  userId: string,
  userTier: string,
  content: string,
  platforms: string[]
) {
  await checkAndIncrementUsage(userId, userTier)

  // For Threads: hashtags don't work — return empty
  if (platforms.every(p => p === 'threads')) return []

  const response = await anthropic.messages.create({
    model:      env.ANTHROPIC_MODEL,
    max_tokens: 200,
    system:     'Du generierst relevante Hashtags für LinkedIn-Posts. Gib nur eine kommaseparierte Liste aus, z.B.: #seo, #digitalmarketing',
    messages:   [{ role: 'user', content: `Generiere 5-8 relevante LinkedIn-Hashtags für diesen Post:\n\n${content}` }],
  })

  const raw = response.content[0].type === 'text' ? response.content[0].text : ''
  return raw.split(',').map(h => h.trim()).filter(h => h.startsWith('#'))
}

// ─── AI usage stats ───────────────────────────────────────────────────────────

export async function getUsageToday(userId: string): Promise<{ count: number; limit: number; tier: string }> {
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const usage = await prisma.aiUsage.findUnique({ where: { userId_date: { userId, date: today } } })
  const user  = await prisma.user.findUnique({ where: { id: userId }, select: { subscriptionTier: true } })
  const tier  = user?.subscriptionTier ?? 'free'
  return { count: usage?.count ?? 0, limit: tier === 'pro' ? -1 : FREE_DAILY_LIMIT, tier }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

function extractHashtags(text: string): string[] {
  return (text.match(/#\w+/g) ?? []).slice(0, 8)
}

function estimateEngagement(text: string, platform: string): string {
  const len = text.length
  if (platform === 'linkedin') {
    if (len > 1500) return 'Hoch (2–5 %)'
    if (len > 500)  return 'Mittel (1–2 %)'
    return 'Niedrig (<1 %)'
  }
  return len < 200 ? 'Hoch' : 'Mittel'
}
