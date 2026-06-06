/** หาสถานี BTS/MRT ใกล้พิกัดโครงการ — mirror mobile/lib/utils/transit_proximity.dart */

export type TransitStationCoord = {
  system: string;
  nameTh: string;
  nameEn: string;
  lat: number;
  lng: number;
};

const STATIONS: TransitStationCoord[] = [
  { system: "BTS", nameTh: "หมอชิต", nameEn: "Mo Chit", lat: 13.8027, lng: 100.5540 },
  { system: "BTS", nameTh: "อารีย์", nameEn: "Ari", lat: 13.7797, lng: 100.5448 },
  { system: "BTS", nameTh: "สนามเป้า", nameEn: "Sanam Pao", lat: 13.7728, lng: 100.5448 },
  { system: "BTS", nameTh: "อนุสาวรีย์ชัยฯ", nameEn: "Victory Monument", lat: 13.7651, lng: 100.5370 },
  { system: "BTS", nameTh: "พญาไท", nameEn: "Phaya Thai", lat: 13.7569, lng: 100.5347 },
  { system: "BTS", nameTh: "ราชเทวี", nameEn: "Ratchathewi", lat: 13.7519, lng: 100.5316 },
  { system: "BTS", nameTh: "สยาม", nameEn: "Siam", lat: 13.7456, lng: 100.5341 },
  { system: "BTS", nameTh: "ชิดลม", nameEn: "Chit Lom", lat: 13.7445, lng: 100.5430 },
  { system: "BTS", nameTh: "เพลินจิต", nameEn: "Phloen Chit", lat: 13.7431, lng: 100.5488 },
  { system: "BTS", nameTh: "นานา", nameEn: "Nana", lat: 13.7405, lng: 100.5553 },
  { system: "BTS", nameTh: "อโศก", nameEn: "Asok", lat: 13.7373, lng: 100.5606 },
  { system: "BTS", nameTh: "พร้อมพงษ์", nameEn: "Phrom Phong", lat: 13.7305, lng: 100.5693 },
  { system: "BTS", nameTh: "ทองหล่อ", nameEn: "Thong Lo", lat: 13.7242, lng: 100.5784 },
  { system: "BTS", nameTh: "เอกมัย", nameEn: "Ekkamai", lat: 13.7195, lng: 100.5851 },
  { system: "BTS", nameTh: "อ่อนนุช", nameEn: "On Nut", lat: 13.7056, lng: 100.6011 },
  { system: "BTS", nameTh: "บางจาก", nameEn: "Bang Chak", lat: 13.6967, lng: 100.6055 },
  { system: "BTS", nameTh: "แบริ่ง", nameEn: "Bearing", lat: 13.6687, lng: 100.6018 },
  { system: "BTS", nameTh: "สำโรง", nameEn: "Samrong", lat: 13.6462, lng: 100.5956 },
  { system: "BTS", nameTh: "สนามกีฬาแห่งชาติ", nameEn: "National Stadium", lat: 13.7468, lng: 100.5292 },
  { system: "BTS", nameTh: "ราชดำริ", nameEn: "Ratchadamri", lat: 13.7396, lng: 100.5345 },
  { system: "BTS", nameTh: "ศาลาแดง", nameEn: "Sala Daeng", lat: 13.7284, lng: 100.5342 },
  { system: "BTS", nameTh: "ช่องนนทรี", nameEn: "Chong Nonsi", lat: 13.7236, lng: 100.5294 },
  { system: "BTS", nameTh: "สุรศักดิ์", nameEn: "Surasak", lat: 13.7199, lng: 100.5234 },
  { system: "BTS", nameTh: "สะพานตากสิน", nameEn: "Saphan Taksin", lat: 13.7188, lng: 100.5141 },
  { system: "MRT", nameTh: "สุขุมวิท", nameEn: "Sukhumvit", lat: 13.7386, lng: 100.5613 },
  { system: "MRT", nameTh: "สีลม", nameEn: "Silom", lat: 13.7297, lng: 100.5368 },
  { system: "MRT", nameTh: "ลุมพินี", nameEn: "Lumphini", lat: 13.7278, lng: 100.5458 },
  { system: "MRT", nameTh: "คลองเตย", nameEn: "Khlong Toei", lat: 13.7224, lng: 100.5539 },
  { system: "MRT", nameTh: "ศูนย์สิริกิติ์", nameEn: "Queen Sirikit", lat: 13.7220, lng: 100.5600 },
  { system: "MRT", nameTh: "พระราม 9", nameEn: "Phra Ram 9", lat: 13.7587, lng: 100.5650 },
  { system: "MRT", nameTh: "ห้วยขวาง", nameEn: "Huai Khwang", lat: 13.7785, lng: 100.5736 },
  { system: "MRT", nameTh: "ลาดพร้าว", nameEn: "Lat Phrao", lat: 13.8060, lng: 100.5734 },
  { system: "MRT", nameTh: "บางซื่อ", nameEn: "Bang Sue", lat: 13.8038, lng: 100.5392 },
  { system: "MRT", nameTh: "หัวลำโพง", nameEn: "Hua Lamphong", lat: 13.7378, lng: 100.5174 },
  { system: "ARL", nameTh: "มักกะสัน", nameEn: "Makkasan", lat: 13.7510, lng: 100.5608 },
];

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const r = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLng / 2) ** 2;
  return r * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function labelTh(s: TransitStationCoord): string {
  return `${s.system} ${s.nameTh}`;
}

export function labelsFromText(text: string | null | undefined): string[] {
  if (!text?.trim()) return [];
  const hay = text.toLowerCase();
  const found: string[] = [];
  for (const s of STATIONS) {
    const th = s.nameTh.toLowerCase();
    const en = s.nameEn.toLowerCase();
    if (
      hay.includes(th) || hay.includes(en) ||
      hay.includes(`${s.system.toLowerCase()} ${th}`) ||
      hay.includes(`${s.system.toLowerCase()} ${en}`)
    ) {
      found.push(labelTh(s));
    }
  }
  return [...new Set(found)];
}

export function mergeNearbyTransitLabels(input: {
  lat: number;
  lng: number;
  descriptionTh?: string | null;
  html?: string | null;
  existing?: string | null;
  maxKm?: number;
  limit?: number;
}): string[] {
  const maxKm = input.maxKm ?? 1.0;
  const limit = input.limit ?? 5;
  const merged: string[] = [];
  const add = (label: string) => {
    const t = label.trim();
    if (!t || merged.includes(t)) return;
    merged.push(t);
  };

  const hits = STATIONS.map((s) => ({
    s,
    km: haversineKm(input.lat, input.lng, s.lat, s.lng),
  }))
    .filter((h) => h.km <= maxKm)
    .sort((a, b) => a.km - b.km)
    .slice(0, limit);

  for (const h of hits) add(labelTh(h.s));
  for (const l of labelsFromText(input.descriptionTh)) add(l);
  for (const l of labelsFromText(input.html)) add(l);
  if (input.existing) {
    for (const part of input.existing.split(/[·|,/]/)) add(part.trim());
  }
  return merged.slice(0, limit);
}

export function formatBtsField(labels: string[]): string | null {
  if (labels.length === 0) return null;
  return labels.join(" · ");
}

export function transitAliases(labels: string[]): string[] {
  const out: string[] = [];
  for (const label of labels) {
    out.push(label);
    const stripped = label.replace(/^(BTS|MRT|ARL|Gold)\s+/, "");
    if (stripped !== label) out.push(stripped);
  }
  return [...new Set(out)];
}
