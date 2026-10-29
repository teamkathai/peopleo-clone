import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_button.dart';

/// Password reset flow backed by the live endpoints:
///   POST /forget-password-emp { mobile }        -> sends an OTP
///   POST /validate-otp        { mobile, otp }   -> verifies the OTP
///   POST /set-password        { mobile, password }
class ForgotPasswordScreen extends StatefulWidget {
  final String initialMobile;
  const ForgotPasswordScreen({super.key, this.initialMobile = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { enterMobile, enterOtp }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _auth = AuthService();
  final _mobile = TextEditingController();
  final _otp = TextEditingController();
  final _newPass = TextEditingController();

  _Step _step = _Step.enterMobile;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _mobile.text = widget.initialMobile;
  }

  @override
  void dispose() {
    _mobile.dispose();
    _otp.dispose();
    _newPass.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final mob = _mobile.text.trim();
    if (mob.isEmpty) {
      setState(() => _error = 'Enter your mobile number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final body = await _auth.requestPasswordOtp(mob);
      final ok = body['status'] == true;
      setState(() {
        if (ok) {
          _step = _Step.enterOtp;
          _info = (body['message'] ?? 'OTP sent to your mobile.').toString();
        } else {
          _error = (body['message'] ?? 'Could not send OTP.').toString();
        }
      });
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final mob = _mobile.text.trim();
    final otp = _otp.text.trim();
    final pass = _newPass.text;
    if (otp.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Enter the OTP and a new password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final verify = await _auth.validateOtp(mobile: mob, otp: otp);
      if (verify['status'] != true) {
        setState(() => _error =
            (verify['message'] ?? 'OTP verification failed.').toString());
        return;
      }
      final set = await _auth.setPassword(mobile: mob, password: pass);
      final ok = set['status'] == true;
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                (set['message'] ?? 'Password updated. Please log in.')
                    .toString())));
        Navigator.of(context).pop();
      } else {
        setState(() =>
            _error = (set['message'] ?? 'Could not set password.').toString());
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: _mobile,
                enabled: _step == _Step.enterMobile,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder()),
              ),
              if (_step == _Step.enterOtp) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'OTP',
                      prefixIcon: Icon(Icons.pin_outlined),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPass,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'New password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                      border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 12),
              if (_info != null)
                Text(_info!, style: const TextStyle(color: Colors.green)),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              AppButton(
                label: _step == _Step.enterMobile ? 'Send OTP' : 'Reset password',
                busy: _busy,
                onPressed:
                    _step == _Step.enterMobile ? _sendOtp : _resetPassword,
              ),
              if (_step == _Step.enterOtp)
                TextButton(
                  onPressed: _busy ? null : _sendOtp,
                  child: const Text('Resend OTP'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
