import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");

  if (!code) {
    return NextResponse.redirect(`${origin}/settings?error=no_code`);
  }

  try {
    // Exchange code for LinkedIn access token
    const tokenRes = await fetch(
      "https://www.linkedin.com/oauth/v2/accessToken",
      {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "authorization_code",
          code,
          client_id: process.env.LINKEDIN_CLIENT_ID!,
          client_secret: process.env.LINKEDIN_CLIENT_SECRET!,
          redirect_uri: `${origin}/api/auth/linkedin/callback`,
        }),
      }
    );

    if (!tokenRes.ok) {
      const err = await tokenRes.text();
      console.error("LinkedIn token exchange failed:", err);
      return NextResponse.redirect(`${origin}/settings?error=linkedin_token_failed`);
    }

    const tokenData = await tokenRes.json();
    const accessToken = tokenData.access_token;

    // Get user profile
    const profileRes = await fetch(
      "https://api.linkedin.com/v2/userinfo",
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );
    const profile = profileRes.ok ? await profileRes.json() : null;

    // Store token in Supabase users table
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (user) {
      await supabase
        .from("users")
        .update({
          linkedin_token: accessToken,
          linkedin_name: profile?.name ?? null,
        })
        .eq("id", user.id);
    }

    return NextResponse.redirect(`${origin}/settings?success=linkedin_connected`);
  } catch (error) {
    console.error("LinkedIn OAuth error:", error);
    return NextResponse.redirect(`${origin}/settings?error=linkedin_oauth_failed`);
  }
}
