import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/providers.dart';
import '../../core/utils.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final repo = ref.read(authRepoProvider);
      if (_isRegister) {
        final hasSession =
            await repo.register(_name.text, _email.text, _password.text);
        if (!hasSession && mounted) {
          setState(() {
            _isRegister = false;
            _info =
                'تم إنشاء الحساب. أكّد بريدك من الرسالة التي وصلتك ثم سجّل الدخول.';
          });
        }
      } else {
        await repo.signIn(_email.text, _password.text);
      }
      // التوجيه بعد النجاح يتم تلقائياً من الـ router
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } catch (_) {
      if (mounted) setState(() => _error = 'حدث خطأ غير متوقع، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.storefront,
                        size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.storeName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                            labelText: 'الاسم', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'أدخل اسمك'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          border: OutlineInputBorder()),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'أدخل بريداً صحيحاً'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? '6 أحرف على الأقل'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                    if (_info != null) ...[
                      const SizedBox(height: 12),
                      Text(_info!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isRegister ? 'إنشاء حساب' : 'تسجيل الدخول'),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _isRegister = !_isRegister;
                                _error = null;
                              }),
                      child: Text(_isRegister
                          ? 'لدي حساب بالفعل'
                          : 'ليس لدي حساب، إنشاء حساب جديد'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('تصفح كزائر'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
