import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  AI_MERGE_FIELDS,
  FieldLocks,
  mergeAiIntoCanonical,
  parseTimeSlotOnDate,
} from "../_shared/calendar_merge.ts";

type DraftPatch = Record<string, unknown>;

function buildDescriptionFromLead(lead: Record<string, unknown>): string {
  const lines: string[] = [];
  const add = (label: string, key: string) => {
    const v = lead[key];
    if (v != null && String(v).trim()) lines.push(`• ${label}: ${v}`);
  };
  add("ชื่อเล่น", "seeker_nickname");
  add("งบ", "budget_max");
  add("โซน", "preferred_zones");
  add("ย้ายเข้า", "move_in_date");
  add("สัญญา", "lease_months");
  if (lead["notes"]) lines.push(String(lead["notes"]));
  return lines.join("\n");
}

function extractViewingIntent(messages: Array<{ text?: string }>): DraftPatch {
  const joined = messages.map((m) => m.text ?? "").join("\n").toLowerCase();
  const patch: DraftPatch = {};
  if (/นัดดู|นัดชม|viewing|appointment/.test(joined)) {
    patch.event_type = "viewing";
  }
  const budget = joined.match(/(\d{4,6})\s*[-–]\s*(\d{4,6})/);
  if (budget) {
    patch.description = `• งบ: ${budget[1]}-${budget[2]} / เดือน`;
  }
  return patch;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const thread_id = body.thread_id as string | undefined;
    const lead_id = body.lead_id as string | undefined;
    const appointment_id = body.appointment_id as string | undefined;

    if (!thread_id && !lead_id && !appointment_id) {
      return jsonResponse(
        { error: "thread_id, lead_id, or appointment_id required" },
        400,
      );
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    let thread: Record<string, unknown> | null = null;
    let lead: Record<string, unknown> | null = null;
    let appointment: Record<string, unknown> | null = null;

    if (thread_id) {
      const { data } = await db.from("chat_threads").select("*").eq(
        "id",
        thread_id,
      ).maybeSingle();
      thread = data;
    }

    const resolvedLeadId = lead_id ?? (thread?.lead_id as string | undefined);
    if (resolvedLeadId) {
      const { data } = await db.from("leads").select("*").eq(
        "id",
        resolvedLeadId,
      ).maybeSingle();
      lead = data;
    }

    if (appointment_id) {
      const { data } = await db.from("appointments").select("*").eq(
        "id",
        appointment_id,
      ).maybeSingle();
      appointment = data;
    }

    let listing: Record<string, unknown> | null = null;
    const listingId = (lead?.listing_id ?? appointment?.listing_id ?? thread
      ?.listing_id) as string | undefined;
    if (listingId) {
      const { data } = await db.from("listings").select(
        "id, listing_code, title, owner_id, lat, lng, project_name",
      ).eq("id", listingId).maybeSingle();
      listing = data;
    }

    const messages: Array<{ text?: string }> = [];
    if (thread_id) {
      const { data: msgs } = await db.from("chat_messages").select("text").eq(
        "thread_id",
        thread_id,
      ).order("created_at", { ascending: true }).limit(40);
      if (msgs) messages.push(...msgs);
    }

    const seekerName = (lead?.seeker_nickname ?? appointment?.seeker_nickname ??
      "ลูกค้า") as string;
    const listingCode = (listing?.listing_code ?? appointment?.listing_code ??
      "") as string;
    const project = (listing?.project_name ?? listing?.title ?? listingCode) as
      | string;

    const aiDraft: DraftPatch = {
      event_type: "viewing",
      title: `${seekerName}นัดดูห้อง`,
      color_hint: "red",
      listing_id: listingId ?? null,
      listing_code: listingCode || null,
      lead_id: resolvedLeadId ?? null,
      location_label: project || null,
      lat: listing?.lat ?? appointment?.lat ?? null,
      lng: listing?.lng ?? appointment?.lng ?? null,
      owner_user_id: listing?.owner_id ?? null,
      seeker_user_id: thread?.user_id ?? null,
      ...extractViewingIntent(messages),
    };

    if (lead) {
      const desc = buildDescriptionFromLead(lead);
      if (desc) aiDraft.description = desc;
    }

    if (appointment) {
      const date = String(appointment.scheduled_date);
      const slot = String(appointment.time_slot ?? "10:00-11:00");
      const times = parseTimeSlotOnDate(date, slot);
      aiDraft.start_at = times.start_at;
      aiDraft.end_at = times.end_at;
      aiDraft.appointment_id = appointment.id;
    } else {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(12, 0, 0, 0);
      const end = new Date(tomorrow);
      end.setHours(13, 0, 0, 0);
      aiDraft.start_at = tomorrow.toISOString();
      aiDraft.end_at = end.toISOString();
    }

    const dedupeThreadId = thread_id ?? null;
    let existing: Record<string, unknown> | null = null;

    if (dedupeThreadId) {
      const { data } = await db.from("calendar_events").select("*").eq(
        "thread_id",
        dedupeThreadId,
      ).eq("status", "ai_draft").maybeSingle();
      existing = data;
    } else if (appointment_id) {
      const { data } = await db.from("calendar_events").select("*").eq(
        "appointment_id",
        appointment_id,
      ).neq("status", "cancelled").order("updated_at", { ascending: false })
        .limit(1).maybeSingle();
      existing = data;
    }

    const now = new Date().toISOString();
    const fieldLocks = (existing?.field_locks ?? {}) as FieldLocks;

    if (existing) {
      const merged = mergeAiIntoCanonical(existing, aiDraft, fieldLocks);
      const updatePayload: Record<string, unknown> = {
        ai_draft: aiDraft,
        ai_last_run_at: now,
        updated_at: now,
      };
      for (const field of AI_MERGE_FIELDS) {
        if (field in merged) updatePayload[field] = merged[field];
      }

      const { data: updated, error } = await db.from("calendar_events").update(
        updatePayload,
      ).eq("id", existing.id).eq("version", existing.version).select("*")
        .single();

      if (error?.code === "PGRST116") {
        return jsonResponse({
          error: "version_conflict",
          message: "มีคนแก้ไขไปแล้ว — โหลดใหม่แล้วลองอีกครั้ง",
        }, 409);
      }
      if (error) return jsonResponse({ error: error.message }, 400);

      await db.from("calendar_event_audits").insert({
        event_id: updated.id,
        action: "ai_draft_refresh",
        actor_kind: "ai",
        actor_id: auth.userId,
        payload: { ai_draft: aiDraft, merged_fields: AI_MERGE_FIELDS },
      });

      return jsonResponse({ event: updated, created: false });
    }

    const insertRow: Record<string, unknown> = {
      status: "ai_draft",
      thread_id: dedupeThreadId,
      created_by: auth.userId,
      ai_draft: aiDraft,
      ai_last_run_at: now,
      field_locks: {},
      version: 1,
    };
    for (const field of AI_MERGE_FIELDS) {
      if (aiDraft[field] !== undefined) insertRow[field] = aiDraft[field];
    }
    if (appointment_id) insertRow.appointment_id = appointment_id;
    if (!insertRow.title) insertRow.title = "นัดดูห้อง";
    if (!insertRow.start_at || !insertRow.end_at) {
      return jsonResponse({ error: "start_at/end_at required" }, 400);
    }

    const { data: created, error: insErr } = await db.from("calendar_events")
      .insert(insertRow).select("*").single();
    if (insErr) return jsonResponse({ error: insErr.message }, 400);

    await db.from("calendar_event_audits").insert({
      event_id: created.id,
      action: "ai_draft_created",
      actor_kind: "ai",
      actor_id: auth.userId,
      payload: { ai_draft: aiDraft },
    });

    return jsonResponse({ event: created, created: true });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
