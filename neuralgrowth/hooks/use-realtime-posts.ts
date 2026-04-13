"use client";

import { useEffect, useRef } from "react";
import { createClient } from "@/lib/supabase/client";
import type { Post, PostStatus } from "@/types";

type PostChangePayload = {
  id: string;
  status: PostStatus;
  published_at: string | null;
  threads_post_id: string | null;
  linkedin_post_id: string | null;
};

interface UseRealtimePostsOptions {
  /** Called when any post row changes (INSERT, UPDATE, DELETE) */
  onPostChange?: (payload: {
    eventType: "INSERT" | "UPDATE" | "DELETE";
    new: Partial<Post>;
    old: Partial<Post>;
  }) => void;
  /** Called specifically when a post status transitions */
  onStatusChange?: (postId: string, oldStatus: PostStatus, newStatus: PostStatus) => void;
  /** Called when a scheduled post is published */
  onPublished?: (post: PostChangePayload) => void;
  /** Called when a publish attempt fails */
  onFailed?: (postId: string) => void;
  /** Whether the subscription is active */
  enabled?: boolean;
}

/**
 * Hook to subscribe to Supabase Realtime changes on the posts table.
 * Filters to only the authenticated user's posts.
 */
export function useRealtimePosts(options: UseRealtimePostsOptions = {}) {
  const {
    onPostChange,
    onStatusChange,
    onPublished,
    onFailed,
    enabled = true,
  } = options;

  const optionsRef = useRef(options);
  optionsRef.current = { onPostChange, onStatusChange, onPublished, onFailed };

  useEffect(() => {
    if (!enabled) return;

    const supabase = createClient();
    let userId: string | null = null;

    const setup = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser();

      if (!user) return;
      userId = user.id;

      const channel = supabase
        .channel("posts-realtime")
        .on(
          "postgres_changes",
          {
            event: "*",
            schema: "public",
            table: "posts",
            filter: `user_id=eq.${userId}`,
          },
          (payload: { new: Record<string, unknown>; old: Record<string, unknown>; eventType: string }) => {
            const newRecord = (payload.new || {}) as Partial<Post>;
            const oldRecord = (payload.old || {}) as Partial<Post>;
            const eventType = payload.eventType as "INSERT" | "UPDATE" | "DELETE";

            // General change callback
            optionsRef.current.onPostChange?.({
              eventType,
              new: newRecord,
              old: oldRecord,
            });

            // Status change detection
            if (
              eventType === "UPDATE" &&
              oldRecord.status &&
              newRecord.status &&
              oldRecord.status !== newRecord.status
            ) {
              optionsRef.current.onStatusChange?.(
                newRecord.id || oldRecord.id || "",
                oldRecord.status,
                newRecord.status
              );

              // Specific published callback
              if (newRecord.status === "published") {
                optionsRef.current.onPublished?.({
                  id: newRecord.id || "",
                  status: "published",
                  published_at: newRecord.published_at || null,
                  threads_post_id: newRecord.threads_post_id || null,
                  linkedin_post_id: newRecord.linkedin_post_id || null,
                });
              }

              // Specific failed callback
              if (newRecord.status === "failed") {
                optionsRef.current.onFailed?.(newRecord.id || oldRecord.id || "");
              }
            }
          }
        )
        .subscribe();

      return () => {
        supabase.removeChannel(channel);
      };
    };

    let cleanup: (() => void) | undefined;
    setup().then((fn) => {
      cleanup = fn;
    });

    return () => {
      cleanup?.();
    };
  }, [enabled]);
}
