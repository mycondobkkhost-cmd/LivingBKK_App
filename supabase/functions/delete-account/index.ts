import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { createServiceClient, createUserClient } from "../_shared/supabase_env.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonResponse({ error: "Unauthorized" }, 401);

  let userClient;
  try {
    userClient = createUserClient(authHeader);
  } catch (e) {
    return jsonResponse({ error: "edge_config_error", detail: String(e) }, 500);
  }

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const userId = userData.user.id;

  let body: { confirm?: boolean } = {};
  try {
    body = await req.json();
  } catch {
    body = {};
  }
  if (body.confirm !== true) {
    return jsonResponse({ error: "confirmation_required" }, 400);
  }

  let service;
  try {
    service = createServiceClient();
  } catch (e) {
    return jsonResponse({ error: "edge_config_error", detail: String(e) }, 500);
  }

  const { data: profile } = await service
    .from("profiles")
    .select("role")
    .eq("id", userId)
    .maybeSingle();

  if (profile?.role === "admin") {
    return jsonResponse({ error: "admin_delete_blocked" }, 403);
  }

  const { error: deleteError } = await service.auth.admin.deleteUser(userId);
  if (deleteError) {
    console.error("delete-account", deleteError);
    return jsonResponse(
      { error: "delete_failed", detail: deleteError.message },
      500,
    );
  }

  return jsonResponse({ ok: true });
});
