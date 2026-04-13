import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { ThreadsAPI } from "@/lib/threads-api";
import { LinkedInAPI } from "@/lib/linkedin-api";
import type { Post, User } from "@/types";

// This endpoint is called by QStash at the scheduled time
export async function POST(req: NextRequest) {
  try {
    // Verify QStash signature in production
    const signature = req.headers.get("upstash-signature");
    if (
      process.env.NODE_ENV === "production" &&
      process.env.QSTASH_CURRENT_SIGNING_KEY &&
      !signature
    ) {
      return NextResponse.json(
        { error: "Missing QStash signature" },
        { status: 401 }
      );
    }

    const { postId } = await req.json();

    if (!postId) {
      return NextResponse.json({ error: "postId required" }, { status: 400 });
    }

    const supabase = await createClient();

    // 1. Fetch the post from Supabase
    const { data: post, error: postError } = await supabase
      .from("posts")
      .select("*")
      .eq("id", postId)
      .single();

    if (postError || !post) {
      return NextResponse.json(
        { error: "Post not found", postId },
        { status: 404 }
      );
    }

    const typedPost = post as Post;

    // 2. Check post is still scheduled (not cancelled/deleted)
    if (typedPost.status !== "scheduled") {
      return NextResponse.json({
        postId,
        status: typedPost.status,
        skipped: true,
        reason: `Post status is "${typedPost.status}", not "scheduled"`,
      });
    }

    // 3. Get user's social tokens from Supabase
    const { data: userProfile, error: userError } = await supabase
      .from("users")
      .select("*")
      .eq("id", typedPost.user_id)
      .single();

    if (userError || !userProfile) {
      // Mark post as failed if we can't find the user
      await supabase
        .from("posts")
        .update({ status: "failed" })
        .eq("id", postId);

      return NextResponse.json(
        { error: "User profile not found", postId },
        { status: 404 }
      );
    }

    const typedUser = userProfile as User;
    const results: Record<
      string,
      { success: boolean; postId?: string; error?: string }
    > = {};

    // 4. Publish to each platform in post.platforms
    const targetPlatforms = typedPost.platforms;

    // Publish to Threads
    if (
      (targetPlatforms.includes("threads") || targetPlatforms.includes("both")) &&
      typedPost.content_threads
    ) {
      if (!typedUser.threads_token) {
        results.threads = {
          success: false,
          error: "Threads account not connected",
        };
      } else {
        try {
          const threadsApi = new ThreadsAPI(typedUser.threads_token);
          const threadsPostId =
            typedPost.media_urls && typedPost.media_urls.length > 0
              ? await threadsApi.publishImage(
                  typedPost.content_threads,
                  typedPost.media_urls[0]
                )
              : await threadsApi.publishText(typedPost.content_threads);

          results.threads = { success: true, postId: threadsPostId };
        } catch (err) {
          results.threads = {
            success: false,
            error:
              err instanceof Error ? err.message : "Threads publish failed",
          };
        }
      }
    }

    // Publish to LinkedIn
    if (
      (targetPlatforms.includes("linkedin") || targetPlatforms.includes("both")) &&
      typedPost.content_linkedin
    ) {
      if (!typedUser.linkedin_token) {
        results.linkedin = {
          success: false,
          error: "LinkedIn account not connected",
        };
      } else {
        try {
          const linkedinApi = new LinkedInAPI(typedUser.linkedin_token);
          const authorUrn = `urn:li:person:${typedUser.id}`;
          const linkedinPostId = await linkedinApi.publishText(
            typedPost.content_linkedin,
            authorUrn
          );

          results.linkedin = { success: true, postId: linkedinPostId };
        } catch (err) {
          results.linkedin = {
            success: false,
            error:
              err instanceof Error ? err.message : "LinkedIn publish failed",
          };
        }
      }
    }

    // 5. Determine overall status and update post
    const allSucceeded = Object.values(results).every((r) => r.success);
    const allFailed = Object.values(results).every((r) => !r.success);
    const newStatus = allFailed ? "failed" : "published";

    const updateData: Record<string, unknown> = {
      status: newStatus,
      published_at: allFailed ? null : new Date().toISOString(),
    };

    if (results.threads?.postId) {
      updateData.threads_post_id = results.threads.postId;
    }
    if (results.linkedin?.postId) {
      updateData.linkedin_post_id = results.linkedin.postId;
    }

    await supabase.from("posts").update(updateData).eq("id", postId);

    return NextResponse.json({
      postId,
      status: newStatus,
      partial: !allSucceeded && !allFailed,
      results,
      published_at: updateData.published_at,
    });
  } catch (error) {
    console.error("Scheduler error:", error);
    // On failure, QStash will retry with exponential backoff (3 retries)
    return NextResponse.json(
      { error: "Failed to process scheduled post" },
      { status: 500 }
    );
  }
}
