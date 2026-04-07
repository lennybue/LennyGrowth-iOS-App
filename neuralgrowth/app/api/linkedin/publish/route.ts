import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  try {
    const { text, authorUrn, accessToken } = await req.json();

    if (!text) {
      return NextResponse.json({ error: "Text content required" }, { status: 400 });
    }

    const token = accessToken || process.env.LINKEDIN_ACCESS_TOKEN;

    if (!token) {
      return NextResponse.json({ error: "LinkedIn not connected" }, { status: 401 });
    }

    // LinkedIn UGC Post
    const ugcPost = {
      author: authorUrn || "urn:li:person:me",
      lifecycleState: "PUBLISHED",
      specificContent: {
        "com.linkedin.ugc.ShareContent": {
          shareCommentary: {
            text,
          },
          shareMediaCategory: "NONE",
        },
      },
      visibility: {
        "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC",
      },
    };

    const res = await fetch("https://api.linkedin.com/v2/ugcPosts", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        "X-Restli-Protocol-Version": "2.0.0",
      },
      body: JSON.stringify(ugcPost),
    });

    if (!res.ok) {
      const err = await res.text();
      // Implement exponential backoff on 429
      if (res.status === 429) {
        return NextResponse.json(
          { error: "LinkedIn rate limit reached. Try again later.", retryAfter: res.headers.get("Retry-After") },
          { status: 429 }
        );
      }
      return NextResponse.json(
        { error: "Failed to publish to LinkedIn", details: err },
        { status: res.status }
      );
    }

    const result = await res.json();

    return NextResponse.json({
      success: true,
      postId: result.id,
      platform: "linkedin",
    });
  } catch (_error) {
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
