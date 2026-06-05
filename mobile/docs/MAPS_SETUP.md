# Google Maps — LivingBKK Mobile

## 1. API Key

1. https://console.cloud.google.com  
2. Enable APIs:
   - **Maps JavaScript API** (จำเป็นสำหรับ Chrome/Web)
   - **Maps SDK for Android** and **Maps SDK for iOS**
   - **Places API** (ค้นหาโครงการจาก Google ในช่องค้นหา)
3. Create API key → restrict by app bundle id if needed  

4. Add to `mobile/assets/env`:

```
GOOGLE_MAPS_API_KEY=AIza...
```

## 2. After `flutter create .`

### Android — `android/app/src/main/AndroidManifest.xml`

Inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_KEY_HERE"/>
```

### iOS — `ios/Runner/AppDelegate.swift`

```swift
import GoogleMaps

// in application:didFinishLaunchingWithOptions:
GMSServices.provideAPIKey("YOUR_KEY_HERE")
```

Also add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>ใช้ตำแหน่งเพื่อแสดงทรัพย์ใกล้คุณ</string>
```

### iOS Podfile

Ensure platform iOS 14+ in `ios/Podfile`.

## 3. Web (Chrome) — สำคัญ

แก้ `mobile/web/index.html` บรรทัด Google Maps script:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=AIza...คีย์เดียวกับ env"></script>
```

คีย์ใน `assets/env` อย่างเดียว **ไม่พอ** สำหรับ Flutter Web

## 4. Run

```bash
flutter pub get
flutter run -d chrome
```

Without key → fallback UI (ข้อความแนะนำใส่คีย์) · แผนที่จริงใน ค้นหา / รายละเอียดทรัพย์ / Admin นัดชม
