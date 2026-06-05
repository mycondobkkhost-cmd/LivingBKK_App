# LivingBKK — แก้ปัญหา Flutter / Supabase

## สภาพเครื่องคุณ (ตรวจแล้ว)

| รายการ | สถานะ |
|--------|--------|
| macOS | **12.6** (Monterey) |
| Flutter stable ล่าสุด | ต้องการ macOS **14+** → ใช้ **Flutter 3.19.6** แทน |
| Xcode | ยังไม่ติดตั้งครบ → รันบน **Chrome** ได้ |
| Homebrew | ไม่มีใน PATH → ติดตั้ง Flutter/Supabase CLI แบบ manual แล้ว |

## PATH ที่ติดตั้งแล้ว

เพิ่มใน `~/.zshrc`:

```bash
source /Users/angkarn1996/Desktop/LivingBKK_App/scripts/dev-path.sh
```

จากนั้น `source ~/.zshrc`

- Flutter: `/Users/angkarn1996/development/flutter` (3.19.6)
- Supabase CLI: `/Users/angkarn1996/.local/bin/supabase`

---

## รันแอป (Chrome — แนะนำบน macOS 12)

```bash
cd /Users/angkarn1996/Desktop/LivingBKK_App/mobile
flutter pub get
flutter run -d chrome
```

หรือ:

```bash
chmod +x /Users/angkarn1996/Desktop/LivingBKK_App/scripts/run-chrome.sh
/Users/angkarn1996/Desktop/LivingBKK_App/scripts/run-chrome.sh
```

เปิดเบราว์เซอร์: http://localhost:8080 (หรือ URL ที่ Terminal แสดง)

---

## ตั้งค่า Supabase (Cloud)

1. สร้างโปรเจกต์ที่ https://supabase.com/dashboard  
2. แก้ `mobile/assets/env`:

```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
```

3. ใน Terminal:

```bash
cd /Users/angkarn1996/Desktop/LivingBKK_App
supabase login
supabase link --project-ref YOUR_REF
supabase db push
```

4. ตั้ง Admin (SQL Editor):

```sql
UPDATE profiles SET role = 'admin' WHERE id = 'YOUR_USER_UUID';
```

---

## ทางเลือกถ้าไม่ต้องการ Flutter บน Mac 12

ใช้ **FlutterFlow** ตาม [flutterflow-setup.md](flutterflow-setup.md) — build บนคลาวด์ ไม่ต้องพึ่ง Xcode บนเครื่อง

---

## อัปเกรด macOS (แนะนำระยะยาว)

Mac Mini M2 รองรับ **macOS Sonoma (14)** หรือใหม่กว่า → ติดตั้ง Flutter stable ล่าสุด + Xcode จาก App Store ได้เต็มรูปแบบ
