# สถานะการปิดช่องว่างก่อนส่ง review

อัปเดต: 31 ส.ค. 2026

---

## ✅ 1. ฟังก์ชันลบบัญชี — ปิดแล้ว (รอรัน SQL + ทดสอบ)

Google Play บังคับตั้งแต่ปี 2024: แอปที่ให้สร้างบัญชีได้ต้องมีปุ่มลบบัญชีในแอป **และ** หน้าเว็บสาธารณะ

| ส่วน | สถานะ | ที่อยู่ |
|---|---|---|
| ฟังก์ชันฐานข้อมูล | ✅ เขียนแล้ว ทดสอบ 11 เคสผ่าน | `SUPABASE_ACCOUNT_DELETION.sql` (repo root) |
| ปุ่มลบบัญชีในแอป | ✅ เขียนแล้ว | `lib/features/settings/account_settings_screen.dart` |
| เมนูเข้าหน้านี้ | ✅ เพิ่มใน Dashboard ทั้งจอเล็กและจอใหญ่ | `dashboard_screen.dart` |
| เมธอดเรียก RPC | ✅ เพิ่มแล้ว | `lib/providers/auth_provider.dart` |
| หน้าเว็บสาธารณะ | ✅ เขียนแล้ว | `delete-account.html` (repo root) |

**เหลือทำ:**

- [ ] รัน `SUPABASE_ACCOUNT_DELETION.sql` ใน Supabase SQL Editor
- [ ] `git push` เพื่อให้ `delete-account.html` เผยแพร่บน GitHub Pages แล้วเปิดเช็ก
- [ ] ทดสอบปุ่มลบบัญชีบนเครื่องจริงด้วยบัญชีทิ้ง (ไม่ใช่บัญชีหลัก — ลบแล้วกู้ไม่ได้)
- [ ] กรอก Data deletion URL ใน Data safety: `https://rnai-io.github.io/H2Hfleet/delete-account.html`

### พฤติกรรมที่ออกแบบไว้

| สถานการณ์ | ผลลัพธ์ |
|---|---|
| เป็นสมาชิกคนเดียวในบริษัท | ลบบริษัททั้งก้อน (รถ ค่าใช้จ่าย ซ่อมบำรุง GPS งานวิ่ง รูปใน storage) ต้องติ๊กยืนยันเพิ่ม |
| เป็นแอดมินคนสุดท้าย แต่ยังมีสมาชิกอื่น | บังคับเลือกผู้รับสิทธิ์ owner ก่อน ทีมจึงไม่หลุดจากข้อมูล |
| เป็นสมาชิกทั่วไป / ยังมีแอดมินคนอื่น | ลบเฉพาะบัญชีตัวเอง ข้อมูลบริษัทอยู่ครบ |
| ทุกกรณี | ต้องติ๊กยืนยัน **และ** พิมพ์คำว่า `ลบบัญชี` (EN: `DELETE`) แล้วจึงกดปุ่มได้ |

---

## ✅ 2. Privacy Policy: OpenAI → Gemini — แก้แล้ว

| ไฟล์ | สถานะ |
|---|---|
| `privacy-policy.html` | ✅ เปลี่ยนเป็น Google Gemini 2.5 Flash, LINE Notify → LINE Messaging API, เพิ่มวันแก้ไขล่าสุด |
| `terms-of-service.html` | ✅ แก้ LINE Notify และวันที่ |
| `create_docs.js` | ✅ แก้ต้นทาง + แก้ path เขียนไฟล์ที่เดิมชี้ไปโฟลเดอร์ที่ไม่มีอยู่ |
| `H2HFleet_PrivacyPolicy.docx` | ✅ สร้างใหม่จาก create_docs.js แล้ว |
| `H2HFleet_TermsOfService.docx` | ✅ สร้างใหม่แล้ว |

- [ ] `git push` ให้เวอร์ชันใหม่ขึ้น GitHub Pages ก่อนกรอก Data safety

---

## ✅ 3. อีเมลติดต่อใน Privacy Policy — เพิ่มแล้ว

เพิ่ม `naiguitarfolk@gmail.com` ใน privacy policy, terms, footer, หน้าลบบัญชี และไฟล์ .docx

- [ ] ยืนยันว่าต้องการใช้อีเมลนี้เป็นอีเมลสาธารณะ ถ้าไม่ใช่ ให้ค้นหา `naiguitarfolk@gmail.com` แล้วแทนที่ทุกจุด

---

## ✅ 4. บัญชีทดสอบสำหรับ reviewer — เตรียมสคริปต์แล้ว

| ส่วน | สถานะ | ที่อยู่ |
|---|---|---|
| สคริปต์ seed ข้อมูลตัวอย่าง | ✅ เขียนแล้ว ทดสอบผ่าน (รันซ้ำได้) | `SUPABASE_REVIEWER_DEMO_SEED.sql` |
| ข้อความกรอกใน App access | ✅ เขียนแล้ว | `REVIEWER_ACCESS.md` |

**เหลือทำ:**

- [ ] สร้าง auth user `playreview@h2hfleet.app` ใน Supabase (ติ๊ก **Auto Confirm User**)
- [ ] รัน `SUPABASE_REVIEWER_DEMO_SEED.sql`
- [ ] ล็อกอินทดสอบบนเครื่องจริงหนึ่งรอบ
- [ ] คัดลอกข้อความจาก `REVIEWER_ACCESS.md` ไปกรอกใน Play Console → App access

---

## 🆕 5. เพิ่มเติมที่พบระหว่างทาง — แก้แล้ว

**Deep link ของ OAuth หายไปจาก AndroidManifest**
`AuthRepository._getAuthRedirectUrl()` ส่ง `com.h2hfleet.app://login-callback/` แต่ manifest เดิมไม่มี intent-filter รองรับ → ปุ่ม "เข้าสู่ระบบด้วย Google/Apple" บน Android จะเด้งออกเบราว์เซอร์แล้วไม่กลับเข้าแอป

✅ เพิ่ม intent-filter (`VIEW` + `BROWSABLE`, scheme `com.h2hfleet.app`, host `login-callback`) ใน `AndroidManifest.xml` แล้ว

- [ ] ทดสอบปุ่ม Google Sign-In บนเครื่อง Android จริงในโหมด release
- [ ] เพิ่ม `com.h2hfleet.app://login-callback/` ใน Supabase → Authentication → URL Configuration → Redirect URLs

---

## ⏳ 6. ยังเหลือ (ต้องทำเอง)

- [ ] **Sign in with Apple บน Android** — ถ้าปุ่มแสดงบน Android ต้องกดแล้วทำงานจริง ไม่ค้าง ถ้าไม่รองรับให้ซ่อนเมื่อ `Platform.isAndroid`
- [ ] **ตรวจคำโปรยให้ตรงกับของจริง** — ไล่ทีละบรรทัดใน `LISTING_TH.md` ว่าฟีเจอร์ที่เขียนมีจริงครบ ("misleading store listing" คือเหตุผล reject ที่พบบ่อย)
- [ ] **ภาพหน้าจอ 2–8 ภาพ** — ดู `SCREENSHOT_SPEC.md`
- [ ] **สมัคร Play Console** ($25) + ยืนยันตัวตน (1–3 วัน)
- [ ] **versionCode** — ตอนนี้ `1.1.0+5` ทุกครั้งที่อัปโหลดใหม่ต้องเพิ่มเลขหลัง `+`
