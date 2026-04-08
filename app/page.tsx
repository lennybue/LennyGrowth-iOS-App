import { redirect } from "next/navigation";

export default function Home() {
  // MVP: redirect to login. When auth is wired up,
  // check for session and redirect to /compose if authenticated.
  redirect("/login");
}
