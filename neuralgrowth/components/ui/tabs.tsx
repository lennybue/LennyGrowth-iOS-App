"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

interface TabsContextValue {
  value: string;
  onValueChange: (value: string) => void;
}

const TabsContext = React.createContext<TabsContextValue>({
  value: "",
  onValueChange: () => {},
});

function Tabs({
  defaultValue,
  value: controlledValue,
  onValueChange,
  children,
  className,
  ...props
}: {
  defaultValue?: string;
  value?: string;
  onValueChange?: (value: string) => void;
  children: React.ReactNode;
} & React.HTMLAttributes<HTMLDivElement>) {
  const [uncontrolledValue, setUncontrolledValue] = React.useState(defaultValue ?? "");
  const isControlled = controlledValue !== undefined;
  const value = isControlled ? controlledValue : uncontrolledValue;

  const handleChange = React.useCallback(
    (newValue: string) => {
      if (!isControlled) setUncontrolledValue(newValue);
      onValueChange?.(newValue);
    },
    [isControlled, onValueChange]
  );

  return (
    <TabsContext.Provider value={{ value, onValueChange: handleChange }}>
      <div className={cn("w-full", className)} {...props}>
        {children}
      </div>
    </TabsContext.Provider>
  );
}

function TabsList({
  children,
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "inline-flex items-center gap-1 rounded-lg bg-[#1A2332] p-1",
        className
      )}
      role="tablist"
      {...props}
    >
      {children}
    </div>
  );
}

function TabsTrigger({
  value,
  children,
  className,
  ...props
}: {
  value: string;
} & React.ButtonHTMLAttributes<HTMLButtonElement>) {
  const { value: selectedValue, onValueChange } = React.useContext(TabsContext);
  const isActive = selectedValue === value;

  return (
    <button
      role="tab"
      aria-selected={isActive}
      className={cn(
        "inline-flex items-center justify-center whitespace-nowrap rounded-md px-3 py-1.5 text-sm font-medium transition-all",
        isActive
          ? "bg-[#FF006E] text-white shadow-sm"
          : "text-[#94A3B8] hover:text-white hover:bg-white/5",
        className
      )}
      onClick={() => onValueChange(value)}
      {...props}
    >
      {children}
    </button>
  );
}

function TabsContent({
  value,
  children,
  className,
  ...props
}: {
  value: string;
} & React.HTMLAttributes<HTMLDivElement>) {
  const { value: selectedValue } = React.useContext(TabsContext);

  if (selectedValue !== value) return null;

  return (
    <div
      role="tabpanel"
      className={cn("mt-2", className)}
      {...props}
    >
      {children}
    </div>
  );
}

export { Tabs, TabsList, TabsTrigger, TabsContent };
