import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/vehicles_provider.dart';
import '../../../../providers/expenses_provider.dart';
import '../../../../providers/ai_provider.dart';
import '../../../vehicles/presentation/screens/vehicle_list_screen.dart';
import '../../../expenses/presentation/screens/expense_list_screen.dart';
import '../../../expenses/presentation/screens/add_expense_dialog.dart';
import '../../../line/line_settings_screen.dart';
import '../../../line/line_service.dart';
import '../../../map/map_screen.dart';
import '../../../driver/driver_mode_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final aiSummaryAsync = ref.watch(aiSummaryProvider);

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('line_notify_token') ?? '';
      if (token.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ยังไม่ได้ตั้งค่า LINE Token'),
              action: SnackBarAction(
                label: 'ตั้งค่า',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LineSettingsScreen()),
                ),
              ),
            ),
          );
        }
        return;
      }
      final message = LineService().buildDailySummary(
        vehicleCount: vehicleCount,
        todayTotal: todayTotal,
        monthTotal: monthTotal,
        aiSummary: summary,
      );
      final ok = await LineService().sendNotify(token: token, message: message);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'ส่งสรุปไป LINE สำเร็จ ✅' : 'ส่งไม่สำเร็จ ตรวจสอบ Token'),
            backgroundColor: ok ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(vehiclesProvider);
          ref.invalidate(expensesProvider);
          ref.invalidate(aiSummaryProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF2563EB)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.local_shipping_rounded,
                                        color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('H2HFleet',
                                    style: TextStyle(
                                      color: Colors.white, fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                                ),
                                onPressed: () => ref.read(authRepositoryProvider).logout(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'สวัสดี! วันนี้รถของคุณเป็นอย่างไรบ้าง?',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14, fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('d MMM yyyy').format(now),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.directions_car_filled_rounded,
                            label: 'รถทั้งหมด',
                            value: '$vehicleCount คัน',
                            iconBg: AppColors.primarySurface,
                            iconColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.today_rounded,
                            label: 'ค่าใช้จ่ายวันนี้',
                            value: '฿${currencyFormat.format(todayTotal)}',
                            iconBg: todayTotal > 5000 ? AppColors.dangerSurface : AppColors.successSurface,
                            iconColor: todayTotal > 5000 ? AppColors.danger : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.calendar_month_rounded,
                            label: 'เดือนนี้',
                            value: '฿${currencyFormat.format(monthTotal)}',
                            iconBg: AppColors.warningSurface,
                            iconColor: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // AI Summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text('AI สรุปวันนี้',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          aiSummaryAsync.when(
                            data: (summary) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  summary,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: 14, height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: () => sendLineNotify(summary),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chat_bubble_outline_rounded,
                                            color: Colors.white, size: 15),
                                        SizedBox(width: 6),
                                        Text('ส่งสรุปไป LINE',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            loading: () => Row(
                              children: [
                                const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Text('กำลังวิเคราะห์...', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                              ],
                            ),
                            error: (_, __) => Text(
                              'ยังไม่มีข้อมูลสำหรับวันนี้',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Menu
                    const _SectionHeader('เมนูด่วน'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickMenuCard(
                            icon: Icons.directions_car_rounded,
                            label: 'รถของฉัน',
                            subtitle: '$vehicleCount คัน',
                            color: AppColors.primary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const VehicleListScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickMenuCard(
                            icon: Icons.map_rounded,
                            label: 'แผนที่สด',
                            subtitle: 'ติดตามรถ GPS',
                            color: const Color(0xFF0EA5E9),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MapScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickMenuCard(
                            icon: Icons.receipt_long_rounded,
                            label: 'บันทึกค่าใช้จ่าย',
                            subtitle: 'เพิ่มค่าใช้จ่าย',
                            color: AppColors.success,
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => const AddExpenseDialog(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickMenuCard(
                            icon: Icons.bar_chart_rounded,
                            label: 'รายงาน',
                            subtitle: 'ดูค่าใช้จ่าย',
                            color: AppColors.warning,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickMenuCard(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'LINE Notify',
                            subtitle: 'ตั้งค่า & ส่งสรุป',
                            color: const Color(0xFF06C755),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LineSettingsScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickMenuCard(
                            icon: Icons.drive_eta_rounded,
                            label: 'โหมดคนขับ',
                            subtitle: 'ส่ง GPS อัตโนมัติ',
                            color: AppColors.success,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const DriverModeScreen()),
                            ),
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Recent Expenses
                    const _SectionHeader('ค่าใช้จ่ายล่าสุด'),
                    const SizedBox(height: 12),
                    expensesAsync.when(
                      data: (expenses) {
                        if (expenses.isEmpty) {
                          return _EmptyState(
                            icon: Icons.receipt_long_rounded,
                            message: 'ยังไม่มีค่าใช้จ่าย\nกดเพิ่มค่าใช้จ่ายเพื่อเริ่มต้น',
                          );
                        }
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: expenses.take(5).toList().asMap().entries.map((entry) {
                              final i = entry.key;
                              final e = entry.value;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.warningSurface,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.receipt_rounded,
                                              color: AppColors.warning, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(e.type, style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              )),
                                              Text(
                                                DateFormat('d MMM yyyy').format(e.expenseDate),
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '฿${currencyFormat.format(e.amount)}',
                                          style: const TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (i < expenses.take(5).length - 1)
                                    const Divider(height: 1, indent: 68),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      error: (e, _) => Text('เกิดข้อผิดพลาด: $e',
                          style: const TextStyle(color: AppColors.danger)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconColor;

  const _StatCard({
    required this.icon, required this.label,
    required this.value, required this.iconBg, required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
          )),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickMenuCard({
    required this.icon, required this.label, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                    )),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        )),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 14, height: 1.5,
          )),
        ],
      ),
    );
  }
}
