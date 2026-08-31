# บัญชีทดสอบสำหรับ Google Play reviewer

กรอกที่ **Play Console → App content → App access**

---

## ขั้นตอนเตรียม (ทำครั้งเดียว ก่อนส่ง review)

1. Supabase Dashboard → **Authentication → Users → Add user → Create new user**

   | ช่อง | ค่า |
   |---|---|
   | Email | `playreview@h2hfleet.app` |
   | Password | ➜ ดูใน `SECRETS.local.md` (ไม่อยู่ใน git) |
   | Auto Confirm User | ✅ **ต้องติ๊ก** — reviewer กดยืนยันอีเมลไม่ได้ |

2. Supabase → **SQL Editor → New Query** → รัน `SUPABASE_ACCOUNT_DELETION.sql` (ที่ repo root)
3. รัน `SUPABASE_REVIEWER_DEMO_SEED.sql` → เติมบริษัทตัวอย่าง รถ 5 คัน ค่าใช้จ่าย 120 รายการ งานซ่อม 6 รายการ และเส้นทาง GPS
4. ล็อกอินด้วยบัญชีนี้บนเครื่องจริงหนึ่งรอบ ตรวจว่าแดชบอร์ด แผนที่ และรายการค่าใช้จ่ายขึ้นข้อมูลครบ

---

## สิ่งที่กรอกใน App access

**เลือก:** `All or some functionality is restricted`

**Add new instructions:**

| ช่อง | ค่าที่กรอก |
|---|---|
| Name | `Fleet manager demo account` |
| Username | `playreview@h2hfleet.app` |
| Password | ➜ ดูใน `SECRETS.local.md` (ไม่อยู่ใน git) |
| Any other information | ข้อความด้านล่าง |

### Any other information (คัดลอกทั้งบล็อก)

```
H2HFleet is a B2B fleet management app. All functionality requires a company
account, so please use the demo credentials above.

HOW TO SIGN IN
1. Open the app and tap "เข้าสู่ระบบ" (Sign in).
2. Enter the email and password above. No OTP, no email verification and no
   two-factor step is required for this account.
3. The app opens on the fleet dashboard.

WHAT TO TRY
- Dashboard: fleet cost summary for the demo company (5 vehicles).
- Map (แผนที่): live vehicle positions and route history. The app requests
  foreground location permission the first time. You may allow or deny it —
  the map still shows the demo vehicles either way, because their positions
  come from the server, not from the reviewer's device. Location is used only
  while the app is open; the app never collects location in the background.
- Expenses (ค่าใช้จ่าย): 120 sample fuel, toll and repair records.
- Maintenance (ซ่อมบำรุง): upcoming service, insurance and road tax reminders.
- My Account (บัญชีของฉัน): profile, privacy policy links, and the in-app
  account deletion flow.

ACCOUNT DELETION
In-app: บัญชีของฉัน (My Account) → ลบบัญชีของฉัน (Delete my account).
The dialog lists exactly what will be removed, requires an acknowledgement
checkbox and a typed confirmation, then deletes the account permanently.
Web: https://rnai-io.github.io/H2Hfleet/delete-account.html

NOTE: the demo account is deleted for real if the deletion flow is completed.
If you need to sign in again afterwards, please contact us at
naiguitarfolk@gmail.com and we will re-provision it.

The app is in Thai by default. Language can be switched to English from the
language toggle in the top bar.
```

---

## ⚠️ หลัง review เสร็จ

ถ้า reviewer ทดสอบปุ่มลบบัญชีจนจบ **บัญชีเดโมจะถูกลบจริง** (รวมข้อมูลบริษัทตัวอย่างทั้งหมด)
ให้สร้าง auth user ใหม่แล้วรัน `SUPABASE_REVIEWER_DEMO_SEED.sql` ซ้ำ — สคริปต์รันซ้ำได้ ไม่สร้างข้อมูลซ้ำซ้อน

## ⚠️ ก่อนอัปเดตแอปครั้งถัดไป

ตรวจทุกครั้งว่าบัญชีนี้ยังล็อกอินได้ — บัญชีทดสอบที่ใช้ไม่ได้คือเหตุผล reject อันดับต้น ๆ ของแอปที่ต้องล็อกอิน
