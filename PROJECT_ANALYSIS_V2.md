# H2HFleet Project Analysis (With Real-Time Map Tracking)

**Updated: 2026-06-03**
**Status: Scope Changed → 5-6 week timeline instead of 4 weeks**

---

## Executive Summary

### Original Plan (4 weeks)
- Auth + Vehicle Management
- Expense Tracking
- Daily AI Summary
- LINE Notifications
- ❌ NO Real-time Map

### New Plan (5-6 weeks)
- ✅ All above +
- ✅ **Real-time GPS tracking**
- ✅ **Live vehicle map**
- ✅ **Geofencing alerts** (Phase 2 ready)

---

## Project Scope Analysis

### What's Staying the Same ✅
- Vehicle Management (add/list rถือรถ)
- Expense Tracking (fuel, repairs, etc.)
- Daily AI Summary
- LINE Notifications
- Auth (login/register)

### What's NEW 🆕
- GPS data integration (from Teltonika/Ruptela devices)
- Real-time map display (Mapbox)
- Live vehicle location updates
- Driver location history
- Route playback (nice to have)

### What's Getting PUSHED to Phase 2
- Geofencing alerts (needs more time)
- Advanced route optimization
- Predictive maintenance
- Driver behavior scoring (complex ML)
- Fleet dashboard (advanced analytics)

---

## Technical Architecture Changes

### Original Flow
```
Driver → GPS Device → ❌ Nowhere (not integrated)
```

### New Flow
```
GPS Device (Teltonika/Ruptela)
    ↓
TCP Server (Node.js / Python)
    ↓
Parse GPS Protocol
    ↓
Supabase PostgreSQL (gps_logs table)
    ↓
Realtime Subscriptions
    ↓
Flutter App → Mapbox Map
```

---

## Implementation Breakdown

### Layer 1: GPS Data Collection (Server)
**What**: Build or use existing GPS server to parse device data

**Options**:
1. **Option A (Recommended)**: Use Teltonika HTTP API directly
   - Teltonika devices can send HTTP instead of TCP
   - Simpler, no server needed
   - Works with Supabase Edge Functions
   
2. **Option B**: Build TCP Server
   - Full control
   - More complex (15-20 hours)
   - Use Node.js + TCP listener

**Recommendation**: Start with Option A (10 minutes setup)

---

### Layer 2: Supabase Realtime
**What**: Stream GPS locations to Flutter in real-time

**Tables Affected**:
```sql
-- Already exists
gps_logs (id, vehicle_id, lat, lng, speed, engine_status, fuel_level, recorded_at)

-- New: Track current location
vehicle_current_location (vehicle_id, lat, lng, speed, updated_at)
```

**Realtime Channel**:
```dart
supabase.channel('gps:vehicle_$vehicleId')
  .on(RealtimeEventType.postgresChanges, ...)
  .subscribe()
```

---

### Layer 3: Flutter Map UI
**What**: Display vehicles on map in real-time

**Features**:
- Live vehicle positions (dots on map)
- Car icon showing direction
- Tap vehicle → see details
- Last updated timestamp
- Simple animation (smooth movement)

**Library**: Mapbox Flutter + realtime subscription

---

## Updated Timeline

| Week | Tasks | Hours | Deliverables |
|------|-------|-------|--------------|
| **1** | Supabase + Flutter + Auth | 3-4 | Login works |
| **2** | Vehicle Mgmt + Setup GPS | 3-4 | Add vehicles, can add GPS device |
| **3** | GPS Server + Map UI | 4-5 | Real-time map shows vehicle positions |
| **4** | Expense Tracking + AI | 3-4 | Expense tracking + AI summary works |
| **5** | LINE + Polish | 2-3 | LINE notifications + final polish |
| **6** | Testing + Demo | 2-3 | Ready for customer demo |

**Total: 17-23 hours (average 3-4 hrs/week)**

---

## Week-by-Week Detail

### Week 1: Foundation
- [ ] Supabase project created + schema
- [ ] Flutter project scaffold
- [ ] Auth screens (login/register)
- [ ] Database connection verified
- **Goal**: Login/Logout works perfectly

### Week 2: Vehicle Mgmt + GPS Prep
- [ ] Vehicle list screen
- [ ] Add vehicle dialog
- [ ] GPS device configuration screen
  - Input device ID
  - Select device type (Teltonika/Ruptela)
  - Save to database
- [ ] Get Mapbox API key
- **Goal**: Can add vehicles + capture GPS device info

### Week 3: Real-Time Map ⭐ (NEW)
- [ ] Set up Teltonika HTTP API forwarding
- [ ] Parse GPS data → Supabase
- [ ] Create Mapbox map screen
- [ ] Realtime subscription to gps_logs
- [ ] Display vehicle markers on map
- [ ] Show last location + speed
- **Goal**: Open app → See live vehicle positions on map

### Week 4: Expenses + AI
- [ ] Expense tracking form
- [ ] Expense list by vehicle
- [ ] Daily AI summary (from expenses)
- [ ] Summary display in app
- **Goal**: Expense tracking + AI summary working

### Week 5: LINE + Features
- [ ] LINE Notify integration
- [ ] Send daily summary to LINE
- [ ] Geofencing setup (basic)
- [ ] Route history screen
- [ ] UI polish + Thai language
- **Goal**: Customer can use all core features

### Week 6: Testing + Demo
- [ ] Test on real phones (iOS + Android)
- [ ] Test with real GPS device
- [ ] Fix bugs
- [ ] Record demo video
- [ ] Demo to customer
- **Goal**: Ready for customer feedback

---

## GPS Integration Details

### How Teltonika Devices Work

**Physical Device**: Teltonika FM1010 (或类似)
- Installed in vehicle
- Connects to vehicle battery
- Gets GPS from satellite
- Sends location every 60 seconds

**Default**: Sends via TCP to port 27015

**Our Approach**: Use HTTP API instead
- Teltonika device can be configured to send HTTP POST
- Post to Supabase Edge Function
- Parse location → Save to gps_logs
- Supabase Realtime broadcasts to app

### Setup Flow

```
1. Customer buys Teltonika FM1010 (~$80)
2. Install in vehicle
3. Configure device to send HTTP to our endpoint
4. Our server receives: {lat, lng, speed, timestamp, device_id}
5. Save to Supabase
6. Flutter app sees real-time update
7. Map shows vehicle location
```

### Code Example: Supabase Edge Function

```typescript
// Supabase Edge Function: handle_gps_data
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js"

serve(async (req) => {
  const { latitude, longitude, speed, imei } = await req.json()
  
  const supabase = createClient(SUPABASE_URL, SERVICE_KEY)
  
  // Get vehicle by GPS device imei
  const { data: vehicle } = await supabase
    .from('vehicles')
    .select('id')
    .eq('gps_device_imei', imei)
    .single()
  
  // Save GPS log
  await supabase.from('gps_logs').insert({
    vehicle_id: vehicle.id,
    lat: latitude,
    lng: longitude,
    speed: speed,
    recorded_at: new Date().toISOString()
  })
  
  // Update current location
  await supabase.from('vehicle_current_location').upsert({
    vehicle_id: vehicle.id,
    lat: latitude,
    lng: longitude,
    speed: speed,
    updated_at: new Date().toISOString()
  })
  
  return new Response('OK')
})
```

---

## Data Flow Diagram

```
┌─────────────────────┐
│ Teltonika Device    │
│ in Vehicle          │
└──────────┬──────────┘
           │ HTTP POST (lat, lng, speed)
           ↓
┌─────────────────────────────────────┐
│ Supabase Edge Function              │
│ (Parse + Validate)                  │
└──────────┬──────────────────────────┘
           │
           ↓
┌─────────────────────────────────────┐
│ Supabase PostgreSQL                 │
│ - gps_logs (history)                │
│ - vehicle_current_location (live)   │
└──────────┬──────────────────────────┘
           │ Realtime Subscription
           ↓
┌─────────────────────────────────────┐
│ Flutter App                         │
│ - Listen to location changes        │
│ - Update map markers in real-time   │
└─────────────────────────────────────┘
```

---

## Database Schema Changes

### New Table: vehicle_current_location
```sql
CREATE TABLE vehicle_current_location (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id),
  lat DECIMAL(10, 8) NOT NULL,
  lng DECIMAL(11, 8) NOT NULL,
  speed DECIMAL(10, 2),
  heading DECIMAL(3, 1), -- Direction (0-360 degrees)
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(vehicle_id)
);

CREATE INDEX idx_vehicle_current_location_vehicle_id 
  ON vehicle_current_location(vehicle_id);
```

### Modified: vehicles Table
```sql
ALTER TABLE vehicles ADD COLUMN gps_device_imei TEXT;
ALTER TABLE vehicles ADD COLUMN gps_device_type TEXT; -- teltonika, ruptela, etc
```

### Realtime Enable
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE vehicle_current_location;
```

---

## Risk Analysis: Map Tracking Addition

| Risk | Impact | Mitigation |
|------|--------|-----------|
| GPS device setup is complex | Medium | Provide step-by-step setup guide + support |
| Realtime updates can be slow | Low | Use Supabase Realtime (proven reliable) |
| Mapbox billing | Low | Free tier covers 50k requests/month |
| Battery drain on device | Low | Configurable update interval (60 sec default) |
| Scope creep (add more map features) | **High** | Lock scope: only live positions + history |
| 5-6 weeks is long | Medium | Prioritize MVP features (map is week 3) |

---

## Must-Have vs Nice-to-Have

### Must-Have (MVP)
- ✅ Live vehicle positions on map
- ✅ Update every 60 seconds
- ✅ Tap vehicle → see details
- ✅ Last updated time
- ✅ Basic marker design

### Nice-to-Have (Phase 2)
- ⏳ Route playback (show path taken)
- ⏳ Geofencing (alert when enters/exits zone)
- ⏳ Speed alerts (notify if overspeed)
- ⏳ Driver scoring (harsh braking, etc.)
- ⏳ Heatmap (most traveled routes)

### Not Doing Yet
- ❌ AI route optimization
- ❌ Predictive maintenance
- ❌ Fleet dashboard
- ❌ Advanced analytics

---

## Customer Demo (Week 6)

### 10-Minute Demo Flow

1. **Add Vehicle** (30 sec)
   - "นี่คือ สมชาย มีรถปูน 3 คัน"
   - Add plate: 1234-บบ

2. **Add GPS Device** (30 sec)
   - "ติดตั้ง Teltonika ในรถแล้ว"
   - Input device ID

3. **Live Map** (2 min)
   - "เปิดแผนที่ → เห็นรถวิ่งเรียลไทม์"
   - "ทำให้รู้ว่ารถอยู่ไหน คนขับไปไหน"

4. **Add Expense** (1 min)
   - "เติมน้ำมัน 500 บาท"
   - App records it

5. **AI Summary** (1 min)
   - "วันนี้ใช้จ่าย 500 บาท"
   - "ประหยัด 200 บาท vs วานนี้"

6. **LINE Notify** (1 min)
   - "ส่ง summary ไป LINE ของคุณ"
   - Show LINE message

7. **Close**: "สัปดาห์หน้า บวกเพิ่ม: ระบบแจ้งเตือน, ขับมีปัญหา, คิดค่าแก้ไข"

---

## Equipment Needed

### What Customer Buys
1. **GPS Device**: Teltonika FM1010 (~$80-100 per vehicle)
   - Or: Ruptela FM2125 (~$60)
   - Or: DTC device (if already customer)

2. **SIM Card**: For GPS device (~$5/month)
   - Needs 2G/3G/4G (small data)

3. **Installation**: Mechanic installs in vehicle (~$30-50 per vehicle)

### What We Provide
1. **App**: Free (freemium model)
2. **Cloud infrastructure**: Supabase (free tier)
3. **Map API**: Mapbox (free tier covers MVP)

### Cost Breakdown (Per Vehicle Per Month)
- GPS Device (amortized): $2-3
- SIM Card: $5
- Our software (future): $50-100
- **Total**: $60-110 per vehicle (worth it if saves $200-300 in fuel)

---

## Success Metrics (End of Week 6)

✅ **Technical**:
- Live map shows all vehicles
- Updates every 60 seconds
- No crashes with 5+ vehicles
- Works on iPhone + Android

✅ **Functional**:
- Customer can add GPS device
- Can see live locations
- Map responsive + fast
- Tap vehicle → shows details

✅ **Business**:
- 1 customer using daily
- Demo converts interest
- Can sell to next customer
- Documentation ready for support

---

## Risks & Contingencies

### If GPS device setup too complex
→ Provide pre-configured devices (white-label from partner)

### If realtime is slow
→ Fall back to polling every 30 seconds (acceptable)

### If Mapbox expensive
→ Use OpenStreetMap (free, less features)

### If time runs out
→ Deploy without map first, add in Phase 2

### If customer doesn't have GPS device
→ Can still use expense tracking + AI summary
→ Add map when ready

---

## Next Actions (Start Week 1)

1. ☐ Create Supabase project + run schema
2. ☐ Get Mapbox API key (free account)
3. ☐ Buy 1 test GPS device (Teltonika FM1010)
4. ☐ Create Flutter project + scaffold
5. ☐ Start with Auth screens (Week 1)

---

## Timeline Summary

| Milestone | Week | Status |
|-----------|------|--------|
| Auth working | 1 | Planning |
| Vehicle + GPS setup | 2 | Planning |
| **Live map showing vehicles** | 3 | **NEW FOCUS** |
| Expense + AI | 4 | Planning |
| LINE + Polish | 5 | Planning |
| Demo ready | 6 | Target |

**Total Investment**: 17-23 hours over 6 weeks (3-4 hrs/week)
**Total Cost**: ~$100 (1 test device) + free cloud
**Potential Revenue**: $50-100/month per customer

This is very doable. Map tracking makes product 10x stronger. 🚀
