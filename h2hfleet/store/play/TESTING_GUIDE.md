# 🧪 คู่มือทดสอบ H2HFleet บน Android Studio (Emulator)

อัปเดต: 31 ส.ค. 2026 · Application ID `com.h2hfleet.app` · SQL ทั้งสองไฟล์รันใน Supabase แล้ว

---

## 1. สร้าง Emulator

**Android Studio → Tools → Device Manager → Create Virtual Device**

| ตั้งค่า | ค่าที่แนะนำ | ทำไม |
|---|---|---|
| Device | **Pixel 7** (หรือ Pixel 6) | ความละเอียด 1080×2400 ตรงกับสเปกภาพหน้าจอที่ Play ต้องการพอดี |
| System image | **Android 14 (API 34)** ที่มีป้าย **Google Play** | ⚠️ สำคัญ — ต้องเป็นอิมเมจที่มี Play Services ไม่ใช่ตัว "Google APIs" เปล่า ๆ |
| RAM | 4096 MB ขึ้นไป | แผนที่ + realtime WebSocket กินหน่วยความจำพอสมควร |
| Graphics | Hardware - GLES 2.0 | แผนที่จะกระตุกถ้าใช้ software rendering |

**ทำไมต้องเป็นอิมเมจที่มี Google Play**

- `geolocator` เรียก **Fused Location Provider** ของ Play Services ถ้าไม่มีจะ fallback ไปใช้ LocationManager ซึ่งบน emulator มักคืนค่า null
- ปุ่ม "เข้าสู่ระบบด้วย Google" ต้องมี Play Services ถึงจะทดสอบได้

---

## 2. ⚠️ ตั้งพิกัด GPS ก่อนกด Run (ข้ามไม่ได้)

Emulator ที่เพิ่งสร้างจะ**ไม่มีพิกัดใด ๆ** ถ้าไม่ตั้ง โค้ดจะ timeout ใน 4 วินาที (`Geolocator.getCurrentPosition(timeLimit: 4s)`) แล้วแผนที่จะไม่แสดงตำแหน่งของคุณ — ดูเหมือนแอปพัง ทั้งที่จริงคือ emulator ไม่มีพิกัด

1. เปิด emulator แล้วกดปุ่ม **⋯ (Extended controls)** ที่แถบข้าง
2. เลือกแท็บ **Location**
3. ใส่พิกัดกรุงเทพฯ ให้ตรงกับข้อมูลเดโมที่ seed ไว้:

   | ช่อง | ค่า |
   |---|---|
   | Latitude | `13.7563` |
   | Longitude | `100.5018` |

4. กด **Set Location**

> อยากทดสอบรถวิ่ง: ในแท็บ Location มีโหมด **Routes** ให้ลากเส้นทางแล้วกด Play เพื่อจำลองการเคลื่อนที่ต่อเนื่อง เหมาะกับการทดสอบโหมดคนขับ

---

## 3. เลือก Run configuration

ผมเพิ่มไว้ให้ 2 อันแล้ว เลือกจาก dropdown มุมบนขวาของ Android Studio

| Configuration | ใช้เมื่อไหร่ |
|---|---|
| **H2HFleet (debug · hot reload)** | ตอนไล่ทดสอบทั่วไป แก้โค้ดแล้วกด ⚡ hot reload ได้ทันที |
| **H2HFleet (release · ตรวจก่อนอัป Play)** | รอบสุดท้ายก่อนอัปโหลด — เป็นโหมดเดียวกับที่ผู้ใช้จริงจะได้ |

ถ้าไม่เห็นใน dropdown ให้ปิดเปิด Android Studio หนึ่งครั้ง (ไฟล์อยู่ที่ `.idea/runConfigurations/`)

**ต้องทดสอบโหมด release อย่างน้อยหนึ่งรอบ** — บั๊กหลายอย่างโผล่เฉพาะ release เช่นแผนที่ไม่ขึ้นเพราะ permission หรือจอขาวเพราะ obfuscation

---

## 4. เช็กลิสต์ทดสอบ

### 4.1 เข้าสู่ระบบ

- [ ] เปิดแอปขึ้นหน้า Login ไม่ใช่จอขาว
- [ ] ล็อกอินด้วย `playreview@h2hfleet.app` / ➜ ดูใน `SECRETS.local.md` (ไม่อยู่ใน git)
- [ ] เข้าแดชบอร์ดได้ ไม่ต้องยืนยันอีเมลหรือ OTP

### 4.2 ข้อมูลจาก seed ขึ้นครบ

- [ ] แดชบอร์ดแสดง **รถ 5 คัน**
- [ ] ค่าใช้จ่ายเดือนนี้มีตัวเลข ไม่ใช่ 0
- [ ] รายการค่าใช้จ่ายล่าสุดขึ้น 5 รายการ
- [ ] หน้ารายการรถเห็นทะเบียน ดม-1001 ถึง ดม-1005

### 4.3 แผนที่และ GPS

- [ ] เปิดหน้าแผนที่ → ระบบขอสิทธิ์ตำแหน่ง (dialog ของ Android โผล่)
- [ ] กด **"ขณะใช้แอป"** → เห็นหมุดรถ 5 คันบนแผนที่
- [ ] กด **"ไม่อนุญาต"** ในอีกรอบ → หมุดรถยังต้องขึ้นเหมือนเดิม (เพราะพิกัดรถมาจากเซิร์ฟเวอร์ ไม่ใช่จากเครื่อง) — ข้อนี้ reviewer จะทดสอบแน่นอน
- [ ] แตะรถหนึ่งคัน → ดูประวัติเส้นทางย้อนหลังได้ (ดม-1001 มี 20 จุด, ดม-1003 มี 15 จุด)

### 4.4 ค่าใช้จ่ายและซ่อมบำรุง

- [ ] เพิ่มค่าใช้จ่ายใหม่ได้ บันทึกแล้วเห็นในรายการ
- [ ] แนบรูปใบเสร็จได้ (emulator: Photos มีรูปตัวอย่างให้เลือก หรือใช้กล้องจำลอง)
- [ ] หน้าซ่อมบำรุงเห็น 6 รายการ มีทั้งที่เลยกำหนด (ผ้าเบรก ดม-1002) และที่กำลังจะถึง

### 4.5 🆕 หน้าบัญชีของฉัน

- [ ] แดชบอร์ดมีเมนู **"บัญชีของฉัน"** (ไอคอนโล่สีเทาเข้ม)
- [ ] เปิดแล้วเห็นชื่อ อีเมล บทบาท OWNER และชื่อบริษัท
- [ ] กดลิงก์ **นโยบายความเป็นส่วนตัว** → เปิดเบราว์เซอร์ได้
- [ ] กดลิงก์ **วิธีขอลบบัญชีและข้อมูล** → เปิด delete-account.html ได้
- [ ] ปุ่มออกจากระบบทำงาน กลับมาหน้า Login

> ถ้าลิงก์เปิดไม่ได้บน emulator ให้เช็กว่า emulator ต่อเน็ตได้ (เปิด Chrome ใน emulator ลองเข้าเว็บ)

### 4.6 🆕 ลบบัญชี — ทดสอบด้วยบัญชีทิ้งเท่านั้น

⚠️ **ห้ามทดสอบด้วยบัญชี reviewer หรือบัญชีหลัก** ลบแล้วกู้ไม่ได้จริง

**เตรียมบัญชีทิ้ง:**

1. Supabase → Authentication → Users → Add user
   - Email: `throwaway1@h2hfleet.app`
   - Password: ➜ ดูใน `SECRETS.local.md` (ไม่อยู่ใน git)
   - ✅ Auto Confirm User
2. ล็อกอินด้วยบัญชีนี้ในแอป — ระบบจะสร้างบริษัทเปล่าให้อัตโนมัติ (`ensureUserProfile`)

**ทดสอบ:**

- [ ] บัญชีของฉัน → เลื่อนลงสุด เห็นกล่องแดง **"ลบบัญชีถาวร"**
- [ ] กด "ลบบัญชีของฉัน" → มี loading แวบหนึ่งแล้วขึ้น dialog
- [ ] dialog แสดงจำนวนรถ/ค่าใช้จ่าย/GPS (บัญชีใหม่จะเป็น 0 ทั้งหมด — ถูกต้อง)
- [ ] มีกล่องแดงเตือนว่า **"คุณเป็นสมาชิกคนสุดท้าย ข้อมูลของทั้งบริษัทจะถูกลบ"**
- [ ] ปุ่ม "ลบบัญชีถาวร" **กดไม่ได้** ตอนเริ่มต้น
- [ ] ติ๊ก checkbox แล้ว → ยังกดไม่ได้
- [ ] พิมพ์ `ลบบัญชี` ในช่อง → ปุ่มเปลี่ยนเป็นกดได้
- [ ] ลองพิมพ์ผิดเช่น `ลบ` → ปุ่มกลับไปกดไม่ได้
- [ ] กดลบ → เด้งกลับหน้า Login พร้อม snackbar เขียว "ลบบัญชีเรียบร้อยแล้ว"
- [ ] ลองล็อกอินด้วยบัญชีเดิมอีกครั้ง → **ต้องเข้าไม่ได้**

**ยืนยันในฝั่งฐานข้อมูล** (Supabase → SQL Editor):

```sql
select count(*) as auth_user   from auth.users     where email = 'throwaway1@h2hfleet.app';
select count(*) as profile     from public.users   where email = 'throwaway1@h2hfleet.app';
```
ต้องได้ **0 ทั้งสองแถว**

**ทดสอบเคสโอนสิทธิ์** (ถ้าอยากครบ): สร้างบัญชีทิ้งสองอัน แล้วแก้ให้อยู่บริษัทเดียวกัน

```sql
-- ให้ throwaway2 ย้ายมาอยู่บริษัทเดียวกับ throwaway1 ในบทบาท driver
update public.users
   set company_id = (select company_id from public.users where email = 'throwaway1@h2hfleet.app'),
       role = 'driver'
 where email = 'throwaway2@h2hfleet.app';
```
แล้วล็อกอินด้วย throwaway1 → กดลบ → dialog ต้องบังคับให้เลือกผู้รับสิทธิ์ owner ก่อน

### 4.7 Google Sign-In (ถ้าตั้งค่า OAuth client เสร็จแล้ว)

- [ ] กด "เข้าสู่ระบบด้วย Google" → เปิดเบราว์เซอร์
- [ ] เลือกบัญชี → **ต้องเด้งกลับเข้าแอป** ไม่ใช่ค้างอยู่ที่เบราว์เซอร์

ถ้าค้างที่เบราว์เซอร์ แปลว่า deep link ยังไม่ทำงาน ตรวจ 2 จุด:
1. Supabase → Authentication → URL Configuration → Redirect URLs มี `com.h2hfleet.app://login-callback/` หรือยัง
2. ทดสอบ deep link ตรง ๆ:
   ```bash
   adb shell am start -a android.intent.action.VIEW -d "com.h2hfleet.app://login-callback/"
   ```
   ถ้าแอปเปิดขึ้นมา = intent-filter ใน manifest ถูกต้องแล้ว ปัญหาอยู่ฝั่ง Supabase/Google

---

## 5. ปัญหาที่เจอบ่อยบน Emulator

| อาการ | สาเหตุ / วิธีแก้ |
|---|---|
| แผนที่ไม่แสดงตำแหน่งของฉัน | ยังไม่ได้ตั้งพิกัดใน Extended controls → Location (ดูข้อ 2) |
| แผนที่ขาวโล่ง ไม่มี tile | emulator ต่อเน็ตไม่ได้ → **Cold Boot Now** ใน Device Manager หรือรีสตาร์ท emulator |
| จอขาวหลังเปิดแอป | ดู **Logcat** กรองด้วยคำว่า `flutter` — มักเป็น Supabase เชื่อมต่อไม่ได้ |
| `adb: device offline` | `adb kill-server && adb start-server` |
| ไม่เห็นเมนู "บัญชีของฉัน" | ยังรันโค้ดเก่า → Stop แล้ว Run ใหม่ (hot reload ไม่ดึงเมนูใหม่ในบางกรณี) |
| ปุ่มลบบัญชีขึ้น error เรื่อง function | `SUPABASE_ACCOUNT_DELETION.sql` ยังไม่ได้รัน หรือรันคนละ project |
| กดปุ่มลบแล้วไม่มีอะไรเกิดขึ้น | ยังติ๊ก checkbox หรือพิมพ์คำยืนยันไม่ครบ — ปุ่มถูกล็อกไว้โดยตั้งใจ |
| Emulator ช้ามาก | ปิด "Show taps" และลด RAM ของ AVD อื่นที่เปิดค้างไว้ |

---

## 6. ถ่ายภาพหน้าจอจาก emulator ไปใช้ใน Play Store

```bash
# Pixel 7 emulator ให้ภาพ 1080×2400 ตรงสเปก Play พอดี
adb exec-out screencap -p > ~/Desktop/shot_01_map.png
```

หรือกดปุ่มกล้อง 📷 ที่แถบข้าง emulator (ไฟล์ไปอยู่ที่ Desktop)

ดูลำดับภาพและข้อห้ามที่ `SCREENSHOT_SPEC.md`

> เปลี่ยนภาษาเป็นอังกฤษได้จากปุ่มสลับภาษาบนแถบบน ถ้าจะทำชุดภาพ en-US ด้วย
