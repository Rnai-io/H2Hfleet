# 🚀 H2H Fleet — คู่มืออัปขึ้น Google Play Store

อัปเดตล่าสุด: 31 ส.ค. 2026 · Application ID: `com.h2hfleet.app` · เวอร์ชัน `1.1.0+5`

---

## 🔑 ข้อมูล Keystore — เก็บให้ดีที่สุด

| รายการ | ค่า |
|---|---|
| ไฟล์ | `h2hfleet/android/upload-keystore.jks` (PKCS12) |
| Alias | `h2hfleet-upload` |
| Password (ทั้ง store และ key) | `vtdLUGktyJXB1nErYAbic4T6bhkf` |
| หมดอายุ | 16 ม.ค. 2597 |
| SHA-256 | `1C:B7:95:7A:03:66:0A:DC:89:9A:F8:E4:4A:28:20:02:FB:7E:77:3F:5D:7F:5D:B4:3A:06:42:9B:EF:FC:25:5B` |

> ⚠️ **ถ้าไฟล์นี้หายหรือลืมรหัส คุณจะอัปเดตแอปตัวเดิมไม่ได้อีกเลย** ต้องขึ้นแอปใหม่ทั้งหมด
> - สำรอง `upload-keystore.jks` + `key.properties` ไว้นอกโฟลเดอร์โปรเจกต์ (1Password / Google Drive ส่วนตัว / external drive)
> - ทั้งสองไฟล์ถูก gitignore ไว้แล้ว จะไม่ขึ้น GitHub
> - เปิด **Play App Signing** ตอนสร้างแอปใน Play Console → Google จะถือ app signing key ให้ ไฟล์นี้จะเป็นแค่ *upload key* ที่ขอรีเซ็ตได้ถ้าหาย (ปลอดภัยกว่ามาก **แนะนำอย่างยิ่ง**)

---

## ✅ สิ่งที่เตรียมให้แล้ว

| รายการ | สถานะ | ที่อยู่ |
|---|---|---|
| Application ID เปลี่ยนจาก `com.example.h2hfleet` | ✅ | `android/app/build.gradle.kts` |
| MainActivity ย้าย package | ✅ | `android/app/src/main/kotlin/com/h2hfleet/app/` |
| Upload keystore (PKCS12, 10,000 วัน) | ✅ | `android/upload-keystore.jks` |
| Release signing config | ✅ | `android/key.properties` + gradle |
| AndroidManifest: permissions + label "H2H Fleet" | ✅ | `android/app/src/main/AndroidManifest.xml` |
| Native debug symbols (crash report อ่านออก) | ✅ | `build.gradle.kts` → `debugSymbolLevel` |
| ปิด language split (กัน asset ภาษาหาย) | ✅ | `build.gradle.kts` → `bundle {}` |
| ProGuard rules (เตรียมไว้ ยังไม่เปิด R8) | ✅ | `android/app/proguard-rules.pro` |
| Launcher icon + adaptive icon | ✅ | มีครบทุก density แล้ว |
| App icon 512×512 | ✅ | `store/play/graphics/play_icon_512.png` |
| Feature graphic 1024×500 | ✅ | `store/play/graphics/feature_graphic_1024x500.png` |
| คำอธิบายไทย/อังกฤษ | ✅ | `LISTING_TH.md`, `LISTING_EN.md` |
| คำตอบ Data safety | ✅ | `DATA_SAFETY.md` |
| สเปกภาพหน้าจอ | ✅ | `SCREENSHOT_SPEC.md` |

## ⚙️ ต้องรันใน Supabase ก่อน (SQL Editor → New Query → RUN)

| ลำดับ | ไฟล์ | ทำอะไร |
|---|---|---|
| 1 | `SUPABASE_ACCOUNT_DELETION.sql` | ติดตั้งฟังก์ชันลบบัญชี — ถ้าไม่รัน ปุ่มลบบัญชีในแอปจะขึ้น error |
| 2 | `SUPABASE_REVIEWER_DEMO_SEED.sql` | สร้างข้อมูลตัวอย่างให้บัญชี reviewer (ต้องสร้าง auth user ก่อน ดู `REVIEWER_ACCESS.md`) |

เพิ่มใน Supabase → Authentication → **URL Configuration → Redirect URLs**:
```
com.h2hfleet.app://login-callback/
```

## ❌ สิ่งที่คุณต้องทำเอง

| รายการ | ทำไม |
|---|---|
| รัน SQL 2 ไฟล์ด้านบน | ปุ่มลบบัญชีและบัญชี reviewer ต้องใช้ |
| `git push` ให้ GitHub Pages อัปเดต | `delete-account.html` และ privacy policy ที่แก้แล้วต้องเข้าถึงได้สาธารณะ |
| ทดสอบปุ่มลบบัญชีด้วยบัญชีทิ้ง | ลบแล้วกู้ไม่ได้ ห้ามทดสอบด้วยบัญชีหลัก |
| ภาพหน้าจอ 2–8 ภาพ | `SCREENSHOT_SPEC.md` |
| สมัคร Play Console ($25 ครั้งเดียว) + ยืนยันตัวตน | ใช้เวลา 1–3 วัน |

---

## 📦 ขั้นตอนที่ 1 — บิลด์ AAB

รันบนเครื่อง Mac ของคุณ (โฟลเดอร์นี้ยังไม่มี Flutter ติดตั้งใน sandbox)

```bash
cd ~/projects/H2Hfleet/h2hfleet

# ล้างของเก่าทิ้ง (สำคัญ เพราะเปลี่ยน package name)
flutter clean
flutter pub get

# ตรวจว่าไม่มี error ก่อน
flutter analyze

# สร้าง launcher icon ใหม่ (ถ้าเปลี่ยนไอคอน)
dart run flutter_launcher_icons

# บิลด์ App Bundle สำหรับ Play Store
flutter build appbundle --release
```

ได้ไฟล์ที่: `build/app/outputs/bundle/release/app-release.aab`

### ตรวจว่าเซ็นถูกต้องแล้ว

```bash
# ต้องเห็น applicationId = com.h2hfleet.app
unzip -p build/app/outputs/bundle/release/app-release.aab base/manifest/AndroidManifest.xml | strings | grep -i h2hfleet

# ต้องเห็น alias h2hfleet-upload ไม่ใช่ androiddebugkey
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab | head -20
```

### ทดสอบตัว release ก่อนอัป (ห้ามข้าม)

```bash
# ติดตั้งลงเครื่องจริงในโหมด release
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

ต้องเช็ก: ล็อกอินได้ · แผนที่ขึ้น · ขอสิทธิ์ GPS แล้วเห็นตำแหน่ง · ถ่ายรูปใบเสร็จได้ · AI chat ตอบ · ไม่มีจอขาว

---

## 🏪 ขั้นตอนที่ 2 — สร้างแอปใน Play Console

1. เข้า https://play.google.com/console → **Create app**
2. กรอก:
   - App name: `H2H Fleet – จัดการกองรถ GPS`
   - Default language: **ไทย (th-TH)**
   - App or game: **App**
   - Free or paid: **Free**
   - ติ๊กยอมรับ Developer Program Policies + US export laws
3. เมื่อสร้างเสร็จ ไปที่ **Release → Setup → App integrity** → เปิด **Play App Signing** (เปิดโดยดีฟอลต์อยู่แล้ว อย่าปิด)

---

## 📝 ขั้นตอนที่ 3 — กรอก Dashboard ให้ครบทุกช่อง

Play Console จะไล่เช็กลิสต์ให้ ต้องเขียวครบถึงจะส่งได้

### Store listing (Grow → Store presence → Main store listing)
- App name / Short description / Full description → คัดลอกจาก `LISTING_TH.md`
- App icon → `graphics/play_icon_512.png`
- Feature graphic → `graphics/feature_graphic_1024x500.png`
- Phone screenshots → อย่างน้อย 2 ภาพ ดู `SCREENSHOT_SPEC.md`
- เพิ่มภาษา **English (United States)** → คัดลอกจาก `LISTING_EN.md`

### App content (Policy → App content)
กรอกตาม `DATA_SAFETY.md` ทั้งหมด — Privacy policy, Ads, App access, Content rating, Target audience, Data safety, Government apps, Financial features, Health

### Store settings
- Category: **Business**
- Contact email / website
- Tags

---

## 🧪 ขั้นตอนที่ 4 — Closed testing (บังคับสำหรับบัญชีใหม่)

> บัญชี developer ส่วนบุคคลที่สมัครใหม่ ต้องผ่าน **closed test กับผู้ทดสอบอย่างน้อย 12 คน ต่อเนื่อง 14 วัน** ก่อนถึงจะขอเปิด production ได้
> บัญชีองค์กร (organization) ไม่ต้องผ่านข้อนี้ — ถ้าจะขึ้นเร็ว ให้สมัครแบบ organization

1. **Testing → Closed testing → Create new release**
2. อัปโหลด `app-release.aab`
3. Release name: `1.1.0 (5)`
4. Release notes ภาษาไทย:
   ```
   <th-TH>
   เวอร์ชันแรกของ H2H Fleet
   • ติดตามตำแหน่งรถแบบเรียลไทม์บนแผนที่
   • บันทึกค่าน้ำมัน ค่าซ่อม พร้อมแนบรูปใบเสร็จ
   • แจ้งเตือนกำหนดซ่อมบำรุงและต่อภาษี
   • ผู้ช่วย AI ภาษาไทย สรุปข้อมูลกองรถ
   </th-TH>
   ```
5. สร้าง email list ผู้ทดสอบ 12+ คน → **Testers** tab
6. ส่งลิงก์ opt-in ให้ทุกคนกดเข้าร่วมและติดตั้งจริง
7. รอครบ 14 วันโดยมีคน opt-in อยู่ต่อเนื่อง

---

## 🌏 ขั้นตอนที่ 5 — Production

1. **Production → Create new release** → อัปโหลด AAB ตัวเดิมหรือใหม่กว่า
2. **Countries/regions** → เลือกไทยก่อน หรือทั้งอาเซียนตามแผนธุรกิจ
3. **Send for review**
4. รอ review ปกติ 1–7 วัน (ครั้งแรกมักนานกว่า)

---

## 🔁 อัปเดตครั้งถัดไป

```bash
# 1) แก้เลขเวอร์ชันใน pubspec.yaml เช่น 1.1.1+6  (เลขหลัง + ต้องเพิ่มเสมอ)
# 2) บิลด์ใหม่
flutter build appbundle --release
# 3) Production → Create new release → อัปโหลด → rollout
```

---

## 🆘 ปัญหาที่เจอบ่อย

| อาการ | สาเหตุ / วิธีแก้ |
|---|---|
| `Keystore file not found` | `storeFile` ใน `key.properties` ต้องเป็น `../upload-keystore.jks` (อ้างอิงจาก `android/app/`) |
| `Package name already exists` | มีคนใช้ `com.h2hfleet.app` แล้ว ต้องเปลี่ยนเป็นชื่ออื่นแล้วบิลด์ใหม่ |
| `You uploaded an APK signed with debug key` | `key.properties` ไม่ถูกอ่าน → เช็กว่าไฟล์อยู่ที่ `android/key.properties` |
| `Version code 5 has already been used` | เพิ่มเลขหลัง `+` ใน pubspec.yaml |
| จอขาวหลังติดตั้งจาก Play | มัก proguard/R8 → ตอนนี้ปิดไว้แล้ว ถ้าเปิดต้องเพิ่ม keep rules |
| `Target API level requirement` | Flutter จัดการให้อัตโนมัติ ถ้าโดนเตือนให้อัป Flutter แล้วบิลด์ใหม่ |
| แผนที่ไม่ขึ้นในตัว release | เช็ก INTERNET permission และ network security config |
