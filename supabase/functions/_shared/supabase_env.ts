import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

function pickEnv(...names: string[]): string | undefined {
  for (const name of names) {
    const value = Deno.env.get(name)?.trim();
    if (value) return value;
  }
  return undefined;
}

/** อ่านคีย์จาก JSON dict ใหม่ (SUPABASE_*_KEYS) หรือ plain string เก่า */
function keyFromEnv(jsonEnv: string, legacyNames: string[]): string | undefined {
  const raw = Deno.env.get(jsonEnv)?.trim();
  if (raw) {
    try {
      const dict = JSON.parse(raw) as Record<string, string>;
      if (dict.default?.trim()) return dict.default.trim();
      for (const v of Object.values(dict)) {
        if (v?.trim()) return v.trim();
      }
    } catch {
      return raw;
    }
  }
  return pickEnv(...legacyNames);
}

export function getSupabaseUrl(): string {
  const url = pickEnv("SUPABASE_URL");
  if (!url) throw new Error("edge_config_missing:SUPABASE_URL");
  return url;
}

/** คีย์ฝั่งแอป — publishable / anon */
export function getAnonOrPublishableKey(): string {
  const key = keyFromEnv("SUPABASE_PUBLISHABLE_KEYS", [
    "SUPABASE_ANON_KEY",
    "SUPABASE_PUBLISHABLE_KEY",
    "SUPABASE_PUBLISHABLE_DEFAULT_KEY",
  ]);
  if (!key) throw new Error("edge_config_missing:SUPABASE_ANON_KEY");
  return key;
}

/** คีย์ลับฝั่งเซิร์ฟเวอร์ — secret / service_role */
export function getServiceRoleKey(): string {
  const key = keyFromEnv("SUPABASE_SECRET_KEYS", [
    "SUPABASE_SERVICE_ROLE_KEY",
    "SUPABASE_SECRET_KEY",
  ]);
  if (!key) throw new Error("edge_config_missing:SUPABASE_SERVICE_ROLE_KEY");
  return key;
}

export function createServiceClient(): SupabaseClient {
  return createClient(getSupabaseUrl(), getServiceRoleKey());
}

export function createUserClient(authHeader: string): SupabaseClient {
  return createClient(getSupabaseUrl(), getAnonOrPublishableKey(), {
    global: { headers: { Authorization: authHeader } },
  });
}
