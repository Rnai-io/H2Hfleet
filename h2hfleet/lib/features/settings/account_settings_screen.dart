import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/supabase_service.dart';

const String kPrivacyPolicyUrl =
    'https://rnai-io.github.io/H2Hfleet/privacy-policy.html';
const String kTermsUrl =
    'https://rnai-io.github.io/H2Hfleet/terms-of-service.html';
const String kDeleteAccountUrl =
    'https://rnai-io.github.io/H2Hfleet/delete-account.html';

/// หน้า "บัญชีของฉัน" — โปรไฟล์ ความเป็นส่วนตัว ออกจากระบบ และลบบัญชี
///
/// ปุ่มลบบัญชีในแอปเป็นข้อบังคับของ Google Play สำหรับแอปที่สมัครสมาชิกได้
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final auth = SupabaseService().getCurrentUser();
      if (auth == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final row = await SupabaseService()
          .client
          .from('users')
          .select('name, email, role, company_id, companies(name)')
          .eq('id', auth.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _profile = row == null ? null : Map<String, dynamic>.from(row);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final s = ref.read(strProvider);
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw Exception('could not launch');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.isTh ? 'เปิดลิงก์ไม่สำเร็จ' : 'Could not open link'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final s = ref.read(strProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.logout,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(s.isTh
            ? 'ต้องการออกจากระบบใช่หรือไม่ ข้อมูลของคุณจะยังอยู่ครบ'
            : 'Sign out of H2HFleet? Your data stays exactly as it is.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.isTh ? 'ยกเลิก' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.logout),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authRepositoryProvider).logout();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _startDeleteFlow() async {
    final s = ref.read(strProvider);
    final repo = ref.read(authRepositoryProvider);

    // ── ขั้นที่ 1: ดึงสรุปว่ากำลังจะลบอะไร ────────────────────────────
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic> preview;
    List<Map<String, dynamic>> candidates = const [];
    try {
      preview = await repo.accountDeletionPreview();
      if (preview['needs_transfer'] == true) {
        candidates = await repo.transferCandidates();
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.isTh
              ? 'โหลดข้อมูลบัญชีไม่สำเร็จ: $e'
              : 'Could not load account details: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(); // ปิด loading

    // ── ขั้นที่ 2: dialog ยืนยัน ────────────────────────────────────
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(
        preview: preview,
        candidates: candidates,
      ),
    );

    if (deleted == true && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.isTh
              ? 'ลบบัญชีเรียบร้อยแล้ว ขอบคุณที่ใช้งาน H2HFleet'
              : 'Your account has been deleted. Thank you for using H2HFleet.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(strProvider);
    final isTh = s.isTh;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(isTh ? 'บัญชีของฉัน' : 'My Account',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _profileCard(isTh),
                const SizedBox(height: 18),
                _sectionLabel(isTh ? 'ความเป็นส่วนตัว' : 'Privacy'),
                _linkTile(
                  icon: Icons.privacy_tip_outlined,
                  title: isTh ? 'นโยบายความเป็นส่วนตัว' : 'Privacy Policy',
                  onTap: () => _openUrl(kPrivacyPolicyUrl),
                ),
                _linkTile(
                  icon: Icons.description_outlined,
                  title: isTh ? 'ข้อกำหนดการใช้งาน' : 'Terms of Service',
                  onTap: () => _openUrl(kTermsUrl),
                ),
                _linkTile(
                  icon: Icons.help_outline_rounded,
                  title: isTh
                      ? 'วิธีขอลบบัญชีและข้อมูล'
                      : 'How to request data deletion',
                  onTap: () => _openUrl(kDeleteAccountUrl),
                ),
                const SizedBox(height: 18),
                _sectionLabel(isTh ? 'บัญชี' : 'Account'),
                _linkTile(
                  icon: Icons.logout_rounded,
                  title: s.logout,
                  onTap: _confirmLogout,
                ),
                const SizedBox(height: 24),
                _dangerZone(isTh),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _profileCard(bool isTh) {
    final auth = SupabaseService().getCurrentUser();
    final name = (_profile?['name'] as String?) ??
        (auth?.userMetadata?['full_name'] as String?) ??
        (isTh ? 'ผู้ใช้งาน' : 'User');
    final email = (_profile?['email'] as String?) ?? auth?.email ?? '-';
    final role = (_profile?['role'] as String?) ?? 'owner';
    final company = _profile?['companies'] is Map
        ? (_profile!['companies'] as Map)['name'] as String?
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(role.toUpperCase(), AppColors.primary),
                    if (company != null && company.isNotEmpty)
                      _chip(company, AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .30)),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
        ),
      );

  Widget _linkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, size: 20, color: AppColors.textSecondary),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 20, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }

  Widget _dangerZone(bool isTh) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 20, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                isTh ? 'ลบบัญชีถาวร' : 'Delete account permanently',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isTh
                ? 'ข้อมูลบัญชี ประวัติตำแหน่ง GPS รูปใบเสร็จ และบันทึกค่าใช้จ่ายของคุณจะถูกลบถาวร '
                    'การลบไม่สามารถย้อนกลับได้ และไม่สามารถกู้คืนข้อมูลได้ในภายหลัง'
                : 'Your account, GPS history, receipt photos, and expense records will be '
                    'permanently deleted. This cannot be undone and nothing can be recovered.',
            style: const TextStyle(
                fontSize: 13, height: 1.55, color: Color(0xFF7F1D1D)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startDeleteFlow,
              icon: const Icon(Icons.delete_forever_rounded, size: 19),
              label: Text(
                isTh ? 'ลบบัญชีของฉัน' : 'Delete my account',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Dialog ยืนยันการลบ — ต้องผ่านทั้งเช็กบ็อกซ์และพิมพ์คำยืนยัน
// ══════════════════════════════════════════════════════════════════════
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> preview;
  final List<Map<String, dynamic>> candidates;

  const _DeleteAccountDialog({
    required this.preview,
    required this.candidates,
  });

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _confirmCtrl = TextEditingController();
  String? _transferTo;
  bool _acknowledged = false;
  bool _busy = false;
  String? _error;

  bool get _willDeleteCompany => widget.preview['will_delete_company'] == true;
  bool get _needsTransfer => widget.preview['needs_transfer'] == true;

  @override
  void initState() {
    super.initState();
    if (widget.candidates.isNotEmpty) {
      _transferTo = widget.candidates.first['id'] as String?;
    }
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  int _count(String key) {
    final v = widget.preview[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  String _confirmWord(bool isTh) => isTh ? 'ลบบัญชี' : 'DELETE';

  bool _canSubmit(bool isTh) {
    if (_busy) return false;
    if (!_acknowledged) return false;
    if (_needsTransfer && (_transferTo == null || _transferTo!.isEmpty)) {
      return false;
    }
    return _confirmCtrl.text.trim() == _confirmWord(isTh);
  }

  String _friendlyError(Object e, bool isTh) {
    final raw = e is PostgrestException ? e.message : e.toString();
    if (raw.contains('transfer_required')) {
      return isTh
          ? 'คุณเป็นผู้ดูแลคนสุดท้าย กรุณาเลือกผู้รับสิทธิ์ก่อน'
          : 'You are the last admin. Please choose who takes over first.';
    }
    if (raw.contains('invalid_transfer_target')) {
      return isTh
          ? 'ผู้รับสิทธิ์ไม่ได้อยู่ในบริษัทเดียวกัน'
          : 'That user is not in your company.';
    }
    if (raw.contains('confirm_company_delete')) {
      return isTh
          ? 'ต้องยืนยันการลบข้อมูลบริษัทก่อน'
          : 'Company deletion must be acknowledged first.';
    }
    if (raw.contains('not_authenticated')) {
      return isTh
          ? 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'
          : 'Session expired. Please sign in again.';
    }
    if (raw.contains('account_deletion_preview') ||
        raw.contains('delete_my_account') ||
        raw.contains('does not exist') ||
        raw.contains('PGRST202')) {
      return isTh
          ? 'ระบบยังไม่ได้ติดตั้งฟังก์ชันลบบัญชีในฐานข้อมูล '
              '(รัน SUPABASE_ACCOUNT_DELETION.sql)'
          : 'The account deletion function is not installed on the database '
              '(run SUPABASE_ACCOUNT_DELETION.sql).';
    }
    return raw;
  }

  Future<void> _submit(bool isTh) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).deleteMyAccount(
            transferTo: _needsTransfer ? _transferTo : null,
            deleteCompany: _willDeleteCompany,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _friendlyError(e, isTh);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(strProvider);
    final isTh = s.isTh;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
      title: Row(
        children: [
          const Icon(Icons.delete_forever_rounded,
              color: AppColors.danger, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              isTh ? 'ยืนยันการลบบัญชี' : 'Confirm account deletion',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTh
                    ? 'ข้อมูลต่อไปนี้จะถูกลบถาวรและกู้คืนไม่ได้'
                    : 'The following will be permanently deleted and cannot be recovered:',
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              _summaryBox(isTh),
              if (_willDeleteCompany) ...[
                const SizedBox(height: 12),
                _noticeBox(
                  color: AppColors.danger,
                  text: isTh
                      ? 'คุณเป็นสมาชิกคนสุดท้ายของ "${widget.preview['company_name'] ?? ''}" '
                          'ข้อมูลของทั้งบริษัทจะถูกลบไปพร้อมกับบัญชีของคุณ'
                      : 'You are the last member of "${widget.preview['company_name'] ?? ''}". '
                          'All company data will be deleted along with your account.',
                ),
              ],
              if (_needsTransfer) ...[
                const SizedBox(height: 12),
                _noticeBox(
                  color: AppColors.warning,
                  text: isTh
                      ? 'คุณเป็นผู้ดูแลคนสุดท้าย เลือกผู้ที่จะรับสิทธิ์ผู้ดูแลต่อ '
                          'เพื่อไม่ให้ทีมเข้าถึงข้อมูลไม่ได้'
                      : 'You are the last admin. Choose who takes over so your team '
                          'does not lose access.',
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _transferTo,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText:
                        isTh ? 'โอนสิทธิ์ผู้ดูแลให้' : 'Transfer ownership to',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  items: widget.candidates.map((c) {
                    final label =
                        '${c['name'] ?? '-'} · ${c['email'] ?? ''}';
                    return DropdownMenuItem<String>(
                      value: c['id'] as String?,
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _transferTo = v),
                ),
              ],
              const SizedBox(height: 14),
              CheckboxListTile(
                value: _acknowledged,
                onChanged:
                    _busy ? null : (v) => setState(() => _acknowledged = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  _willDeleteCompany
                      ? (isTh
                          ? 'ฉันเข้าใจว่าข้อมูลของทั้งบริษัทจะถูกลบถาวร'
                          : 'I understand all company data will be permanently deleted')
                      : (isTh
                          ? 'ฉันเข้าใจว่าการลบนี้ย้อนกลับไม่ได้'
                          : 'I understand this cannot be undone'),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isTh
                    ? 'พิมพ์คำว่า "${_confirmWord(isTh)}" เพื่อยืนยัน'
                    : 'Type "${_confirmWord(isTh)}" to confirm',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmCtrl,
                enabled: !_busy,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: _confirmWord(isTh),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _noticeBox(color: AppColors.danger, text: _error!),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(isTh ? 'ยกเลิก' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton.icon(
          onPressed: _canSubmit(isTh) ? () => _submit(isTh) : null,
          icon: _busy
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.delete_forever_rounded, size: 18),
          label: Text(
            _busy
                ? (isTh ? 'กำลังลบ...' : 'Deleting...')
                : (isTh ? 'ลบบัญชีถาวร' : 'Delete permanently'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
        ),
      ],
    );
  }

  Widget _summaryBox(bool isTh) {
    final rows = <List<String>>[
      [isTh ? 'รถในระบบ' : 'Vehicles', '${_count('vehicles')}'],
      [isTh ? 'บันทึกค่าใช้จ่าย' : 'Expense records', '${_count('expenses')}'],
      [isTh ? 'ประวัติซ่อมบำรุง' : 'Maintenance records', '${_count('maintenance')}'],
      [isTh ? 'จุดพิกัด GPS' : 'GPS points', '${_count('gps_points')}'],
      [isTh ? 'งานวิ่ง' : 'Trips', '${_count('trips')}'],
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r[0],
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  Text(r[1],
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _noticeBox({required Color color, required String text}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      );
}
