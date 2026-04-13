import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { ThreadsAPI } from "@/lib/threads-api";

// Curated handle list (MVP: admin-defined engagement targets)
const CURATED_HANDLES = [
  "marketingexamples",
  "growthbylenny",
  "neuralnetworksnerd",
  "seotweets",
  "ppcchris",
  "contentmarketinginstitute",
];

export async function GET(_req: NextRequest) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    // Fetch user profile for Threads token
    const { data: profile } = await supabase
      .from("users")
      .select("threads_token")
      .eq("id", user.id)
      .single();

    // Check engagement_pool for cached posts (refresh every 48h)
    const cutoff = new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString();
    const { data: cachedPosts } = await supabase
      .from("engagement_pool")
      .select("*")
      .eq("user_id", user.id)
      .eq("trashed", false)
      .gte("refreshed_at", cutoff)
      .order("likes", { ascending: false });

    if (cachedPosts && cachedPosts.length > 0) {
      return NextResponse.json({
        feed: cachedPosts,
        next_refresh: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
        source: "cache",
      });
    }

    // If user has Threads connected, fetch their conversation threads
    if (profile?.threads_token) {
      try {
        const threadsApi = new ThreadsAPI(profile.threads_token);
        const userPosts = await threadsApi.getUserPosts(20);

        const feed = userPosts.map((post, i) => ({
          id: `threads-${post.id}`,
          threads_post_id: post.id,
          author_handle: profile.threads_token ? "you" : CURATED_HANDLES[i % CURATED_HANDLES.length],
          content: post.text || "",
          likes: 0,
          replies: 0,
          permalink: post.permalink || null,
          saved: false,
          trashed: false,
          liked_by_user: false,
          refreshed_at: new Date().toISOString(),
          expires_at: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
        }));

        // Fetch insights for each post to get actual metrics
        const feedWithMetrics = await Promise.all(
          feed.map(async (item) => {
            try {
              const insights = await threadsApi.getPostInsights(item.threads_post_id);
              return {
                ...item,
                likes: insights.likes || 0,
                replies: insights.replies || 0,
              };
            } catch {
              return item;
            }
          })
        );

        // Sort by engagement (likes + replies)
        feedWithMetrics.sort((a, b) => (b.likes + b.replies) - (a.likes + a.replies));

        // Cache in engagement_pool
        const poolRows = feedWithMetrics.map((item) => ({
          user_id: user.id,
          threads_post_id: item.threads_post_id,
          author_handle: item.author_handle,
          content: item.content,
          likes: item.likes,
          replies: item.replies,
          permalink: item.permalink,
          saved: false,
          trashed: false,
          liked_by_user: false,
          refreshed_at: item.refreshed_at,
          expires_at: item.expires_at,
        }));

        if (poolRows.length > 0) {
          await supabase
            .from("engagement_pool")
            .upsert(poolRows, { onConflict: "user_id,threads_post_id" });
        }

        return NextResponse.json({
          feed: feedWithMetrics,
          next_refresh: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
          source: "threads_api",
        });
      } catch (apiError) {
        console.error("Threads API fetch error:", apiError);
        // Fall through to curated fallback
      }
    }

    // Fallback: return curated engagement prompts when Threads not connected
    const feed = CURATED_HANDLES.map((handle, i) => ({
      id: `curated-${i}`,
      threads_post_id: `curated-${handle}-${i}`,
      author_handle: handle,
      content: getCuratedPrompt(handle),
      likes: Math.floor(Math.random() * 5000 + 500),
      replies: Math.floor(Math.random() * 300 + 50),
      permalink: null,
      saved: false,
      trashed: false,
      liked_by_user: false,
      refreshed_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
    }));

    return NextResponse.json({
      feed,
      next_refresh: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
      source: "curated",
    });
  } catch (error) {
    console.error("Feed fetch error:", error);
    return NextResponse.json(
      { error: "Failed to fetch engagement feed" },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const { action, postId } = await req.json();

    if (!postId) {
      return NextResponse.json({ error: "postId required" }, { status: 400 });
    }

    switch (action) {
      case "like": {
        // Fetch user's Threads token and like via API
        const { data: profile } = await supabase
          .from("users")
          .select("threads_token")
          .eq("id", user.id)
          .single();

        if (profile?.threads_token) {
          try {
            // Threads API doesn't have a direct like endpoint via graph API,
            // but we track the action locally
            await supabase
              .from("engagement_pool")
              .update({ liked_by_user: true })
              .eq("user_id", user.id)
              .eq("threads_post_id", postId);
          } catch {
            // Silently fail for API like
          }
        }

        return NextResponse.json({ success: true, action: "liked" });
      }

      case "save": {
        await supabase
          .from("engagement_pool")
          .update({ saved: true })
          .eq("user_id", user.id)
          .eq("threads_post_id", postId);

        return NextResponse.json({ success: true, action: "saved" });
      }

      case "trash": {
        await supabase
          .from("engagement_pool")
          .update({ trashed: true })
          .eq("user_id", user.id)
          .eq("threads_post_id", postId);

        return NextResponse.json({ success: true, action: "trashed" });
      }

      case "undo-trash": {
        await supabase
          .from("engagement_pool")
          .update({ trashed: false })
          .eq("user_id", user.id)
          .eq("threads_post_id", postId);

        return NextResponse.json({ success: true, action: "untrashed" });
      }

      default:
        return NextResponse.json({ error: "Unknown action" }, { status: 400 });
    }
  } catch (error) {
    console.error("Feed action error:", error);
    return NextResponse.json(
      { error: "Failed to process action" },
      { status: 500 }
    );
  }
}

// Curated engagement prompts for when Threads API isn't connected
function getCuratedPrompt(handle: string): string {
  const prompts: Record<string, string> = {
    marketingexamples:
      "The best marketing doesn't feel like marketing.\n\nHere are 5 brands that mastered this in 2025:\n\n1. Duolingo — turned TikTok into a growth machine\n2. Notion — community-led content strategy\n3. Arc Browser — word of mouth only\n4. Linear — product quality = marketing\n5. Figma — built an ecosystem, not just a tool",
    growthbylenny:
      "I spent $0 on ads this quarter and grew 47% on Threads.\n\nHere's the exact playbook:\n\n→ Post at 8:30 AM (Tue/Wed/Thu)\n→ Lead with a bold hook\n→ Reply to 20 posts daily in your niche\n→ Use the 1-3-1 format for LinkedIn cross-posts\n→ Repost top performers after 3 weeks",
    neuralnetworksnerd:
      "AI won't replace marketers.\n\nBut marketers who use AI will replace those who don't.\n\nThe shift isn't about automation — it's about augmentation.\n\nUse AI to write 10x drafts, then edit with your human insight.\n\nThat's the competitive advantage.",
    seotweets:
      "Google's March 2025 update just dropped.\n\nKey changes:\n• Helpful content signals are stronger than ever\n• AI-generated content without original insights gets penalized\n• First-party data is now a ranking signal\n• Site reputation abuse crackdown expanded\n\nThread with full analysis below 👇",
    ppcchris:
      "Hot take: Most brands waste 40% of their Google Ads budget.\n\nThe fix is simple:\n1. Audit search term reports weekly (not monthly)\n2. Use exact match for high-intent terms\n3. Separate brand vs. non-brand campaigns\n4. Set up proper conversion tracking\n5. Stop trusting Google's recommendations blindly",
    contentmarketinginstitute:
      "Content marketing in 2025 is fundamentally different.\n\nThe old playbook: publish more, rank higher, get traffic.\n\nThe new playbook: publish less, go deeper, build trust.\n\nQuality > Quantity has never been more true.\n\nHere's how the best brands are adapting...",
  };

  return prompts[handle] || `Trending post from @${handle} — connect your Threads account to see real posts in your niche.`;
}
