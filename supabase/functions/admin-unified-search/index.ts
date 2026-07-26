import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  adminConsoleDeepLink,
  adminLeadsDeepLink,
  adminProjectsDeepLink,
  adminViewingCalendarDeepLink,
  adminModerationDeepLink,
  listingAdminDeepLink,
} from "../_shared/admin_ai_feed.ts";
import {
  extractListingCodeFromQuery,
  resolveListingFromQuery,
} from "../_shared/search_listing_resolve.ts";

const CHAT_REF_RE = /^CHAT-\d{4}-\d{6}$/i;
const LEAD_REF_RE = /^LEAD-\d{4}-\d{6}$/i;
const APPT_REF_RE = /^APPT-\d{4}-\d{6}$/i;
const OIQ_REF_RE = /^OIQ-\d{4}-\d{6}$/i;

function pushUnique(
  results: Array<Record<string, unknown>>,
  row: Record<string, unknown>,
  limit: number,
  key: string,
): boolean {
  if (results.some((r) => r[key] === row[key])) return false;
  results.push(row);
  return results.length >= limit;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Forbidden" }, 403);
  }
  const authClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: userData } = await authClient.auth.getUser();
  if (!userData.user) return jsonResponse({ error: "Forbidden" }, 403);
  const { data: profile } = await authClient
    .from("profiles")
    .select("role")
    .eq("id", userData.user.id)
    .maybeSingle();
  if (profile?.role !== "admin") {
    return jsonResponse({ error: "Forbidden" }, 403);
  }

  try {
    const { query, limit: rawLimit } = await req.json();
    if (!query || typeof query !== "string") {
      return jsonResponse({ error: "query required" }, 400);
    }

    const q = query.trim();
    const limit = Math.min(rawLimit ?? 20, 40);
    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const results: Array<Record<string, unknown>> = [];
    const code = extractListingCodeFromQuery(q);
    const refUpper = q.toUpperCase();

    const listingRes = await resolveListingFromQuery(db, q);
    if (listingRes.status === "found") {
      results.push({
        kind: "listing",
        title: listingRes.title,
        subtitle: listingRes.listing_code,
        listing_id: listingRes.listing_id,
        listing_code: listingRes.listing_code,
        deep_link: `/listing/${listingRes.listing_id}`,
      });
    }

    if (CHAT_REF_RE.test(refUpper)) {
      const { data: thread } = await db
        .from("chat_threads")
        .select("id, listing_code, transaction_ref, category, status")
        .eq("transaction_ref", refUpper)
        .maybeSingle();
      if (thread) {
        results.unshift({
          kind: "chat",
          title: `แชท ${refUpper}`,
          subtitle: thread.listing_code ?? thread.category,
          thread_id: thread.id,
          deep_link: adminConsoleDeepLink(thread.id as string),
        });
      }
    }

    if (LEAD_REF_RE.test(refUpper)) {
      const { data: lead } = await db
        .from("leads")
        .select("id, listing_code, seeker_nickname, status, thread_id")
        .eq("transaction_ref", refUpper)
        .maybeSingle();
      if (lead) {
        results.unshift({
          kind: "lead",
          title: `Lead ${refUpper}`,
          subtitle: `${lead.listing_code} · ${lead.seeker_nickname ?? ""}`,
          lead_id: lead.id,
          thread_id: lead.thread_id,
          deep_link: lead.thread_id
            ? adminConsoleDeepLink(lead.thread_id as string)
            : adminLeadsDeepLink(),
        });
      }
    }

    if (APPT_REF_RE.test(refUpper)) {
      const { data: appt } = await db
        .from("appointments")
        .select("id, listing_code, scheduled_date, time_slot, status, lead_id")
        .eq("transaction_ref", refUpper)
        .maybeSingle();
      if (appt) {
        results.unshift({
          kind: "appointment",
          title: `นัดชม ${refUpper}`,
          subtitle: `${appt.listing_code} · ${appt.scheduled_date} ${appt.time_slot}`,
          appointment_id: appt.id,
          deep_link: adminViewingCalendarDeepLink(),
        });
      }
    }

    if (OIQ_REF_RE.test(refUpper)) {
      const { data: oiq } = await db
        .from("owner_inquiries")
        .select("id, code, listing_code, seeker_question, status, thread_id")
        .eq("code", refUpper)
        .maybeSingle();
      if (oiq) {
        results.unshift({
          kind: "owner_inquiry",
          title: `คำถามเจ้าของ ${refUpper}`,
          subtitle: `${oiq.listing_code} · ${oiq.status}`,
          owner_inquiry_id: oiq.id,
          thread_id: oiq.thread_id,
          deep_link: adminConsoleDeepLink(oiq.thread_id as string),
        });
      }
    }

    if (results.length < limit) {
      const { data: threads } = await db
        .from("chat_threads")
        .select("id, listing_code, listing_title, transaction_ref, category, status")
        .or(
          `listing_code.ilike.%${q}%,listing_title.ilike.%${q}%,transaction_ref.ilike.%${q}%`,
        )
        .order("last_message_at", { ascending: false })
        .limit(limit);

      for (const t of threads ?? []) {
        if (pushUnique(results, {
          kind: "chat",
          title: t.listing_title ?? t.listing_code ?? "แชท",
          subtitle: `${t.transaction_ref ?? ""} · ${t.status}`,
          thread_id: t.id,
          listing_code: t.listing_code,
          deep_link: adminConsoleDeepLink(t.id as string),
        }, limit, "thread_id")) break;
      }
    }

    if (results.length < limit && (code || q.length >= 3)) {
      const { data: listings } = await db
        .from("listings_public")
        .select("id, listing_code, title, project_name, district")
        .or(
          `listing_code.ilike.%${code ?? q}%,title.ilike.%${q}%,project_name.ilike.%${q}%`,
        )
        .limit(limit);

      for (const l of listings ?? []) {
        if (pushUnique(results, {
          kind: "listing",
          title: l.title,
          subtitle: `${l.listing_code} · ${l.project_name ?? l.district ?? ""}`,
          listing_id: l.id,
          listing_code: l.listing_code,
          deep_link: `/listing/${l.id}`,
        }, limit, "listing_id")) break;
      }
    }

    if (results.length < limit && q.length >= 2) {
      const { data: leads } = await db
        .from("leads")
        .select("id, listing_code, seeker_nickname, status, thread_id, transaction_ref")
        .or(`listing_code.ilike.%${q}%,seeker_nickname.ilike.%${q}%`)
        .order("created_at", { ascending: false })
        .limit(limit);

      for (const lead of leads ?? []) {
        if (pushUnique(results, {
          kind: "lead",
          title: lead.seeker_nickname ?? "Lead",
          subtitle: `${lead.listing_code} · ${lead.transaction_ref ?? lead.status}`,
          lead_id: lead.id,
          thread_id: lead.thread_id,
          deep_link: lead.thread_id
            ? adminConsoleDeepLink(lead.thread_id as string)
            : adminLeadsDeepLink(),
        }, limit, "lead_id")) break;
      }
    }

    if (results.length < limit && q.length >= 2) {
      const { data: inquiries } = await db
        .from("owner_inquiries")
        .select("id, code, listing_code, seeker_question, status, thread_id")
        .or(`code.ilike.%${q}%,listing_code.ilike.%${q}%,seeker_question.ilike.%${q}%`)
        .order("created_at", { ascending: false })
        .limit(limit);

      for (const oiq of inquiries ?? []) {
        if (pushUnique(results, {
          kind: "owner_inquiry",
          title: oiq.code,
          subtitle: `${oiq.listing_code} · ${oiq.seeker_question?.slice(0, 60) ?? ""}`,
          owner_inquiry_id: oiq.id,
          thread_id: oiq.thread_id,
          deep_link: adminConsoleDeepLink(oiq.thread_id as string),
        }, limit, "owner_inquiry_id")) break;
      }
    }

    if (results.length < limit && q.length >= 2) {
      const { data: projects } = await db
        .from("project_requests")
        .select("id, project_name, status, source")
        .ilike("project_name", `%${q}%`)
        .order("created_at", { ascending: false })
        .limit(limit);

      for (const pr of projects ?? []) {
        if (pushUnique(results, {
          kind: "project_request",
          title: pr.project_name,
          subtitle: `${pr.status} · ${pr.source}`,
          project_request_id: pr.id,
          deep_link: adminProjectsDeepLink(),
        }, limit, "project_request_id")) break;
      }
    }

    if (results.length < limit && q.length >= 2) {
      const { data: appts } = await db
        .from("appointments")
        .select("id, listing_code, scheduled_date, time_slot, status, transaction_ref")
        .or(`listing_code.ilike.%${q}%,transaction_ref.ilike.%${q}%`)
        .order("scheduled_date", { ascending: false })
        .limit(limit);

      for (const appt of appts ?? []) {
        if (pushUnique(results, {
          kind: "appointment",
          title: appt.listing_code ?? "นัดชม",
          subtitle: `${appt.transaction_ref ?? ""} · ${appt.scheduled_date} ${appt.time_slot}`,
          appointment_id: appt.id,
          deep_link: adminViewingCalendarDeepLink(),
        }, limit, "appointment_id")) break;
      }
    }

    if (results.length < limit && q.length >= 2) {
      const { data: modFlags } = await db
        .from("moderation_flags")
        .select("id, flag_type, raw_match, listing_id, created_at, listings(listing_code, title)")
        .is("resolved_at", null)
        .or(`flag_type.ilike.%${q}%,raw_match.ilike.%${q}%`)
        .order("created_at", { ascending: false })
        .limit(limit);

      for (const flag of modFlags ?? []) {
        const listing = flag.listings as Record<string, unknown> | null;
        const code = listing?.listing_code as string | undefined;
        if (pushUnique(results, {
          kind: "moderation",
          title: code ?? "ตรวจสอบประกาศ",
          subtitle: `${flag.flag_type}${flag.raw_match ? ` · ${String(flag.raw_match).slice(0, 40)}` : ""}`,
          moderation_flag_id: flag.id,
          listing_id: flag.listing_id,
          listing_code: code,
          deep_link: adminModerationDeepLink(),
        }, limit, "moderation_flag_id")) break;
      }
    }

    if (results.length < limit && q.length >= 2) {
      const { data: feedRows } = await db
        .from("admin_ai_feed")
        .select("id, title, summary, event_type, status, deep_link, thread_id")
        .or(`title.ilike.%${q}%,summary.ilike.%${q}%,listing_code.ilike.%${q}%`)
        .order("created_at", { ascending: false })
        .limit(limit);

      for (const row of feedRows ?? []) {
        if (pushUnique(results, {
          kind: "feed",
          title: row.title,
          subtitle: `${row.event_type} · ${row.status}`,
          feed_id: row.id,
          thread_id: row.thread_id,
          deep_link: row.deep_link ?? (row.thread_id
            ? adminConsoleDeepLink(row.thread_id as string)
            : listingAdminDeepLink(q)),
        }, limit, "feed_id")) break;
      }
    }

    return jsonResponse({ query: q, results: results.slice(0, limit) });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
