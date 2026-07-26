import type { ListingDetail } from "./chat_answer_openai.ts";
import type { BotReply, ChatLink } from "./chat_logic.ts";

export type MapPin = {
  lat: number;
  lng: number;
  label: string;
  btsStation?: string | null;
  maxDistanceBtsKm?: number | null;
};

const LOCATION_KEYS = [
  "โลเคชั่น",
  "location",
  "แผนที่",
  "แมพ",
  "map",
  "google map",
  "ใกล้ bts",
  "ใกล้ mrt",
  "ทำเล",
  "เดินทาง",
  "รถไฟฟ้า",
  "กี่เมตร",
  "ห่าง bts",
  "ห่าง mrt",
  "ขอพิกัด",
  "พิกัด",
  "ใกล้สถานี",
  "เดินถึง",
  "ใกล้ห้าง",
];

export function isLocationQuestion(text: string): boolean {
  const q = text.toLowerCase();
  return LOCATION_KEYS.some((k) => q.includes(k));
}

export function buildGoogleMapsUrl(pin: { lat: number; lng: number }): string {
  return `https://www.google.com/maps/search/?api=1&query=${pin.lat},${pin.lng}`;
}

export function locationMapLink(pin: MapPin): ChatLink {
  return {
    label: "เปิด Google Maps · โครงการ",
    kind: "viewing_location",
    listingId: "",
    refCode: buildGoogleMapsUrl(pin),
    projectName: pin.label,
  };
}

export function listingToMapPin(
  listing?: ListingDetail | null,
): MapPin | null {
  const lat = listing?.map_lat ?? null;
  const lng = listing?.map_lng ?? null;
  if (lat == null || lng == null || !Number.isFinite(lat) || !Number.isFinite(lng)) {
    return null;
  }
  return {
    lat,
    lng,
    label: listing?.project_name?.trim() || listing?.title?.trim() || "โครงการ",
    btsStation: listing?.project_bts ?? null,
    maxDistanceBtsKm: listing?.max_distance_bts_km ?? null,
  };
}

export function locationReplyTexts(pin: MapPin | null): string[] {
  if (!pin) {
    return [
      "แผนที่ที่แสดงจะบอกโซนโดยประมาณค่ะ หากต้องการทราบระยะทางจาก BTS/MRT แจ้งได้เลยนะคะ",
    ];
  }
  return [
    "แอดมินส่งโลเคชั่นโครงการให้ทางนี้นะคะ ลูกค้าสามารถคลิกเพื่อตรวจสอบพิกัดได้เลยค่ะ",
  ];
}

export function locationReplyLinks(pin: MapPin | null): ChatLink[] {
  if (!pin) return [];
  return [locationMapLink(pin)];
}

export function locationFaqReply(pin: MapPin | null): BotReply {
  if (!pin) {
    return {
      role: "ai",
      text:
        "แผนที่ที่แสดงจะบอกโซนโดยประมาณค่ะ หากต้องการทราบระยะทางจาก BTS/MRT " +
        "แจ้งได้เลยนะคะ แอดมินจะตรวจสอบรายละเอียดให้ค่ะ",
    };
  }

  const parts: string[] = [];
  if (pin.btsStation && pin.maxDistanceBtsKm != null && pin.maxDistanceBtsKm > 0) {
    const meters = Math.round(pin.maxDistanceBtsKm * 1000);
    parts.push(`ระยะทางจาก ${pin.btsStation} ในระบบแจ้งไว้ประมาณ ${meters} เมตรค่ะ`);
  } else if (pin.btsStation) {
    parts.push(`โครงการอยู่ใกล้ ${pin.btsStation} ค่ะ`);
  }
  parts.push(
    "แอดมินส่งโลเคชั่นโครงการให้ทางนี้นะคะ ลูกค้าสามารถคลิกเพื่อตรวจสอบพิกัดได้เลยค่ะ",
  );

  return {
    role: "ai",
    text: parts.join(" "),
    links: [locationMapLink(pin)],
  };
}
