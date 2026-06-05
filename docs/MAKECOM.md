# Make.com → Google Sheets (Admin)

ดึงเฉพาะ **สถิติ** ไม่ดึงเบอร์โทรเต็ม

## แหล่งข้อมูล

View ใน Supabase (แนะนำ — รวม Lead + นัดชม):

```sql
SELECT * FROM platform_stats_daily ORDER BY stat_date DESC LIMIT 30;
```

คอลัมน์: `stat_date`, `lead_count`, `accepted_count`, `new_count`, `appointment_count`, `appointment_confirmed_count`, `appointment_completed_count`

เฉพาะ Lead:

```sql
SELECT * FROM lead_stats_daily ORDER BY stat_date DESC LIMIT 30;
```

## Scenario แนะนำ

1. **Schedule** ทุก 1 ชั่วโมง  
2. **HTTP** → Supabase REST  
   - URL: `{SUPABASE_URL}/rest/v1/platform_stats_daily?order=stat_date.desc&limit=7`  
   - Header: `apikey: {SERVICE_ROLE_KEY}`  
   - Header: `Authorization: Bearer {SERVICE_ROLE_KEY}`  
3. **Google Sheets** → Append row  

## ข้อห้าม

- อย่า sync ตาราง `leads`, `demand_offers` ไปชีตเปิด  
- อย่าใส่ `seeker_phone` ใน Sheets  

## Webhook (ทางเลือก)

เมื่อ insert `leads` → webhook ไป Make.com → แจ้ง Slack/Line ทีมงาน (ไม่ส่ง PII เต็ม)
