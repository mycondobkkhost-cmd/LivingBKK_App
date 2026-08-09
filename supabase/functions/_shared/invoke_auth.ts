import { jsonResponse } from "./cors.ts";
import { createUserClient } from "./supabase_env.ts";

/**
 * Gate for edge functions that use the service role internally.
 * Accepts: valid user JWT, service-role key, or CRON_SECRET.
 */
export async function requireInvokerAuth(
  req: Request,
): Promise<true | Response> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }
  const token = authHeader.slice("Bearer ".length).trim();
  if (!token) return jsonResponse({ error: "Unauthorized" }, 401);

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const cronSecret = Deno.env.get("CRON_SECRET") ?? "";
  if (serviceKey && token === serviceKey) return true;
  if (cronSecret && token === cronSecret) return true;

  try {
    const userClient = createUserClient(authHeader);
    const { data, error } = await userClient.auth.getUser();
    if (error || !data.user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }
    return true;
  } catch {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }
}
