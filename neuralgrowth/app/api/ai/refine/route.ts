import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { BASE_SYSTEM_PROMPT, streamCompletion } from "@/lib/anthropic";
import { getRateLimiter } from "@/lib/redis";
import type { AIRefineRequest, RefinementAction } from "@/types";

const REFINEMENT_PROMPTS: Record<RefinementAction, string> = {
  "auto-refine": `Automatically improve this post for maximum engagement. Fix weak hooks, tighten the copy, strengthen the CTA, and improve readability. Preserve the core message and tone but make every line earn its place. Output only the refined post.`,

  "stronger-hook": `Rewrite the opening hook of this post to be more scroll-stopping. Use a proven hook format (confession, bold number, hot take, contrarian statement, story opener, or intriguing question). Keep the rest of the post intact but adjust flow if needed. Output only the refined post.`,

  "stronger-cta": `Rewrite the ending of this post with a stronger call-to-action. Make readers feel compelled to comment, share, or save. Use techniques like direct questions, controversial prompts, "save this for later", or "comment X if you agree". Output only the refined post.`,

  "shorten": `Shorten this post by 30-50% while keeping the core message and impact. Cut filler words, redundant points, and unnecessary qualifiers. Every remaining word should earn its place. Output only the shortened post.`,

  "expand": `Expand this post by adding more depth, examples, or a story element. Add 2-3 more lines that provide additional value without becoming fluffy. Maintain the same tone and energy. Output only the expanded post.`,

  "tighten": `Tighten the copy of this post. Remove filler words (just, really, very, actually, basically), fix passive voice, sharpen verbs, and make every sentence punch harder. Do NOT change the structure or core message. Output only the tightened post.`,

  "rewrite": `Completely rewrite this post from scratch while preserving the core message and key points. Use a totally different hook format, structure, and flow. Make it feel like a fresh take on the same idea. Output only the rewritten post.`,

  "add-value": `Add more actionable value to this post. Include a specific tip, framework, data point, example, or step-by-step that the reader can apply immediately. The post should make readers want to save it. Output only the refined post.`,

  "more-casual": `Rewrite this post in a more casual, conversational tone. Use shorter sentences, informal language, and write like you're texting a smart friend. Remove corporate speak and stiffness. Output only the refined post.`,

  "more-professional": `Rewrite this post in a more professional, authoritative tone. Use data-driven language, industry terminology where appropriate, and position the author as a credible expert. Remove slang or overly casual phrasing. Output only the refined post.`,

  "make-viral": `Optimize this post for maximum virality. Use a polarizing or highly relatable hook, create "I need to share this" moments, add pattern interrupts, and end with something that demands engagement. Be bold. Output only the refined post.`,

  "split-thread": `Split this post into a Threads thread (multiple connected posts). The first post should be a powerful hook that makes people want to read the rest. Each subsequent post should deliver one clear point. End with a CTA. Format each post on a new line, separated by "---THREAD---". Output only the thread posts.`,
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

    const body: AIRefineRequest = await request.json();
    const { content, action, platform, tone, customInstruction } = body;

    const refinementInstruction =
      REFINEMENT_PROMPTS[action] ??
      `Refine this post based on the following instruction: ${customInstruction ?? "improve it"}`;

    const systemPrompt = `${BASE_SYSTEM_PROMPT}\n\nYou are refining an existing post. ${refinementInstruction}`;

    const userPrompt = `Platform: ${platform}\nTone: ${tone}\n\nOriginal post:\n${content}${
      customInstruction ? `\n\nAdditional notes: ${customInstruction}` : ""
    }`;

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
    console.error("AI refine error:", error);
    return NextResponse.json(
      { error: "Failed to refine content" },
      { status: 500 }
    );
  }
}
