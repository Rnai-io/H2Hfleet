import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerStatefulWidget, ConsumerState;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_exporter.dart';
import '../../core/i18n/app_strings.dart';
import '../../providers/locale_provider.dart';

/// Role ระดับองค์กร (Active Directory RBAC)
enum AdRole {
  superAdmin('Super Admin (ผู้ดูแลระบบสูงสุด)', Icons.admin_panel_settings_rounded, Color(0xFFEF4444)),
  fleetManager('Fleet Manager (ผู้จัดการกองรถ)', Icons.local_shipping_rounded, Color(0xFF0284C7)),
  safetyDispatcher('Safety & Dispatcher (ฝ่ายความปลอดภัยและจัดรถ)', Icons.shield_rounded, Color(0xFF10B981)),
  technician('Technician (ช่างเทคนิคซ่อมบำรุง)', Icons.build_rounded, Color(0xFFF59E0B)),
  driver('Fleet Driver (พนักงานขับรถ)', Icons.badge_rounded, Color(0xFF8B5CF6));

  final String label;
  final IconData icon;
  final Color color;
  const AdRole(this.label, this.icon, this.color);
}

/// โมเดลผู้ใช้งาน Active Directory
class AdUser {
  final String id;
  String name;
  String email;
  AdRole role;
  String department;
  bool isActive;
  bool mfaEnabled;
  String lastLogin;

  AdUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.isActive = true,
    this.mfaEnabled = true,
    required this.lastLogin,
  });
}

/// ประวัติกิจกรรม Audit Log
class AuditLogItem {
  final String timestamp;
  final String user;
  final String action;
  final String ip;
  final IconData icon;

  const AuditLogItem({
    required this.timestamp,
    required this.user,
    required this.action,
    required this.ip,
    required this.icon,
  });
}

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;

  // Controllers สำหรับข้อมูลบริษัท
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();

  // Fleet Policy Settings
  double _maxSpeedLimit = 90.0;
  bool _nightCurfewEnabled = true;
  int _gpsIntervalSec = 10;
  bool _requirePreTripCheck = true;

  bool _isSaving = false;
  bool _isSaved = false;

  static const _keyName = 'company_name';
  static const _keyAddress = 'company_address';
  static const _keyPhone = 'company_phone';
  static const _keyEmail = 'company_email';
  static const _keyTaxId = 'company_tax_id';
  static const _keyBranch = 'company_branch';
  static const _keySpeed = 'policy_max_speed';
  static const _keyCurfew = 'policy_night_curfew';
  static const _keyGpsInterval = 'policy_gps_interval';
  static const _keyPreTrip = 'policy_pretrip_check';

  // รายชื่อผู้ใช้งาน Active Directory (RBAC)
  final List<AdUser> _adUsers = [
    AdUser(
      id: 'AD-001',
      name: 'สมชาย วงศ์สวัสดิ์ (Somchai W.)',
      email: 'somchai.w@h2hfleet.com',
      role: AdRole.superAdmin,
      department: 'Executive Operations',
      isActive: true,
      mfaEnabled: true,
      lastLogin: 'วันนี้, 15:42 น.',
    ),
    AdUser(
      id: 'AD-002',
      name: 'กาญจนา เพ็ชรศิริ (Kanchana P.)',
      email: 'kanchana.p@h2hfleet.com',
      role: AdRole.fleetManager,
      department: 'Logistics Operations',
      isActive: true,
      mfaEnabled: true,
      lastLogin: 'วันนี้, 14:20 น.',
    ),
    AdUser(
      id: 'AD-003',
      name: 'อนันต์ สายตรง (Anan S.)',
      email: 'anan.s@h2hfleet.com',
      role: AdRole.safetyDispatcher,
      department: 'Safety & Dispatch',
      isActive: true,
      mfaEnabled: false,
      lastLogin: 'วันนี้, 11:05 น.',
    ),
    AdUser(
      id: 'AD-004',
      name: 'วิชัย ช่างทอง (Wichai C.)',
      email: 'wichai.c@h2hfleet.com',
      role: AdRole.technician,
      department: 'Maintenance & Garage',
      isActive: true,
      mfaEnabled: true,
      lastLogin: 'เมื่อวาน, 16:30 น.',
    ),
    AdUser(
      id: 'AD-005',
      name: 'สมเกียรติ ยิ้มแย้ม (Somkiat Y.)',
      email: 'somkiat.y@h2hfleet.com',
      role: AdRole.driver,
      department: 'Fleet Driving Team',
      isActive: true,
      mfaEnabled: false,
      lastLogin: 'วันนี้, 08:15 น.',
    ),
  ];

  // บันทึกกิจกรรม Audit Logs
  final List<AuditLogItem> _auditLogs = [
    const AuditLogItem(
      timestamp: '28 ส.ค. 2026 15:58:12',
      user: 'somchai.w (Super Admin)',
      action: 'ปรับแก้ Speed Limit นโยบายความปลอดภัยเป็น 90 km/h',
      ip: '192.168.1.104 (TLS 1.3)',
      icon: Icons.speed_rounded,
    ),
    const AuditLogItem(
      timestamp: '28 ส.ค. 2026 14:15:30',
      user: 'kanchana.p (Fleet Manager)',
      action: 'สร้างกำหนดการซ่อมบำรุง 5,000 กม. ให้รถ ทะเบียน 7กบ-9901',
      ip: '192.168.1.112 (TLS 1.3)',
      icon: Icons.build_circle_rounded,
    ),
    const AuditLogItem(
      timestamp: '28 ส.ค. 2026 11:20:04',
      user: 'anan.s (Safety Officer)',
      action: 'อนุมัติการตรวจสอบ Pre-trip Checklist คนขับ ท.3-4819203',
      ip: '192.168.1.120 (TLS 1.3)',
      icon: Icons.verified_user_rounded,
    ),
    const AuditLogItem(
      timestamp: '28 ส.ค. 2026 09:00:18',
      user: 'System Bot (@655Jmtme)',
      action: 'ส่งสรุปรายงานประจำวันไปยัง LINE Official Channel สำเร็จ',
      ip: 'Cloud Webhook (Supabase)',
      icon: Icons.mark_chat_read_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nameCtrl.text = prefs.getString(_keyName) ?? 'บริษัท เอช ทู เอช โลจิสติกส์ จำกัด';
        _addressCtrl.text = prefs.getString(_keyAddress) ?? '123/45 ถนนวิภาวดีรังสิต แขวงจตุจักร เขตจตุจักร กรุงเทพฯ 10900';
        _phoneCtrl.text = prefs.getString(_keyPhone) ?? '02-555-8899';
        _emailCtrl.text = prefs.getString(_keyEmail) ?? 'contact@h2hfleet.com';
        _taxIdCtrl.text = prefs.getString(_keyTaxId) ?? '0105559012345';
        _branchCtrl.text = prefs.getString(_keyBranch) ?? 'สำนักงานใหญ่ (สาขา 00000)';
        _maxSpeedLimit = prefs.getDouble(_keySpeed) ?? 90.0;
        _nightCurfewEnabled = prefs.getBool(_keyCurfew) ?? true;
        _gpsIntervalSec = prefs.getInt(_keyGpsInterval) ?? 10;
        _requirePreTripCheck = prefs.getBool(_keyPreTrip) ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _isSaved = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, _nameCtrl.text.trim());
    await prefs.setString(_keyAddress, _addressCtrl.text.trim());
    await prefs.setString(_keyPhone, _phoneCtrl.text.trim());
    await prefs.setString(_keyEmail, _emailCtrl.text.trim());
    await prefs.setString(_keyTaxId, _taxIdCtrl.text.trim());
    await prefs.setString(_keyBranch, _branchCtrl.text.trim());
    await prefs.setDouble(_keySpeed, _maxSpeedLimit);
    await prefs.setBool(_keyCurfew, _nightCurfewEnabled);
    await prefs.setInt(_keyGpsInterval, _gpsIntervalSec);
    await prefs.setBool(_keyPreTrip, _requirePreTripCheck);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });
      final s = ref.read(strProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.companyProfileSaved),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSaved = false);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxIdCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(strProvider);
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 54,
        titleSpacing: 4,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
          child: Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enterprise Control Panel & Active Directory',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Colors.white),
                ),
                Text(
                  s.isTh ? 'ศูนย์ควบคุมระบบองค์กร, สิทธิ์ผู้ใช้งาน และนโยบายกองรถ' : 'Corporate Directory & Fleet Governance',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: Icon(_isSaved ? Icons.check_circle_rounded : Icons.save_rounded, size: 18),
              label: Text(_isSaved ? 'บันทึกเรียบร้อย' : 'บันทึกการตั้งค่า'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaved ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation Tab Bar
          _buildNavigationTabBar(isLargeScreen),

          // Main Tab Body
          Expanded(
            child: isLargeScreen
                ? _buildLargeScreenBody(context, s)
                : _buildMobileBody(context, s),
          ),
        ],
      ),
    );
  }

  // ═══════════════ Tab Bar ═══════════════
  Widget _buildNavigationTabBar(bool isLargeScreen) {
    final tabs = [
      {'title': 'ข้อมูลองค์กร & หัวบิล', 'icon': Icons.apartment_rounded},
      {'title': 'Active Directory (RBAC)', 'icon': Icons.people_alt_rounded},
      {'title': 'นโยบายควบคุมกองรถ (Policy)', 'icon': Icons.tune_rounded},
      {'title': 'ความปลอดภัย & Audit Logs', 'icon': Icons.security_rounded},
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 24 : 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            final tab = tabs[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedTabIndex = index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tab['title'] as String,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ═══════════════ iPad & Web Layout ═══════════════
  Widget _buildLargeScreenBody(BuildContext context, AppStrings s) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildCorporateIdentityTab(context, s, isLarge: true);
      case 1:
        return _buildActiveDirectoryTab(context, isLarge: true);
      case 2:
        return _buildFleetPolicyTab(context, isLarge: true);
      case 3:
        return _buildSecurityAuditTab(context, isLarge: true);
      default:
        return _buildCorporateIdentityTab(context, s, isLarge: true);
    }
  }

  // ═══════════════ Mobile Layout ═══════════════
  Widget _buildMobileBody(BuildContext context, AppStrings s) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildCorporateIdentityTab(context, s, isLarge: false);
      case 1:
        return _buildActiveDirectoryTab(context, isLarge: false);
      case 2:
        return _buildFleetPolicyTab(context, isLarge: false);
      case 3:
        return _buildSecurityAuditTab(context, isLarge: false);
      default:
        return _buildCorporateIdentityTab(context, s, isLarge: false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 0: ข้อมูลองค์กร & หัวบิล (Corporate Identity & Document Header)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildCorporateIdentityTab(BuildContext context, AppStrings s, {required bool isLarge}) {
    if (isLarge) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left (Identity & PDF Header Preview: 45%)
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCorporateSummaryCard(),
                    const SizedBox(height: 16),
                    _buildLineOfficialCard(),
                    const SizedBox(height: 16),
                    _buildInvoicePreviewCard(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Right (Form Fields: 55%)
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  child: _buildCorporateForm(s),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        children: [
          _buildCorporateSummaryCard(),
          const SizedBox(height: 16),
          _buildLineOfficialCard(),
          const SizedBox(height: 20),
          _buildCorporateForm(s),
          const SizedBox(height: 20),
          _buildInvoicePreviewCard(),
        ],
      ),
    );
  }

  Widget _buildCorporateSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.8),
                ),
                child: const Icon(Icons.business_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'ชื่อบริษัท / กิจการขนส่ง',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    const Text('H2HFleet Enterprise Production · AD Domain Active', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF334155)),
          const SizedBox(height: 12),
          _CorpInfoRow(icon: Icons.badge_rounded, label: 'เลขประจำตัวผู้เสียภาษี', value: _taxIdCtrl.text.isNotEmpty ? _taxIdCtrl.text : '–'),
          const SizedBox(height: 8),
          _CorpInfoRow(icon: Icons.store_mall_directory_rounded, label: 'สาขาที่ออกเอกสาร', value: _branchCtrl.text.isNotEmpty ? _branchCtrl.text : 'สำนักงานใหญ่'),
          const SizedBox(height: 8),
          _CorpInfoRow(icon: Icons.phone_rounded, label: 'เบอร์โทรศัพท์ติดต่อ', value: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : '–'),
          const SizedBox(height: 8),
          _CorpInfoRow(icon: Icons.email_rounded, label: 'อีเมลบริษัท', value: _emailCtrl.text.isNotEmpty ? _emailCtrl.text : '–'),
        ],
      ),
    );
  }

  Widget _buildLineOfficialCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF06C755).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF06C755), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LINE Official Enterprise Bot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                Text('LINE: @655Jmtme · ส่งแจ้งเตือนฉุกเฉิน & สรุปรายงานรายวัน', style: TextStyle(fontSize: 11, color: Color(0xFF047857))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => openExternalUrl('https://line.me/R/ti/p/@655Jmtme'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06C755),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('แอด LINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicePreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Text('ตัวอย่างหัวบิลและรายงาน (Document Header Preview)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isNotEmpty ? _nameCtrl.text.toUpperCase() : 'COMPANY NAME CO., LTD.',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  _addressCtrl.text.isNotEmpty ? _addressCtrl.text : '123/45 ถนนวิภาวดีรังสิต แขวงจตุจักร เขตจตุจักร กรุงเทพฯ 10900',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'TAX ID: ${_taxIdCtrl.text.isNotEmpty ? _taxIdCtrl.text : "0105550000000"} | สาขา: ${_branchCtrl.text.isNotEmpty ? _branchCtrl.text : "สนญ."} | TEL: ${_phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : "02-xxx-xxxx"}',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorporateForm(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.companyName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameCtrl,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          decoration: _decoration(s.companyNameHint, Icons.apartment_rounded),
        ),
        const SizedBox(height: 16),

        Text(s.companyAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _addressCtrl,
          onChanged: (_) => setState(() {}),
          maxLines: 3,
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          decoration: _decoration(s.companyAddressHint, Icons.location_on_outlined),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.companyPhone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneCtrl,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: _decoration('08x-xxx-xxxx', Icons.phone_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.companyEmail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: _decoration('info@company.com', Icons.email_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.companyTaxId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _taxIdCtrl,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: _decoration('เลขประจำตัว 13 หลัก', Icons.badge_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('สาขาที่ออกใบเสร็จ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _branchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: _decoration('สาขา 00000', Icons.store_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: Icon(_isSaved ? Icons.check_circle_rounded : Icons.save_rounded, size: 20),
            label: Text(_isSaved ? 'บันทึกเรียบร้อย' : (s.isTh ? 'บันทึกข้อมูลบริษัท' : 'Save Company Profile'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSaved ? const Color(0xFF10B981) : const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 1: Active Directory & RBAC User Management
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildActiveDirectoryTab(BuildContext context, {required bool isLarge}) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isLarge ? 24 : 16, 20, isLarge ? 24 : 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AD Domain Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hub_rounded, color: Color(0xFF38BDF8), size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Directory & RBAC Management', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Domain: ad.h2hfleet.internal · SAML SSO / Multi-Factor Authentication (MFA) Active', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('เพิ่มผู้ใช้งาน AD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // User Table / Cards
          Text(
            'รายชื่อผู้ดูแลและพนักงานในระบบ Active Directory (${_adUsers.length} บัญชี)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          ..._adUsers.map((user) => _buildUserCard(user)),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: user.isActive ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: user.role.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: user.role.color, width: 1.5),
            ),
            child: Icon(user.role.icon, color: user.role.color, size: 22),
          ),
          const SizedBox(width: 14),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.role.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: user.role.color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        user.role.label.split(' ')[0],
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: user.role.color),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (user.mfaEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_rounded, size: 10, color: Color(0xFF10B981)),
                            SizedBox(width: 3),
                            Text('MFA 2FA', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${user.email} · แผนก: ${user.department} · เข้าสู่ระบบล่าสุด: ${user.lastLogin}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Action Controls (Edit / Status Toggle / Delete)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Edit User Button
              IconButton(
                tooltip: 'แก้ไขข้อมูลผู้ใช้ (Edit User)',
                icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7), size: 22),
                onPressed: () => _showEditUserDialog(user),
              ),

              // 2. Toggle Active / Suspended
              IconButton(
                tooltip: user.isActive ? 'สถานะ: ปกติ (คลิกเพื่อระงับสิทธิ์)' : 'สถานะ: ระงับสิทธิ์ (คลิกเพื่อเปิดใช้งาน)',
                icon: Icon(
                  user.isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                  color: user.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 20,
                ),
                onPressed: () {
                  setState(() => user.isActive = !user.isActive);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.name} เปลี่ยนสถานะเป็น ${user.isActive ? "Active (ใช้งานได้)" : "Suspended (ระงับสิทธิ์)"}'),
                      backgroundColor: user.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  );
                },
              ),

              // 3. Delete User Button
              IconButton(
                tooltip: 'ลบผู้ใช้ (Delete User)',
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: () => _showDeleteUserDialog(user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Edit User Dialog ───────────────────────────────────────────────────────
  void _showEditUserDialog(AdUser user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final deptCtrl = TextEditingController(text: user.department);
    AdRole selectedRole = user.role;
    bool mfa = user.mfaEnabled;
    bool active = user.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF0284C7), size: 22),
              ),
              const SizedBox(width: 10),
              const Text('แก้ไขข้อมูลผู้ใช้ (Edit User)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'ชื่อ - นามสกุล', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'อีเมลองค์กร', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(labelText: 'แผนก / สังกัด', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AdRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'บทบาทในระบบ (RBAC Role)', border: OutlineInputBorder()),
                    items: AdRole.values.map((r) => DropdownMenuItem(
                      value: r,
                      child: Row(
                        children: [
                          Icon(r.icon, size: 16, color: r.color),
                          const SizedBox(width: 8),
                          Text(r.label.split(' ')[0], style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          Text('(${r.label.split('(')[1]}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('การยืนยันตัวตนสองชั้น (MFA / 2FA)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    value: mfa,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (v) => setDialogState(() => mfa = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('สถานะบัญชีผู้ใช้ (Account Active)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    value: active,
                    activeThumbColor: const Color(0xFF0284C7),
                    onChanged: (v) => setDialogState(() => active = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('บันทึกการแก้ไข'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                  setState(() {
                    user.name = nameCtrl.text.trim();
                    user.email = emailCtrl.text.trim();
                    user.department = deptCtrl.text.trim();
                    user.role = selectedRole;
                    user.mfaEnabled = mfa;
                    user.isActive = active;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('อัปเดตข้อมูลผู้ใช้ ${user.name} สำเร็จ'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete User Dialog ─────────────────────────────────────────────────────
  void _showDeleteUserDialog(AdUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text('ยืนยันการลบผู้ใช้', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'คุณต้องการลบบัญชี "${user.name}" (${user.email}) ออกจากระบบ Active Directory ขององค์กรใช่หรือไม่?\n\nการกระทำนี้จะเพิกถอนสิทธิ์การเข้าถึงระบบทั้งหมดทันที',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('ลบผู้ใช้ทันที'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                _adUsers.removeWhere((u) => u.id == user.id);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ลบผู้ใช้ ${user.name} ออกจากระบบแล้ว'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Add User Dialog ────────────────────────────────────────────────────────
  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    AdRole selectedRole = AdRole.driver;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0284C7)),
              SizedBox(width: 10),
              Text('เพิ่มผู้ใช้งาน Active Directory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'ชื่อ - นามสกุล (ภาษาไทย / อังกฤษ)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'อีเมลองค์กร (@h2hfleet.com)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(labelText: 'แผนก / สังกัด', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AdRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'บทบาทในระบบ (RBAC Role)', border: OutlineInputBorder()),
                    items: AdRole.values.map((r) => DropdownMenuItem(
                      value: r,
                      child: Row(
                        children: [
                          Icon(r.icon, size: 16, color: r.color),
                          const SizedBox(width: 8),
                          Text(r.label.split(' ')[0], style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          Text('(${r.label.split('(')[1]}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('เพิ่มผู้ใช้งาน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                  setState(() {
                    _adUsers.add(
                      AdUser(
                        id: 'AD-00${_adUsers.length + 1}',
                        name: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        role: selectedRole,
                        department: deptCtrl.text.isNotEmpty ? deptCtrl.text.trim() : 'Operations',
                        lastLogin: 'รอดำเนินการ (Pending)',
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เพิ่มผู้ใช้ ${nameCtrl.text.trim()} เข้าสู่ระบบเรียบร้อย'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 2: นโยบายควบคุมกองรถ (Fleet Telematics & Policy)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFleetPolicyTab(BuildContext context, {required bool isLarge}) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isLarge ? 24 : 16, 20, isLarge ? 24 : 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fleet Telematics Governance & Safety Policies', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('กำหนดกฎเกณฑ์และพารามิเตอร์อัตโนมัติสำหรับรถและคนขับทุกคันในกองยานยนต์', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Policy 1: Speed Limit
          _PolicyCard(
            icon: Icons.speed_rounded,
            title: 'ขีดจำกัดความเร็วสูงสุด (Max Speed Limit Alert)',
            description: 'ระบบจะส่งสัญญาณเตือนคนขับและบันทึกเหตุการณ์ความเร็วเกินลง Audit Log อัตโนมัติ',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxSpeedLimit,
                    min: 60.0,
                    max: 140.0,
                    divisions: 16,
                    label: '${_maxSpeedLimit.toInt()} กม./ชม.',
                    activeColor: const Color(0xFF0284C7),
                    onChanged: (val) => setState(() => _maxSpeedLimit = val),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0284C7)),
                  ),
                  child: Text(
                    '${_maxSpeedLimit.toInt()} กม./ชม.',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Policy 2: Night Curfew
          _PolicyCard(
            icon: Icons.nights_stay_rounded,
            title: 'เคอร์ฟิวการขับรถช่วงเวลากลางคืน (Night Driving Curfew)',
            description: 'แจ้งเตือนผู้จัดการกองรถทันทีหากมีรถออกปฏิบัติการในช่วงเวลา 22:00 - 05:00 น.',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_nightCurfewEnabled ? 'เปิดใช้งานเคอร์ฟิวความปลอดภัยกลางคืน (Active)' : 'ปิดการตรวจจับเคอร์ฟิว', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              value: _nightCurfewEnabled,
              activeThumbColor: const Color(0xFF0284C7),
              onChanged: (val) => setState(() => _nightCurfewEnabled = val),
            ),
          ),

          const SizedBox(height: 12),

          // Policy 3: GPS Telematics Interval
          _PolicyCard(
            icon: Icons.satellite_alt_rounded,
            title: 'ความถี่การส่งสัญญาณ GPS Beacon (Telematics Interval)',
            description: 'อัตราการส่งพิกัดดาวเทียมเข้าเซิร์ฟเวอร์แบบเรียลไทม์',
            child: Row(
              children: [5, 10, 30, 60].map((sec) {
                final isSelected = _gpsIntervalSec == sec;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text('$sec วินาที'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0284C7),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w700),
                    onSelected: (_) => setState(() => _gpsIntervalSec = sec),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Policy 4: Pre-Trip Safety Check
          _PolicyCard(
            icon: Icons.checklist_rounded,
            title: 'บังคับตรวจ Pre-Trip Safety Checklist ก่อนเริ่มงาน',
            description: 'คนขับต้องยืนยันการตรวจสภาพ ลมยาง เบรก และระดับแอลกอฮอล์ 0.00 mg% ก่อนออกรถ',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_requirePreTripCheck ? 'บังคับตรวจเช็กทุกกะการทำงาน (Enforced)' : 'เปิดให้ข้ามการตรวจเช็กได้', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              value: _requirePreTripCheck,
              activeThumbColor: const Color(0xFF10B981),
              onChanged: (val) => setState(() => _requirePreTripCheck = val),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 3: ความปลอดภัย & Audit Logs
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSecurityAuditTab(BuildContext context, {required bool isLarge}) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isLarge ? 24 : 16, 20, isLarge ? 24 : 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Status Badges
          const Row(
            children: [
              Expanded(
                child: _SecurityBadgeCard(
                  icon: Icons.lock_rounded,
                  title: 'TLS 1.3 Encryption',
                  subtitle: '256-bit AES End-to-End',
                  color: Color(0xFF10B981),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SecurityBadgeCard(
                  icon: Icons.cloud_done_rounded,
                  title: 'Supabase Cloud DB',
                  subtitle: 'PostgreSQL Realtime Sync',
                  color: Color(0xFF0284C7),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SecurityBadgeCard(
                  icon: Icons.verified_user_rounded,
                  title: 'Active Directory SSO',
                  subtitle: 'SAML 2.0 / LDAP Integrated',
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Audit Logs List
          const Text('บันทึกประวัติการเข้าใช้งานและปรับแต่งระบบ (System Audit Trail)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          ..._auditLogs.map((log) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(log.icon, size: 20, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.action, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text('${log.timestamp} · ดำเนินการโดย: ${log.user}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(log.ip, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────
class _CorpInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CorpInfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  const _PolicyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SecurityBadgeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SecurityBadgeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
