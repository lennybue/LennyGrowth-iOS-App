import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors",
  {
    variants: {
      variant: {
        default: "bg-[#FF006E]/20 text-[#FF006E] border border-[#FF006E]/30",
        secondary: "bg-[#16E1C4]/20 text-[#16E1C4] border border-[#16E1C4]/30",
        outline: "border border-white/20 text-[#94A3B8]",
        ice: "bg-[#4CC9F0]/20 text-[#4CC9F0] border border-[#4CC9F0]/30",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  );
}

export { Badge, badgeVariants };
