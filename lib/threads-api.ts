const THREADS_API_BASE = "https://graph.threads.net/v1.0";

interface ThreadsMediaContainer {
  id: string;
}

interface ThreadsAPIResponse {
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

interface ThreadsPost {
  id: string;
  text?: string;
  timestamp?: string;
  media_type?: string;
  permalink?: string;
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

  async publishText(text: string): Promise<string> {
    const container = await this.request<ThreadsMediaContainer>("/me/threads", {
      method: "POST",
      body: JSON.stringify({
        media_type: "TEXT",
        text,
      }),
    });

    const result = await this.request<ThreadsAPIResponse>(
      "/me/threads_publish",
      {
        method: "POST",
        body: JSON.stringify({
          creation_id: container.id,
        }),
      }
    );

    if (!result.id) {
      throw new Error("Failed to publish Threads post: no ID returned");
    }

    return result.id;
  }

  async publishImage(text: string, imageUrl: string): Promise<string> {
    const container = await this.request<ThreadsMediaContainer>("/me/threads", {
      method: "POST",
      body: JSON.stringify({
        media_type: "IMAGE",
        image_url: imageUrl,
        text,
      }),
    });

    const result = await this.request<ThreadsAPIResponse>(
      "/me/threads_publish",
      {
        method: "POST",
        body: JSON.stringify({
          creation_id: container.id,
        }),
      }
    );

    if (!result.id) {
      throw new Error("Failed to publish Threads image post: no ID returned");
    }

    return result.id;
  }

  async getInsights(mediaId: string): Promise<ThreadsInsights> {
    return this.request<ThreadsInsights>(
      `/${mediaId}/insights?metric=views,likes,replies,reposts,quotes`
    );
  }

  async getUserPosts(limit: number = 25): Promise<ThreadsPost[]> {
    const result = await this.request<{ data: ThreadsPost[] }>(
      `/me/threads?fields=id,text,timestamp,media_type,permalink&limit=${limit}`
    );
    return result.data;
  }

  async getPostInsights(postId: string): Promise<Record<string, number>> {
    const insights = await this.getInsights(postId);
    const metrics: Record<string, number> = {};

    for (const metric of insights.data) {
      metrics[metric.name] = metric.values[0]?.value ?? 0;
    }

    return metrics;
  }
}
