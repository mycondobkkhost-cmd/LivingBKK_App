import { jsonResponse } from "./cors.ts";
import { createUserClient } from "./supabase_env.ts";

export type VaultActor = {
  userId: string;
  tier: string;
};

export async function requireVaultTier(
  req: Request,
): Promise<VaultActor | Response> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonResponse({ error: "Unauthorized" }, 401);

  let supabase;
  try {
    supabase = createUserClient(authHeader);
  } catch (e) {
    return jsonResponse({ error: "edge_config_error", detail: String(e) }, 500);
  }

  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("role, admin_tier")
    .eq("id", userData.user.id)
    .maybeSingle();

  if (profile?.role !== "admin") {
    return jsonResponse({ error: "Admin only" }, 403);
  }

  let tier = (profile.admin_tier as string) ?? "admin";
  if (tier === "standard") tier = "admin";

  if (tier !== "super" && tier !== "ceo") {
    return jsonResponse({
      error: "vault_tier_required",
      detail: "ต้องเป็น CEO หรือ SUPER",
    }, 403);
  }

  return { userId: userData.user.id, tier };
}
