import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { BASE_SYSTEM_PROMPT, streamCompletion } from "@/lib/anthropic";
import { getRateLimiter } from "@/lib/redis";
import type { AIEngageRequest, ReplyType } from "@/types";

const REPLY_PROMPTS: Record<ReplyType, string> = {
  "add-value": `Write a reply that adds genuine value to this post. Share a specific insight, tip, resource, or experience that complements the original content. Position the replier as knowledgeable without being preachy.`,

  "bold-take": `Write a reply with a bold, confident take on this post's topic. Agree or respectfully push back with a strong opinion that sparks further discussion. Be provocative but not rude.`,

  "question": `Write a reply that asks a thoughtful, specific question about this post. The question should show genuine curiosity, demonstrate expertise, and invite the author to share more. Avoid generic questions.`,

  "data-point": `Write a reply that adds a relevant data point, statistic, or case study that supports or enriches the original post. Make it concrete and memorable.`,

  "witty": `Write a reply that is witty, clever, and memorable. Use humor, a clever analogy, or a punchy one-liner that adds to the conversation while being entertaining. Never be mean-spirited.`,

  "agree-extend": `Write a reply that agrees with the post and extends the idea further. Add a new angle, a "yes, and..." perspective, or a related insight that builds on the author's point.`,
};

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const rateLimiter = getRateLimiter();
    const { success, remaining } = await rateLimiter.limit(user.id);
    if (!success) {
      return NextResponse.json(
        { error: "Rate limit exceeded. Please try again later." },
        { status: 429, headers: { "X-RateLimit-Remaining": String(remaining) } }
      );
    }

    const body: AIEngageRequest = await request.json();
    const { originalContent, authorHandle, replyType } = body;

    const replyInstruction =
      REPLY_PROMPTS[replyType] ?? "Write a thoughtful reply to this post.";

    const systemPrompt = `${BASE_SYSTEM_PROMPT}

You are generating an engagement reply to another creator's post on Threads.

Rules:
- Maximum 280 characters
- Sound authentic, not AI-generated
- Never use hashtags
- Match the energy and tone of the original post
- Be concise and punchy

${replyInstruction}`;

    const userPrompt = `Reply to this post by @${authorHandle}:\n\n"${originalContent}"`;

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
    console.error("AI engage error:", error);
    return NextResponse.json(
      { error: "Failed to generate engagement reply" },
      { status: 500 }
    );
  }
}
