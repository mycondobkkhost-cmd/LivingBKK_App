import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { ChatRoomKind, welcomeMessage } from "./chat_logic.ts";

export async function ensureChatThread(
  db: SupabaseClient,
  userId: string,
  body: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const roomKind = (body.room_kind as ChatRoomKind) ?? "property";
  const listingCode = (body.listing_code as string | undefined)?.trim() || undefined;
  let listingId = body.listing_id as string | undefined;
  const uuidRe =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (listingId && !uuidRe.test(listingId)) {
    if (listingCode) {
      const { data: row } = await db
        .from("listings")
        .select("id")
        .eq("listing_code", listingCode)
        .maybeSingle();
      listingId = (row?.id as string | undefined) ?? undefined;
    } else {
      listingId = undefined;
    }
  }
  const threadId = body.thread_id as string | undefined;
  const isDiscovery = roomKind === "property" && !listingId;

  if (threadId) {
    const { data, error } = await db
      .from("chat_threads")
      .select("*")
      .eq("id", threadId)
      .eq("user_id", userId)
      .single();
    if (error || !data) throw new Error("Thread not found");
    return data;
  }

  let existingQuery = db.from("chat_threads").select("*").eq("user_id", userId);

  if (roomKind === "property" && listingId) {
    existingQuery = existingQuery
      .eq("listing_id", listingId)
      .eq("room_kind", "property");
  } else if (roomKind === "property" && !listingId) {
    if (listingCode) {
      existingQuery = existingQuery
        .eq("listing_code", listingCode)
        .eq("room_kind", "property");
    } else {
      existingQuery = existingQuery
        .is("listing_id", null)
        .eq("room_kind", "property");
    }
  } else {
    existingQuery = existingQuery.eq("room_kind", roomKind);
  }

  const { data: existing } = await existingQuery.maybeSingle();
  if (existing) return existing;

  const listingTitle = (body.listing_title as string) ?? "";
  const allowViewing = Boolean(body.allow_viewing_request) && !isDiscovery;

  let category = isDiscovery ? "discovery" : "property_faq";
  if (roomKind === "staff_support") category = "staff_support";

  const { data: created, error: insertError } = await db
    .from("chat_threads")
    .insert({
      user_id: userId,
      room_kind: roomKind,
      listing_id: listingId ?? null,
      listing_code: (body.listing_code as string) ?? null,
      listing_title: listingTitle,
      project_name: (body.project_name as string) ?? null,
      category,
      allow_viewing_request: allowViewing,
      admin_escalated: roomKind === "staff_support",
      status: roomKind === "staff_support" ? "waiting_admin" : "open",
    })
    .select("*")
    .single();

  if (insertError || !created) {
    throw new Error(insertError?.message ?? "Failed to create thread");
  }

  const welcome = welcomeMessage(
    roomKind,
    listingTitle,
    allowViewing,
    isDiscovery,
  );
  await db.from("chat_messages").insert({
    thread_id: created.id,
    role: welcome.role,
    text: welcome.text,
    links: welcome.links ?? [],
  });

  return created;
}
