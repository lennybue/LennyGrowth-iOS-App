import { Client } from "@upstash/qstash";

let qstashClient: Client | null = null;

export function getQStashClient(): Client {
  if (!qstashClient) {
    qstashClient = new Client({
      token: process.env.QSTASH_TOKEN!,
    });
  }
  return qstashClient;
}

export async function schedulePost(
  postId: string,
  publishAt: Date,
  callbackUrl: string
): Promise<string> {
  const client = getQStashClient();

  const notBefore = Math.floor(publishAt.getTime() / 1000);

  const result = await client.publishJSON({
    url: callbackUrl,
    body: { postId },
    notBefore,
  });

  return result.messageId;
}
