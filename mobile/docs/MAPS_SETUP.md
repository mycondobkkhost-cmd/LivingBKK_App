# Google Maps — RealXtate Mobile

## 1. API Key

1. https://console.cloud.google.com  
2. Enable APIs:
   - **Maps JavaScript API** (จำเป็นสำหรับ Chrome/Web)
   - **Maps SDK for Android** and **Maps SDK for iOS**
   - **Places API (New)** — ค้นหาโครงการ / geocode
   - **Geocoding API** — fallback ดึงพิกัดจากชื่อ (Edge `maps-share-resolve`)
3. Create API key → restrict by HTTP referrer (web) / bundle id (iOS) / package (Android) ตามแพลตฟอร์ม  

4. ใส่ใน `.env.local` แล้วรัน sync:

```bash
# .env.local
GOOGLE_MAPS_API_KEY=AIza...
GOOGLE_MAPS_WEB_USE_OSM=false   # true = บังคับ OSM บน web

./scripts/sync-env.sh
# หรือ ./scripts/setup-google-maps.sh
```

`sync-env.sh` จะอัปเดต:
- `mobile/assets/env`
- `mobile/web/index.html` (Maps JS + `gm_authFailure` → fallback OSM)
- `mobile/android/local.properties`
- `mobile/ios/Runner/AppDelegate.swift` (**ครั้งเดียว** ไม่ซ้อน `GMSServices`)

ตรวจ key:

```bash
./scripts/verify-google-maps-key.sh
```

## พิกัดโครงการจริง + UI แผนที่

- Bootstrap `mobile/lib/data/bangkok_projects.dart` และ migration
  `supabase/migrations/20260713120000_property_projects_google_places_coords.sql`
  ผูกพิกัดจาก **Places API (New) searchText**
- แอดมิน → แก้โครงการ → **ค้นหาพิกัดบน Google Maps** (`project-geocode-preview`)
- `ListingsMap` / `AppointmentsMap` ใช้สไตล์สะอาด (`GoogleMapCleanStyle`) · หมุดราคาขาว · ปุ่ม Near me แบบ Google

## 2. After `flutter create .`

### Android — `android/app/src/main/AndroidManifest.xml`

Inside `<application>` (มีอยู่แล้วผ่าน `${googleMapsApiKey}`):

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${googleMapsApiKey}"/>
```

### iOS — `ios/Runner/AppDelegate.swift`

```swift
import GoogleMaps

// in application:didFinishLaunchingWithOptions:
GMSServices.provideAPIKey("AIza...") // LIVINGBKK_GOOGLE_MAPS_INIT
```

Also add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>ใช้ตำแหน่งเพื่อแสดงทรัพย์ใกล้คุณ</string>
```

### iOS Podfile

Ensure platform iOS 14+ in `ios/Podfile`.

## 3. Web (Chrome) — สำคัญ

`sync-env.sh` ใส่ script ให้แล้ว — คีย์ใน `assets/env` อย่างเดียว **ไม่พอ** สำหรับ Flutter Web

ถ้า Maps JS auth ล้มเหลว (Referer / billing) แอปจะสลับไป **OSM** อัตโนมัติ

## 4. Supabase Edge (ลิงก์สั้น maps.app.goo.gl)

```bash
supabase secrets set GOOGLE_MAPS_API_KEY=AIza...
supabase functions deploy maps-share-resolve --use-api
```

## 5. Run

```bash
./scripts/restart-cursor-dev.sh   # preview :7357
# หรือ
flutter run -d chrome
```

Without key / OSM forced → `OsmListingsMap` · มี key → `GoogleMap` ใน ค้นหา / รายละเอียด / Admin นัดชม
