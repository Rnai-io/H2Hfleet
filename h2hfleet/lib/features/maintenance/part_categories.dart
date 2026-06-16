import 'package:flutter/material.dart';

class PartCategory {
  final String key;
  final String labelTh;
  final String labelEn;
  final IconData icon;
  final Color color;

  const PartCategory({
    required this.key,
    required this.labelTh,
    required this.labelEn,
    required this.icon,
    required this.color,
  });

  String label(bool isTh) => isTh ? labelTh : labelEn;
}

const kPartCategories = <PartCategory>[
  PartCategory(
    key: 'engine',
    labelTh: 'เครื่องยนต์',
    labelEn: 'Engine',
    icon: Icons.settings_rounded,
    color: Color(0xFFDC2626),
  ),
  PartCategory(
    key: 'oil',
    labelTh: 'น้ำมันเครื่อง',
    labelEn: 'Engine Oil',
    icon: Icons.opacity_rounded,
    color: Color(0xFFD97706),
  ),
  PartCategory(
    key: 'brake',
    labelTh: 'เบรก',
    labelEn: 'Brake',
    icon: Icons.album_rounded,
    color: Color(0xFFB91C1C),
  ),
  PartCategory(
    key: 'tire',
    labelTh: 'ยาง / ล้อ',
    labelEn: 'Tire / Wheel',
    icon: Icons.tire_repair_rounded,
    color: Color(0xFF1F2937),
  ),
  PartCategory(
    key: 'battery',
    labelTh: 'แบตเตอรี่',
    labelEn: 'Battery',
    icon: Icons.battery_charging_full_rounded,
    color: Color(0xFF059669),
  ),
  PartCategory(
    key: 'suspension',
    labelTh: 'ช่วงล่าง',
    labelEn: 'Suspension',
    icon: Icons.vertical_align_center_rounded,
    color: Color(0xFF7C3AED),
  ),
  PartCategory(
    key: 'electrical',
    labelTh: 'ไฟฟ้า / ระบบไฟ',
    labelEn: 'Electrical',
    icon: Icons.electric_bolt_rounded,
    color: Color(0xFFCA8A04),
  ),
  PartCategory(
    key: 'ac',
    labelTh: 'แอร์',
    labelEn: 'Air Conditioning',
    icon: Icons.ac_unit_rounded,
    color: Color(0xFF0891B2),
  ),
  PartCategory(
    key: 'transmission',
    labelTh: 'เกียร์ / คลัตช์',
    labelEn: 'Transmission / Clutch',
    icon: Icons.sync_alt_rounded,
    color: Color(0xFF4338CA),
  ),
  PartCategory(
    key: 'body',
    labelTh: 'ตัวถัง / สี',
    labelEn: 'Body / Paint',
    icon: Icons.directions_car_filled_rounded,
    color: Color(0xFF2563EB),
  ),
  PartCategory(
    key: 'exhaust',
    labelTh: 'ท่อไอเสีย',
    labelEn: 'Exhaust',
    icon: Icons.air_rounded,
    color: Color(0xFF6B7280),
  ),
  PartCategory(
    key: 'other',
    labelTh: 'อื่นๆ',
    labelEn: 'Other',
    icon: Icons.build_circle_rounded,
    color: Color(0xFF64748B),
  ),
];

PartCategory partCategoryByKey(String key) =>
    kPartCategories.firstWhere((c) => c.key == key, orElse: () => kPartCategories.last);
