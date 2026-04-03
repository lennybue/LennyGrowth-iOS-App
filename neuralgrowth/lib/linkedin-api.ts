const LINKEDIN_API_BASE = "https://api.linkedin.com/v2";

interface LinkedInPostResponse {
  id?: string;
  status?: number;
  message?: string;
}

interface LinkedInStatsResponse {
  elements: Array<{
    totalShareStatistics: {
      shareCount: number;
      clickCount: number;
      engagement: number;
      impressionCount: number;
      likeCount: number;
      commentCount: number;
    };
  }>;
}

export class LinkedInAPI {
  private accessToken: string;

  constructor(accessToken: string) {
    this.accessToken = accessToken;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${LINKEDIN_API_BASE}${endpoint}`;

    const response = await fetch(url, {
      ...options,
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
        "Content-Type": "application/json",
        "X-Restli-Protocol-Version": "2.0.0",
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(
        `LinkedIn API error (${response.status}): ${error?.message ?? response.statusText}`
      );
    }

    return response.json() as Promise<T>;
  }

  async publishText(
    text: string,
    authorUrn: string
  ): Promise<LinkedInPostResponse> {
    return this.request<LinkedInPostResponse>("/ugcPosts", {
      method: "POST",
      body: JSON.stringify({
        author: authorUrn,
        lifecycleState: "PUBLISHED",
        specificContent: {
          "com.linkedin.ugc.ShareContent": {
            shareCommentary: { text },
            shareMediaCategory: "NONE",
          },
        },
        visibility: {
          "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC",
        },
      }),
    });
  }

  async publishImage(
    text: string,
    imageUrl: string,
    authorUrn: string
  ): Promise<LinkedInPostResponse> {
    return this.request<LinkedInPostResponse>("/ugcPosts", {
      method: "POST",
      body: JSON.stringify({
        author: authorUrn,
        lifecycleState: "PUBLISHED",
        specificContent: {
          "com.linkedin.ugc.ShareContent": {
            shareCommentary: { text },
            shareMediaCategory: "IMAGE",
            media: [
              {
                status: "READY",
                originalUrl: imageUrl,
              },
            ],
          },
        },
        visibility: {
          "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC",
        },
      }),
    });
  }

  async getPostStats(postUrn: string): Promise<LinkedInStatsResponse> {
    const encodedUrn = encodeURIComponent(postUrn);
    return this.request<LinkedInStatsResponse>(
      `/organizationalEntityShareStatistics?q=organizationalEntity&shares[0]=${encodedUrn}`
    );
  }
}
