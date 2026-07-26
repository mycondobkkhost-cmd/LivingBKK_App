import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { orchestrateAdminFeed } from "../_shared/admin_orchestrator.ts";

async function authAdmin(req: Request): Promise<boolean> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return false;
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

  if (!(await authAdmin(req))) {
    return jsonResponse({ error: "Forbidden" }, 403);
  }

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    const url = new URL(req.url);
    const body = req.method === "POST"
      ? await req.json().catch(() => ({}))
      : {};
    const action = (body as Record<string, unknown>).action as string | undefined;

    if (action === "list" || req.method === "GET") {
      const status = (body as Record<string, string>).status ??
        url.searchParams.get("status") ?? "open";
      const limit = Math.min(
        parseInt(
          (body as Record<string, string>).limit ??
            url.searchParams.get("limit") ?? "30",
          10,
        ),
        100,
      );

      let q = db
        .from("admin_ai_feed")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(limit);

      if (status !== "all") {
        q = q.eq("status", status);
      }

      const { data, error } = await q;
      if (error) return jsonResponse({ error: error.message }, 400);
      return jsonResponse({ items: data ?? [] });
    }

    if (action === "count_open") {
      const { count, error } = await db
        .from("admin_ai_feed")
        .select("id", { count: "exact", head: true })
        .eq("status", "open");
      if (error) return jsonResponse({ error: error.message }, 400);
      return jsonResponse({ count: count ?? 0 });
    }

    if (action === "update_status") {
      const id = (body as Record<string, string>).id;
      const status = (body as Record<string, string>).status;
      if (!id || !status) {
        return jsonResponse({ error: "id and status required" }, 400);
      }
      const { data, error } = await db
        .from("admin_ai_feed")
        .update({ status })
        .eq("id", id)
        .select("*")
        .single();
      if (error) return jsonResponse({ error: error.message }, 400);
      return jsonResponse({ item: data });
    }

    if (action === "emit_test") {
      const id = await orchestrateAdminFeed(db, "admin-ai-feed-test", {
        eventType: "test",
        priority: "normal",
        title: "ทดสอบ AI Feed",
        summary: "การ์ดทดสอบจาก admin-ai-feed",
        suggestedAction: "กดลิงก์เพื่อเปิดคอนโซล",
        deepLink: "/admin/console",
      });
      return jsonResponse({ id });
    }

    return jsonResponse({ error: "Unknown action" }, 400);
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
