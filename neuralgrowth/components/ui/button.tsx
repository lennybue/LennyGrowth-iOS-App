"use client";

import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-lg text-sm font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-offset-[#0C1222] disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default:
          "bg-[#FF006E] text-white hover:bg-[#FF006E]/90 hover:shadow-[0_0_20px_rgba(255,0,110,0.4)] focus-visible:ring-[#FF006E]",
        secondary:
          "bg-[#16E1C4] text-[#0C1222] hover:bg-[#16E1C4]/90 hover:shadow-[0_0_20px_rgba(22,225,196,0.4)] focus-visible:ring-[#16E1C4]",
        outline:
          "border border-white/10 bg-white/5 backdrop-blur-sm text-white hover:bg-white/10 hover:border-white/20 focus-visible:ring-white/20",
        ghost:
          "text-white hover:bg-white/10 focus-visible:ring-white/20",
        destructive:
          "bg-red-600 text-white hover:bg-red-700 focus-visible:ring-red-600",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-8 rounded-md px-3 text-xs",
        lg: "h-12 rounded-lg px-8 text-base",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
