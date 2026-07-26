import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import 'auth_form_widgets.dart';

/// Bottom sheet — กรอกเบอร์ → ส่ง OTP → ยืนยัน
class PhoneLoginSheet extends StatefulWidget {
  const PhoneLoginSheet({super.key, required this.onVerified});

  final Future<void> Function() onVerified;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onVerified,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhoneLoginSheet(onVerified: onVerified),
    );
  }

  @override
  State<PhoneLoginSheet> createState() => _PhoneLoginSheetState();
}

class _PhoneLoginSheetState extends State<PhoneLoginSheet> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _auth = AuthService.instance;
  bool _loading = false;
  bool _otpSent = false;
  String? _normalizedPhone;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final s = AppStrings.of(context);
    final raw = _phone.text.trim();
    if (raw.replaceAll(RegExp(r'\D'), '').length < 9) {
      _snack(s.phoneRequired);
      return;
    }
    setState(() => _loading = true);
    try {
      final normalized = await _auth.requestPhoneOtp(raw);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _normalizedPhone = normalized;
      });
      _snack(s.authPhoneOtpSent);
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final phone = _normalizedPhone ?? _phone.text.trim();
    final token = _otp.text.trim();
    if (token.length < 4) {
      _snack(AppStrings.of(context).authPhoneOtpHint);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.verifyPhoneOtp(phone: phone, token: token);
      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onVerified();
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.authPhoneSheetTitle,
              textAlign: TextAlign.center,
              style: authTitleTextStyle().copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            if (!_otpSent) ...[
              Row(
                children: [
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      s.signUpCountryCode,
                      style: authFormFieldTextStyle(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AuthFormField(
                      controller: _phone,
                      hint: s.signUpPhoneHint,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _loading ? null : _sendOtp,
                  style: authPrimaryButtonStyle(context),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(s.authPhoneSendOtp),
                ),
              ),
            ] else ...[
              Text(
                _normalizedPhone ?? '',
                textAlign: TextAlign.center,
                style: authBodyTextStyle(),
              ),
              const SizedBox(height: 12),
              AuthFormField(
                controller: _otp,
                hint: s.authPhoneOtpHint,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _loading ? null : _verify,
                  style: authPrimaryButtonStyle(context),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(s.authPhoneVerifyOtp),
                ),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _otpSent = false;
                          _otp.clear();
                        }),
                child: Text(
                  s.t('เปลี่ยนเบอร์', 'Change number'),
                  style: authLinkStyle(color: p.primary).copyWith(
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
