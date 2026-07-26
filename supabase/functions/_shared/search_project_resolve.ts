import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export type ProjectResolution = {
  query_name: string | null;
  status: "unknown" | "matched" | "listings_only" | "none";
  matched_slug: string | null;
  suggest_project_request: boolean;
};

const PROJECT_HINT_RE =
  /\b(ideo|the\s|noble|rhythm|line\s|mobi|place|condo|คอนโด|โครงการ)\b/i;

function normalizeName(raw: string): string {
  return raw.trim().toLowerCase().replace(/\s+/g, " ");
}

export function namesMatch(query: string, ...candidates: (string | null | undefined)[]): boolean {
  const q = normalizeName(query);
  if (q.length < 3) return false;
  for (const c of candidates) {
    if (!c) continue;
    const h = normalizeName(c);
    if (h.includes(q) || q.includes(h)) return true;
    const qTokens = q.split(/\s+/).filter((t) => t.length > 2);
    if (qTokens.length >= 2 && qTokens.every((t) => h.includes(t))) return true;
  }
  return false;
}

/** ดึงชื่อโครงการจาก filters หรือ query ดิบ */
export function extractProjectName(
  query: string,
  filters: Record<string, unknown>,
): string | null {
  const fromFilter = filters.project_name;
  if (typeof fromFilter === "string" && fromFilter.trim().length >= 2) {
    return fromFilter.trim();
  }
  const q = query.trim();
  if (q.length < 4) return null;
  if (!PROJECT_HINT_RE.test(q) && q.split(/\s+/).length < 2) return null;
  return q;
}

export async function resolveProjectInCatalog(
  projectName: string | null,
): Promise<ProjectResolution> {
  if (!projectName || projectName.length < 3) {
    return {
      query_name: projectName,
      status: "none",
      matched_slug: null,
      suggest_project_request: false,
    };
  }

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: projects } = await db
    .from("property_projects")
    .select("id, slug, name_th, name_en, aliases")
    .eq("is_active", true)
    .limit(500);

  for (const p of projects ?? []) {
    const aliases = Array.isArray(p.aliases) ? p.aliases as string[] : [];
    if (namesMatch(projectName, p.name_th, p.name_en, p.slug, ...aliases)) {
      return {
        query_name: projectName,
        status: "matched",
        matched_slug: p.slug as string,
        suggest_project_request: false,
      };
    }
  }

  const { data: listings } = await db
    .from("listings_public")
    .select("project_name, title")
    .limit(2000);

  for (const l of listings ?? []) {
    if (namesMatch(projectName, l.project_name as string, l.title as string)) {
      return {
        query_name: projectName,
        status: "listings_only",
        matched_slug: null,
        suggest_project_request: false,
      };
    }
  }

  return {
    query_name: projectName,
    status: "unknown",
    matched_slug: null,
    suggest_project_request: true,
  };
}
