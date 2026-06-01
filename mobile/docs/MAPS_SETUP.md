# Google Maps — LivingBKK Mobile

## 1. API Key

1. https://console.cloud.google.com  
2. Enable **Maps SDK for Android** and **Maps SDK for iOS**  
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

## 3. Run

```bash
flutter pub get
flutter run
```

Without key → fallback UI แต่ยังใช้「ใกล้ฉัน」ได้ (เลื่อนกล้องเมื่อมี Maps)
