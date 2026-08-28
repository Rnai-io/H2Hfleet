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
  final double? distanceKm;

  const LocationSearchResult({
    required this.title,
    required this.subtitle,
    required this.point,
    required this.category,
    this.distanceKm,
  });

  LocationSearchResult copyWith({
    String? title,
    String? subtitle,
    LatLng? point,
    String? category,
    double? distanceKm,
  }) {
    return LocationSearchResult(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      point: point ?? this.point,
      category: category ?? this.category,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

class RouteNavigationService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  // ─── 1. Preset Thai Logistics Hubs & POIs ──────────────────────────────────
  static const List<LocationSearchResult> presetHubs = [
    LocationSearchResult(
      title: 'ศูนย์กระจายสินค้า วังน้อย (DC Wang Noi)',
      subtitle: 'ถ.พหลโยธิน ต.ลำไทร อ.วังน้อย จ.พระนครศรีอยุธยา',
      point: LatLng(14.2272, 100.7145),
      category: 'คลังสินค้า',
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
      category: 'จุดพักรถ',
    ),
    LocationSearchResult(
      title: 'ศูนย์กระจายสินค้า บางนา-ตราด กม.19',
      subtitle: 'ถ.บางนา-ตราด ต.บางโฉลง อ.บางพลี จ.สมุทรปราการ',
      point: LatLng(13.6185, 100.7712),
      category: 'คลังสินค้า',
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
      category: 'คลังสินค้า',
    ),
    LocationSearchResult(
      title: 'จุดพักรถ ปตท. วังน้อย (PTT Station Rest Area)',
      subtitle: 'ถ.พหลโยธิน ขาออก กม.55 จ.พระนครศรีอยุธยา',
      point: LatLng(14.2389, 100.7258),
      category: 'ปั๊มน้ำมัน',
    ),
    LocationSearchResult(
      title: 'ปั๊ม ปตท. ชลบุรี-บายพาส (PTT Rest Stop)',
      subtitle: 'ถ.เลี่ยงเมืองชลบุรี ต.หนองไม้แดง อ.เมือง จ.ชลบุรี',
      point: LatLng(13.3852, 100.9950),
      category: 'ปั๊มน้ำมัน',
    ),
    LocationSearchResult(
      title: 'ศูนย์บริการรถบรรทุก ฮีโน่/อีซูซุ บางนา',
      subtitle: 'ถ.เทพรัตน กม.23 ต.บางเสาธง จ.สมุทรปราการ',
      point: LatLng(13.5824, 100.8123),
      category: 'อู่ซ่อมบำรุง',
    ),
  ];

  // ─── 2. Reverse Geocode Coordinate to Readable Address ────────────────────
  static Future<String> reverseGeocode(LatLng point) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': point.latitude,
          'lon': point.longitude,
          'format': 'json',
          'accept-language': 'th,en',
        },
        options: Options(
          headers: {'User-Agent': 'H2HFleet_Telematics_App/1.0 (contact@h2hfleet.app)'},
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final displayName = response.data['display_name']?.toString() ?? '';
        final parts = displayName.split(',');
        if (parts.length > 1) {
          return parts.take(4).join(', ').trim();
        }
        return displayName.isNotEmpty ? displayName : '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
      }
    } catch (_) {}

    return 'พิกัด ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
  }

  // ─── 3. Search Online Location (with Proximity & Category Bias) ───────────
  static Future<List<LocationSearchResult>> searchLocations(
    String query, {
    LatLng? userLocation,
    String? categoryFilter,
  }) async {
    const distanceCalc = Distance();

    // Attach distances to presetHubs based on userLocation
    List<LocationSearchResult> enrichedPresets = presetHubs.map((h) {
      if (userLocation != null) {
        final d = distanceCalc.as(LengthUnit.Kilometer, userLocation, h.point);
        return h.copyWith(distanceKm: d);
      }
      return h;
    }).toList();

    if (userLocation != null) {
      enrichedPresets.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    }

    if (query.trim().isEmpty) {
      if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all') {
        return enrichedPresets.where((h) => h.category.contains(categoryFilter)).toList();
      }
      return enrichedPresets;
    }

    final trimmed = query.trim().toLowerCase();

    // 1. Check local preset matches first
    final localMatches = enrichedPresets
        .where((h) =>
            h.title.toLowerCase().contains(trimmed) ||
            h.subtitle.toLowerCase().contains(trimmed) ||
            h.category.toLowerCase().contains(trimmed))
        .toList();

    // 2. Fetch online results from OpenStreetMap Nominatim with proximity viewbox
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'format': 'json',
        'countrycodes': 'th',
        'limit': '10',
        'addressdetails': '1',
      };

      if (userLocation != null) {
        // Bias search towards user/fleet current location within ~100km
        queryParams['viewbox'] =
            '${userLocation.longitude - 1.0},${userLocation.latitude + 1.0},${userLocation.longitude + 1.0},${userLocation.latitude - 1.0}';
        queryParams['bounded'] = '0';
      }

      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: queryParams,
        options: Options(
          headers: {'User-Agent': 'H2HFleet_Telematics_App/1.0 (contact@h2hfleet.app)'},
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        final onlineResults = list.map((item) {
          final lat = double.tryParse(item['lat'].toString()) ?? 13.7563;
          final lon = double.tryParse(item['lon'].toString()) ?? 100.5018;
          final pt = LatLng(lat, lon);
          final displayName = item['display_name']?.toString() ?? query;
          final parts = displayName.split(',');
          final title = parts.isNotEmpty ? parts.first.trim() : query;
          final subtitle = parts.length > 1
              ? parts.sublist(1, parts.length > 4 ? 4 : parts.length).join(', ').trim()
              : displayName;

          final dist = userLocation != null ? distanceCalc.as(LengthUnit.Kilometer, userLocation, pt) : null;

          return LocationSearchResult(
            title: title,
            subtitle: subtitle,
            point: pt,
            category: item['type']?.toString() ?? 'สถานที่ทั่วไป',
            distanceKm: dist,
          );
        }).toList();

        // Combine unique results
        final all = [...localMatches, ...onlineResults];
        final seen = <String>{};
        final unique = all.where((e) => seen.add('${e.point.latitude.toStringAsFixed(4)}_${e.point.longitude.toStringAsFixed(4)}')).toList();

        if (userLocation != null) {
          unique.sort((a, b) => (a.distanceKm ?? 9999).compareTo(b.distanceKm ?? 9999));
        }

        if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all') {
          return unique.where((h) => h.category.contains(categoryFilter)).toList();
        }

        return unique;
      }
    } catch (_) {
      // Fallback
    }

    return localMatches.isNotEmpty ? localMatches : enrichedPresets;
  }

  // ─── 4. Calculate Driving Route with Road Coordinates (OSRM API) ──────────
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
      // Fallback
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

    final durationMinutes = (totalKm / 60.0) * 60;
    final estimatedFuelCost = (totalKm / 8.5) * 34.0;

    return {
      'polyline': polyline,
      'distanceKm': totalKm,
      'durationMinutes': durationMinutes,
      'fuelCost': estimatedFuelCost,
    };
  }

  // ─── 5. Generate Google Maps Direct Navigation URL ─────────────────────────
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
