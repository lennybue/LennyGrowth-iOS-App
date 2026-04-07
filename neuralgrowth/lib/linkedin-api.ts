const LINKEDIN_API_BASE = "https://api.linkedin.com/v2";

interface LinkedInPostResponse {
  id: string;
}

interface LinkedInPostStats {
  totalShareStatistics: {
    shareCount: number;
    clickCount: number;
    engagement: number;
    impressionCount: number;
    likeCount: number;
    commentCount: number;
  };
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

  async publishText(text: string, authorUrn: string): Promise<string> {
    const result = await this.request<LinkedInPostResponse>("/ugcPosts", {
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

    return result.id;
  }

  async publishImage(
    text: string,
    imageUrl: string,
    authorUrn: string
  ): Promise<string> {
    const result = await this.request<LinkedInPostResponse>("/ugcPosts", {
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

    return result.id;
  }

  async getPostStats(
    postUrn: string
  ): Promise<LinkedInPostStats["totalShareStatistics"]> {
    const encodedUrn = encodeURIComponent(postUrn);
    const result = await this.request<{ elements: LinkedInPostStats[] }>(
      `/organizationalEntityShareStatistics?q=organizationalEntity&shares[0]=${encodedUrn}`
    );

    if (!result.elements.length) {
      throw new Error("No stats found for the specified post");
    }

    return result.elements[0].totalShareStatistics;
  }
}
