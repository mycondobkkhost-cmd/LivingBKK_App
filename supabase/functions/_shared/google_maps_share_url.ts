export type GoogleMapsShareCoords = {
  lat: number;
  lng: number;
  resolved_url: string;
  place_name: string | null;
};

export function looksLikeMapsUrl(raw: string): boolean {
  const t = raw.trim().toLowerCase();
  if (!t.startsWith("http://") && !t.startsWith("https://")) return false;
  return (
    t.includes("maps.google") ||
    t.includes("google.com/maps") ||
    t.includes("goo.gl/maps") ||
    t.includes("maps.app.goo.gl")
  );
}

export async function resolveAndParseCoords(
  raw: string,
): Promise<GoogleMapsShareCoords | null> {
  let url = normalizeUrl(raw);
  if (!url) return null;

  if (isShortMapsUrl(url)) {
    const expanded = await followRedirects(url);
    if (expanded) url = expanded;
  }

  const coords = extractCoords(url);
  if (!coords) return null;

  return {
    lat: coords.lat,
    lng: coords.lng,
    resolved_url: url,
    place_name: extractPlaceName(url),
  };
}

function normalizeUrl(raw: string): string {
  let url = raw.trim();
  if (!url) return "";
  if (!url.startsWith("http://") && !url.startsWith("https://")) {
    url = `https://${url}`;
  }
  try {
    const u = new URL(url);
    u.hash = "";
    return u.toString();
  } catch {
    return url;
  }
}

function isShortMapsUrl(url: string): boolean {
  try {
    const host = new URL(url).host.toLowerCase();
    return (
      host === "goo.gl" ||
      host === "maps.app.goo.gl" ||
      (host.endsWith("goo.gl") && url.includes("/maps"))
    );
  } catch {
    return false;
  }
}

async function followRedirects(url: string, maxHops = 6): Promise<string | null> {
  let current = url;
  for (let i = 0; i < maxHops; i++) {
    try {
      const res = await fetch(current, {
        method: "GET",
        redirect: "manual",
        headers: {
          "User-Agent":
            "Mozilla/5.0 (compatible; RealXtate/1.0; +https://realxtateth.com)",
        },
      });
      if (res.status >= 300 && res.status < 400) {
        const loc = res.headers.get("location");
        if (!loc) return current;
        current = loc.startsWith("http")
          ? loc
          : new URL(loc, current).toString();
        continue;
      }
      return current;
    } catch {
      return null;
    }
  }
  return current;
}

function extractCoords(url: string): { lat: number; lng: number } | null {
  const decoded = decodeURIComponent(url);

  const pin = decoded.match(/!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)/);
  if (pin) return pair(pin[1], pin[2]);

  const at = decoded.match(/@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/);
  if (at) return pair(at[1], at[2]);

  try {
    const uri = new URL(url);
    for (const key of ["q", "query", "ll", "center"]) {
      const q = uri.searchParams.get(key);
      if (!q) continue;
      const fromQ = coordsFromPairText(q);
      if (fromQ) return fromQ;
    }
  } catch {
    // ignore
  }

  const qInline = decoded.match(
    /[?&](?:q|query|ll|center)=(-?\d+(?:\.\d+)?)[,%20+](-?\d+(?:\.\d+)?)/,
  );
  if (qInline) return pair(qInline[1], qInline[2]);

  return null;
}

function extractPlaceName(url: string): string | null {
  const decoded = decodeURIComponent(url);

  const placePath = decoded.match(/\/place\/([^/@?#]+)/);
  if (placePath?.[1]) {
    return cleanPlaceName(placePath[1]);
  }

  try {
    const uri = new URL(url);
    for (const key of ["q", "query"]) {
      const q = uri.searchParams.get(key);
      if (!q) continue;
      if (/^-?\d+(?:\.\d+)?\s*[, ]\s*-?\d+(?:\.\d+)?/.test(q.trim())) {
        continue;
      }
      const cleaned = cleanPlaceName(q);
      if (cleaned) return cleaned;
    }
  } catch {
    // ignore
  }

  return null;
}

function cleanPlaceName(raw: string): string | null {
  const name = raw.replace(/\+/g, " ").trim();
  if (name.length < 2) return null;
  return name;
}

function coordsFromPairText(text: string): { lat: number; lng: number } | null {
  const m = text.trim().match(/^(-?\d+(?:\.\d+)?)\s*[, ]\s*(-?\d+(?:\.\d+)?)/);
  if (!m) return null;
  return pair(m[1], m[2]);
}

function pair(a: string | undefined, b: string | undefined): { lat: number; lng: number } | null {
  if (!a || !b) return null;
  const lat = Number.parseFloat(a);
  const lng = Number.parseFloat(b);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (!isValidLatLng(lat, lng)) return null;
  return maybeSwapBangkok(lat, lng);
}

function isValidLatLng(lat: number, lng: number): boolean {
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return false;
  if (lat === 0 && lng === 0) return false;
  return true;
}

function maybeSwapBangkok(lat: number, lng: number): { lat: number; lng: number } {
  const minLat = 12.5;
  const maxLat = 15.5;
  const minLng = 99.0;
  const maxLng = 102.0;
  const inBox = (la: number, ln: number) =>
    la >= minLat && la <= maxLat && ln >= minLng && ln <= maxLng;
  if (inBox(lat, lng)) return { lat, lng };
  if (inBox(lng, lat)) return { lat: lng, lng: lat };
  return { lat, lng };
}
