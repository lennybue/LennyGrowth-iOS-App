import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  try {
    const { text, imageUrl, accessToken } = await req.json();

    if (!text) {
      return NextResponse.json({ error: "Text content required" }, { status: 400 });
    }

    // In production: use actual Threads API token from Supabase
    const token = accessToken || process.env.THREADS_ACCESS_TOKEN;

    if (!token) {
      return NextResponse.json({ error: "Threads not connected" }, { status: 401 });
    }

    // Step 1: Create thread container
    const createBody: Record<string, string> = {
      media_type: imageUrl ? "IMAGE" : "TEXT",
      text,
      access_token: token,
    };

    if (imageUrl) {
      createBody.image_url = imageUrl;
    }

    const createRes = await fetch("https://graph.threads.net/v1.0/me/threads", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(createBody),
    });

    if (!createRes.ok) {
      const err = await createRes.json();
      return NextResponse.json(
        { error: "Failed to create thread container", details: err },
        { status: createRes.status }
      );
    }

    const { id: creationId } = await createRes.json();

    // Step 2: Publish
    const publishRes = await fetch("https://graph.threads.net/v1.0/me/threads_publish", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        creation_id: creationId,
        access_token: token,
      }),
    });

    if (!publishRes.ok) {
      const err = await publishRes.json();
      return NextResponse.json(
        { error: "Failed to publish thread", details: err },
        { status: publishRes.status }
      );
    }

    const { id: postId } = await publishRes.json();

    return NextResponse.json({
      success: true,
      postId,
      platform: "threads",
    });
  } catch (_error) {
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
