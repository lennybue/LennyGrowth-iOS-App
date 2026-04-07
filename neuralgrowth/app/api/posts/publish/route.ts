import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { ThreadsAPI } from "@/lib/threads-api";
import { LinkedInAPI } from "@/lib/linkedin-api";
import type { Post, User } from "@/types";

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();
    const {
      data: { user: authUser },
    } = await supabase.auth.getUser();

    if (!authUser) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { postId, platforms } = (await request.json()) as {
      postId: string;
      platforms?: string[];
    };

    if (!postId) {
      return NextResponse.json(
        { error: "Post ID is required" },
        { status: 400 }
      );
    }

    // Fetch the post
    const { data: post, error: postError } = await supabase
      .from("posts")
      .select("*")
      .eq("id", postId)
      .eq("user_id", authUser.id)
      .single();

    if (postError || !post) {
      return NextResponse.json({ error: "Post not found" }, { status: 404 });
    }

    const typedPost = post as Post;

    // Fetch user profile for tokens
    const { data: userProfile, error: userError } = await supabase
      .from("users")
      .select("*")
      .eq("id", authUser.id)
      .single();

    if (userError || !userProfile) {
      return NextResponse.json(
        { error: "User profile not found" },
        { status: 404 }
      );
    }

    const typedUser = userProfile as User;
    const targetPlatforms = platforms ?? typedPost.platforms;
    const results: Record<string, { success: boolean; postId?: string; error?: string }> = {};

    // Publish to Threads
    if (
      (targetPlatforms.includes("threads") ||
        targetPlatforms.includes("both")) &&
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
            typedPost.media_urls.length > 0
              ? await threadsApi.publishImage(
                  typedPost.content_threads,
                  typedPost.media_urls[0]
                )
              : await threadsApi.publishText(typedPost.content_threads);

          results.threads = { success: true, postId: threadsPostId };
        } catch (err) {
          results.threads = {
            success: false,
            error: err instanceof Error ? err.message : "Threads publish failed",
          };
        }
      }
    }

    // Publish to LinkedIn
    if (
      (targetPlatforms.includes("linkedin") ||
        targetPlatforms.includes("both")) &&
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
          const authorUrn = `urn:li:person:${authUser.id}`;
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

    // Determine overall status
    const allSucceeded = Object.values(results).every((r) => r.success);
    const allFailed = Object.values(results).every((r) => !r.success);
    const newStatus = allFailed ? "failed" : "published";

    // Update post in database
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

    await supabase
      .from("posts")
      .update(updateData)
      .eq("id", postId)
      .eq("user_id", authUser.id);

    return NextResponse.json({
      success: allSucceeded,
      partial: !allSucceeded && !allFailed,
      results,
    });
  } catch (error) {
    console.error("Publish post error:", error);
    return NextResponse.json(
      { error: "Failed to publish post" },
      { status: 500 }
    );
  }
}
