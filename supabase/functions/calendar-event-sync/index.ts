import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { postMakeComWebhook } from "../_shared/notify.ts";

/**
 * Sync calendar event to external calendar (Make.com → Google Calendar).
 * Idempotent: reuses external_event_id when present.
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const calendar_event_id = body.calendar_event_id as string | undefined;
    if (!calendar_event_id) {
      return jsonResponse({ error: "calendar_event_id required" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: ev, error } = await supabase
      .from("calendar_events")
      .select("*")
      .eq("id", calendar_event_id)
      .single();

    if (error || !ev) {
      return jsonResponse({ error: "Calendar event not found" }, 404);
    }

    const externalId = (ev.external_event_id as string | null) ??
      `proppiter-${ev.id}`;

    await postMakeComWebhook({
      event: "calendar_event_sync",
      calendar_event_id: ev.id as string,
      appointment_id: ev.appointment_id as string | undefined,
      lead_id: ev.lead_id as string | undefined,
      listing_code: (ev.listing_code as string) ?? undefined,
      status: ev.status as string,
      scheduled_date: String(ev.start_at).split("T")[0],
      time_slot: formatSlot(ev.start_at as string, ev.end_at as string),
      title: (ev.title as string) ?? undefined,
      description: (ev.description as string) ?? undefined,
      external_event_id: externalId,
      start_at: ev.start_at as string,
      end_at: ev.end_at as string,
    });

    const { error: updErr } = await supabase
      .from("calendar_events")
      .update({
        external_event_id: externalId,
        external_calendar_provider: "make",
        external_synced_at: new Date().toISOString(),
      })
      .eq("id", calendar_event_id);

    if (updErr) return jsonResponse({ error: updErr.message }, 400);

    await supabase.from("calendar_event_audits").insert({
      event_id: calendar_event_id,
      action: "external_sync",
      actor_kind: "system",
      payload: { external_event_id: externalId, provider: "make" },
    });

    return jsonResponse({
      success: true,
      calendar_event_id,
      external_event_id: externalId,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});

function formatSlot(start: string, end: string): string {
  const s = start.includes("T") ? start.split("T")[1].slice(0, 5) : start;
  const e = end.includes("T") ? end.split("T")[1].slice(0, 5) : end;
  return `${s}-${e}`;
}
