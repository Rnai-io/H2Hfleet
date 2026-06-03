import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';

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
  bool _isLoading = false;
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        companyName: _companyController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสมาชิกสำเร็จ! โปรดเช็คอีเมลยืนยัน'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'สมัครไม่สำเร็จ ลองใหม่อีกครั้ง');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('สร้างบัญชีใหม่', style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary,
                          )),
                          Text('กรอกข้อมูลด้านล่างให้ครบถ้วน', style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],

              _SectionTitle('ข้อมูลส่วนตัว'),
              const SizedBox(height: 12),
              _FieldLabel('ชื่อเจ้าของกิจการ'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'ชื่อ-นามสกุล',
                  prefixIcon: Icon(Icons.person_outlined, size: 20),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _FieldLabel('ชื่อบริษัท / กิจการ'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  hintText: 'เช่น ขนส่งสมชาย',
                  prefixIcon: Icon(Icons.business_outlined, size: 20),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อบริษัท' : null,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 24),
              _SectionTitle('ข้อมูลเข้าสู่ระบบ'),
              const SizedBox(height: 12),
              _FieldLabel('อีเมล'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณากรอกอีเมล';
                  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _FieldLabel('รหัสผ่าน'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'อย่างน้อย 8 ตัวอักษร',
                  prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20, color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (v) {
                  if (v == null || v.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัว';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _FieldLabel('ยืนยันรหัสผ่าน'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  hintText: 'กรอกรหัสผ่านอีกครั้ง',
                  prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20, color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                obscureText: _obscureConfirm,
                validator: (v) {
                  if (v != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _register(),
              ),

              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('สมัครสมาชิก'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        )),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    ));
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(
              color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500,
            )),
          ),
        ],
      ),
    );
  }
}
