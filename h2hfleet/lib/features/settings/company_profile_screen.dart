import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerStatefulWidget, ConsumerState;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  bool _isSaving = false;

  static const _keyName = 'company_name';
  static const _keyAddress = 'company_address';
  static const _keyPhone = 'company_phone';
  static const _keyEmail = 'company_email';
  static const _keyTaxId = 'company_tax_id';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nameCtrl.text = prefs.getString(_keyName) ?? '';
        _addressCtrl.text = prefs.getString(_keyAddress) ?? '';
        _phoneCtrl.text = prefs.getString(_keyPhone) ?? '';
        _emailCtrl.text = prefs.getString(_keyEmail) ?? '';
        _taxIdCtrl.text = prefs.getString(_keyTaxId) ?? '';
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, _nameCtrl.text.trim());
    await prefs.setString(_keyAddress, _addressCtrl.text.trim());
    await prefs.setString(_keyPhone, _phoneCtrl.text.trim());
    await prefs.setString(_keyEmail, _emailCtrl.text.trim());
    await prefs.setString(_keyTaxId, _taxIdCtrl.text.trim());
    if (mounted) {
      setState(() => _isSaving = false);
      final s = ref.read(strProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.companyProfileSaved),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxIdCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(strProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(s.companyProfile,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.companyProfileDesc,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(s.companyName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: _decoration(s.companyNameHint, Icons.business_rounded),
            ),
            const SizedBox(height: 20),

            Text(s.companyAddress,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: _decoration(s.companyAddressHint, Icons.location_on_outlined),
            ),
            const SizedBox(height: 20),

            Text(s.companyPhone,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: _decoration('08x-xxx-xxxx', Icons.phone_outlined),
            ),
            const SizedBox(height: 20),

            Text(s.companyEmail,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: _decoration('company@email.com', Icons.email_outlined),
            ),
            const SizedBox(height: 20),

            Text(s.companyTaxId,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(s.companyTaxIdHint,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _taxIdCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: _decoration('0-0000-00000-00-0', Icons.badge_outlined),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(s.save, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
