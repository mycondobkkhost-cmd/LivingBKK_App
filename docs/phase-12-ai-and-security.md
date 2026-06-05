# Phase 12: AI Search + Security + Verify

**Status:** Implemented  
**Date:** 2026-06-02

---

## Delivered

| Feature | Location |
|---------|----------|
| OpenAI ใน `smart-search-parse` (ทางเลือก) | `_shared/search_parse_openai.ts` |
| Rule-based fallback เสมอ | `_shared/search_parse_stub.ts` |
| ห้ามตั้ง `role=admin` เอง | migration `20260602120022` |
| แอป: ซ่อนปุ่ม Admin ในโปรไฟล์ | `profile_page.dart` (ยกเว้น admin จริง / Demo) |
| สรุปสิ่งที่เหลือ | [ROADMAP-REMAINING.md](ROADMAP-REMAINING.md) |
| ตรวจพร้อม deploy | `scripts/verify-ready.sh` |

---

## OpenAI (ทางเลือก)

ตั้งใน Supabase Edge secrets:

```
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini   # ทางเลือก
```

Deploy:

```bash
supabase functions deploy smart-search-parse
```

Response มี `source`: `"openai"` หรือ `"rules"`

---

## Security

ผู้ใช้ทั่วไป **เปลี่ยน role เป็น admin ในแอปไม่ได้** — ใช้ SQL / `demo-admin` ตาม [บัญชี-admin.md](บัญชี-admin.md)

---

## Next

- ~~Phase 13 เว็บมือถือ~~ → [phase-13-เปิดใช้บนมือถือ.md](phase-13-เปิดใช้บนมือถือ.md)  
- ดู [ROADMAP-REMAINING.md](ROADMAP-REMAINING.md)
