const THREADS_API_BASE = "https://graph.threads.net/v1.0";

interface ThreadsResponse {
  id?: string;
  error?: { message: string; code: number };
}

interface ThreadsInsights {
  data: Array<{
    name: string;
    period: string;
    values: Array<{ value: number }>;
  }>;
}

interface ThreadsPostsResponse {
  data: Array<{
    id: string;
    text?: string;
    timestamp: string;
    media_type: string;
    permalink: string;
  }>;
  paging?: { cursors: { after: string }; next: string };
}

export class ThreadsAPI {
  private accessToken: string;

  constructor(accessToken: string) {
    this.accessToken = accessToken;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const separator = endpoint.includes("?") ? "&" : "?";
    const url = `${THREADS_API_BASE}${endpoint}${separator}access_token=${this.accessToken}`;

    const response = await fetch(url, {
      ...options,
      headers: {
        "Content-Type": "application/json",
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(
        `Threads API error (${response.status}): ${error?.error?.message ?? response.statusText}`
      );
    }

    return response.json() as Promise<T>;
  }

  async publishText(text: string): Promise<ThreadsResponse> {
    // Step 1: Create media container
    const container = await this.request<ThreadsResponse>("/me/threads", {
      method: "POST",
      body: JSON.stringify({
        media_type: "TEXT",
        text,
      }),
    });

    if (!container.id) {
      throw new Error("Failed to create Threads media container");
    }

    // Step 2: Publish the container
    return this.request<ThreadsResponse>("/me/threads_publish", {
      method: "POST",
      body: JSON.stringify({
        creation_id: container.id,
      }),
    });
  }

  async publishImage(
    text: string,
    imageUrl: string
  ): Promise<ThreadsResponse> {
    // Step 1: Create media container with image
    const container = await this.request<ThreadsResponse>("/me/threads", {
      method: "POST",
      body: JSON.stringify({
        media_type: "IMAGE",
        text,
        image_url: imageUrl,
      }),
    });

    if (!container.id) {
      throw new Error("Failed to create Threads image container");
    }

    // Step 2: Publish the container
    return this.request<ThreadsResponse>("/me/threads_publish", {
      method: "POST",
      body: JSON.stringify({
        creation_id: container.id,
      }),
    });
  }

  async getInsights(mediaId: string): Promise<ThreadsInsights> {
    return this.request<ThreadsInsights>(
      `/${mediaId}/insights?metric=views,likes,replies,reposts,quotes`
    );
  }

  async getUserPosts(limit: number = 25): Promise<ThreadsPostsResponse> {
    return this.request<ThreadsPostsResponse>(
      `/me/threads?fields=id,text,timestamp,media_type,permalink&limit=${limit}`
    );
  }

  async getPostInsights(postId: string): Promise<ThreadsInsights> {
    return this.request<ThreadsInsights>(
      `/${postId}/insights?metric=views,likes,replies,reposts,quotes`
    );
  }
}
