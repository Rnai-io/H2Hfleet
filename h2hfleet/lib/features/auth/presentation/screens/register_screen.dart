import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _fleetType = 'truck'; // truck, van, express, corporate
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ref.read(authRepositoryProvider).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            companyName: _companyController.text.trim().isNotEmpty
                ? _companyController.text.trim()
                : '${_nameController.text.trim()} Fleet',
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.isTh
                  ? 'สร้างบัญชีสำเร็จ! ยินดีต้อนรับสู่ H2H Fleet 🚛🎉'
                  : 'Account created successfully! Welcome to H2H Fleet.'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.of(context).pop();
        } else {
          setState(() => _error = s.isTh ? 'สมัครสมาชิกไม่สำเร็จ โปรดลองใหม่อีกครั้ง' : 'Registration failed');
        }
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('user already registered') || errStr.contains('already exists')) {
          setState(() => _error = s.isTh ? 'อีเมลนี้ถูกลงทะเบียนไว้แล้ว โปรดเข้าสู่ระบบ' : 'Email already registered. Please login.');
        } else if (errStr.contains('password should be at least')) {
          setState(() => _error = s.isTh ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร' : 'Password must be at least 6 characters');
        } else {
          setState(() => _error = s.isTh
              ? 'เกิดข้อผิดพลาด: ${e.toString().replaceAll('Exception:', '').trim()}'
              : 'Error occurred during registration');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle(AppStrings s) async {
    setState(() {
      _isGoogleLoading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() => _error = s.oAuthError);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _signInWithApple(AppStrings s) async {
    setState(() {
      _isAppleLoading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
    } catch (e) {
      if (mounted) {
        setState(() => _error = s.oAuthError);
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(strProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Ambient Glow Orbs
            Positioned(
              top: -60,
              left: -50,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                ),
              ),
            ),
            Positioned(
              top: 160,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top Navigation Bar: Prominent Glass Back Button & Language
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Material(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        _LanguagePill(s: s),
                      ],
                    ),
                  ),

                  // Hero Brand Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                          ),
                          child: const _FleetHeroIcon(),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'H2H',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(width: 6),
                            _BadgePill('FLEET'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.isTh
                              ? 'สมัครสมาชิกและเริ่มต้นจัดการกองยานพาหนะ'
                              : 'Create account and empower your fleet management',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main White Content Card
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: size.height * 0.65),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 30,
                          offset: Offset(0, -10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 36),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            s.isTh ? 'สร้างบัญชีใหม่' : 'Create Account',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.isTh
                                ? 'กรอกข้อมูลเพื่อเปิดใช้งานศูนย์ควบคุมกองรถของคุณ'
                                : 'Enter your organization details to start telematics',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (_error != null) ...[
                            _ErrorBanner(message: _error!),
                            const SizedBox(height: 16),
                          ],

                          // ─── Single Sign-On (Google & Apple) ───────────
                          _SocialButton(
                            label: s.isTh ? 'สมัครด้วย Google Account' : 'Sign up with Google',
                            icon: const _GoogleLogoIcon(),
                            isLoading: _isGoogleLoading,
                            backgroundColor: Colors.white,
                            textColor: const Color(0xFF1F2937),
                            borderColor: const Color(0xFFE2E8F0),
                            onPressed: _isGoogleLoading || _isAppleLoading || _isLoading
                                ? null
                                : () => _signInWithGoogle(s),
                          ),
                          const SizedBox(height: 10),
                          _SocialButton(
                            label: s.isTh ? 'สมัครด้วย Apple ID' : 'Sign up with Apple',
                            icon: const _AppleLogoIcon(),
                            isLoading: _isAppleLoading,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            borderColor: Colors.black,
                            onPressed: _isGoogleLoading || _isAppleLoading || _isLoading
                                ? null
                                : () => _signInWithApple(s),
                          ),

                          const SizedBox(height: 20),

                          // OR Divider
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  s.isTh ? 'หรือกรอกข้อมูลสมัครสมาชิก' : 'Or register with details',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ─── Section 1: ข้อมูลองค์กร & เจ้าของ ──────────
                          _SectionHeading(
                            icon: Icons.business_center_rounded,
                            title: s.isTh ? 'ข้อมูลองค์กร / กองยานพาหนะ' : 'Fleet & Organization',
                          ),
                          const SizedBox(height: 12),

                          _FieldLabel(s.isTh ? 'ชื่อเจ้าของกิจการ / ผู้ดูแลระบบ *' : 'Owner / Manager Full Name *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: s.isTh ? 'เช่น สมชาย ใจมั่นคง' : 'e.g. Somchai Jaimankong',
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? (s.isTh ? 'กรุณากรอกชื่อผู้ดูแล' : 'Please enter manager name')
                                : null,
                          ),
                          const SizedBox(height: 14),

                          _FieldLabel(s.isTh ? 'ชื่อบริษัท / นิติบุคคล / กองรถ *' : 'Company / Fleet Name *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _companyController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: s.isTh ? 'เช่น บจก. นำส่งด่วน ทรานสปอร์ต' : 'e.g. Express Logistics Co.',
                              prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? (s.isTh ? 'กรุณากรอกชื่อบริษัท' : 'Please enter company name')
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Fleet Type Pills
                          _FieldLabel(s.isTh ? 'ประเภทกองรถหลัก' : 'Primary Fleet Operation'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _FleetTypePill(
                                label: s.isTh ? '🚛 บรรทุกหนัก' : '🚛 Heavy Trucks',
                                isSelected: _fleetType == 'truck',
                                onTap: () => setState(() => _fleetType = 'truck'),
                              ),
                              const SizedBox(width: 6),
                              _FleetTypePill(
                                label: s.isTh ? '🚐 กระบะ/ตู้ทึบ' : '🚐 Vans & Pickups',
                                isSelected: _fleetType == 'van',
                                onTap: () => setState(() => _fleetType = 'van'),
                              ),
                              const SizedBox(width: 6),
                              _FleetTypePill(
                                label: s.isTh ? '🏢 องค์กรทั่วไป' : '🏢 Corporate',
                                isSelected: _fleetType == 'corporate',
                                onTap: () => setState(() => _fleetType = 'corporate'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ─── Section 2: ข้อมูลเข้าสู่ระบบ ───────────────
                          _SectionHeading(
                            icon: Icons.shield_rounded,
                            title: s.isTh ? 'ข้อมูลบัญชีเข้าสู่ระบบ' : 'Account Credentials',
                          ),
                          const SizedBox(height: 12),

                          _FieldLabel(s.isTh ? 'อีเมลสำหรับเข้าใช้งาน *' : 'Work Email Address *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'admin@company.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return s.isTh ? 'กรุณากรอกอีเมล' : 'Please enter email';
                              }
                              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) {
                                return s.isTh ? 'รูปแบบอีเมลไม่ถูกต้อง' : 'Invalid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _FieldLabel(s.isTh ? 'รหัสผ่าน (อย่างน้อย 6 ตัวอักษร) *' : 'Password (min. 6 chars) *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return s.fillAllFields;
                              if (v.length < 6) {
                                return s.isTh ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร' : 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _FieldLabel(s.isTh ? 'ยืนยันรหัสผ่านอีกครั้ง *' : 'Confirm Password *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _register(s),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return s.isTh ? 'รหัสผ่านทั้งสองช่องไม่ตรงกัน' : 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 28),

                          // ─── Register Submit Button ────────────────────
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading || _isGoogleLoading || _isAppleLoading
                                  ? null
                                  : () => _register(s),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : Text(
                                      s.isTh ? 'ยืนยันการสมัครสมาชิก 🚛' : 'Complete Registration 🚛',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ─── Back to Login Link ─────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.isTh ? 'มีบัญชีผู้ใช้อยู่แล้ว? ' : 'Already have an account? ',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  s.login,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Local Components ────────────────────────────────────────────────────────
class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeading({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E3A8A), size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
      ),
    );
  }
}

class _FleetTypePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FleetTypePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String text;
  const _BadgePill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _LanguagePill extends ConsumerWidget {
  final AppStrings s;
  const _LanguagePill({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTh = s.isTh;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangOption(
            label: 'TH',
            isActive: isTh,
            onTap: () => ref.read(localeProvider.notifier).setLocale('th'),
          ),
          _LangOption(
            label: 'EN',
            isActive: !isTh,
            onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LangOption({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

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
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.6), radius: size.width * 0.38);
    canvas.drawArc(rect, 3.14159, 3.14159, false, paint);

    final innerRect = Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.6), radius: size.width * 0.22);
    paint.color = const Color(0xFF06B6D4);
    canvas.drawArc(innerRect, 3.14159, 3.14159, false, paint);

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.22), 2.5, glowPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), 2.0, glowPaint);

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

    final wheelPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.78), 4, wheelPaint);
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.78), 2, rimPaint);

    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.78), 4, wheelPaint);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.78), 2, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.butt;

    strokePaint.color = bluePaint.color;
    canvas.drawArc(rect, -0.6, 1.2, false, strokePaint);

    strokePaint.color = greenPaint.color;
    canvas.drawArc(rect, 0.6, 1.5, false, strokePaint);

    strokePaint.color = yellowPaint.color;
    canvas.drawArc(rect, 2.1, 1.3, false, strokePaint);

    strokePaint.color = redPaint.color;
    canvas.drawArc(rect, 3.4, 1.3, false, strokePaint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.48, h * 0.42, w * 0.48, 3.5), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppleLogoIcon extends StatelessWidget {
  const _AppleLogoIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.apple,
      color: Colors.white,
      size: 22,
    );
  }
}
