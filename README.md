# Chớp Chớp Quiz

Game đố vui nhanh 120 giây: đúng +1 sao, sai về 0 sao, câu hỏi khó dần.

## Chạy

```bash
flutter pub get
flutter test
flutter run
```

- iOS: `com.tranbang.chopChopQuiz`
- Android: `com.tranbang.chop_chop_quiz`
- Khóa dọc.
- Điểm cao = số sao cao nhất trong 1 lượt; gửi lên Game Center / Play Games. ID console nằm ở `lib/config/leaderboard_ids.dart`.
- Ảnh store: `store/graphics/` (icon, feature graphic, screenshot Play và App Store 6.7"). Listing: `store/listing.md`.

## Âm thanh (CC0, miễn phí thương mại)

- Nhạc menu: *Happy Vibes* — Ruskerdax (OpenGameArt)
- Nhạc lúc chơi: *Puzzling* — Ruskerdax (OpenGameArt)
- Hiệu ứng (đúng, sai, tick đồng hồ, bắt đầu, hết giờ…): Kenney Interface Sounds (kenney.nl)

Không bắt buộc ghi công. Tắt/bật nhạc và SFX ở góc màn hình Home và Play.

## Quảng cáo

Debug dùng test ID của Google. Trước khi lên store:

- `lib/config/ad_ids.dart`: điền 6 ad unit ID.
- `android/admob.properties` (copy từ `android/admob.properties.example`): AdMob **Android App ID**.
- `ios/Runner/Info.plist` → `GADApplicationIdentifier`: AdMob **iOS App ID**.

Banner ở Home, Cách chơi và Play. Rewarded ở màn hình "Sẵn sàng" (1 lần/lượt) → +5 giây. Interstitial sau lượt thứ 5, 10, 15...

## Android

Play Console: Play Games Services → tạo game + 1 bảng xếp hạng (score "Larger is better", số nguyên). Dán:

- Project ID số vào `android/app/src/main/res/values/strings.xml` (`game_services_project_id`)
- Leaderboard ID vào `LeaderboardIds.android`

Ký release: tạo `android/key.properties` trỏ tới keystore (file này không commit).

## iOS

- Xcode → Signing & Capabilities → **Game Center** (đã bật qua `Runner.entitlements`).
- App Store Connect → Game Center → tạo leaderboard, ID khớp `LeaderboardIds.ios`.
- Nếu dùng ATT/UMP cho quảng cáo cá nhân hoá, bổ sung `NSUserTrackingUsageDescription` và form đồng ý (UMP) theo yêu cầu khu vực.

## Thêm câu hỏi

Hiện có **3000 câu** trong `assets/data/questions.json` (14 chủ đề). Thêm object vào `questions` với đúng schema:
`id, topic, difficulty (easy|medium|hard), question, options (4), correct_index, correct_answer, explanation, time_limit_sec`.
Game tự nhận, không cần sửa code.

## Quy tắc

- 120 giây/lượt; xem Rewarded ở màn hình "Sẵn sàng" (1 lần/lượt) → +5 giây.
- Độ khó theo số sao: 0–2 chủ yếu Dễ, 3–5 Vừa, 6–8 Vừa/Khó, ≥9 chủ yếu Khó (chỉnh ở `_pickDifficulty` trong `question_repository.dart`).
- Điểm lên bảng xếp hạng = số sao cao nhất trong 1 lượt.
