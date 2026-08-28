import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/vehicles_provider.dart';
import '../../../../providers/expenses_provider.dart';
import '../../../../providers/ai_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../core/widgets/large_screen_art_widgets.dart';
import '../../../../providers/vehicle_location_provider.dart';
import '../../../vehicles/presentation/screens/vehicle_list_screen.dart';
import '../../../expenses/presentation/screens/expense_list_screen.dart';
import '../../../expenses/presentation/screens/add_expense_dialog.dart';
import '../../../line/line_settings_screen.dart';
import '../../../map/map_screen.dart';
import '../../../driver/driver_mode_screen.dart';
import '../../../settings/ai_settings_screen.dart';
import '../../../settings/company_profile_screen.dart';
import '../../../maintenance/maintenance_screen.dart';
import '../../../ai_chat/presentation/screens/ai_chat_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final aiSummaryAsync = ref.watch(aiSummaryProvider);
    final s = ref.watch(strProvider);
    final locale = ref.watch(localeProvider);
    final isTh = locale.languageCode == 'th';
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;

    final now = DateTime.now();
    final todayTotal = expensesAsync.when(
      data: (expenses) => expenses
          .where((e) =>
              e.expenseDate.year == now.year &&
              e.expenseDate.month == now.month &&
              e.expenseDate.day == now.day)
          .fold<double>(0, (sum, e) => sum + e.amount),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final monthTotal = expensesAsync.when(
      data: (expenses) => expenses
          .where((e) => e.expenseDate.year == now.year && e.expenseDate.month == now.month)
          .fold<double>(0, (sum, e) => sum + e.amount),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final vehicleCount = vehiclesAsync.when(
      data: (v) => v.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final currencyFormat = NumberFormat('#,##0', 'th_TH');

    Future<void> sendLineNotify(String summary) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('line_user_id') ?? '';

        if (userId.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.noLineUserId),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          return;
        }

        final message = '''🚛 H2HFleet สรุปประจำวัน

$summary

📊 สถิติ:
• รถ: $vehicleCount คัน
• ค่าใช้จ่ายวันนี้: ฿${todayTotal.toStringAsFixed(0)}
• เดือนนี้: ฿${monthTotal.toStringAsFixed(0)}''';

        const supabaseUrl = 'https://rdobhvuiadmsqdfugrlp.supabase.co';
        const anonKey =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkb2JodnVpYWRtc3FkZnVncmxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNjU4MzMsImV4cCI6MjA5NDc0MTgzM30.7pvs8B38unEmBkPmP14lfgDrr59wjd-WroMiqpkIzvY';

        final dio = Dio(BaseOptions(validateStatus: (status) => true));

        final response = await dio.post(
          '$supabaseUrl/functions/v1/line-push-message',
          data: jsonEncode({
            'userId': userId,
            'message': message,
          }),
          options: Options(headers: {
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
            'Content-Type': 'application/json',
          }),
        );

        final ok = response.statusCode == 200;
        if (context.mounted) {
          final detail = ok ? '' : '\n[${response.statusCode}] ${response.data}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? s.sendLineSuccess : '${s.sendLineFail}$detail'),
              backgroundColor: ok ? AppColors.success : AppColors.danger,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      } on DioException catch (e) {
        final body = e.response?.data?.toString() ?? e.message ?? '$e';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('LINE Error [${e.response?.statusCode}]: $body'),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Network Error: $e'),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: const Color(0xFF0284C7),
        onRefresh: () async {
          ref.invalidate(vehiclesProvider);
          ref.invalidate(expensesProvider);
          ref.invalidate(aiSummaryProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Modern High-Tech Gradient Header (Scrolls naturally) ──
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B1120),
                      Color(0xFF0F172A),
                      Color(0xFF1E3A8A),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  children: [
                    // Ambient glow orb
                    Positioned(
                      top: -30,
                      right: -20,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                        ),
                      ),
                    ),

                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Logo Badge + Actions (Chat, Lang, Logout)
                            Row(
                              children: [
                                // New H2HFleet Brand Badge
                                Container(
                                  width: 42,
                                  height: 42,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const _FleetHeroIcon(),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'H2H',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 19,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'FLEET',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isTh ? 'ระบบออนไลน์สด' : 'Live Connected',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.75),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const Spacer(),

                                // AI Chat Quick Action
                                GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.5)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.auto_awesome_rounded, color: Color(0xFFA78BFA), size: 13),
                                        SizedBox(width: 4),
                                        Text(
                                          'AI',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Language Switcher Pill
                                GestureDetector(
                                  onTap: () => ref.read(localeProvider.notifier).toggle(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                    ),
                                    child: Text(
                                      isTh ? 'TH' : 'EN',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Logout Button
                                GestureDetector(
                                  onTap: () => ref.read(authRepositoryProvider).logout(),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    child: const Icon(Icons.logout_rounded, color: Colors.white, size: 15),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Greeting & Date
                            Text(
                              s.greeting,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy', isTh ? 'th_TH' : 'en_US').format(now),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Dashboard Body Content (Responsive Mobile vs iPad/Web) ───
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isLargeScreen ? 24 : 16,
                  18,
                  isLargeScreen ? 24 : 16,
                  32,
                ),
                child: isLargeScreen
                    // ═══════════════ iPad & Web Large Screen Layout ═══════════════
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Hero Art Banner with Cybernetic Mesh & Isometric Truck
                          CyberFleetHeroArt(
                            height: 180,
                            activeVehicles: vehicleCount,
                            isTh: isTh,
                          ),
                          const SizedBox(height: 20),

                          // 2. 4-Column KPI Stats Row
                          Row(
                            children: [
                              Expanded(
                                child: _KpiStatCard(
                                  icon: Icons.local_shipping_rounded,
                                  label: s.totalVehicles,
                                  value: '$vehicleCount',
                                  unit: s.vehiclesUnit,
                                  accentColor: const Color(0xFF0284C7),
                                  bgGradient: const [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _KpiStatCard(
                                  icon: Icons.payments_rounded,
                                  label: s.todayExpense,
                                  value: '฿${currencyFormat.format(todayTotal)}',
                                  unit: isTh ? 'วันนี้' : 'Today',
                                  accentColor: todayTotal > 0 ? const Color(0xFFEA580C) : const Color(0xFF10B981),
                                  bgGradient: const [Color(0xFFFEF2F2), Color(0xFFFFF7ED)],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _KpiStatCard(
                                  icon: Icons.calendar_month_rounded,
                                  label: s.monthExpense,
                                  value: '฿${currencyFormat.format(monthTotal)}',
                                  unit: isTh ? 'เดือนนี้' : 'This Mo.',
                                  accentColor: const Color(0xFF6366F1),
                                  bgGradient: const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _KpiStatCard(
                                  icon: Icons.satellite_alt_rounded,
                                  label: isTh ? 'สถานะ GPS สด' : 'GPS Telemetry',
                                  value: '$vehicleCount/$vehicleCount',
                                  unit: isTh ? 'ออนไลน์' : 'Online',
                                  accentColor: const Color(0xFF10B981),
                                  bgGradient: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 3. Dual-Pane Columns (Left 50% : Right 50%)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ─── Left Column (Menus & Expenses: 50%) ───
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionTitle(
                                      title: s.fleetControlCenter,
                                      badge: s.modulesCount(9),
                                    ),
                                    const SizedBox(height: 14),

                                    // 3-Column Menu Grid on Large Screen
                                    GridView.count(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 1.38,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      children: [
                                        _BespokeMenuTile(
                                          badge: const _FleetTruckIconBadge(),
                                          title: s.myVehicles,
                                          subtitle: '$vehicleCount ${s.vehiclesUnit} · ${isTh ? "ข้อมูลรถ" : "Fleet info"}',
                                          badgeTag: '$vehicleCount',
                                          badgeTagColor: const Color(0xFF1E3A8A),
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const VehicleListScreen()),
                                          ),
                                        ),
                                        _BespokeMenuTile(
                                          badge: const _LiveMapGpsIconBadge(),
                                          title: s.liveMap,
                                          subtitle: isTh ? 'ติดตาม GPS สดทุกคัน' : 'Live Telematics',
                                          isLive: true,
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const MapScreen()),
                                          ),
                                        ),
                                        _BespokeMenuTile(
                                          badge: const _DriverCockpitIconBadge(),
                                          title: s.driverMode,
                                          subtitle: isTh ? 'ส่งพิกัด GPS อัตโนมัติ' : 'Auto GPS Sync',
                                          badgeTag: isTh ? 'คนขับ' : 'Driver',
                                          badgeTagColor: const Color(0xFF059669),
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const DriverModeScreen()),
                                          ),
                                        ),
                                        _BespokeMenuTile(
                                          badge: const _MaintenanceWrenchIconBadge(),
                                          title: s.maintenance,
                                          subtitle: isTh ? 'ประวัติซ่อม / อะไหล่' : 'Repairs & Parts',
                                          badgeTag: isTh ? 'อะไหล่' : 'Parts',
                                          badgeTagColor: const Color(0xFFD97706),
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
                                          ),
                                        ),
                                        _BespokeMenuTile(
                                          badge: const _SmartExpenseIconBadge(),
                                          title: s.addExpense,
                                          subtitle: isTh ? 'บันทึกน้ำมัน & บิล' : 'Log Gas & Costs',
                                          badgeTag: isTh ? '+บันทึก' : '+Add',
                                          badgeTagColor: const Color(0xFFE11D48),
                                          onTap: () => showDialog(
                                            context: context,
                                            builder: (_) => const AddExpenseDialog(),
                                          ),
                                        ),
                                        _BespokeMenuTile(
                                          badge: const _AnalyticsChartIconBadge(),
                                          title: s.reports,
                                          subtitle: isTh ? 'สถิติและกราฟสรุป' : 'Cost Analytics',
                                          badgeTag: isTh ? 'สถิติ' : 'Stats',
                                          badgeTagColor: const Color(0xFF4F46E5),
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
                                          ),
                                        ),
                                        _BespokeMenuTile(
                                          badge: const _AiAssistantGalaxyBadge(),
                                          title: s.aiAssistant,
                                          subtitle: isTh ? 'ถาม-ตอบกับ AI' : 'Gemini Copilot',
                                          badgeTag: 'AI 2.5',
                                          badgeTagColor: const Color(0xFF7C3AED),
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const AiChatScreen()),
                                          ),
                                        ),
                                        _BespokeMenuTile(
                                          badge: const _LineNotifyBadge(),
                                          title: s.lineNotify,
                                          subtitle: isTh ? 'ส่งสรุปเข้า LINE' : 'LINE Bot Sync',
                                          badgeTag: 'LINE',
                                          badgeTagColor: const Color(0xFF06C755),
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const LineSettingsScreen()),
                                          ),
                                        ),
                                        _BespokeMenuTile(
                                          badge: const _CompanyEnterpriseBadge(),
                                          title: s.companyProfile,
                                          subtitle: isTh ? 'ตั้งค่าชื่อกิจการ' : 'HQ Profile',
                                          badgeTag: isTh ? 'โปรไฟล์' : 'Profile',
                                          badgeTagColor: const Color(0xFF0F172A),
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Recent Expenses Stream
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _SectionTitle(
                                          title: s.recentExpenses,
                                          badge: isTh ? '5 รายการล่าสุด' : 'Recent 5',
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                s.viewAll,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0284C7),
                                                ),
                                              ),
                                              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF0284C7)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildExpensesStream(expensesAsync, currencyFormat, isTh, s),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 20),

                              // ─── Right Column (Radar Map, AI Copilot, Line: 50%) ───
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Radar Telemetry Card
                                    IpadTelemetryRadarCard(
                                      vehicles: vehiclesAsync.valueOrNull ?? [],
                                      locations: ref.watch(vehicleLocationsProvider).valueOrNull ?? [],
                                      isTh: isTh,
                                      onOpenMap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const MapScreen()),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // 2. AI Copilot Intelligence
                                    _AiCopilotCard(
                                      s: s,
                                      aiSummaryAsync: aiSummaryAsync,
                                      onSendLine: (summary) => sendLineNotify(summary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    // ═══════════════ Mobile Screen Layout ═══════════════
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. KPI Stats Cards Row
                          Row(
                            children: [
                              Expanded(
                                child: _KpiStatCard(
                                  icon: Icons.local_shipping_rounded,
                                  label: s.totalVehicles,
                                  value: '$vehicleCount',
                                  unit: s.vehiclesUnit,
                                  accentColor: const Color(0xFF0284C7),
                                  bgGradient: const [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiStatCard(
                                  icon: Icons.payments_rounded,
                                  label: s.todayExpense,
                                  value: '฿${currencyFormat.format(todayTotal)}',
                                  unit: isTh ? 'วันนี้' : 'Today',
                                  accentColor: todayTotal > 0 ? const Color(0xFFEA580C) : const Color(0xFF10B981),
                                  bgGradient: const [Color(0xFFFEF2F2), Color(0xFFFFF7ED)],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiStatCard(
                                  icon: Icons.calendar_month_rounded,
                                  label: s.monthExpense,
                                  value: '฿${currencyFormat.format(monthTotal)}',
                                  unit: isTh ? 'เดือนนี้' : 'This Mo.',
                                  accentColor: const Color(0xFF6366F1),
                                  bgGradient: const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // 2. AI Telematics Copilot Card
                          _AiCopilotCard(
                            s: s,
                            aiSummaryAsync: aiSummaryAsync,
                            onSendLine: (summary) => sendLineNotify(summary),
                          ),

                          const SizedBox(height: 24),

                          // 3. All Features & Menus (9 Menus)
                          _SectionTitle(
                            title: s.fleetControlCenter,
                            badge: s.modulesCount(9),
                          ),
                          const SizedBox(height: 14),

                          // Grid of 9 Bespoke Action Menus
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.38,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _BespokeMenuTile(
                                badge: const _FleetTruckIconBadge(),
                                title: s.myVehicles,
                                subtitle: '$vehicleCount ${s.vehiclesUnit} · จัดการข้อมูล',
                                badgeTag: '$vehicleCount',
                                badgeTagColor: const Color(0xFF1E3A8A),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const VehicleListScreen()),
                                ),
                              ),
                              _BespokeMenuTile(
                                badge: const _LiveMapGpsIconBadge(),
                                title: s.liveMap,
                                subtitle: isTh ? 'ติดตาม GPS สดทุกคัน' : 'Live Telematics',
                                isLive: true,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const MapScreen()),
                                ),
                              ),
                              _BespokeMenuTile(
                                badge: const _DriverCockpitIconBadge(),
                                title: s.driverMode,
                                subtitle: isTh ? 'ส่งพิกัด GPS อัตโนมัติ' : 'Auto GPS Sync',
                                badgeTag: isTh ? 'คนขับ' : 'Driver',
                                badgeTagColor: const Color(0xFF059669),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const DriverModeScreen()),
                                ),
                              ),
                              _BespokeMenuTile(
                                badge: const _MaintenanceWrenchIconBadge(),
                                title: s.maintenance,
                                subtitle: isTh ? 'ประวัติซ่อม / อะไหล่' : 'Repairs & Parts',
                                badgeTag: isTh ? 'อะไหล่' : 'Parts',
                                badgeTagColor: const Color(0xFFD97706),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
                                ),
                              ),
                              _BespokeMenuTile(
                                badge: const _SmartExpenseIconBadge(),
                                title: s.addExpense,
                                subtitle: isTh ? 'บันทึกน้ำมัน & บิล' : 'Log Gas & Costs',
                                badgeTag: isTh ? '+บันทึก' : '+Add',
                                badgeTagColor: const Color(0xFFE11D48),
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => const AddExpenseDialog(),
                                ),
                              ),
                              _BespokeMenuTile(
                                badge: const _AnalyticsChartIconBadge(),
                                title: s.reports,
                                subtitle: isTh ? 'สถิติและกราฟสรุป' : 'Cost Analytics',
                                badgeTag: isTh ? 'สถิติ' : 'Stats',
                                badgeTagColor: const Color(0xFF4F46E5),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
                                ),
                              ),
                              _BespokeMenuTile(
                                badge: const _AiAssistantGalaxyBadge(),
                                title: s.aiAssistant,
                                subtitle: isTh ? 'ถาม-ตอบกับ AI' : 'Gemini Copilot',
                                badgeTag: 'AI 2.5',
                                badgeTagColor: const Color(0xFF7C3AED),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AiChatScreen()),
                                ),
                              ),
                              _BespokeMenuTile(
                                badge: const _LineNotifyBadge(),
                                title: s.lineNotify,
                                subtitle: isTh ? 'ส่งสรุปเข้า LINE' : 'LINE Bot Sync',
                                badgeTag: 'LINE',
                                badgeTagColor: const Color(0xFF06C755),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LineSettingsScreen()),
                                ),
                              ),
                              _BespokeMenuTile(
                                badge: const _CompanyEnterpriseBadge(),
                                title: s.companyProfile,
                                subtitle: isTh ? 'ตั้งค่าชื่อกิจการ' : 'HQ Profile',
                                badgeTag: isTh ? 'โปรไฟล์' : 'Profile',
                                badgeTagColor: const Color(0xFF0F172A),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
                                ),
                              ),
                              _BespokeMenuTile(
                                badge: const _AiSettingsGearBadge(),
                                title: isTh ? 'ตั้งค่าระบบ AI' : 'AI Settings',
                                subtitle: isTh ? 'จัดการ API Key' : 'API Key Setup',
                                badgeTag: 'CONFIG',
                                badgeTagColor: const Color(0xFF64748B),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 26),

                          // 4. Recent Expenses Stream
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SectionTitle(
                                title: s.recentExpenses,
                                badge: isTh ? '5 รายการล่าสุด' : 'Recent 5',
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      isTh ? 'ดูทั้งหมด' : 'View All',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF0284C7)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildExpensesStream(expensesAsync, currencyFormat, isTh, s),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesStream(
    AsyncValue<List<dynamic>> expensesAsync,
    NumberFormat currencyFormat,
    bool isTh,
    dynamic s,
  ) {
    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return _EmptyExpensesCard(s: s);
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: expenses.take(5).length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 64,
              color: Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final item = expenses[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getExpenseColor(item.type).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getExpenseIcon(item.type),
                        color: _getExpenseColor(item.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.type,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('d MMM yyyy', isTh ? 'th_TH' : 'en_US')
                                .format(item.expenseDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '฿${currencyFormat.format(item.amount)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF0284C7)),
        ),
      ),
      error: (e, _) => Text(
        'Error: $e',
        style: const TextStyle(color: AppColors.danger),
      ),
    );
  }

  Color _getExpenseColor(String type) {
    if (type.contains('น้ำมัน') || type.toLowerCase().contains('fuel')) return const Color(0xFFEA580C);
    if (type.contains('ซ่อม') || type.toLowerCase().contains('repair')) return const Color(0xFFDC2626);
    if (type.contains('ทางด่วน') || type.toLowerCase().contains('toll')) return const Color(0xFF2563EB);
    if (type.contains('ยาง') || type.toLowerCase().contains('tire')) return const Color(0xFF7C3AED);
    return const Color(0xFF059669);
  }

  IconData _getExpenseIcon(String type) {
    if (type.contains('น้ำมัน') || type.toLowerCase().contains('fuel')) return Icons.local_gas_station_rounded;
    if (type.contains('ซ่อม') || type.toLowerCase().contains('repair')) return Icons.build_rounded;
    if (type.contains('ทางด่วน') || type.toLowerCase().contains('toll')) return Icons.toll_rounded;
    if (type.contains('ยาง') || type.toLowerCase().contains('tire')) return Icons.tire_repair_rounded;
    return Icons.receipt_rounded;
  }
}

// ─── KPI Metric Card ────────────────────────────────────────────────────────
class _KpiStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final List<Color> bgGradient;

  const _KpiStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    required this.bgGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Copilot Card ────────────────────────────────────────────────────────
class _AiCopilotCard extends StatelessWidget {
  final AppStrings s;
  final AsyncValue<String> aiSummaryAsync;
  final Function(String) onSendLine;

  const _AiCopilotCard({
    required this.s,
    required this.aiSummaryAsync,
    required this.onSendLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF312E81),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s.aiSummaryTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'GEMINI 2.5',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    s.isTh ? 'วิเคราะห์ข้อมูลรถและค่าใช้จ่ายอัตโนมัติ' : 'Fleet Intelligence Insights',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Summary Content
          aiSummaryAsync.when(
            data: (summary) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    summary,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Send to LINE button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onSendLine(summary),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06C755),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06C755).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                s.sendToLine,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Chat with AI Copilot
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AiChatScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.forum_rounded, color: Color(0xFF38BDF8), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                s.isTh ? 'ปรึกษา AI' : 'Ask Copilot',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  s.analyzing,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            error: (_, __) => Text(
              s.noDataToday,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bespoke Menu Tile Widget ───────────────────────────────────────────────
class _BespokeMenuTile extends StatelessWidget {
  final Widget badge;
  final String title;
  final String subtitle;
  final String? badgeTag;
  final Color badgeTagColor;
  final bool isLive;
  final VoidCallback onTap;

  const _BespokeMenuTile({
    required this.badge,
    required this.title,
    required this.subtitle,
    this.badgeTag,
    this.badgeTagColor = const Color(0xFF0284C7),
    this.isLive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  badge,
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Color(0xFF10B981), size: 5),
                          SizedBox(width: 3),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (badgeTag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeTagColor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeTag!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: badgeTagColor,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 1. รถของฉัน Badge (Fleet Truck + Telematics Wave) ──────────────────────
class _FleetTruckIconBadge extends StatelessWidget {
  const _FleetTruckIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 19),
      ),
    );
  }
}

// ─── 2. แผนที่สด Badge (Live Radar Pin + Signal Wave) ───────────────────────
class _LiveMapGpsIconBadge extends StatelessWidget {
  const _LiveMapGpsIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.radar_rounded, color: Colors.white70, size: 22),
          Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
        ],
      ),
    );
  }
}

// ─── 3. โหมดคนขับ Badge (Cockpit Speedometer + Steering) ───────────────────
class _DriverCockpitIconBadge extends StatelessWidget {
  const _DriverCockpitIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.speed_rounded, color: Colors.white, size: 19),
      ),
    );
  }
}

// ─── 4. ซ่อมบำรุง Badge (Precision Wrench & Diagnostic Gear) ────────────────
class _MaintenanceWrenchIconBadge extends StatelessWidget {
  const _MaintenanceWrenchIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.build_circle_rounded, color: Colors.white, size: 19),
      ),
    );
  }
}

// ─── 5. บันทึกค่าใช้จ่าย Badge (Fuel Station & Smart Bill) ──────────────────
class _SmartExpenseIconBadge extends StatelessWidget {
  const _SmartExpenseIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 19),
      ),
    );
  }
}

// ─── 6. รายงาน & สถิติ Badge (3D Growth Bar Chart) ──────────────────────────
class _AnalyticsChartIconBadge extends StatelessWidget {
  const _AnalyticsChartIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.insights_rounded, color: Colors.white, size: 19),
      ),
    );
  }
}

// ─── 7. AI Assistant Galaxy Badge (Gemini Star Sparkle) ─────────────────────
class _AiAssistantGalaxyBadge extends StatelessWidget {
  const _AiAssistantGalaxyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19),
      ),
    );
  }
}

// ─── 8. LINE Notify Badge (LINE Emerald Brand Message) ──────────────────────
class _LineNotifyBadge extends StatelessWidget {
  const _LineNotifyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06C755), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06C755).withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── 9. ข้อมูลบริษัท Badge (Enterprise Fleet HQ) ────────────────────────────
class _CompanyEnterpriseBadge extends StatelessWidget {
  const _CompanyEnterpriseBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.domain_rounded, color: Colors.white, size: 19),
      ),
    );
  }
}

// ─── 10. AI Settings Badge (Engine Precision Tuning) ────────────────────────
class _AiSettingsGearBadge extends StatelessWidget {
  const _AiSettingsGearBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF475569), Color(0xFF64748B)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF475569).withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.tune_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}


// ─── Section Header ─────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String badge;

  const _SectionTitle({required this.title, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty Expenses Card ────────────────────────────────────────────────────
class _EmptyExpensesCard extends StatelessWidget {
  final AppStrings s;
  const _EmptyExpensesCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, size: 28, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 10),
          Text(
            s.noExpenses,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Hero Brand Painter ──────────────────────────────────────────────
class _FleetHeroIcon extends StatelessWidget {
  const _FleetHeroIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FleetHeroPainter(),
    );
  }
}

class _FleetHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // GPS Arc
    final rect = Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.6),
      radius: size.width * 0.38,
    );
    canvas.drawArc(rect, 3.14159, 3.14159, false, paint);

    // Pulse node
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.22), 2.0, glowPaint);

    // Truck Silhouette
    final truckPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.72);
    path.lineTo(size.width * 0.50, size.height * 0.72);
    path.lineTo(size.width * 0.60, size.height * 0.58);
    path.lineTo(size.width * 0.74, size.height * 0.58);
    path.lineTo(size.width * 0.80, size.height * 0.68);
    path.lineTo(size.width * 0.80, size.height * 0.78);
    path.lineTo(size.width * 0.25, size.height * 0.78);
    path.close();
    canvas.drawPath(path, truckPaint);

    // Wheels
    final wheelPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.78), 3, wheelPaint);
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.78), 1.5, rimPaint);

    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.78), 3, wheelPaint);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.78), 1.5, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
