# H2HFleet - Fleet Intelligence for Thai SMEs

## Project Overview

**Vision**: AI-first Fleet Copilot for SME owners (1-5 vehicles)

**Problem**: Thai SME fleet owners use Excel to track vehicles, expenses, and maintenance. They lose money to:
- Oil leaks (น้ำมันรั่ว)
- Idling (รถจอด)
- Cheating drivers (คนขับอู้)
- Delayed jobs (งาน delay)
- Broken vehicles (รถพัง)

**Solution**: Simple mobile app that helps owners see:
- What each vehicle costs per day
- Which vehicle is problematic
- How much they're losing
- What to do next

**Not trying to be**: DTC, ERP, or enterprise software. Just **useful**. Just **simple**. Just **works**.

---

## Product Strategy

### Phase 1 (Week 1-4): MVP — Core Features
- **Vehicle Management**: Add rถือรถ (plate number, brand, year)
- **Expense Tracking**: Record fuel, repairs, tires, mileage costs
- **AI Summary**: Daily message in Thai summarizing today's spend
- **LINE Notify**: Send summary to owner's LINE every morning

### Phase 2 (Month 2): Intelligence
- Driver behavior scoring (overspeed, harsh braking, idle)
- Fuel analytics (cost per KM)
- Predictive maintenance alerts

### Phase 3 (Month 3): Multi-Company + Scale
- Support multiple companies
- Subscription billing
- API for partners

---

## What You Have Now

```
/Users/chanakhongdi/H2Hfleet/
├── SUPABASE_SCHEMA.sql        ← Database schema (ready to run)
├── FLUTTER_SETUP.md            ← Project structure + dependencies
├── FLUTTER_SCREENS.md          ← Complete Auth + Vehicle screens (copy-paste ready)
├── FLUTTER_PROVIDERS.md        ← Riverpod state management
├── QUICKSTART.md               ← Step-by-step 45-min setup
└── README.md                   ← This file
```

## How to Get Started

### Option A: Rush to MVP (4 weeks, 5-10 hours/week)
1. Read `QUICKSTART.md` (5 minutes)
2. Follow the checklist exactly
3. Copy code from `FLUTTER_SCREENS.md`
4. Test on phone
5. Demo to first customer

### Option B: Deep Dive First (1 week planning)
1. Read `FLUTTER_SETUP.md` (architecture understanding)
2. Read `FLUTTER_PROVIDERS.md` (state management)
3. Then start building

**Recommendation**: Option A. You have limited time per week. Action > perfection.

---

## Tech Stack (Chosen)

| Layer | Technology | Why |
|-------|-----------|-----|
| Frontend | Flutter | Mobile-first, works offline, iOS + Android |
| State | Riverpod | Modern, null-safe, reactive |
| Backend | Supabase | PostgreSQL, auth, realtime, affordable |
| AI | OpenAI API | Best Thai language support, GPT-4 |
| Maps | Mapbox | Needed for Phase 2 GPS |
| GPS Hardware | Teltonika/Ruptela | No need to build hardware |
| Notifications | LINE Notify | Thais prefer LINE |

---

## Success Metrics (4 weeks)

✅ 1 customer using app daily
✅ Can add vehicles + expenses
✅ AI summary generates (in Thai)
✅ Sends to LINE
✅ No crashes
✅ Works on iPhone + Android

**Not needed yet:**
- Admin dashboard
- Analytics
- Multiple users per company
- GPS tracking
- Route optimization
- Dashcams

---

## Business Model (Planning)

**Phase 1**: Free for 1 vehicle → Customer sees value

**Phase 2**: 
- Free: 1 vehicle
- ฿99/คัน/เดือน: 2-5 vehicles
- ฿299/คัน/เดือน: 6+ vehicles

**Target Customer**: 
- Fleet owner (ชายวัฒนะ 40-55 years old)
- 3-20 vehicles
- Uses GPS but no smart analytics
- Spends 50k-200k/month on fleet costs
- Loses 10-20% to inefficiency

---

## Why You'll Succeed

1. **You've lived the pain** (70 vehicles, real operations)
2. **You understand SME** (not enterprise software, not toy app)
3. **You know what works** (simple, mobile-first, Thai language)
4. **Timing is right** (market moving from hardware → intelligence)
5. **Competition sleeps** (DTC is heavy, startups haven't noticed SME gap)

---

## Risks to Watch

1. **Scope creep**: Build 1 feature at a time. Resist temptation to "just add" GPS/routes/dashcam
2. **Tech rabbit holes**: Don't optimize architecture yet. Use Supabase defaults.
3. **Feature addiction**: 70% of MVP value comes from Daily Summary + Expense Tracking. Don't build more yet.
4. **Perfectionism**: Ship broken → iterate. Don't wait for perfect.

---

## Week-by-Week Roadmap

### Week 1 (3-4 hours)
- Set up Supabase (10 min)
- Create Flutter project (10 min)
- Build Auth screens (rest of week)
- Goal: Login → Logout works

### Week 2 (2-3 hours)
- Build Vehicle Management
- Add/list vehicles
- Goal: Add 3 vehicles, see them listed

### Week 3 (2-3 hours)
- Build Expense Tracking
- Add expenses, see summary per vehicle
- Integrate OpenAI for Daily Summary
- Goal: See AI-generated summary in Thai

### Week 4 (2-3 hours)
- LINE integration (send summary to LINE)
- Polish UI
- Test on real phone
- Goal: Demo to 1 customer

---

## File Guide

| File | Read When | Why |
|------|-----------|-----|
| QUICKSTART.md | Ready to code | Step-by-step checklist |
| FLUTTER_SETUP.md | Need architecture | Folder structure + setup |
| FLUTTER_SCREENS.md | Building screens | Copy-paste ready code |
| FLUTTER_PROVIDERS.md | Building state | Riverpod patterns |
| SUPABASE_SCHEMA.sql | Setting up DB | SQL to run once |

---

## Next Actions (Today)

1. ☐ Read `QUICKSTART.md`
2. ☐ Create Supabase account
3. ☐ Run SQL schema
4. ☐ Create Flutter project
5. ☐ Copy auth screens code
6. ☐ Run `flutter run`

Should take 45 minutes total.

---

## Questions?

- Code questions → Read relevant .md file
- Architecture questions → Read FLUTTER_SETUP.md
- State management → Read FLUTTER_PROVIDERS.md
- "How do I test?" → Read QUICKSTART.md testing section

---

## Remember

This is **not** a race to perfect. This is a race to:
1. **Working** (app doesn't crash)
2. **Useful** (customer sees value in 30 seconds)
3. **Repeatable** (customer uses it daily)

If you have these 3, scaling is the easy part.

**You've got this.** 4 weeks, 5-10 hours/week, 1 customer. Let's go.

---

Last updated: 2026-05-19
Project: H2HFleet MVP
Status: Ready to build
