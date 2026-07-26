# Phase 29: Admin Chat Bot Training

**Status:** Implemented (Flutter + Edge `chat-turn`)  
**Brand:** RealXtate

---

## เป้าหมาย

เมนูหลังบ้าน **เทรนบอท AI** — แก้ FAQ · ความจำ coach · ตรรกะการสื่อสารจากในแอป

| แท็บ | ตาราง / ที่เก็บ |
|------|----------------|
| FAQ | `chat_faq_rules` |
| ความจำ | `chat_learned_answers` |
| ตรรกะ | `chat_bot_training_settings` (singleton `default`) |

---

## Preview

http://127.0.0.1:7357/admin?nav=chatBotTraining

Legacy `/admin/faq` → redirect มาหน้านี้

---

## Edge

- `_shared/chat_bot_training_settings.ts` — โหลด settings
- `chat-turn` ส่ง `botTraining` เข้า router
- `chat_conversational_openai.ts` — รวม `voice_extra_rules` + `strategy_hints` ใน system prompt

---

## Migration

`20260617150000_chat_bot_training_settings.sql`
