import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const cronSecret = Deno.env.get("CRON_SECRET");
    const auth = req.headers.get("Authorization") ?? "";
    if (!cronSecret || auth !== `Bearer ${cronSecret}`) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    const url = new URL(req.url);
    const days = Math.min(
      90,
      Math.max(1, parseInt(url.searchParams.get("days") ?? "30", 10)),
    );

    const service = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data, error } = await service.rpc("refresh_analytics_rollups", {
      p_from: new Date(Date.now() - days * 86400000).toISOString().slice(0, 10),
      p_to: new Date().toISOString().slice(0, 10),
    });

    if (error) {
      console.error(error);
      return jsonResponse({ error: error.message }, 500);
    }

    return jsonResponse({ ok: true, result: data });
  } catch (e) {
    console.error(e);
    return jsonResponse({ error: "server_error" }, 500);
  }
});
