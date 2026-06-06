#!/usr/bin/env python3
"""POV chat routing test — mirrors supabase/functions/_shared chat_router logic."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "supabase/seed/chat_bot_training_gemini_v1.json"

THAI_TONE = re.compile(r"[\u0e31\u0e34-\u0e3a\u0e47-\u0e4e]")
PHONE = re.compile(r"(?:^|[^\d])(0[689]\d{8}|0[2-9]\d{7,8})(?:[^\d]|$)")

TYPO = {
    "เท่าไหร่": "เท่าไร", "เท่าไร่": "เท่าไร", "ทะไหร่": "เท่าไร", "กี่บาท": "เท่าไร",
    "price": "ราคา", "cam fee": "ค่าส่วนกลาง", "cam": "ค่าส่วนกลาง", "common fee": "ค่าส่วนกลาง",
    "pet": "สัตว์เลี้ยง", "สัตว": "สัตว์", "สัตวเลี้ยง": "สัตว์เลี้ยง", "เลี้ยงสัตว": "สัตว์เลี้ยง",
    "คับ": "ครับ", "ปะ": "ไหม", "ป่าว": "เปล่า", "มั้ย": "ไหม",
    "proppiter คึอ": "proppiter คือ", "co agent": "co-agent",
}

CONTACT_KEYS = ["เบอร์", "เบอ", "โทร", "line", "ไลน์", "phone", "whatsapp", "เบอร์เจ้าของ", "ติดต่อเจ้าของ"]
OWNER_KEYS = ["เจ้าของ", "ผู้ขาย", "ผู้ให้เช่า", "ผู้ลงประกาศ", "owner", "landlord"]
NEGOTIATE_DIRECT = ["ต่อรอง", "ลดราคา", "ลดได้", "ส่วนลด", "discount", "ขอลด", "ต่อราคา", "ต่อค่าเช่า", "ต่อค่า", "เจรจา"]
UNIT_KEYS = ["เลขห้อง", "ชั้น", "ชั้นที่", "floor", "ทิศ", "ทิศห้อง", "unit"]
DISCOVERY_KEYS = ["หา", "แนะนำ", "ค้นห", "อยากเช่า", "งบ", "เช่า", "bts", "mrt", "อโศก", "ทองหล่อ"]

REPLIES = {
    "contact": "ขออภัยครับ ทางเราไม่สามารถแจ้งข้อมูลติดต่อของเจ้าของทรัพย์ได้โดยตรง รบกวนคุณลูกค้าทิ้งเบอร์โทรศัพท์และข้อซักถามไว้ แล้วทีมงานจะรีบประสานงานและติดต่อกลับเพื่อดูแลครับ",
    "owner": "เนื่องจากนโยบายความเป็นส่วนตัว (PDPA) ทางแพลตฟอร์มไม่สามารถเปิดเผยข้อมูลส่วนบุคคลของเจ้าของทรัพย์ได้ครับ หากคุณลูกค้ามีข้อสงสัยเกี่ยวกับตัวทรัพย์ สามารถสอบถามเพิ่มเติมกับทางเราได้เลยครับ",
    "negotiate": "ในส่วนของการต่อรองราคาหรือการขอปรับเงื่อนไขสัญญา ทางเรายังไม่สามารถยืนยันให้ได้ในทันทีครับ ขออนุญาตส่งเรื่องให้ทีมงานพิจารณาร่วมกับเจ้าของ แล้วจะรีบติดต่อกลับเพื่อแจ้งรายละเอียดอีกครั้งครับ",
    "unit_privacy": "เพื่อความเป็นส่วนตัวและความปลอดภัยของทรัพย์ ทางเราขอสงวนสิทธิ์ในการแจ้งเลขห้องหรือชั้นที่แน่นอนผ่านช่องทางนี้ครับ หากท่านสนใจ สามารถนัดหมายเพื่อเข้าชมสถานที่จริงกับเจ้าหน้าที่ได้ครับ",
    "phone_ack": "ขอบคุณมากครับ ทางเราได้รับเบอร์ติดต่อและข้อมูลของท่านเรียบร้อยแล้ว ทีมงานจะรีบนำข้อมูลไปตรวจสอบและติดต่อกลับเพื่อให้บริการโดยเร็วที่สุดครับ",
    "clarify": "ยังไม่แน่ใจคำถามครับ ลองระบุทำเล · งบ · หรือรายละเอียดที่ต้องการเพิ่ม\nหรือพิมพ์「ขอคุยกับเจ้าหน้าที่」เมื่อต้องการให้ทีมช่วยโดยตรง",
    "escalate": "คำถามนี้ต้องให้เจ้าหน้าที่ตอบโดยตรง — เราแจ้งทีมแล้ว และจะติดต่อกลับในแชทนี้โดยเร็วที่สุด",
}


def strip_tones(s: str) -> str:
    return THAI_TONE.sub("", s)


def normalize(text: str) -> str:
    s = strip_tones(text.lower().strip())
    s = re.sub(r"\s+", " ", s)
    for typo in sorted(TYPO, key=len, reverse=True):
        s = s.replace(strip_tones(typo.lower()), strip_tones(TYPO[typo].lower()))
    return s


def levenshtein(a: str, b: str) -> int:
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (0 if ca == cb else 1)))
        prev = cur
    return prev[-1]


def fuzzy_threshold(n: int) -> int:
    if n <= 3:
        return 0
    if n <= 5:
        return 1
    if n <= 8:
        return 2
    return min(3, n // 4)


def fuzzy_includes(text: str, pattern: str) -> bool:
    hay, needle = normalize(text), normalize(pattern)
    if not needle:
        return False
    if needle in hay:
        return True
    if len(needle) < 3:
        return False
    md = fuzzy_threshold(len(needle))
    if md == 0:
        return False
    win = len(needle)
    for start in range(0, len(hay) - min(3, win) + 1):
        for size in range(max(3, win - md), win + md + 1):
            if start + size > len(hay):
                continue
            if levenshtein(hay[start : start + size], needle) <= md:
                return True
    return False


def has_phone(text: str) -> bool:
    return bool(PHONE.search(re.sub(r"[\s\-().]", "", text)))


def is_negotiate(q: str) -> bool:
    if any(k in q for k in NEGOTIATE_DIRECT):
        return True
    if "สัญญา" not in q and "ระยะสัญญา" not in q:
        return False
    return any(x in q for x in ["ต่อรอง", "ลด", "ต่อราคา", "ต่อค่า"]) or ("ปี" in q and "ได้ไหม" in q)


def classify_sensitive(text: str):
    q = text.lower().strip()
    if is_negotiate(q):
        return "negotiate"
    if any(k in q for k in CONTACT_KEYS):
        return "contact"
    if any(k in q for k in OWNER_KEYS):
        return "owner"
    if any(k in q for k in UNIT_KEYS):
        return "unit_privacy"
    return None


def match_faq(text: str, rules: list, scopes: list):
    eligible = [r for r in rules if r["scope"] in scopes]
    eligible.sort(key=lambda r: r.get("priority", 100))
    for rule in eligible:
        for p in rule["patterns"]:
            if fuzzy_includes(text, p):
                return rule
    return None


def is_discovery_intent(text: str) -> bool:
    q = normalize(text)
    return any(k in q for k in DISCOVERY_KEYS) or bool(re.search(r"\d[\d,]*\s*(?:บาท|k)?", q))


def discovery_reply(text: str, listings: list) -> tuple[str, list, str]:
    q = normalize(text)
    budget = None
    m = re.search(r"(\d[\d,]*)", text)
    if m:
        budget = float(m.group(1).replace(",", ""))
        if budget < 500:
            budget *= 1000
    matched = []
    for l in listings:
        if budget and l["price_net"] > budget * 1.15:
            continue
        hay = " ".join(filter(None, [l["title"], l.get("project_name"), l.get("district")])).lower()
        if "อโศก" in q and "อโศก" in hay:
            matched.append(l)
        elif "ทองหล่อ" in q and "ทองหล่อ" in hay:
            matched.append(l)
        elif "คอนโด" in q and l.get("property_type") == "condo":
            matched.append(l)
    if not matched and budget:
        matched = [l for l in listings if l["price_net"] <= budget * 1.2]
    matched = matched[:3]
    if matched:
        links = [f"{l['listing_code']} · {l['price_net']:,}/เดือน" for l in matched]
        names = ", ".join(l.get("project_name") or l["title"] for l in matched)
        return (
            f"พบทรัพย์ที่ใกล้เคียงบรีฟของคุณ:\n{names}\nกดลิงก์ด้านล่างเพื่อดูประกาศ",
            links,
            "discovery_db",
        )
    return (
        "ยังไม่พบทรัพย์ที่ตรงบรีฟชัดเจนครับ ลองระบุทำเล โครงการ หรืองบประมาณเพิ่มเติม",
        [],
        "discovery_empty",
    )


def route(text: str, faq_rules: list, has_listing: bool, listing_code, unclear_streak: int, listings: list):
    kind = classify_sensitive(text)
    if kind:
        reply = REPLIES[kind]
        admin = kind in ("negotiate",) or (kind == "contact" and has_phone(text))
        return {"reply": reply, "source": f"sensitive_{kind}", "admin": admin, "status": "waiting_admin" if admin else "open"}

    if has_phone(text):
        return {"reply": REPLIES["phone_ack"], "source": "phone_provided", "admin": True, "status": "waiting_admin"}

    r = match_faq(text, faq_rules, ["global"])
    if r:
        return faq_result(r, listing_code, "faq_global")

    if has_listing:
        r = match_faq(text, faq_rules, ["property"])
        if r:
            return faq_result(r, listing_code, "faq_property")

    is_disc = not has_listing
    r = match_faq(text, faq_rules, ["discovery"])
    if r and (is_disc or is_discovery_intent(text)):
        return faq_result(r, listing_code, "faq_discovery", category="discovery")

    if is_disc or is_discovery_intent(text):
        msg, links, src = discovery_reply(text, listings)
        if links:
            return {"reply": msg, "source": src, "admin": False, "status": "open", "links": links}
        if is_disc or is_discovery_intent(text):
            return {"reply": msg, "source": src, "admin": False, "status": "open"}

    if unclear_streak < 1:
        return {"reply": REPLIES["clarify"], "source": "soft_clarify", "admin": False, "status": "open"}
    return {"reply": REPLIES["escalate"], "source": "fallback_admin", "admin": True, "status": "waiting_admin"}


def faq_result(rule, listing_code, source, category="property_faq"):
    reply = rule["reply_text"]
    if listing_code and rule["scope"] == "property" and listing_code not in reply:
        reply = f"{reply} ({listing_code})"
    admin = bool(rule.get("escalate"))
    return {
        "reply": reply,
        "source": source,
        "admin": admin,
        "status": "waiting_admin" if admin else "open",
        "topic": rule.get("topic_th"),
    }


SCENARIOS = [
    ("ลูกค้า — ถามราคา (พิมพ์ผิด)", "เท่าไหร่คับ", True, 0),
    ("ลูกค้า — สัตว์เลี้ยง (พิมพ์ผิด)", "เลี้ยงสัตวได้ไหม", True, 0),
    ("ลูกค้า — ขอเบอร์เจ้าของ", "ขอเบอร์เจ้าของหน่อยค่ะ จะคุยรายละเอียด", True, 0),
    ("ลูกค้า — ถามชื่อเจ้าของ (PDPA)", "เจ้าของห้องชื่ออะไรคะ เป็นคนไทยหรือเปล่า", True, 0),
    ("ลูกค้า — ต่อราคา สัญญา 2 ปี", "ราคา 15,000 ลดเหลือ 14,000 ได้ไหม ถ้าทำสัญญา 2 ปี", True, 0),
    ("ลูกค้า — ถามชั้น/ทิศ", "ห้องนี้อยู่ชั้นอะไร ทิศไหนคะ", True, 0),
    ("ลูกค้า — ทิ้งเบอร์มา", "0891112222 สนใจห้องนี้ครับ", True, 0),
    ("ลูกค้า — ค่าคอมกี่เปอร์เซ็นต์", "ราคาเนทนี้รวมคอมมิชชั่นของเว็บไปกี่เปอร์เซ็นต์ครับ", True, 0),
    ("ลูกค้า — นัดดูห้อง", "ขอดูห้องหน่อย ว่างไหม", True, 0),
    ("ลูกค้า — ห้องว่างเมื่อไหร่", "ห้องนี้ว่างวันไหนคะ", True, 0),
    ("ลูกค้า — ค้นหาทรัพย์ (discovery)", "หาคอนโดแถวอโศกงบหมื่นห้า", False, 0),
    ("ลูกค้า — สัญญากี่ปี (ทั่วไป)", "สัญญาเช่ากี่เดือนคะ", True, 0),
    ("ลูกค้า — คำถามกำกวมครั้งแรก", "อืม", True, 0),
    ("ลูกค้า — คำถามกำกวมครั้งสอง", "ไม่รู้สิ", True, 1),
    ("ลูกค้า — แพลตฟอร์มคืออะไร", "proppiter คึออะไร", False, 0),
    ("ลูกค้า — Co-Agent", "co agent รับไหมค่ะ", False, 0),
    ("ลูกค้า — cam fee", "cam fee เท่าไหร่", True, 0),
    ("ลูกค้า — ลดราคา (ต่อรอง)", "ลดค่าเช่าได้อีกไหม", True, 0),
    ("ลูกค้า — ฝากหาห้อง", "ช่วยหาห้องแถวทองหล่อหน่อย", False, 0),
]


def main():
    data = json.loads(SEED.read_text(encoding="utf-8"))
    rules = data["faq_rules"]
    listings = [
        {"listing_code": "PPTR-2026-000101", "title": "คอนโด 1 นอน อโศก", "project_name": "The Address Asoke", "listing_type": "rent", "price_net": 15000, "property_type": "condo", "district": "วัฒนา"},
        {"listing_code": "PPTR-2026-000202", "title": "คอนโด ทองหล่อ", "project_name": "Rhythm Sukhumvit", "listing_type": "rent", "price_net": 14000, "property_type": "condo", "district": "วัฒนา"},
    ]
    print("=== PROPPITER Chat POV Test (local simulation) ===\n")
    print(f"FAQ rules: {len(rules)} | หมายเหตุ: ไม่มี OpenAI RAG ในเทสต์นี้\n")

    results = []
    for pov, msg, has_listing, streak in SCENARIOS:
        r = route(msg, rules, has_listing, "PPTR-2026-000101" if has_listing else None, streak, listings)
        preview = r["reply"] if len(r["reply"]) <= 240 else r["reply"][:240] + "…"
        tag = "🔔 แจ้งแอดมิน" if r["admin"] else "🤖 บอทตอบเอง"
        results.append((pov, msg, tag, r["source"], preview, r.get("links"), r.get("topic")))
        print(f"【{pov}】")
        print(f'ลูกค้า: "{msg}"')
        print(f"{tag} | source: {r['source']}" + (f" | topic: {r['topic']}" if r.get("topic") else ""))
        print(f"บอท: {preview}")
        if r.get("links"):
            print("ลิงก์:", ", ".join(r["links"]))
        print()

    out = ROOT / "scripts/chat_pov_test_results.txt"
    with out.open("w", encoding="utf-8") as f:
        for row in results:
            f.write("\n".join([str(x) for x in row if x]) + "\n---\n")
    print(f"Saved: {out}")


if __name__ == "__main__":
    main()
