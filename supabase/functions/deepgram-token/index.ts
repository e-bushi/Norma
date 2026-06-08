// Deepgram temporary-token edge function.
//
// A wss audio stream can't be sensibly proxied, so instead of shipping the
// long-lived Deepgram key in the app, the client asks this function for a
// short-lived (60s) grant token right before it opens the stream. The token
// only needs to be valid for the initial handshake; the stream then stays open.
//
//   1. Requires an authenticated Supabase user.
//   2. Calls Deepgram's grant endpoint with the secret DEEPGRAM_API_KEY.
//   3. Returns Deepgram's { access_token, expires_in } verbatim.
//
// Deploy with:
//   supabase functions deploy deepgram-token
//   supabase secrets set DEEPGRAM_API_KEY=<rotated key, Member+ permission>
// SUPABASE_URL and SUPABASE_ANON_KEY are injected automatically.

import { createClient } from "jsr:@supabase/supabase-js@2";

const DEEPGRAM_GRANT_URL = "https://api.deepgram.com/v1/auth/grant";
const TTL_SECONDS = 60;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const dgKey = Deno.env.get("DEEPGRAM_API_KEY");
  if (!dgKey) {
    return json({ error: "Server misconfigured: DEEPGRAM_API_KEY not set" }, 500);
  }

  // Require a real authenticated user (the anon key alone is not enough).
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

  // Mint a short-lived token scoped to streaming usage.
  const grant = await fetch(DEEPGRAM_GRANT_URL, {
    method: "POST",
    headers: { "Authorization": `Token ${dgKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({ ttl_seconds: TTL_SECONDS }),
  });

  if (!grant.ok) {
    const detail = await grant.text();
    console.error("[deepgram-token] grant failed:", grant.status, detail);
    return json({ error: "Failed to mint Deepgram token" }, 502);
  }

  // Pass Deepgram's { access_token, expires_in } back to the client unchanged.
  const body = await grant.text();
  return new Response(body, {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});

function json(payload: unknown, status: number): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
