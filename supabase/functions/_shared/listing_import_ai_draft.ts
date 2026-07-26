/** ใช้ร่วมกัน — บันทึก AI draft ลง import + listing draft */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  extractContacts,
  matchProject,
  projectNamesAlign,
} from "./li_parser.ts";
import {
  generateListingAiDraft,
  type ListingAiDraftResult,
} from "./listing_draft_openai.ts";

export type DuplicateImportRef = {
  import_id: string;
  listing_id: string | null;
  listing_code: string | null;
  title_preview: string | null;
  status: string;
  source_url: string;
  source_external_id: string | null;
};

async function loadDuplicateImportRef(
  db: SupabaseClient,
  importId: string,
): Promise<DuplicateImportRef | null> {
  const { data } = await db
    .from("listing_imports")
    .select(
      "id, status, title_preview, listing_id, source_url, source_external_id, listings(listing_code)",
    )
    .eq("id", importId)
    .maybeSingle();
  if (!data) return null;
  const listing = data.listings as { listing_code?: string } | null;
  return {
    import_id: data.id as string,
    listing_id: (data.listing_id as string | null) ?? null,
    listing_code: listing?.listing_code ?? null,
    title_preview: (data.title_preview as string | null) ?? null,
    status: data.status as string,
    source_url: data.source_url as string,
    source_external_id: (data.source_external_id as string | null) ?? null,
  };
}

export class CaptureImportDuplicateError extends Error {
  constructor(
    message: string,
    readonly importId: string,
    readonly duplicateOf: DuplicateImportRef,
  ) {
    super(message);
    this.name = "CaptureImportDuplicateError";
  }
}

export type ImportCapturePayload = {
  source_text_original: string;
  post_url: string | null;
  owner_profile_url: string | null;
  evidence_images: {
    storage_path: string;
    public_url: string;
    uploaded_at: string;
  }[];
  captured_at: string;
};

const PLACEHOLDER_PRICE = 1;

function geographyPoint(lng: number, lat: number): string {
  return `SRID=4326;POINT(${lng} ${lat})`;
}

export async function applyAiDraftToImport(
  db: SupabaseClient,
  importId: string,
  sourceText: string,
  options: {
    platform: string;
    postUrl?: string | null;
    ownerProfileUrl?: string | null;
    capture?: Partial<ImportCapturePayload>;
    mergeRawPayload?: Record<string, unknown>;
  },
): Promise<{ aiDraft: ListingAiDraftResult; listingId: string }> {
  const { data: row, error } = await db
    .from("listing_imports")
    .select("*")
    .eq("id", importId)
    .single();
  if (error || !row) throw new Error("Import not found");

  const listingId = row.listing_id as string | null;
  if (!listingId) throw new Error("Import has no draft listing");

  const aiDraft = await generateListingAiDraft(sourceText, {
    platform: options.platform,
    post_url: options.postUrl ?? row.source_url,
  });

  const project = await matchProject(db, aiDraft.fields.project_name);
  const matchedNameTh = project?.name_th as string | undefined;
  const useMatched = project &&
    projectNamesAlign(aiDraft.fields.project_name, matchedNameTh);

  const lat = (project?.lat as number | undefined) ?? 13.7367;
  const lng = (project?.lng as number | undefined) ?? 100.5608;
  const district = aiDraft.fields.district ??
    (project?.district as string | undefined) ??
    "กรุงเทพฯ";

  const priceNet = aiDraft.fields.price_net && aiDraft.fields.price_net > 0
    ? aiDraft.fields.price_net
    : PLACEHOLDER_PRICE;

  await db.from("listings").update({
    title: aiDraft.fields.title.slice(0, 200),
    description_public: aiDraft.fields.description_public.slice(0, 8000),
    listing_type: aiDraft.fields.listing_type,
    property_type: aiDraft.fields.property_type,
    price_net: priceNet,
    area_sqm: aiDraft.fields.area_sqm,
    bedrooms: aiDraft.fields.bedrooms,
    district,
    project_name: useMatched ? matchedNameTh : aiDraft.fields.project_name,
    project_id: useMatched ? project?.id ?? null : null,
    geo_zone_id: useMatched ? project?.geo_zone_id ?? null : null,
    location_exact: geographyPoint(lng, lat),
    location_public: geographyPoint(lng, lat),
  }).eq("id", listingId);

  const existingRaw = (row.raw_payload as Record<string, unknown> | null) ??
    {};
  const existingCapture =
    (existingRaw.capture as Record<string, unknown> | null) ?? {};

  const capture: ImportCapturePayload = {
    source_text_original: sourceText,
    post_url: options.postUrl ?? existingCapture.post_url as string | null ??
      row.source_url as string,
    owner_profile_url: options.ownerProfileUrl ??
      existingCapture.owner_profile_url as string | null ?? null,
    evidence_images: (options.capture?.evidence_images ??
      existingCapture.evidence_images ??
      []) as ImportCapturePayload["evidence_images"],
    captured_at: options.capture?.captured_at ??
      existingCapture.captured_at as string ??
      new Date().toISOString(),
  };

  const contactPrivate = extractContacts(sourceText);
  const parsed = (row.parsed as Record<string, unknown> | null) ?? {};
  const flags = new Set([
    ...((parsed.flags as string[] | undefined) ?? []),
    ...aiDraft.flags,
    "needs_admin_review",
  ]);

  if (!useMatched && aiDraft.fields.project_name) {
    flags.add("project_not_in_registry");
  }

  const rawPayload = {
    ...existingRaw,
    ...options.mergeRawPayload,
    contact_private: contactPrivate,
    capture,
    ai_draft: {
      generated_at: new Date().toISOString(),
      model: aiDraft.model,
      source: aiDraft.source,
      title_suggested: aiDraft.fields.title,
      description_suggested: aiDraft.fields.description_public,
      fields: aiDraft.fields,
      confidence: aiDraft.confidence,
      flags: aiDraft.flags,
    },
  };

  const { count: imageCount } = await db
    .from("listing_images")
    .select("id", { count: "exact", head: true })
    .eq("listing_id", listingId);

  await db.from("listing_imports").update({
    title_preview: aiDraft.fields.title,
    project_preview: useMatched
      ? matchedNameTh
      : aiDraft.fields.project_name,
    price_preview: aiDraft.fields.price_net && aiDraft.fields.price_net > 0
      ? aiDraft.fields.price_net
      : null,
    image_count: imageCount ?? 0,
    raw_payload: rawPayload,
    parsed: {
      ...parsed,
      flags: [...flags],
      matched_project_id: useMatched ? project?.id ?? null : null,
      parsed_project_name: aiDraft.fields.project_name,
      source_platform: options.platform,
    },
  }).eq("id", importId);

  return { aiDraft, listingId };
}

export async function createCaptureImportRow(
  db: SupabaseClient,
  adminId: string,
  params: {
    sourceText: string;
    postUrl?: string | null;
    ownerProfileUrl?: string | null;
  },
): Promise<{ importId: string; listingId: string }> {
  const postUrl = params.postUrl?.trim() || null;

  if (postUrl) {
    const { data: dup } = await db
      .from("listing_imports")
      .select("id, status")
      .eq("source_url", postUrl)
      .maybeSingle();
    if (dup && dup.status !== "archived" && dup.status !== "failed") {
      const duplicateOf = await loadDuplicateImportRef(db, dup.id as string);
      if (duplicateOf) {
        throw new CaptureImportDuplicateError(
          "ลิงก์โพสต์นี้อยู่ในคิวแล้ว",
          duplicateOf.import_id,
          duplicateOf,
        );
      }
    }
  }

  const sourceUrl = postUrl ?? `manual-capture://pending`;

  const { data: listing, error: listErr } = await db
    .from("listings")
    .insert({
      owner_id: adminId,
      created_by_id: adminId,
      listed_by_role: "admin",
      platform_has_owner_contact: true,
      co_agent_eligible: true,
      co_agent_eligibility_reason: "platform_contact",
      co_agent_listing_type: "co_agent_50_50",
      owner_verified: false,
      title: "นำเข้าแบบแคปเจอร์",
      listing_type: "rent",
      property_type: "condo",
      price_net: PLACEHOLDER_PRICE,
      description_public: "",
      district: "กรุงเทพฯ",
      source_platform: "manual_capture",
      source_url: sourceUrl,
      status: "draft",
      location_exact: geographyPoint(100.5608, 13.7367),
      location_public: geographyPoint(100.5608, 13.7367),
    })
    .select("id")
    .single();
  if (listErr || !listing) throw new Error(listErr?.message ?? "listing create failed");

  const listingId = listing.id as string;
  const finalSourceUrl = postUrl ?? `manual-capture://${listingId}`;

  const { data: imp, error: impErr } = await db
    .from("listing_imports")
    .insert({
      source_url: finalSourceUrl,
      source_platform: "manual_capture",
      status: "needs_fix",
      listing_id: listingId,
      created_by: adminId,
      title_preview: params.sourceText.slice(0, 80),
      parsed: { flags: ["manual_capture", "needs_admin_review"] },
      raw_payload: {
        capture: {
          source_text_original: params.sourceText,
          post_url: postUrl,
          owner_profile_url: params.ownerProfileUrl?.trim() || null,
          evidence_images: [],
          captured_at: new Date().toISOString(),
        },
      },
    })
    .select("id")
    .single();
  if (impErr || !imp) throw new Error(impErr?.message ?? "import create failed");

  if (!postUrl) {
    await db.from("listing_imports").update({
      source_url: `manual-capture://${imp.id}`,
    }).eq("id", imp.id);
    await db.from("listings").update({ source_url: `manual-capture://${imp.id}` })
      .eq("id", listingId);
  }

  return { importId: imp.id as string, listingId };
}
