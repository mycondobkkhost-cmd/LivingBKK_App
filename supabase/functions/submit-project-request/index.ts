import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { feedFromProjectRequest } from "../_shared/admin_ai_feed.ts";
import { orchestrateAdminFeed } from "../_shared/admin_orchestrator.ts";

const SOURCES = ["search_bar", "discovery_chat", "discovery_page"] as const;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const body = await req.json();
    const projectName = String(body.project_name ?? "").trim();
    const sourceQuery = body.source_query != null
      ? String(body.source_query).trim()
      : null;
    const source = String(body.source ?? "search_bar");

    if (!projectName || projectName.length < 2) {
      return jsonResponse({ error: "project_name required" }, 400);
    }
    if (!SOURCES.includes(source as typeof SOURCES[number])) {
      return jsonResponse({ error: "Invalid source" }, 400);
    }

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const { data: dup } = await db
      .from("project_requests")
      .select("id, status")
      .eq("user_id", userData.user.id)
      .ilike("project_name", projectName)
      .gte("created_at", since)
      .in("status", ["pending", "reviewing"])
      .limit(1)
      .maybeSingle();

    if (dup) {
      return jsonResponse({
        success: true,
        duplicate: true,
        request: dup,
        project_name: projectName,
      });
    }

    const { data: row, error: insertError } = await db
      .from("project_requests")
      .insert({
        user_id: userData.user.id,
        project_name: projectName,
        source,
        source_query: sourceQuery,
        status: "pending",
      })
      .select("id, project_name, status, created_at")
      .single();

    if (insertError || !row) {
      return jsonResponse({ error: insertError?.message ?? "Insert failed" }, 400);
    }

    await orchestrateAdminFeed(
      db,
      "submit-project-request",
      feedFromProjectRequest({
        requestId: row.id as string,
        projectName,
        source,
        sourceQuery,
      }),
    );

    return jsonResponse({
      success: true,
      duplicate: false,
      request: row,
      project_name: projectName,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
