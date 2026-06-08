// Anthropic proxy edge function.
//
// The iOS app builds a normal Anthropic /v1/messages request body and POSTs it
// here instead of to api.anthropic.com. This function:
//   1. Requires an authenticated Supabase user (not just the anon key).
//   2. Injects the secret ANTHROPIC_API_KEY server-side.
//   3. Forwards the body verbatim and returns Anthropic's response unchanged,
//      so the client's existing request/response parsing is untouched.
//
// The Anthropic API key never ships in the app. Deploy with:
//   supabase functions deploy anthropic-proxy
//   supabase secrets set ANTHROPIC_API_KEY=<rotated key>
// SUPABASE_URL and SUPABASE_ANON_KEY are injected automatically.

import { createClient } from "jsr:@supabase/supabase-js@2";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const DEFAULT_ANTHROPIC_VERSION = "2023-06-01";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    return json({ error: "Server misconfigured: ANTHROPIC_API_KEY not set" }, 500);
  }

  // Require a real authenticated user. The gateway accepts any valid project
  // JWT (including the anon key), so we verify the token resolves to a user.
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } }, auth: { persistSession: false } },
  );
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    return json({ error: "Unauthorized" }, 401);
  }

  // Forward the request body verbatim, preserving the client's anthropic-version
  // and anthropic-beta (prompt caching) headers so behavior is unchanged.
  const body = await req.text();
  const upstreamHeaders: Record<string, string> = {
    "Content-Type": "application/json",
    "x-api-key": apiKey,
    "anthropic-version": req.headers.get("anthropic-version") ?? DEFAULT_ANTHROPIC_VERSION,
  };
  const beta = req.headers.get("anthropic-beta");
  if (beta) upstreamHeaders["anthropic-beta"] = beta;

  const upstream = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: upstreamHeaders,
    body,
  });

  // Return Anthropic's status + body unchanged.
  const respBody = await upstream.text();
  return new Response(respBody, {
    status: upstream.status,
    headers: { "Content-Type": "application/json" },
  });
});

function json(payload: unknown, status: number): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
