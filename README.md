# 🚛 H2HFleet — Intelligent Fleet Management Platform
### แพลตฟอร์มบริหารจัดการกองยานพาหนะและติดตาม GPS อัจฉริยะ สำหรับธุรกิจ SME และโลจิสติกส์

[![Live WebApp](https://img.shields.io/badge/Live%20WebApp-h2hfleet.netlify.app-0284C7?style=for-the-badge&logo=netlify&logoColor=white)](https://h2hfleet.netlify.app/)
[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Google Gemini](https://img.shields.io/badge/AI%20Engine-Gemini%202.5%20Flash-8E75C2?style=for-the-badge&logo=googlegemini&logoColor=white)](https://ai.google.dev/)
[![LINE Notify](https://img.shields.io/badge/LINE-Messaging%20API-06C755?style=for-the-badge&logo=line&logoColor=white)](https://line.me)

---

## 🌐 ลิงก์เข้าใช้งานระบบ (Direct Access Links)

| บริการ / หน้าเว็บ | ลิงก์เข้าใช้งาน | รายละเอียด |
| :--- | :--- | :--- |
| 🚀 **Web Application (ระบบจริง)** | [**https://h2hfleet.netlify.app/**](https://h2hfleet.netlify.app/) | ระบบบริหารฟลีตเต็มรูปแบบ รองรับทั้ง Desktop, iPad Pro และ Mobile Web |
| 📊 **Executive Business Report** | [**เปิดอ่านรายงานสถาปัตยกรรม & โมเดลธุรกิจ v1.1.0**](https://rnai-io.github.io/H2Hfleet/H2HFLEET_EXECUTIVE_REPORT.html) | รายงานฉบับผู้บริหาร โครงสร้างต้นทุน กำไรขาดทุน 3 ปี และกลยุทธ์ราคาอาเซียน |
| 📑 **Official Landing Page** | [**https://rnai-io.github.io/H2Hfleet/**](https://rnai-io.github.io/H2Hfleet/) | หน้าแนะนำระบบและฟีเจอร์หลักของ H2HFleet |

---

## ✨ ฟังก์ชันเด่นของระบบ (Core Features)

```
+-----------------------------------------------------------------------------------------------+
|                                    H2HFLEET CLIENT APPS                                       |
|   +---------------------------+   +---------------------------+   +-----------------------+   |
|   |   iOS App (TestFlight)    |   |   Android Native App      |   | Flutter Web (Netlify) |   |
|   |   • Face ID / Touch ID    |   |   • Background Tracking   |   | • Single Page App CDN |   |
|   |   • Native Apple Sign In  |   |   • Push Notifications    |   | • Dynamic Routing     |   |
|   +---------------------------+   +---------------------------+   +-----------------------+   |
+-----------------------------------------------+-----------------------------------------------+
                                                | HTTPS & WebSockets (WSS)
                                                v
+-----------------------------------------------------------------------------------------------+
|                                   CLOUD BACKEND & DATABASE (SUPABASE)                         |
|   +---------------------------------------------------------------------------------------+   |
|   | PostgreSQL Database with Row Level Security (RLS Multi-Tenant Architecture)           |   |
|   | • companies, users, vehicles, expenses, trips, maintenance, gps_logs                  |   |
|   +---------------------------------------------------------------------------------------+   |
|   | Realtime WebSocket Telemetry Engine                                                   |   |
|   | • Sub-second GPS Live Stream · Multi-Driver Sync · Fallback Standby Coordinates      |   |
|   +---------------------------------------------------------------------------------------+   |
+-----------------------------------------------+-----------------------------------------------+
```

1. **🗺️ Live Telematics Map & Multi-Waypoint Routing:**
   - ติดตามตำแหน่ง GPS กองรถแบบเรียลไทม์ผ่าน WebSocket Sub-second stream
   - ระบบวางแผนเส้นทางหลายจุดแวะ (Route Planner) ด้วย OSRM Engine และ OpenStreetMap
2. **🚛 Vehicle CAD Blueprint & Photo Management:**
   - บันทึกและจัดการข้อมูลรถ ละเอียดยิบ พร้อมสลับมุมมองระหว่างภาพถ่ายจริงและ CAD Blueprint โครงสร้างรถ
3. **📱 Driver Cockpit Mode:**
   - โหมดคนขับสำหรับส่งสัญญาณ GPS พิกัดสดอัตโนมัติ พร้อมใบขับขี่ดิจิทัล และเช็คลิสต์ตรวจสภาพรถก่อนออกเดินทาง
4. **💰 Smart Expense Tracking & Analytics:**
   - บันทึกค่าน้ำมัน, ค่าซ่อมบำรุง, ยาง, ทางด่วน พร้อมกราฟสถิติวิเคราะห์ต้นทุนต่อคัน / ต่อเดือน
5. **🤖 AI Copilot (Google Gemini 2.5 Flash Engine):**
   - ผู้ช่วยอัจฉริยะวิเคราะห์ความผิดปกติของการใช้น้ำมัน ตรวจสอบพฤติกรรมขับขี่ และสรุปรายงานประจำวัน
6. **💬 Automated LINE Broadcast:**
   - เชื่อมต่อ LINE Messaging API ส่งสรุปงานและเส้นทางเข้าห้องแชทคนขับหรือผู้บริหารอัตโนมัติ
7. **🏢 Enterprise Control Panel & Active Directory RBAC:**
   - ระบบจัดการสิทธิ์ผู้ใช้งานตามระดับ (Super Admin, Manager, Driver) และข้อมูลองค์กร

---

## 🛠️ เทคโนโลยีที่ใช้ในการพัฒนา (Technology Stack)

- **Frontend:** [Flutter 3.44+](https://flutter.dev) (Dart 3.12+), [Riverpod 2.6](https://riverpod.dev)
- **Backend & Database:** [Supabase](https://supabase.com) (PostgreSQL 15+ with RLS Multi-Tenant, Realtime WSS, Auth, Storage)
- **AI Intelligence:** [Google Gemini 2.5 Flash Engine](https://ai.google.dev/)
- **Routing & Maps:** OSRM Routing Engine, Flutter Map, OpenStreetMap
- **Messaging:** LINE Official Messaging API SDK & Supabase Edge Functions
- **Hosting & CI/CD:** [Netlify](https://www.netlify.com/) (Web SPA CDN with Auto Deploy from GitHub)

---

## 🚀 การติดตั้งและรันในเครื่อง (Local Setup)

```bash
# 1. Clone the repository
git clone https://github.com/Rnai-io/H2Hfleet.git
cd H2Hfleet/h2hfleet

# 2. Install dependencies
flutter pub get

# 3. Run on Chrome Web
flutter run -d chrome

# 4. Run on iOS Simulator / iPad Pro
flutter run -d "iPad Pro (13-inch) (M4)"
```

---

## 📄 ลิขสิทธิ์และผู้พัฒนา (License & Credits)

- พัฒนาโดย: **Rnai-io & H2HFleet Engineering Team**
- เว็บไซต์หลัก: [https://h2hfleet.netlify.app/](https://h2hfleet.netlify.app/)
- เอกสารลิขสิทธิ์: [MIT License](LICENSE)
