import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

function serviceDb() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

function decodeBase64Image(dataUrlOrBase64: string): Uint8Array | null {
  const raw = dataUrlOrBase64.includes(",")
    ? dataUrlOrBase64.split(",")[1]
    : dataUrlOrBase64;
  try {
    const bin = atob(raw);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return bytes;
  } catch {
    return null;
  }
}

async function uploadListingPhotos(
  db: ReturnType<typeof serviceDb>,
  adminId: string,
  listingId: string,
  images: string[],
): Promise<number> {
  const { data: existing } = await db
    .from("listing_images")
    .select("sort_order")
    .eq("listing_id", listingId)
    .order("sort_order", { ascending: false })
    .limit(1);
  let sort = existing?.[0]?.sort_order != null
    ? Number(existing[0].sort_order) + 1
    : 0;

  let uploaded = 0;
  for (let i = 0; i < Math.min(images.length, 12); i++) {
    const bytes = decodeBase64Image(images[i]);
    if (!bytes || bytes.length < 512) continue;

    const path =
      `${adminId}/${listingId}/capture_${Date.now()}_${i}.jpeg`;
    const { error: upErr } = await db.storage
      .from("listing-images")
      .upload(path, bytes, {
        contentType: "image/jpeg",
        upsert: false,
      });
    if (upErr) continue;

    const { data: pub } = db.storage.from("listing-images").getPublicUrl(path);
    await db.from("listing_images").insert({
      listing_id: listingId,
      storage_path: path,
      public_url: pub.publicUrl,
      sort_order: sort + uploaded,
      moderation_status: "approved",
    });
    uploaded++;
  }
  return uploaded;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const importId = body.import_id as string | undefined;
    const listingId = body.listing_id as string | undefined;
    const evidenceImages = body.evidence_images as string[] | undefined;
    const listingImages = body.listing_images as string[] | undefined;

    if (!importId) {
      return jsonResponse({ error: "import_id required" }, 400);
    }
    if (
      (!evidenceImages || evidenceImages.length === 0) &&
      (!listingImages || listingImages.length === 0 || !listingId)
    ) {
      return jsonResponse({
        error: "evidence_images[] and/or listing_id + listing_images[] required",
      }, 400);
    }

    const db = serviceDb();
    const { data: row, error } = await db
      .from("listing_imports")
      .select("raw_payload, listing_id")
      .eq("id", importId)
      .single();
    if (error || !row) {
      return jsonResponse({ error: "Import not found" }, 404);
    }

    const effectiveListingId = listingId ?? row.listing_id as string | null;
    const raw = (row.raw_payload as Record<string, unknown> | null) ?? {};
    const capture = (raw.capture as Record<string, unknown> | null) ?? {};
    const existingEvidence = (capture.evidence_images as unknown[]) ?? [];
    const uploadedEvidence: Record<string, string>[] = [];

    if (evidenceImages?.length) {
      for (let i = 0; i < Math.min(evidenceImages.length, 8); i++) {
        const bytes = decodeBase64Image(evidenceImages[i]);
        if (!bytes || bytes.length < 512) continue;

        const path =
          `${auth.userId}/${importId}/evidence_${Date.now()}_${i}.jpeg`;
        const { error: upErr } = await db.storage
          .from("import-captures")
          .upload(path, bytes, {
            contentType: "image/jpeg",
            upsert: false,
          });
        if (upErr) continue;

        const { data: signed } = await db.storage
          .from("import-captures")
          .createSignedUrl(path, 60 * 60 * 24 * 7);

        uploadedEvidence.push({
          storage_path: path,
          public_url: signed?.signedUrl ?? path,
          uploaded_at: new Date().toISOString(),
        });
      }
    }

    let listingUploaded = 0;
    if (effectiveListingId && listingImages?.length) {
      listingUploaded = await uploadListingPhotos(
        db,
        auth.userId,
        effectiveListingId,
        listingImages,
      );
    }

    const nextEvidence = [...existingEvidence, ...uploadedEvidence];
    const nextRaw = {
      ...raw,
      capture: {
        ...capture,
        evidence_images: nextEvidence,
      },
    };

    const updates: Record<string, unknown> = { raw_payload: nextRaw };
    if (listingUploaded > 0) {
      const { count } = await db
        .from("listing_images")
        .select("id", { count: "exact", head: true })
        .eq("listing_id", effectiveListingId);
      updates.image_count = count ?? listingUploaded;
    }

    await db.from("listing_imports").update(updates).eq("id", importId);

    return jsonResponse({
      import_id: importId,
      evidence_uploaded: uploadedEvidence.length,
      listing_uploaded: listingUploaded,
      evidence_images: nextEvidence,
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
