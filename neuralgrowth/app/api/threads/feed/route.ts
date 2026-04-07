import { NextRequest, NextResponse } from "next/server";

// Curated handle list (MVP: admin-defined)
const CURATED_HANDLES = [
  "marketingexamples",
  "growthbylenny",
  "neuralnetworksnerd",
  "seotweets",
  "ppcchris",
  "contentmarketinginstitute",
];

export async function GET(_req: NextRequest) {
  try {
    // In production, this would:
    // 1. Get user's Threads token from Supabase
    // 2. Fetch posts from curated handles via Threads API
    // 3. Filter out trashed posts for this user
    // 4. Return sorted by engagement

    // MVP: Return mock feed data
    const feed = CURATED_HANDLES.map((handle, i) => ({
      id: `feed-${i}`,
      threads_post_id: `t-${i}`,
      author_handle: handle,
      content: `Sample post from @${handle}. In production, this would be fetched via Threads API.`,
      likes: Math.floor(Math.random() * 5000),
      replies: Math.floor(Math.random() * 500),
      permalink: null,
      saved: false,
      trashed: false,
      liked_by_user: false,
      refreshed_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + 172800000).toISOString(),
    }));

    return NextResponse.json({ feed, next_refresh: new Date(Date.now() + 172800000).toISOString() });
  } catch (_error) {
    return NextResponse.json(
      { error: "Failed to fetch engagement feed" },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const { action } = await req.json();

    switch (action) {
      case "like":
        // POST /{thread-id}/likes via Threads API
        return NextResponse.json({ success: true, action: "liked" });

      case "save":
        // Update engagement_pool set saved = true
        return NextResponse.json({ success: true, action: "saved" });

      case "trash":
        // Update engagement_pool set trashed = true
        return NextResponse.json({ success: true, action: "trashed" });

      case "undo-trash":
        // Update engagement_pool set trashed = false
        return NextResponse.json({ success: true, action: "untrashed" });

      default:
        return NextResponse.json({ error: "Unknown action" }, { status: 400 });
    }
  } catch (_error) {
    return NextResponse.json(
      { error: "Failed to process action" },
      { status: 500 }
    );
  }
}
