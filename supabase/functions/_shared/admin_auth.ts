import { jsonResponse } from "./cors.ts";
import { createUserClient } from "./supabase_env.ts";

export async function requireAdmin(
  req: Request,
): Promise<{ userId: string } | Response> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonResponse({ error: "Unauthorized" }, 401);

  let supabase;
  try {
    supabase = createUserClient(authHeader);
  } catch (e) {
    const code = String(e).includes("edge_config_missing")
      ? "edge_config_missing"
      : "edge_config_error";
    return jsonResponse({ error: code, detail: String(e) }, 500);
  }

  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", userData.user.id)
    .maybeSingle();

  if (profile?.role !== "admin") {
    return jsonResponse({ error: "Admin only" }, 403);
  }

  return { userId: userData.user.id };
}
