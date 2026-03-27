import { z } from 'zod'

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default('0.0.0.0'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  DATABASE_URL: z.string().min(1),
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_ACCESS_EXPIRES_IN: z.coerce.number().default(900),      // 15 min
  JWT_REFRESH_EXPIRES_IN: z.coerce.number().default(2592000), // 30 days
  APPLE_TEAM_ID: z.string().optional(),
  APPLE_CLIENT_ID: z.string().optional(),
  APPLE_KEY_ID: z.string().optional(),
  APPLE_PRIVATE_KEY_BASE64: z.string().optional(),
  ANTHROPIC_API_KEY: z.string().min(1),
  ANTHROPIC_MODEL: z.string().default('claude-sonnet-4-5'),
  ENCRYPTION_KEY: z.string().length(64), // 32 bytes hex
  LINKEDIN_CLIENT_ID: z.string().optional(),
  LINKEDIN_CLIENT_SECRET: z.string().optional(),
  LINKEDIN_REDIRECT_URI: z.string().optional(),
  THREADS_APP_ID: z.string().optional(),
  THREADS_APP_SECRET: z.string().optional(),
  THREADS_REDIRECT_URI: z.string().optional(),
  ALLOWED_ORIGINS: z.string().default(''),
})

function loadEnv() {
  const parsed = envSchema.safeParse(process.env)
  if (!parsed.success) {
    console.error('❌ Invalid environment variables:')
    for (const [key, issues] of Object.entries(parsed.error.flatten().fieldErrors)) {
      console.error(`  ${key}: ${issues?.join(', ')}`)
    }
    process.exit(1)
  }
  return parsed.data
}

export const env = loadEnv()
export type Env = typeof env
