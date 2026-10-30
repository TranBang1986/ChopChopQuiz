# Store launch — checklist

Ảnh, bản mô tả, ID AdMob/Play Games trong code đã sẵn. Việc còn lại chủ yếu là host URL và thao tác trên console.

## Ảnh

| File | Dùng cho | Kích thước |
|---|---|---|
| `store/graphics/play_icon_512.png` | Play icon | 512×512 |
| `store/graphics/app_icon_1024.png` | App Store icon | 1024×1024 |
| `store/graphics/play_feature_1024x500.png` | Play feature graphic | 1024×500 |
| `store/graphics/play_phone_01_home.png` | Play screenshot | 1080×1920 |
| `store/graphics/play_phone_02_play.png` | Play screenshot | 1080×1920 |
| `store/graphics/play_phone_03_guide.png` | Play screenshot | 1080×1920 |
| `store/graphics/appstore_67_01_home.png` | App Store 6.7" | 1290×2796 |
| `store/graphics/appstore_67_02_play.png` | App Store 6.7" | 1290×2796 |
| `store/graphics/appstore_67_03_guide.png` | App Store 6.7" | 1290×2796 |
| `store/graphics/splash_1080x1920.png` | Ảnh splash (nguồn) | 1080×1920 |

Icon đã gắn vào Android (`mipmap-*/ic_launcher`) và iOS (`AppIcon.appiconset`). Bản gốc: `assets/icon/app_icon_1024_square.png`. Splash đã gắn Android (`drawable-nodpi/launch_bg.png`) và iOS (`LaunchImage.imageset`).

Xuất lại ảnh:

```bash
STORE_EXPORT=1 flutter test test/store_export_test.dart
python3 tool/compose_store_graphics.py
dart run flutter_launcher_icons
```

## Listing

Dán nội dung `store/listing.md`.

## Chính sách quyền riêng tư

Bản nháp: `docs/privacy-policy.html`. Email: `tranbang13@gmail.com`. Host xong rồi dán URL vào Play Console và App Store Connect.

## app-ads.txt

Nội dung: `docs/app-ads.txt` (cùng publisher AdMob `pub-8986841471505348`). Host tại `https://<domain>/.well-known/app-ads.txt` hoặc `https://<domain>/app-ads.txt`, rồi khai báo domain đó trong AdMob.

## 1. AdMob — đã điền trong code

Debug vẫn dùng ID test của Google. Release dùng ID production.

- Android App ID: `ca-app-pub-8986841471505348~1322961501` (`android/admob.properties`, không commit)
- iOS App ID: `ca-app-pub-8986841471505348~9755985297` (`ios/Runner/Info.plist`)
- Banner / interstitial / rewarded: `lib/config/ad_ids.dart`

## 2. Leaderboard

- Android Play Games: project `333722417943`, leaderboard `CgkIl_afm9sJEAIQAg` (đã điền).
  Upload key SHA-1 (keystore local): `E9:31:80:29:29:AD:89:BA:EB:57:97:48:0D:C0:CA:0A:DE:63:74:F7`.
  Play App Signing SHA-1 (cài từ Play): `86:55:E8:EF:B6:05:CD:B9:77:4E:95:1A:02:E3:FC:2B:6B:57:6E:CF`.
  Debug SHA-1 (S9 debug): `55:EE:77:95:EB:10:4A:D7:5B:15:A7:E4:9D:AA:6A:46:18:14:5A:B6`.
  Cả ba nên có trong Play Games → Credentials.
- iOS: tạo leaderboard Game Center đúng ID `com.tranbang.chopChopQuiz.best_stars` trên App Store Connect (entitlements đã bật).

## 3. Ký Android

- `android/key.properties` + `secrets/upload-keystore.p12` (không commit). Backup mật khẩu: `secrets/BACKUP.txt`.
- Build store: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.

## 4. Còn làm trên console (không nằm trong repo)

**Play Console**
- Tạo app `com.tranbang.chop_chop_quiz`, upload AAB.
- Dán listing, icon, feature graphic, 2+ screenshot.
- Privacy policy URL công khai.
- Content rating, target audience, Data safety, ads declaration.
- Play Games đã Publish + testers.

**App Store Connect**
- Tạo app `com.tranbang.chopChopQuiz`, team `58Y5M7MWAM`.
- Privacy policy URL, screenshots 6.7", icon 1024.
- Game Center: bật + tạo leaderboard `com.tranbang.chopChopQuiz.best_stars`.
- Export compliance: `ITSAppUsesNonExemptEncryption` = false trong Info.plist.
