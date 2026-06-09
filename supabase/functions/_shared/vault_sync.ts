import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

type VaultUpsert = {
  entity_type: string;
  entity_id: string;
  source_platform?: string | null;
  title_preview?: string | null;
  listing_id?: string | null;
  listing_code?: string | null;
  profile_id?: string | null;
  import_id?: string | null;
  payload: Record<string, unknown>;
};

export async function upsertVaultAsset(
  db: SupabaseClient,
  row: VaultUpsert,
): Promise<void> {
  const { error } = await db.from("vault_assets").upsert(
    {
      ...row,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "entity_type,entity_id" },
  );
  if (error) throw new Error(error.message);
}

function contactFromParsed(parsed: Record<string, unknown>, raw: Record<string, unknown>) {
  const cp = (raw.contact_private ?? parsed.contactPrivate) as
    | { phones?: string[]; lines?: string[] }
    | undefined;
  return {
    phones: cp?.phones ?? [],
    lines: cp?.lines ?? [],
    raw: cp ?? null,
  };
}

export async function syncImportToVault(
  db: SupabaseClient,
  importId: string,
): Promise<VaultUpsert | null> {
  const { data, error } = await db
    .from("listing_imports")
    .select(
      "id, source_url, source_platform, source_external_id, status, title_preview, "
      + "listing_id, raw_payload, parsed, listings(listing_code)",
    )
    .eq("id", importId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) return null;

  const raw = (data.raw_payload as Record<string, unknown> | null) ?? {};
  const parsed = (data.parsed as Record<string, unknown> | null) ?? {};
  const meta = (parsed.source_meta ?? raw.source_meta ?? {}) as Record<string, unknown>;
  const contact = contactFromParsed(parsed, raw);
  const listing = data.listings as { listing_code?: string } | null;

  const row: VaultUpsert = {
    entity_type: "listing_import",
    entity_id: data.id as string,
    source_platform: data.source_platform as string,
    title_preview: data.title_preview as string | null,
    listing_id: data.listing_id as string | null,
    listing_code: listing?.listing_code ?? null,
    import_id: data.id as string,
    payload: {
      source_url: data.source_url,
      source_external_id: data.source_external_id,
      import_status: data.status,
      post_text_full: meta.postText ?? parsed.description ?? null,
      post_links: meta.postLinks ?? [],
      poster_name: meta.posterName ?? null,
      poster_url: meta.posterUrl ?? null,
      post_url: meta.postUrl ?? data.source_url,
      phones: contact.phones,
      lines: contact.lines,
      contact_private: contact.raw,
      source_meta: meta,
      description_public_stripped: parsed.description ?? null,
      synced_from: "listing_imports",
      synced_at: new Date().toISOString(),
    },
  };

  await upsertVaultAsset(db, row);
  return row;
}

export async function syncListingToVault(
  db: SupabaseClient,
  listingId: string,
): Promise<VaultUpsert | null> {
  const { data, error } = await db
    .from("listings")
    .select(
      "id, listing_code, title, source_url, source_platform, source_external_id, "
      + "owner_id, created_by_id, listed_by_role, description_public",
    )
    .eq("id", listingId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) return null;

  const ownerId = (data.owner_id ?? data.created_by_id) as string | null;
  let ownerPhone: string | null = null;
  let ownerLine: string | null = null;
  let ownerName: string | null = null;
  if (ownerId) {
    const { data: prof } = await db
      .from("profiles")
      .select("phone, line_id, display_name")
      .eq("id", ownerId)
      .maybeSingle();
    ownerPhone = prof?.phone ?? null;
    ownerLine = prof?.line_id ?? null;
    ownerName = prof?.display_name ?? null;
  }

  const row: VaultUpsert = {
    entity_type: "listing",
    entity_id: data.id as string,
    source_platform: data.source_platform as string | null,
    title_preview: data.title as string,
    listing_id: data.id as string,
    listing_code: data.listing_code as string | null,
    profile_id: ownerId,
    payload: {
      source_url: data.source_url,
      source_external_id: data.source_external_id,
      listed_by_role: data.listed_by_role,
      owner_profile_id: ownerId,
      owner_display_name: ownerName,
      owner_phone: ownerPhone,
      owner_line: ownerLine,
      description_public: data.description_public,
      synced_from: "listings",
      synced_at: new Date().toISOString(),
    },
  };

  await upsertVaultAsset(db, row);
  if (ownerId) await syncProfileToVault(db, ownerId);
  return row;
}

export async function syncProfileToVault(
  db: SupabaseClient,
  profileId: string,
): Promise<VaultUpsert | null> {
  const { data, error } = await db
    .from("profiles")
    .select("id, display_name, phone, line_id, role, admin_tier, created_at")
    .eq("id", profileId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) return null;

  const row: VaultUpsert = {
    entity_type: "profile",
    entity_id: data.id as string,
    title_preview: data.display_name as string | null,
    profile_id: data.id as string,
    payload: {
      display_name: data.display_name,
      phone: data.phone,
      line_id: data.line_id,
      role: data.role,
      admin_tier: data.admin_tier,
      account_created_at: data.created_at,
      synced_from: "profiles",
      synced_at: new Date().toISOString(),
    },
  };

  await upsertVaultAsset(db, row);
  return row;
}

export async function syncAllImportsToVault(db: SupabaseClient): Promise<number> {
  const { data, error } = await db
    .from("listing_imports")
    .select("id")
    .order("created_at", { ascending: false })
    .limit(500);
  if (error) throw new Error(error.message);
  let n = 0;
  for (const row of data ?? []) {
    await syncImportToVault(db, row.id as string);
    n++;
  }
  return n;
}
