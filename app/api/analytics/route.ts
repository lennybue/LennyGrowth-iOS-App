import { NextRequest, NextResponse } from "next/server";

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const platform = searchParams.get("platform") || "both";
  const period = searchParams.get("period") || "30d";

  try {
    // In production:
    // 1. Check Redis cache first (TTL 1h)
    // 2. If cache miss, fetch from Threads Insights API + LinkedIn API
    // 3. Calculate engagement rates
    // 4. Store in analytics_cache table
    // 5. Return aggregated data

    // MVP: Return mock analytics data
    const days = period === "7d" ? 7 : period === "90d" ? 90 : 30;

    const chartData = Array.from({ length: days }, (_, i) => {
      const date = new Date(Date.now() - (days - 1 - i) * 86400000);
      return {
        date: date.toISOString().split("T")[0],
        threads_views: Math.floor(Math.random() * 1200 + 400),
        threads_likes: Math.floor(Math.random() * 100 + 20),
        threads_comments: Math.floor(Math.random() * 30 + 5),
        linkedin_views: Math.floor(Math.random() * 800 + 200),
        linkedin_likes: Math.floor(Math.random() * 60 + 10),
        linkedin_comments: Math.floor(Math.random() * 20 + 3),
      };
    });

    const totals = chartData.reduce(
      (acc, day) => ({
        threads_views: acc.threads_views + day.threads_views,
        threads_likes: acc.threads_likes + day.threads_likes,
        threads_comments: acc.threads_comments + day.threads_comments,
        linkedin_views: acc.linkedin_views + day.linkedin_views,
        linkedin_likes: acc.linkedin_likes + day.linkedin_likes,
        linkedin_comments: acc.linkedin_comments + day.linkedin_comments,
      }),
      {
        threads_views: 0,
        threads_likes: 0,
        threads_comments: 0,
        linkedin_views: 0,
        linkedin_likes: 0,
        linkedin_comments: 0,
      }
    );

    const totalViews = totals.threads_views + totals.linkedin_views;
    const totalLikes = totals.threads_likes + totals.linkedin_likes;
    const totalComments = totals.threads_comments + totals.linkedin_comments;
    const engagementRate = totalViews > 0
      ? ((totalLikes + totalComments) / totalViews) * 100
      : 0;

    return NextResponse.json({
      period,
      platform,
      metrics: {
        total_views: totalViews,
        total_likes: totalLikes,
        total_comments: totalComments,
        engagement_rate: Math.round(engagementRate * 100) / 100,
        follower_growth: Math.floor(Math.random() * 200 + 50),
      },
      chart_data: chartData,
      last_updated: new Date().toISOString(),
    });
  } catch (_error) {
    return NextResponse.json(
      { error: "Failed to fetch analytics" },
      { status: 500 }
    );
  }
}
