import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const AUTH_REQUIRED = new Set([
  "listing_impression",
  "listing_view",
  "listing_share",
  "map_marker_tap",
  "search_performed",
  "chat_start",
]);

const PUBLIC = new Set([
  "app_install",
  "app_open",
  "app_uninstall",
  "client_error",
]);

type TrackEvent = {
  event_type: string;
  listing_id?: string;
  district?: string;
  geo_zone_slug?: string;
  listing_type?: string;
  property_type?: string;
  source?: string;
  session_hash?: string;
  metadata?: Record<string, unknown>;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      authHeader ? { global: { headers: { Authorization: authHeader } } } : {},
    );

    let userId: string | null = null;
    if (authHeader) {
      const { data: userData } = await supabase.auth.getUser();
      userId = userData.user?.id ?? null;
    }

    const body = await req.json() as { events?: TrackEvent[] };
    const events = Array.isArray(body.events) ? body.events.slice(0, 50) : [];
    if (events.length === 0) {
      return jsonResponse({ ok: true, inserted: 0 });
    }

    const service = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const rows = [];
    const errorRows = [];

    for (const ev of events) {
      const type = ev.event_type;
      if (!AUTH_REQUIRED.has(type) && !PUBLIC.has(type)) continue;

      if (AUTH_REQUIRED.has(type) && !userId) continue;
      if (PUBLIC.has(type) && !ev.session_hash && type !== "client_error") continue;

      let ownerId: string | null = null;
      if (ev.listing_id) {
        const { data: listing } = await service
          .from("listings")
          .select("owner_id")
          .eq("id", ev.listing_id)
          .maybeSingle();
        ownerId = (listing?.owner_id as string | undefined) ?? null;
      }

      const meta = ev.metadata ?? {};
      const platform = (meta.platform as string | undefined)?.slice(0, 32) ?? "unknown";

      rows.push({
        event_type: type,
        listing_id: ev.listing_id ?? null,
        owner_id: ownerId,
        actor_id: userId,
        district: ev.district?.slice(0, 80) ?? null,
        geo_zone_slug: ev.geo_zone_slug?.slice(0, 64) ?? null,
        listing_type: ev.listing_type?.slice(0, 32) ?? null,
        property_type: ev.property_type?.slice(0, 32) ?? null,
        source: ev.source?.slice(0, 32) ?? null,
        session_hash: ev.session_hash?.slice(0, 64) ?? null,
        metadata: meta,
      });

      if (type === "client_error") {
        const errorKey = (meta.error_key as string | undefined)?.slice(0, 64) ?? "unknown";
        const rawMessage = (meta.message as string | undefined)?.slice(0, 500) ?? null;
        errorRows.push({
          error_key: errorKey,
          raw_message: rawMessage,
          platform,
          route: (meta.route as string | undefined)?.slice(0, 120) ?? null,
          session_hash: ev.session_hash?.slice(0, 64) ?? null,
          actor_id: userId,
          metadata: meta,
        });
      }
    }

    if (rows.length === 0) {
      return jsonResponse({ ok: true, inserted: 0 });
    }

    const { error: insertErr } = await service.from("analytics_events").insert(rows);
    if (insertErr) {
      console.error(insertErr);
      return jsonResponse({ error: "insert_failed" }, 500);
    }

    if (errorRows.length > 0) {
      const { error: errLog } = await service.from("client_error_reports").insert(errorRows);
      if (errLog) console.error("client_error_reports", errLog);
    }

    return jsonResponse({ ok: true, inserted: rows.length });
  } catch (e) {
    console.error(e);
    return jsonResponse({ error: "server_error" }, 500);
  }
});
