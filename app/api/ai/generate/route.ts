import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { BASE_SYSTEM_PROMPT, streamCompletion } from "@/lib/anthropic";
import { getRateLimiter } from "@/lib/redis";
import type { AIGenerateRequest } from "@/types";

const CONTENT_POOL_INSTRUCTION = `
You are generating social media content for a content pool.

When generating a SINGLE post:
- Output only the post text, ready to copy-paste
- Use the specified tone and platform conventions
- Open with a scroll-stopping hook using one of the requested hook formats

When generating MULTIPLE posts (pool generation):
- Return a valid JSON array of strings, each string being a complete post
- Each post should use a DIFFERENT hook format to maximize variety
- Vary the topics across the provided niche tags
- Example: ["Post 1 text here...", "Post 2 text here...", "Post 3 text here..."]

Platform rules:
- Threads: max 500 chars, no hashtags, no URLs, short punchy lines, line breaks for readability
- LinkedIn: longer form OK (up to 3000 chars), professional value-driven, use line breaks
- Both: generate two versions — first for Threads, then for LinkedIn, separated by "---SPLIT---"
`;

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Rate limiting
    const rateLimiter = getRateLimiter();
    const { success, remaining } = await rateLimiter.limit(user.id);
    if (!success) {
      return NextResponse.json(
        { error: "Rate limit exceeded. Please try again later." },
        { status: 429, headers: { "X-RateLimit-Remaining": String(remaining) } }
      );
    }

    const body: AIGenerateRequest = await request.json();
    const {
      prompt,
      platform,
      tone,
      count = 1,
      niche_tags = [],
      language = "english",
      hook_formats = [],
      used_hooks = [],
    } = body;

    const systemPrompt = `${BASE_SYSTEM_PROMPT}\n\n${CONTENT_POOL_INSTRUCTION}`;

    const userPrompt = buildUserPrompt({
      prompt,
      platform,
      tone,
      count,
      niche_tags,
      language,
      hook_formats,
      used_hooks,
    });

    // For pool generation (count > 1), collect the full response and return JSON
    if (count > 1) {
      const stream = streamCompletion(systemPrompt, userPrompt);
      let fullText = "";

      for await (const event of stream) {
        if (
          event.type === "content_block_delta" &&
          event.delta.type === "text_delta"
        ) {
          fullText += event.delta.text;
        }
      }

      let posts: string[];
      try {
        posts = JSON.parse(fullText.trim());
      } catch {
        // If JSON parsing fails, split by double newline as fallback
        posts = fullText
          .split(/\n{2,}/)
          .map((p) => p.trim())
          .filter(Boolean);
      }

      return NextResponse.json({ posts });
    }

    // For single post generation, stream the response
    const stream = streamCompletion(systemPrompt, userPrompt);

    const readableStream = new ReadableStream({
      async start(controller) {
        try {
          for await (const event of stream) {
            if (
              event.type === "content_block_delta" &&
              event.delta.type === "text_delta"
            ) {
              controller.enqueue(
                new TextEncoder().encode(event.delta.text)
              );
            }
          }
          controller.close();
        } catch (err) {
          controller.error(err);
        }
      },
    });

    return new Response(readableStream, {
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Transfer-Encoding": "chunked",
        "X-RateLimit-Remaining": String(remaining),
      },
    });
  } catch (error) {
    console.error("AI generate error:", error);
    return NextResponse.json(
      { error: "Failed to generate content" },
      { status: 500 }
    );
  }
}

function buildUserPrompt(params: {
  prompt?: string;
  platform: string;
  tone: string;
  count: number;
  niche_tags: string[];
  language: string;
  hook_formats: string[];
  used_hooks: string[];
}): string {
  const parts: string[] = [];

  if (params.count > 1) {
    parts.push(
      `Generate ${params.count} unique social media posts as a JSON array of strings.`
    );
  } else {
    parts.push("Generate a single social media post.");
  }

  parts.push(`Platform: ${params.platform}`);
  parts.push(`Tone: ${params.tone}`);
  parts.push(`Language: ${params.language}`);

  if (params.niche_tags.length > 0) {
    parts.push(`Topics/Niches: ${params.niche_tags.join(", ")}`);
  }

  if (params.hook_formats.length > 0) {
    parts.push(`Use these hook formats: ${params.hook_formats.join(", ")}`);
  }

  if (params.used_hooks.length > 0) {
    parts.push(
      `AVOID these hook formats (already used recently): ${params.used_hooks.join(", ")}`
    );
  }

  if (params.prompt) {
    parts.push(`Additional instructions: ${params.prompt}`);
  }

  return parts.join("\n");
}
