import { Redis } from "@upstash/redis";
import { Ratelimit } from "@upstash/ratelimit";

let redisClient: Redis | null = null;
let rateLimiter: Ratelimit | null = null;

export function getRedis(): Redis {
  if (!redisClient) {
    redisClient = new Redis({
      url: process.env.UPSTASH_REDIS_REST_URL!,
      token: process.env.UPSTASH_REDIS_REST_TOKEN!,
    });
  }
  return redisClient;
}

export function getRateLimiter(): Ratelimit {
  if (!rateLimiter) {
    rateLimiter = new Ratelimit({
      redis: getRedis(),
      limiter: Ratelimit.slidingWindow(250, "1 h"),
      analytics: true,
      prefix: "neuralgrowth:ratelimit",
    });
  }
  return rateLimiter;
}

export async function cacheGet<T>(key: string): Promise<T | null> {
  const redis = getRedis();
  return redis.get<T>(key);
}

export async function cacheSet<T>(key: string, value: T, ttlSeconds: number = 3600): Promise<void> {
  const redis = getRedis();
  await redis.set(key, value, { ex: ttlSeconds });
}
