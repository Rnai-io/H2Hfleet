# Real-Time Map Tracking Implementation Guide

**For: H2HFleet MVP (Week 3)**

---

## Quick Overview

This guide shows how to add **live vehicle tracking** to your Flutter app using:
- **Mapbox** (map display)
- **Supabase Realtime** (live location updates)
- **Teltonika/Ruptela GPS devices** (location source)

---

## Part 1: Setup (30 minutes)

### 1.1 Get Mapbox API Key

1. Go to https://www.mapbox.com
2. Sign up (free account)
3. In dashboard: "Tokens" → "Create a token"
4. Copy token (starts with `pk.`)
5. Save: `MAPBOX_ACCESS_TOKEN=pk.xxx`

### 1.2 Add Mapbox to Flutter

In `pubspec.yaml`:

```yaml
dependencies:
  mapbox_maps_flutter: ^10.0.0
  flutter_map: ^6.0.0  # Alternative: lighter weight
  uuid: ^4.0.0
```

Run: `flutter pub get`

### 1.3 Update Supabase Schema

Add these tables to your Supabase:

```sql
-- Current vehicle location (updated in real-time)
CREATE TABLE vehicle_current_location (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id),
  lat DECIMAL(10, 8) NOT NULL,
  lng DECIMAL(11, 8) NOT NULL,
  speed DECIMAL(10, 2) DEFAULT 0,
  heading INTEGER DEFAULT 0, -- 0-360 degrees
  accuracy DECIMAL(10, 2), -- GPS accuracy in meters
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(vehicle_id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- GPS history (for playback later)
CREATE TABLE gps_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id),
  lat DECIMAL(10, 8) NOT NULL,
  lng DECIMAL(11, 8) NOT NULL,
  speed DECIMAL(10, 2) DEFAULT 0,
  heading INTEGER DEFAULT 0,
  engine_status TEXT,
  fuel_level DECIMAL(10, 2),
  recorded_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- GPS device mapping
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS gps_device_imei TEXT;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS gps_device_type TEXT;

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE vehicle_current_location;
ALTER PUBLICATION supabase_realtime ADD TABLE gps_logs;

-- Indexes
CREATE INDEX idx_gps_logs_vehicle_date 
  ON gps_logs(vehicle_id, recorded_at);
CREATE INDEX idx_vehicle_current_location_vehicle_id 
  ON vehicle_current_location(vehicle_id);
```

---

## Part 2: Backend - GPS Data Handler (1 hour)

### 2.1 Supabase Edge Function (Handle GPS Data)

Create: `supabase/functions/handle-gps-data/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js"

const supabaseUrl = Deno.env.get("SUPABASE_URL")
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")

serve(async (req) => {
  // Only accept POST
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 })
  }

  try {
    const data = await req.json()
    
    // Parse GPS data from Teltonika/Ruptela
    const { imei, latitude, longitude, speed, heading, accuracy } = data
    
    if (!imei || !latitude || !longitude) {
      return new Response("Missing required fields", { status: 400 })
    }

    const supabase = createClient(supabaseUrl!, supabaseKey!)

    // 1. Find vehicle by GPS device IMEI
    const { data: vehicle } = await supabase
      .from("vehicles")
      .select("id, company_id")
      .eq("gps_device_imei", imei)
      .single()

    if (!vehicle) {
      return new Response("Vehicle not found", { status: 404 })
    }

    const vehicleId = vehicle.id
    const now = new Date().toISOString()

    // 2. Save to gps_logs (history)
    await supabase.from("gps_logs").insert({
      vehicle_id: vehicleId,
      lat: latitude,
      lng: longitude,
      speed: speed || 0,
      heading: heading || 0,
      accuracy: accuracy,
      recorded_at: now,
    })

    // 3. Update vehicle_current_location (realtime)
    await supabase.from("vehicle_current_location").upsert({
      vehicle_id: vehicleId,
      lat: latitude,
      lng: longitude,
      speed: speed || 0,
      heading: heading || 0,
      accuracy: accuracy,
      updated_at: now,
    })

    // 4. Update vehicle status
    await supabase
      .from("vehicles")
      .update({ status: "active" })
      .eq("id", vehicleId)

    return new Response(
      JSON.stringify({ success: true, vehicleId }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    console.error("Error:", error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
```

**Deploy to Supabase:**
```bash
supabase functions deploy handle-gps-data
```

Get your function URL:
```
https://<your-project-id>.supabase.co/functions/v1/handle-gps-data
```

---

## Part 3: Flutter Implementation (2-3 hours)

### 3.1 Models

Create: `lib/models/vehicle_location_model.dart`

```dart
class VehicleLocationModel {
  final String vehicleId;
  final double lat;
  final double lng;
  final double speed;
  final int heading;
  final DateTime updatedAt;

  VehicleLocationModel({
    required this.vehicleId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.updatedAt,
  });

  factory VehicleLocationModel.fromJson(Map<String, dynamic> json) {
    return VehicleLocationModel(
      vehicleId: json['vehicle_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: json['heading'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
```

### 3.2 Map Provider (Riverpod)

Create: `lib/providers/map_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_location_model.dart';
import '../services/supabase_service.dart';

final vehicleLocationsProvider = StateNotifierProvider<
    VehicleLocationsNotifier,
    AsyncValue<Map<String, VehicleLocationModel>>>((ref) {
  return VehicleLocationsNotifier(ref);
});

class VehicleLocationsNotifier extends StateNotifier<
    AsyncValue<Map<String, VehicleLocationModel>>> {
  final Ref _ref;
  final _supabase = SupabaseService();

  VehicleLocationsNotifier(this._ref)
      : super(const AsyncValue.loading()) {
    _initializeRealtimeSubscription();
  }

  void _initializeRealtimeSubscription() {
    final user = _supabase.getCurrentUser();
    if (user == null) {
      state = const AsyncValue.data({});
      return;
    }

    // Subscribe to realtime updates
    _supabase.client
        .from('vehicle_current_location')
        .on(
          RealtimeListenOptions(event: 'UPDATE'),
          (payload) {
            _handleLocationUpdate(payload.newRecord);
          },
        )
        .on(
          RealtimeListenOptions(event: 'INSERT'),
          (payload) {
            _handleLocationUpdate(payload.newRecord);
          },
        )
        .subscribe();

    // Load initial locations
    _fetchInitialLocations();
  }

  Future<void> _fetchInitialLocations() async {
    try {
      final user = _supabase.getCurrentUser();
      if (user == null) return;

      // Get user's company
      final userRecord = await _supabase.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final companyId = userRecord['company_id'];

      // Get all vehicles for this company
      final vehicles = await _supabase.client
          .from('vehicles')
          .select('id')
          .eq('company_id', companyId);

      final vehicleIds =
          (vehicles as List).map((v) => v['id']).toList();

      if (vehicleIds.isEmpty) {
        state = const AsyncValue.data({});
        return;
      }

      // Get current locations
      final locations = await _supabase.client
          .from('vehicle_current_location')
          .select()
          .inFilter('vehicle_id', vehicleIds);

      final locationMap = <String, VehicleLocationModel>{};
      for (final loc in locations as List) {
        final model = VehicleLocationModel.fromJson(loc);
        locationMap[model.vehicleId] = model;
      }

      state = AsyncValue.data(locationMap);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _handleLocationUpdate(Map<String, dynamic> payload) {
    final location = VehicleLocationModel.fromJson(payload);
    
    state.whenData((locations) {
      final updatedLocations = {...locations};
      updatedLocations[location.vehicleId] = location;
      state = AsyncValue.data(updatedLocations);
    });
  }

  @override
  void dispose() {
    // Unsubscribe from realtime
    super.dispose();
  }
}
```

### 3.3 Map Screen

Create: `lib/features/map/presentation/screens/vehicle_map_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../models/vehicle_location_model.dart';
import '../../../../models/vehicle_model.dart';
import '../../../../providers/map_provider.dart';
import '../../../../providers/vehicles_provider.dart';

class VehicleMapScreen extends ConsumerWidget {
  const VehicleMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(vehicleLocationsProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final mapController = MapController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่รถ'),
        elevation: 0,
      ),
      body: locationsAsync.when(
        data: (locations) {
          return vehiclesAsync.when(
            data: (vehicles) {
              final markers = <Marker>[];

              for (final vehicle in vehicles) {
                final location = locations[vehicle.id];
                if (location != null) {
                  markers.add(
                    Marker(
                      point: LatLng(location.lat, location.lng),
                      width: 40,
                      height: 40,
                      child: _VehicleMarker(
                        vehicle: vehicle,
                        location: location,
                        onTap: () {
                          _showVehicleDetails(context, vehicle, location);
                        },
                      ),
                    ),
                  );
                }
              }

              return FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: const LatLng(13.7563, 100.5018), // Bangkok
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/'
                        '{bbox}/{width}/{height}@2x'
                        '?access_token=YOUR_MAPBOX_TOKEN',
                    additionalOptions: const {
                      'accessToken': 'YOUR_MAPBOX_TOKEN',
                    },
                  ),
                  MarkerLayer(markers: markers),
                  if (locations.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        mini: true,
                        onPressed: () {
                          // Fit all markers on screen
                          if (markers.isNotEmpty) {
                            final bounds = LatLngBounds.fromPoints(
                              markers.map((m) => m.point).toList(),
                            );
                            mapController.fitBounds(
                              bounds,
                              options: const FitBoundsOptions(
                                padding: EdgeInsets.all(100),
                              ),
                            );
                          }
                        },
                        child: const Icon(Icons.zoom_out_map),
                      ),
                    ),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showVehicleDetails(
    BuildContext context,
    VehicleModel vehicle,
    VehicleLocationModel location,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.plateNumber,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _DetailRow('ยี่ห้อ', '${vehicle.brand} ${vehicle.model}'),
              _DetailRow('ความเร็ว', '${location.speed.toStringAsFixed(1)} km/h'),
              _DetailRow(
                'ตำแหน่ง',
                '${location.lat.toStringAsFixed(6)}, '
                '${location.lng.toStringAsFixed(6)}',
              ),
              _DetailRow(
                'อัปเดตล่าสุด',
                _formatTime(location.updatedAt),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('ปิด'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}

class _VehicleMarker extends StatelessWidget {
  final VehicleModel vehicle;
  final VehicleLocationModel location;
  final VoidCallback onTap;

  const _VehicleMarker({
    required this.vehicle,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.directions_car,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
```

### 3.4 Add GPS Device Screen

Create: `lib/features/vehicles/presentation/screens/add_gps_device_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/vehicles_provider.dart';

class AddGpsDeviceScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const AddGpsDeviceScreen({
    Key? key,
    required this.vehicleId,
  }) : super(key: key);

  @override
  ConsumerState<AddGpsDeviceScreen> createState() =>
      _AddGpsDeviceScreenState();
}

class _AddGpsDeviceScreenState extends ConsumerState<AddGpsDeviceScreen> {
  final _imeiController = TextEditingController();
  String _deviceType = 'teltonika';
  bool _isLoading = false;

  @override
  void dispose() {
    _imeiController.dispose();
    super.dispose();
  }

  void _saveGpsDevice() async {
    if (_imeiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก IMEI')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save GPS device info to vehicle
      // This will be called through a new action in vehicles_provider
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึก GPS Device สำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า GPS Device')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'กรุณากรอกรายละเอียด GPS Device',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _imeiController,
              decoration: InputDecoration(
                labelText: 'IMEI หรือ Device ID',
                hintText: 'เช่น 352024086938299',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _deviceType,
              decoration: InputDecoration(
                labelText: 'ประเภท Device',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                'teltonika',
                'ruptela',
                'other',
              ]
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _deviceType = value!);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveGpsDevice,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('บันทึก GPS Device'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Part 4: GPS Device Configuration (20 minutes)

### 4.1 Teltonika Device Setup

**Physical Installation:**
1. Open vehicle's OBD2 connector (under steering wheel)
2. Connect Teltonika FM1010 to OBD2
3. Device gets power from vehicle battery
4. Waits for GPS signal (~30 seconds)

**Software Configuration:**
1. Get device IP address (check router or device manual)
2. Access web panel: `http://<device-ip>`
3. Default login: admin/admin
4. Go to: Settings → Data Protocols → HTTP
5. Configure HTTP endpoint:
   ```
   URL: https://<your-supabase-function-url>/handle-gps-data
   Method: POST
   Send interval: 60 seconds
   ```
6. Add custom fields in JSON:
   ```json
   {
     "imei": "${IMEI}",
     "latitude": ${GPS_LAT},
     "longitude": ${GPS_LNG},
     "speed": ${SPEED},
     "heading": ${HEADING},
     "accuracy": ${GPS_ACCURACY}
   }
   ```
7. Save & restart device

**Test**: Open your Flutter app → should see vehicle on map within 2 minutes

---

## Part 5: Integration with Main App

### 5.1 Update Main Navigation

In `lib/app.dart`, add map screen to navigation:

```dart
class H2HFleetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/vehicles': (_) => const VehicleListScreen(),
        '/map': (_) => const VehicleMapScreen(),  // NEW
        '/expenses': (_) => const ExpenseScreen(),
      },
    );
  }
}
```

### 5.2 Add Map Tab to Dashboard

```dart
class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final _screens = [
    const DashboardHomeScreen(),
    const VehicleMapScreen(),  // NEW
    const ExpenseScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'แผนที่',  // NEW
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'ค่าใช้จ่าย',
          ),
        ],
      ),
    );
  }
}
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Map doesn't show | Check Mapbox token in code |
| Vehicle not appearing | Check GPS device IMEI matches in DB |
| No realtime updates | Check Supabase RLS policies + subscriptions |
| Map tiles not loading | Check internet connection + Mapbox API key |
| Device sends data but no update | Check Supabase Edge Function logs |

---

## Next Steps

1. ☐ Set up Mapbox account + get token
2. ☐ Deploy Supabase Edge Function
3. ☐ Add tables to Supabase (schema)
4. ☐ Build Flutter map screen (copy code above)
5. ☐ Get test GPS device + install
6. ☐ Test end-to-end: Device → Function → Supabase → App

**Estimated time: 4-5 hours total**

Once map works, vehicle tracking becomes your killer feature! 🗺️
