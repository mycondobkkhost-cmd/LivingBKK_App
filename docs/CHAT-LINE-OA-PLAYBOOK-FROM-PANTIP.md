# RealXtate Chat — Playbook จากประวัติ LINE OA (Pantip)

**แหล่ง:** `pantip-property-automation` (chat.line.biz scrape + FAQ draft)  
**ผสานเข้า:** `chat_conversational_openai.ts`, `chat_ai_voice.ts`, `chat_bot_training_settings.ts`  
**อัปเดต:** 2026-07-12

---

## สิ่งที่เรียนรู้จากแชทจริง (~30 ห้องลึก / ~1000 ห้อง audit)

**เอาแค่หลักการ — ไม่เอาชื่อคน / โทนครับ / สต็อกแบรนด์อื่น**

1. โทนผู้หญิง **ค่ะ** ตาม RealXtate เดิม (ห้าม ครับ / ห้ามชื่อแอดมินแบรนด์อื่น เช่น นัท)
2. **ไม่มั่นใจ → อย่าตอบซี้ซั้ว** (ว่าง/ราคา/มัดจำ/สัญญา/เบอร์) — holding / coach / ถามเจ้าของ
3. **มั่นใจแล้ว (owner ยืนยันเคส / มีสถานะชัดในข้อมูล) → ยืนยันลูกค้าได้** ไม่ต้องลังเลเกินจำเป็น
4. สั้น ชัด หนึ่งงานต่อบับเบิล — ไม่มโนรายละเอียดที่ไม่มีใน listing

ไฟล์ต้นทาง (อ้างอิงแพทเทิร์นเท่านั้น):

- `/Users/angkarn1996/Projects/pantip-property-automation/line_bot/FAQ_DRAFT_สำหรับตรวจ.txt`
- `/Users/angkarn1996/Projects/pantip-property-automation/logs/line_study/full_threads_v2.json`

---

## แมปไป RealXtate

| บทเรียนจาก LINE | RealXtate |
|-----------------|-----------|
| โทน ค่ะ สั้นๆ | `AI_VOICE_RULE` (คงโทนผู้หญิง — ไม่พอร์ต ครับ) |
| ไม่มโนว่าง/ราคา | ไม่ invent; coach / owner_inquiry เมื่อไม่แน่ใจ |
| Owner ยืนยันแล้ว | ยืนยันลูกค้าได้จาก LISTING DATA / เคสที่ยืนยันแล้ว |
| นัดชม + โปรไฟล์ | `cta=viewing` — ห้ามยืนยันเวลานัดทันทีจนกว่า ops ยืนยัน |
| Handoff | Coach lane + admin console |

---

## สต็อกประโยค RealXtate (จากแพทเทิร์น LINE)

ดู constants ใน `supabase/functions/_shared/chat_ai_voice.ts`:

- `LINE_OA_STOCK.checkStatus`
- `LINE_OA_STOCK.askTenantProfile`
- `LINE_OA_STOCK.negotiateAskOwner`
- `LINE_OA_STOCK.notVacantAskBrief`
- `LINE_OA_STOCK.discoveryAskBrief`

ใช้เป็น **policy idea** ใน prompt — LLM สังเคราะห์ใหม่ ห้าม copy เป๊ะทุกครั้ง

---

## สิ่งที่ไม่พอร์ต

- ชื่อแอดมิน / เบอร์โทร Pantip (นัท ฯลฯ)
- Welcome โทน「ครับ」
- LINE auto-menu 01–04
- กฎ “ห้ามยืนยันว่างเสมอ” — RealXtate **ยืนยันได้เมื่อข้อมูล/owner ชัด**

---

## วิธีเทส

### 1) แซนด์บ็อกซ์ใน Admin (เร็วสุด)

1. Deploy edge ถ้ายังไม่ได้: `supabase functions deploy chat-turn`
2. เปิด **http://127.0.0.1:7357/admin?nav=chatBotTraining**
3. แท็บเทรนบอท → แผง **Sandbox** (จำลองลูกค้า)
4. เคสแนะนำ:

| เคส | พิมพ์ประมาณนี้ | ผลที่คาด |
|-----|----------------|----------|
| ไม่มั่นใจ / ไม่มีสถานะ | 「ห้องนี้ยังว่างไหมคะ」บนทรัพย์ที่ไม่มีอัปเดตชัด | holding เช็คก่อน / ไม่มโนว่าง |
| มั่นใจหลัง owner ยืนยัน | ทรัพย์ที่มีสถานะว่างชัดจากระบบ | ยืนยันว่างได้ + ชวนนัดดู |
| ต่อราคา | 「ลดเหลือ 15k ได้ไหม」 | ถามเจ้าของ/งบ — ไม่สัญญาเลขเอง |
| โทน | ทัก「สวัสดี」 | **ค่ะ** เท่านั้น ไม่มีครับ / ไม่มีชื่อคนอื่น |

กด **ผ่าน/ไม่ผ่าน** ใน sandbox เพื่อเก็บ feedback

### 2) แชทจริง (หลังล็อกอิน)

เปิดแชทจากหน้ารายละเอียดทรัพย์ → ถามชุดเดียวกับตารางด้านบน → ดูใน Admin console ว่ามี coach เมื่อ AI ไม่มั่นใจ

### 3) สคริปต์ POV (ถ้ามี seed)

ดู `scripts/run_chat_pov_test.ts` / `docs/CHAT-CONVERSATIONAL-ARCHITECTURE.md` — ใช้วัด regression ของ pipeline ไม่ใช่แทน sandbox โทน

---

## Deploy ที่เกี่ยวกับโทน/playbook

```bash
supabase functions deploy chat-turn
```

(ถ้าแก้ coach ด้วย: `chat-admin-coach-reply`)
