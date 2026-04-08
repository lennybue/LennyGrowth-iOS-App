import { cn } from "@/lib/utils";

function Skeleton({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "animate-pulse rounded-lg bg-[#1A2332]",
        className
      )}
      {...props}
    />
  );
}

export { Skeleton };
