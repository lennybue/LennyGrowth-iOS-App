import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");

  if (!code) {
    return NextResponse.redirect(`${origin}/settings?error=no_code`);
  }

  try {
    // Exchange code for Threads long-lived token
    const tokenRes = await fetch(
      "https://graph.threads.net/oauth/access_token",
      {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          client_id: process.env.THREADS_APP_ID!,
          client_secret: process.env.THREADS_APP_SECRET!,
          grant_type: "authorization_code",
          redirect_uri: `${origin}/api/auth/threads/callback`,
          code,
        }),
      }
    );

    if (!tokenRes.ok) {
      const err = await tokenRes.text();
      console.error("Threads token exchange failed:", err);
      return NextResponse.redirect(`${origin}/settings?error=threads_token_failed`);
    }

    const tokenData = await tokenRes.json();
    const accessToken = tokenData.access_token;

    // Exchange for long-lived token (60 days)
    const longLivedRes = await fetch(
      `https://graph.threads.net/access_token?grant_type=th_exchange_token&client_secret=${process.env.THREADS_APP_SECRET!}&access_token=${accessToken}`
    );

    const longLivedData = longLivedRes.ok ? await longLivedRes.json() : null;
    const finalToken = longLivedData?.access_token ?? accessToken;

    // Get user profile for handle
    const profileRes = await fetch(
      `https://graph.threads.net/v1.0/me?fields=id,username&access_token=${finalToken}`
    );
    const profile = profileRes.ok ? await profileRes.json() : null;

    // Store token in Supabase users table
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (user) {
      await supabase
        .from("users")
        .update({
          threads_token: finalToken,
          threads_handle: profile?.username ? `@${profile.username}` : null,
        })
        .eq("id", user.id);
    }

    return NextResponse.redirect(`${origin}/settings?success=threads_connected`);
  } catch (error) {
    console.error("Threads OAuth error:", error);
    return NextResponse.redirect(`${origin}/settings?error=threads_oauth_failed`);
  }
}
