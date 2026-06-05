# ใส่แผนที่ Google (ทำครั้งเดียว)

แอปรันได้แล้ว — แผนที่ต้องมี key จาก Google (ผมสร้างแทนคุณไม่ได้)

1. เปิด https://console.cloud.google.com
2. เปิด API: **Maps JavaScript API**
3. สร้าง **API key** → Copy
4. ส่ง key ให้คนที่ช่วยตั้ง หรือใส่เองในไฟล์ `.env.local` บรรทัด `GOOGLE_MAPS_API_KEY=`
5. รันใน Terminal:

```bash
cd /Users/angkarn1996/Desktop/LivingBKK_App
./scripts/sync-env.sh
./scripts/run-app.sh
```
