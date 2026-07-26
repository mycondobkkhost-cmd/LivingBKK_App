import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import type { AdminAiFeedInput } from "../_shared/admin_ai_feed.ts";
import { orchestrateAdminFeed } from "../_shared/admin_orchestrator.ts";

async function authServiceOrAdmin(req: Request): Promise<boolean> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return false;

  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (token && serviceKey && token === serviceKey) return true;

  const client = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data } = await client.auth.getUser();
  if (!data.user) return false;
  const { data: profile } = await client
    .from("profiles")
    .select("role")
    .eq("id", data.user.id)
    .maybeSingle();
  return profile?.role === "admin";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!(await authServiceOrAdmin(req))) {
    return jsonResponse({ error: "Forbidden" }, 403);
  }

  try {
    const body = await req.json();
    const source = String(body.source ?? "manual").slice(0, 80);
    const feed = body.feed as AdminAiFeedInput | undefined;

    if (!feed?.eventType || !feed.title || !feed.summary) {
      return jsonResponse({ error: "feed.eventType, title, summary required" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const id = await orchestrateAdminFeed(db, source, feed);
    return jsonResponse({ id, source });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
