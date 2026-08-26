import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

enum WaypointType {
  start,
  pickup,
  rest,
  destination,
}

class RouteWaypoint {
  final String id;
  String name;
  final LatLng point;
  final WaypointType type;
  final String? address;

  RouteWaypoint({
    required this.id,
    required this.name,
    required this.point,
    required this.type,
    this.address,
  });

  RouteWaypoint copyWith({
    String? name,
    LatLng? point,
    WaypointType? type,
    String? address,
  }) {
    return RouteWaypoint(
      id: id,
      name: name ?? this.name,
      point: point ?? this.point,
      type: type ?? this.type,
      address: address ?? this.address,
    );
  }
}

class LocationSearchResult {
  final String title;
  final String subtitle;
  final LatLng point;
  final String category;

  const LocationSearchResult({
    required this.title,
    required this.subtitle,
    required this.point,
    required this.category,
  });
}

class RouteNavigationService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  // ─── 1. Preset Thai Logistics Hubs ─────────────────────────────────────────
  static const List<LocationSearchResult> presetHubs = [
    LocationSearchResult(
      title: 'ศูนย์กระจายสินค้า วังน้อย (DC Wang Noi)',
      subtitle: 'ถ.พหลโยธิน ต.ลำไทร อ.วังน้อย จ.พระนครศรีอยุธยา',
      point: LatLng(14.2272, 100.7145),
      category: 'คลังสินค้าหลัก',
    ),
    LocationSearchResult(
      title: 'ท่าเรือแหลมฉบัง (Laem Chabang Port)',
      subtitle: 'ต.ทุ่งสุขลา อ.ศรีราชา จ.ชลบุรี',
      point: LatLng(13.0827, 100.8847),
      category: 'ท่าเรือขนส่ง',
    ),
    LocationSearchResult(
      title: 'สนามบินสุวรรณภูมิ Cargo Terminal',
      subtitle: 'ต.หนองปรือ อ.บางพลี จ.สมุทรปราการ',
      point: LatLng(13.6900, 100.7501),
      category: 'คลังสินค้าอากาศยาน',
    ),
    LocationSearchResult(
      title: 'ตลาดไท (Talaad Thai)',
      subtitle: 'ถ.พหลโยธิน ต.คลองหนึ่ง อ.คลองหลวง จ.ปทุมธานี',
      point: LatLng(14.0792, 100.6275),
      category: 'ตลาดกลางกระจายสินค้า',
    ),
    LocationSearchResult(
      title: 'นิคมอุตสาหกรรมอมตะซิตี้ ชลบุรี',
      subtitle: 'ต.คลองตำหรุ อ.เมืองชลบุรี จ.ชลบุรี',
      point: LatLng(13.4184, 101.0028),
      category: 'นิคมอุตสาหกรรม',
    ),
    LocationSearchResult(
      title: 'จุดพักรถ มอเตอร์เวย์ บางปะกง (Service Area)',
      subtitle: 'ทล.พิเศษหมายเลข 7 (กรุงเทพฯ-ชลบุรี) กม.49',
      point: LatLng(13.5432, 101.0056),
      category: 'จุดพักรถ & ปั๊มน้ำมัน',
    ),
    LocationSearchResult(
      title: 'ศูนย์กระจายสินค้า บางนา-ตราด กม.19',
      subtitle: 'ถ.บางนา-ตราด ต.บางโฉลง อ.บางพลี จ.สมุทรปราการ',
      point: LatLng(13.6185, 100.7712),
      category: 'คลังสินค้าบางนา',
    ),
    LocationSearchResult(
      title: 'สถานีขนส่งสินค้า ร่มเกล้า (ICD Romklao)',
      subtitle: 'ถ.ร่มเกล้า แขวงคลองสามประเวศ เขตลาดกระบัง กรุงเทพฯ',
      point: LatLng(13.7386, 100.7412),
      category: 'สถานีบรรจุตู้สินค้า',
    ),
    LocationSearchResult(
      title: 'ศูนย์กระจายสินค้า นวนคร (Navanakorn DC)',
      subtitle: 'ต.คลองหนึ่ง อ.คลองหลวง จ.ปทุมธานี',
      point: LatLng(14.1205, 100.6052),
      category: 'คลังสินค้านวนคร',
    ),
    LocationSearchResult(
      title: 'จุดพักรถ ปตท. วังน้อย (PTT Rest Stop)',
      subtitle: 'ถ.พหลโยธิน ขาออก กม.55 จ.พระนครศรีอยุธยา',
      point: LatLng(14.2389, 100.7258),
      category: 'จุดพักรถ & ปั๊มน้ำมัน',
    ),
  ];

  // ─── 2. Search Online Location (Nominatim Geocoding) ───────────────────────
  static Future<List<LocationSearchResult>> searchLocations(String query) async {
    if (query.trim().isEmpty) return presetHubs;

    final trimmed = query.trim().toLowerCase();

    // 1. Check local preset matches first
    final localMatches = presetHubs
        .where((h) =>
            h.title.toLowerCase().contains(trimmed) ||
            h.subtitle.toLowerCase().contains(trimmed) ||
            h.category.toLowerCase().contains(trimmed))
        .toList();

    // 2. Fetch online results from OpenStreetMap Nominatim
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'countrycodes': 'th',
          'limit': '6',
          'addressdetails': '1',
        },
        options: Options(
          headers: {'User-Agent': 'H2HFleet_Telematics_App/1.0 (contact@h2hfleet.app)'},
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        final onlineResults = list.map((item) {
          final lat = double.tryParse(item['lat'].toString()) ?? 13.7563;
          final lon = double.tryParse(item['lon'].toString()) ?? 100.5018;
          final displayName = item['display_name']?.toString() ?? query;
          final parts = displayName.split(',');
          final title = parts.isNotEmpty ? parts.first.trim() : query;
          final subtitle = parts.length > 1
              ? parts.sublist(1, parts.length > 4 ? 4 : parts.length).join(',').trim()
              : displayName;

          return LocationSearchResult(
            title: title,
            subtitle: subtitle,
            point: LatLng(lat, lon),
            category: item['type']?.toString() ?? 'สถานที่ทั่วไป',
          );
        }).toList();

        // Combine unique results
        final all = [...localMatches, ...onlineResults];
        final seen = <String>{};
        return all.where((e) => seen.add('${e.point.latitude}_${e.point.longitude}')).toList();
      }
    } catch (_) {
      // Return local matches if offline
    }

    return localMatches.isNotEmpty ? localMatches : presetHubs;
  }

  // ─── 3. Calculate Driving Route with Road Coordinates (OSRM API) ──────────
  static Future<Map<String, dynamic>> calculateRoute({
    required LatLng start,
    required List<LatLng> waypoints,
    required LatLng destination,
  }) async {
    final allPoints = [start, ...waypoints, destination];

    // Build coordinate string for OSRM: lon,lat;lon,lat;...
    final coordsStr = allPoints.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url =
        'https://router.project-osrm.org/route/v1/driving/$coordsStr?overview=full&geometries=geojson';

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first;
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final polyline = coordinates.map<LatLng>((c) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();

          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSeconds = (route['duration'] as num).toDouble();

          final distanceKm = distanceMeters / 1000.0;
          final durationMinutes = durationSeconds / 60.0;

          // Estimated Fuel Cost (approx 8.5 km/L, 34 THB/L)
          final estimatedLiters = distanceKm / 8.5;
          final estimatedFuelCost = estimatedLiters * 34.0;

          return {
            'polyline': polyline,
            'distanceKm': distanceKm,
            'durationMinutes': durationMinutes,
            'fuelCost': estimatedFuelCost,
          };
        }
      }
    } catch (_) {
      // Fallback: Direct straight-line interpolation
    }

    // Straight-line fallback calculation
    final polyline = <LatLng>[];
    double totalKm = 0;
    const distanceCalculator = Distance();

    for (int i = 0; i < allPoints.length - 1; i++) {
      final p1 = allPoints[i];
      final p2 = allPoints[i + 1];
      polyline.add(p1);
      final segmentKm = distanceCalculator.as(LengthUnit.Kilometer, p1, p2);
      totalKm += segmentKm;
    }
    polyline.add(allPoints.last);

    final durationMinutes = (totalKm / 60.0) * 60; // assume 60 km/h average
    final estimatedFuelCost = (totalKm / 8.5) * 34.0;

    return {
      'polyline': polyline,
      'distanceKm': totalKm,
      'durationMinutes': durationMinutes,
      'fuelCost': estimatedFuelCost,
    };
  }

  // ─── 4. Generate Google Maps Direct Navigation URL ─────────────────────────
  static String buildGoogleMapsNavigationUrl({
    required LatLng start,
    required List<LatLng> waypoints,
    required LatLng destination,
  }) {
    final originStr = '${start.latitude},${start.longitude}';
    final destStr = '${destination.latitude},${destination.longitude}';

    if (waypoints.isEmpty) {
      return 'https://www.google.com/maps/dir/?api=1&origin=$originStr&destination=$destStr&travelmode=driving';
    }

    final waypointsStr = waypoints.map((p) => '${p.latitude},${p.longitude}').join('|');
    return 'https://www.google.com/maps/dir/?api=1&origin=$originStr&destination=$destStr&waypoints=$waypointsStr&travelmode=driving';
  }
}
