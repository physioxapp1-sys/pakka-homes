import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../theme/app_colors.dart';
import 'forgot_password_screen.dart';

/// Sign in or sign up. Shown only when something actually needs an account -
/// never as a wall in front of the app.
///
/// Pops `true` once signed in, so a caller that gated an action can carry on.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth, this.reason});

  final AuthRepository auth;

  /// Why the customer is being asked, e.g. "to track this booking".
  final String? reason;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  bool _registering = false;
  bool _busy = false;
  bool _obscure = true;
  Map<String, List<String>> _serverErrors = const {};
  String? _formError;

  @override
  void dispose() {
    for (final c in [_phone, _password, _name]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _serverErrors = const {};
      _formError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      if (_registering) {
        await widget.auth.register(
          phone: _phone.text,
          password: _password.text,
          fullName: _name.text.trim(),
        );
      } else {
        await widget.auth.login(phone: _phone.text, password: _password.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      final errors = e.fieldErrors ?? const <String, List<String>>{};
      setState(() {
        _serverErrors = errors;
        // DRF reports "wrong phone or password" as a non-field error.
        _formError = errors['non_field_errors']?.first ??
            (errors.isEmpty ? e.message : null);
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _serverError(String field) {
    final errors = _serverErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(_registering ? 'Create account' : 'Sign in'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.reason != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.reason!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (_formError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEDED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.emergencyRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: const TextStyle(fontSize: 13, color: AppColors.emergencyRed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_registering)
              _AuthField(
                controller: _name,
                label: 'Your name',
                icon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                validator: (_) => _serverError('full_name'),
              ),
            _AuthField(
              controller: _phone,
              label: 'Phone number',
              icon: Icons.call_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return _serverError('phone') ??
                    (digits.length < 7 ? 'Enter a valid phone number.' : null);
              },
            ),
            _AuthField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              validator: (v) =>
                  _serverError('password') ??
                  ((v == null || v.length < 6) ? 'At least 6 characters.' : null),
            ),
            if (!_registering)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                auth: widget.auth,
                                initialPhone: _phone.text,
                              ),
                            ),
                          ),
                  child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _registering ? 'Create account' : 'Sign in',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _registering = !_registering;
                        _serverErrors = const {};
                        _formError = null;
                      }),
              child: Text(
                _registering
                    ? 'Already have an account? Sign in'
                    : "New here? Create an account",
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.obscure = false,
    this.onToggleObscure,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscure,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: onToggleObscure == null
              ? null
              : IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: onToggleObscure,
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
      ),
    );
  }
}
