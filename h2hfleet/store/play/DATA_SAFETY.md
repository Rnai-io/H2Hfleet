# Data safety form — คำตอบที่ต้องกรอกใน Play Console

> กรอกที่ **Play Console → App content → Data safety**
> คำตอบต้องตรงกับสิ่งที่แอปทำจริงและตรงกับ Privacy Policy ถ้าไม่ตรง Google จะระงับแอป

## ส่วนที่ 1 — Data collection and security

| คำถาม | คำตอบ | เหตุผล |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | เก็บอีเมล ตำแหน่ง รูปใบเสร็จ |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | Supabase ใช้ HTTPS/WSS ทั้งหมด |
| Do you provide a way for users to request that their data be deleted? | **Yes** | ⚠️ ต้องมีจริงก่อนตอบ — ดู COMPLIANCE_GAPS.md ข้อ 1 |

**Data deletion URL** ที่ต้องกรอก (ต้องสร้างหน้านี้ก่อน):
```
https://rnai-io.github.io/H2Hfleet/delete-account.html
```

---

## ส่วนที่ 2 — Data types

หมายเหตุคำนิยาม: **Collected** = ส่งออกจากเครื่อง · **Shared** = ส่งให้บริษัทอื่นที่ไม่ใช่ผู้ประมวลผลของคุณ
Supabase / Netlify / Google Gemini ถือเป็น **service provider** → นับเป็น Collected ไม่ใช่ Shared

### Location
| ประเภท | Collected | Shared | Processed ephemerally | Required or optional | Purpose |
|---|---|---|---|---|---|
| **Approximate location** | ✅ | ❌ | ❌ | Optional | App functionality |
| **Precise location** | ✅ | ❌ | ❌ | Optional | App functionality |

- Linked to user identity: **Yes** (ผูกกับบัญชีคนขับ)
- Used for tracking across apps/companies: **No**

### Personal info
| ประเภท | Collected | Shared | Required | Purpose |
|---|---|---|---|---|
| **Name** | ✅ | ❌ | Required | Account management, App functionality |
| **Email address** | ✅ | ❌ | Required | Account management |
| **User IDs** | ✅ | ❌ | Required | Account management |
| **Phone number** | ✅ ถ้าเก็บเบอร์คนขับ | ❌ | Optional | App functionality |

- Linked to user identity: **Yes** ทุกข้อ
- Used for tracking: **No**

### Photos and videos
| ประเภท | Collected | Shared | Required | Purpose |
|---|---|---|---|---|
| **Photos** | ✅ | ❌ | Optional | App functionality (รูปใบเสร็จ / รูปรถ) |

- Linked to user identity: **Yes**

### App activity
| ประเภท | Collected | Shared | Required | Purpose |
|---|---|---|---|---|
| **Other user-generated content** | ✅ | ❌ | Optional | App functionality (ค่าใช้จ่าย งานวิ่ง บันทึกซ่อม) |

- Linked to user identity: **Yes**

### สิ่งที่ **ไม่** ได้เก็บ — ตอบ No ทั้งหมด
- Financial info (payment method, purchase history) — ค่าใช้จ่ายที่บันทึกเป็นข้อมูลปฏิบัติการ ไม่ใช่ข้อมูลการชำระเงินของผู้ใช้ → ใส่ใน *Other user-generated content* แทน
- Health and fitness · Messages · Contacts · Calendar · Files and docs
- Web browsing history · Search history · Installed apps
- Device or other IDs (ไม่มี Advertising ID เพราะไม่มี SDK โฆษณา)
- Crash logs / Diagnostics (ไม่มี Crashlytics ในโปรเจกต์)

---

## ส่วนที่ 3 — Sensitive permissions declaration

**Location permission** ที่ประกาศไว้: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` เท่านั้น
→ **ไม่มี** `ACCESS_BACKGROUND_LOCATION` จึง **ไม่ต้อง** ส่งแบบฟอร์ม background location + วิดีโอสาธิต (ประหยัดเวลา review 1–2 สัปดาห์)

คำอธิบายการใช้งานตำแหน่งที่แนะนำให้ตอบ:
```
The app shows the live position of company vehicles on a map for fleet
managers. A driver enables "driver mode" in the app, which reports the
device position while the app is in use so the dispatcher can see the
vehicle on the map and reconstruct the trip afterwards. Location is
never collected while the app is in the background or closed.
```

⚠️ ถ้าในอนาคตเปิด background tracking จริง ต้องเพิ่ม permission + Foreground service + กรอกแบบฟอร์ม declaration ใหม่

---

## ส่วนที่ 4 — App content อื่นที่ต้องกรอกให้ครบ

| หัวข้อ | คำตอบ |
|---|---|
| Privacy policy URL | `https://rnai-io.github.io/H2Hfleet/privacy-policy.html` |
| Ads | **No, my app does not contain ads** |
| App access | **All functionality is restricted** → ต้องให้ username/password บัญชีทดสอบ (ดู REVIEWER_ACCOUNT ใน RELEASE_CHECKLIST.md) |
| Content rating | ทำแบบสอบถาม IARC → คาดว่าได้ **Everyone / 3+** |
| Target audience | **18 and over** (แอปสำหรับธุรกิจ) → ไม่เข้าข่าย Families policy |
| News app | **No** |
| COVID-19 contact tracing | **No** |
| Data safety | ตามตารางด้านบน |
| Government app | **No** |
| Financial features | **No** (ไม่มีการชำระเงินหรือสินเชื่อในแอป) |
| Health apps | **No** |
