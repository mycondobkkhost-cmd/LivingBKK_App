import { Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

type WatermarkConfig = {
  enabled: boolean;
  opacity: number;
  sizeRatio: number;
};

async function loadBundledLogo(): Promise<Image> {
  const logoPath = new URL("./watermark-logo.png", import.meta.url);
  const bytes = await Deno.readFile(logoPath);
  return await Image.decode(bytes);
}

async function resolveLogo(
  db: SupabaseClient,
): Promise<{ logo: Image; config: WatermarkConfig }> {
  const { data: settings } = await db
    .from("app_platform_settings")
    .select(
      "listing_watermark_enabled, listing_watermark_storage_path, listing_watermark_opacity, listing_watermark_size_ratio",
    )
    .eq("id", "default")
    .maybeSingle();

  const config: WatermarkConfig = {
    enabled: settings?.listing_watermark_enabled ?? true,
    opacity: Number(settings?.listing_watermark_opacity ?? 72),
    sizeRatio: Number(settings?.listing_watermark_size_ratio ?? 0.08),
  };

  const storagePath = settings?.listing_watermark_storage_path as string | undefined;
  if (storagePath) {
    const { data, error } = await db.storage.from("brand-assets").download(storagePath);
    if (!error && data) {
      const bytes = new Uint8Array(await data.arrayBuffer());
      return { logo: await Image.decode(bytes), config };
    }
  }

  return { logo: await loadBundledLogo(), config };
}

async function sha256Short(bytes: Uint8Array): Promise<string> {
  const hash = await crypto.subtle.digest("SHA-256", bytes);
  const slice = new Uint8Array(hash).slice(0, 16);
  let binary = "";
  for (const b of slice) binary += String.fromCharCode(b);
  return btoa(binary);
}

function contentTypeForPath(path: string): string {
  const ext = path.split(".").pop()?.toLowerCase() ?? "jpg";
  if (ext === "png") return "image/png";
  if (ext === "webp") return "image/webp";
  return "image/jpeg";
}

async function encodeImage(img: Image, path: string): Promise<Uint8Array> {
  const ext = path.split(".").pop()?.toLowerCase() ?? "jpg";
  if (ext === "png") return await img.encode();
  return await img.encodeJPEG(88);
}

/** ลายน้ำมุมเดียว — เล็ก เบา กึ่งโปร่งแสง (มุมล่างขวา) */
async function applyWatermark(
  base: Image,
  logo: Image,
  config: WatermarkConfig,
): Promise<Image> {
  const out = base.clone();
  const ratio = Math.max(0.04, Math.min(0.2, config.sizeRatio));
  const opacity = Math.max(20, Math.min(200, Math.round(config.opacity)));

  const cornerW = Math.max(32, Math.floor(out.width * ratio));
  const cornerH = Math.max(32, Math.floor(logo.height * (cornerW / logo.width)));
  const corner = logo.resize(cornerW, cornerH).opacity(opacity);
  const pad = Math.max(8, Math.floor(out.width * 0.02));
  out.composite(
    corner,
    out.width - cornerW - pad,
    out.height - cornerH - pad,
  );

  return out;
}

function watermarkedStoragePath(originalPath: string): string {
  const slash = originalPath.lastIndexOf("/");
  if (slash < 0) return `wm/${originalPath}`;
  const dir = originalPath.slice(0, slash);
  const file = originalPath.slice(slash + 1);
  return `${dir}/wm/${file}`;
}

export type WatermarkResult = {
  processed: number;
  skipped: number;
  errors: string[];
  disabled?: boolean;
};

export async function watermarkListingImages(
  db: SupabaseClient,
  listingId: string,
): Promise<WatermarkResult> {
  const result: WatermarkResult = { processed: 0, skipped: 0, errors: [] };

  let logo: Image;
  let config: WatermarkConfig;
  try {
    const resolved = await resolveLogo(db);
    logo = resolved.logo;
    config = resolved.config;
  } catch (e) {
    result.errors.push(`logo_load: ${e}`);
    return result;
  }

  if (!config.enabled) {
    result.disabled = true;
    return result;
  }

  const { data: rows, error: listErr } = await db
    .from("listing_images")
    .select(
      "id, storage_path, public_url, watermark_applied_at, watermarked_storage_path",
    )
    .eq("listing_id", listingId)
    .order("sort_order", { ascending: true });

  if (listErr) {
    result.errors.push(listErr.message);
    return result;
  }

  if (!rows?.length) return result;

  const now = new Date().toISOString();

  for (const row of rows) {
    const imageId = row.id as string;
    const path = row.storage_path as string;

    const existingWm = row.watermarked_storage_path as string | undefined;
    if (row.watermark_applied_at && existingWm) {
      result.skipped += 1;
      continue;
    }

    try {
      const { data: blob, error: dlErr } = await db.storage
        .from("listing-images")
        .download(path);

      if (dlErr || !blob) {
        result.errors.push(`${imageId}: download ${dlErr?.message ?? "empty"}`);
        continue;
      }

      const raw = new Uint8Array(await blob.arrayBuffer());
      let decoded: Image;
      try {
        decoded = await Image.decode(raw);
      } catch (e) {
        result.errors.push(`${imageId}: decode ${e}`);
        continue;
      }

      const marked = await applyWatermark(decoded, logo, config);
      const wmPath = watermarkedStoragePath(path);
      const outBytes = await encodeImage(marked, wmPath);
      const hash = await sha256Short(outBytes);

      const { error: upErr } = await db.storage
        .from("listing-images")
        .upload(wmPath, outBytes, {
          upsert: true,
          contentType: contentTypeForPath(wmPath),
          cacheControl: "3600",
        });

      if (upErr) {
        result.errors.push(`${imageId}: upload ${upErr.message}`);
        continue;
      }

      const { data: pub } = db.storage.from("listing-images").getPublicUrl(wmPath);
      const publicUrl = pub.publicUrl;

      const { error: metaErr } = await db
        .from("listing_images")
        .update({
          public_url: publicUrl,
          watermarked_storage_path: wmPath,
          watermark_applied_at: now,
          perceptual_hash: hash,
          moderation_status: "approved",
        })
        .eq("id", imageId);

      if (metaErr) {
        result.errors.push(`${imageId}: meta ${metaErr.message}`);
        continue;
      }

      result.processed += 1;
    } catch (e) {
      result.errors.push(`${imageId}: ${e}`);
    }
  }

  return result;
}
