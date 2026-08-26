import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await ref.read(authRepositoryProvider).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (user == null && mounted) {
        setState(() => _error = s.isTh ? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง โปรดลองใหม่' : s.loginFailed);
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('invalid login credentials') || errStr.contains('invalid_credentials')) {
          setState(() => _error = s.isTh ? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง โปรดตรวจสอบอีกครั้ง' : 'Invalid email or password');
        } else if (errStr.contains('email not confirmed')) {
          setState(() => _error = s.isTh ? 'โปรดยืนยันอีเมลในกล่องข้อความของคุณก่อนเข้าสู่ระบบ' : 'Please verify your email before logging in');
        } else {
          setState(() => _error = s.loginFailed);
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

  void _showForgotPasswordDialog(BuildContext context, AppStrings s) {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(s.forgotPassword, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.isTh
                  ? 'กรอกอีเมลของคุณเพื่อรับลิงก์รีเซ็ตรหัสผ่าน'
                  : 'Enter your email to receive a password reset link.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: s.email,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.isTh ? 'ยกเลิก' : 'Cancel', style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(
                    s.isTh
                        ? 'หากอีเมลนี้อยู่ในระบบ เราได้ส่งลิงก์รีเซ็ตให้เรียบร้อยแล้ว'
                        : 'If registered, reset link has been sent to your email.',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(s.isTh ? 'ส่งลิงก์' : 'Send Link'),
          ),
        ],
      ),
    );
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
            // Background Ambient Glow Orbs
            Positioned(
              top: -60,
              right: -50,
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
              top: 180,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top bar language switch
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _LanguagePill(s: s),
                      ],
                    ),
                  ),

                  // Hero Brand Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      children: [
                        // Futuristic Icon Badge
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                          ),
                          child: const _FleetHeroIcon(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'H2H',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FLEET',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.tagLine,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.75),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Interactive Card
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: size.height * 0.6),
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
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            s.welcomeBack,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.loginSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (_error != null) ...[
                            _ErrorBanner(message: _error!),
                            const SizedBox(height: 16),
                          ],

                          // ─── Single Sign-On (Google & Apple) ───────────
                          _SocialButton(
                            label: s.continueWithGoogle,
                            icon: const _GoogleLogoIcon(),
                            isLoading: _isGoogleLoading,
                            backgroundColor: Colors.white,
                            textColor: const Color(0xFF1F2937),
                            borderColor: const Color(0xFFE5E7EB),
                            onPressed: _isGoogleLoading || _isAppleLoading || _isLoading
                                ? null
                                : () => _signInWithGoogle(s),
                          ),
                          const SizedBox(height: 12),
                          _SocialButton(
                            label: s.continueWithApple,
                            icon: const _AppleLogoIcon(),
                            isLoading: _isAppleLoading,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            borderColor: Colors.black,
                            onPressed: _isGoogleLoading || _isAppleLoading || _isLoading
                                ? null
                                : () => _signInWithApple(s),
                          ),

                          const SizedBox(height: 22),

                          // ─── OR Divider ────────────────────────────────
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  s.orContinueWithEmail,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ─── Email & Password Inputs ───────────────────
                          _FieldLabel(s.email),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: s.isTh ? 'example@company.com' : 'example@company.com',
                              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return s.fillAllFields;
                              if (!v.contains('@') || !v.contains('.')) {
                                return s.isTh ? 'กรุณากรอกอีเมลที่ถูกต้อง' : 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _FieldLabel(s.password),
                              InkWell(
                                onTap: () => _showForgotPasswordDialog(context, s),
                                child: Text(
                                  s.forgotPassword,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _loginWithEmail(s),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.textSecondary,
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
                          const SizedBox(height: 24),

                          // ─── Login Button ──────────────────────────────
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading || _isGoogleLoading || _isAppleLoading
                                  ? null
                                  : () => _loginWithEmail(s),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                                shadowColor: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          s.login,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ─── Register Link ─────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.noAccount,
                                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                ),
                                child: Text(
                                  s.register,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Security Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Text(
                                s.isTh ? 'ระบบเข้ารหัสปลอดภัย 256-bit SSL' : '256-bit SSL Encrypted & Protected',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
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
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
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

class _LanguagePill extends ConsumerWidget {
  final AppStrings s;
  const _LanguagePill({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isTh = currentLocale.languageCode == 'th';

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

    // Outer GPS Wave Arc
    final rect = Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.6), radius: size.width * 0.38);
    canvas.drawArc(rect, 3.14159, 3.14159, false, paint);

    // Inner GPS Wave Arc
    final innerRect = Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.6), radius: size.width * 0.22);
    paint.color = const Color(0xFF06B6D4);
    canvas.drawArc(innerRect, 3.14159, 3.14159, false, paint);

    // Pulse nodes
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.22), 2.5, glowPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), 2.0, glowPaint);

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

    // Google G arcs
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

    // Horizontal bar
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
