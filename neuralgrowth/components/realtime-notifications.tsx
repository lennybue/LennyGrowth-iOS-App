"use client";

import { useRealtimePosts } from "@/hooks/use-realtime-posts";
import { useToast } from "@/components/ui/toast";

/**
 * Global Realtime notification listener.
 * Mount this once in the dashboard layout to show toasts
 * when post statuses change (e.g. scheduled -> published).
 */
export default function RealtimeNotifications() {
  const { toast } = useToast();

  useRealtimePosts({
    onPublished(post) {
      const platform = post.threads_post_id
        ? "Threads"
        : post.linkedin_post_id
        ? "LinkedIn"
        : "your platform";
      toast(`Post published on ${platform}!`, "success");
    },
    onFailed(postId) {
      toast(`Post ${postId.slice(0, 8)}... failed to publish. Check your connections.`, "error");
    },
  });

  return null;
}
