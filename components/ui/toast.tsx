"use client";

import * as React from "react";
import { createPortal } from "react-dom";
import { cn } from "@/lib/utils";

type ToastVariant = "success" | "error" | "info";

interface ToastItem {
  id: string;
  message: string;
  variant: ToastVariant;
  undoAction?: () => void;
}

interface ToastContextValue {
  toast: (message: string, variant?: ToastVariant, undoAction?: () => void) => void;
  dismiss: (id: string) => void;
}

const ToastContext = React.createContext<ToastContextValue>({
  toast: () => {},
  dismiss: () => {},
});

export function useToast() {
  return React.useContext(ToastContext);
}

const variantStyles: Record<ToastVariant, string> = {
  success: "border-[#16E1C4]/30 bg-[#16E1C4]/10 text-[#16E1C4]",
  error: "border-[#FF006E]/30 bg-[#FF006E]/10 text-[#FF006E]",
  info: "border-[#4CC9F0]/30 bg-[#4CC9F0]/10 text-[#4CC9F0]",
};

function Toast({
  item,
  onDismiss,
}: {
  item: ToastItem;
  onDismiss: (id: string) => void;
}) {
  React.useEffect(() => {
    const timer = setTimeout(() => {
      onDismiss(item.id);
    }, 5000);
    return () => clearTimeout(timer);
  }, [item.id, onDismiss]);

  return (
    <div
      className={cn(
        "flex items-center justify-between gap-3 rounded-lg border px-4 py-3 text-sm backdrop-blur-md shadow-lg",
        "animate-in slide-in-from-bottom-2 fade-in-0",
        variantStyles[item.variant]
      )}
    >
      <span>{item.message}</span>
      <div className="flex items-center gap-2">
        {item.undoAction && (
          <button
            onClick={() => {
              item.undoAction?.();
              onDismiss(item.id);
            }}
            className="font-medium underline underline-offset-2 hover:opacity-80"
          >
            Undo
          </button>
        )}
        <button
          onClick={() => onDismiss(item.id)}
          className="opacity-60 hover:opacity-100 transition-opacity"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <line x1="18" y1="6" x2="6" y2="18" />
            <line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>
      </div>
    </div>
  );
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = React.useState<ToastItem[]>([]);
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  const toast = React.useCallback(
    (message: string, variant: ToastVariant = "info", undoAction?: () => void) => {
      const id = crypto.randomUUID();
      setToasts((prev) => [...prev, { id, message, variant, undoAction }]);
    },
    []
  );

  const dismiss = React.useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  return (
    <ToastContext.Provider value={{ toast, dismiss }}>
      {children}
      {mounted &&
        createPortal(
          <div className="fixed bottom-4 right-4 z-[100] flex flex-col gap-2 w-full max-w-sm">
            {toasts.map((item) => (
              <Toast key={item.id} item={item} onDismiss={dismiss} />
            ))}
          </div>,
          document.body
        )}
    </ToastContext.Provider>
  );
}

export { Toast };
