import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({Key? key}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  Timer? _timer;
  bool _resent = false;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _sendVerificationEmail();
    // Poll every 3 seconds to see if they clicked the link
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await _user.sendEmailVerification();
      setState(() => _resent = true);
    } catch (e) {
      setState(() => _error = 'Could not send email: $e');
    }
  }

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    await _user.reload();
    _user = _auth.currentUser!;
    if (_user.emailVerified) {
      _timer?.cancel();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              '''
Please check your email inbox (and spam folder)
for a verification link.
Once you’ve clicked it, come back here and hit “Continue.”
''',
              style: GoogleFonts.inter(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_resent)
              Text('Verification email sent!', style: TextStyle(color: cs.primary)),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              onPressed: _checking ? null : _checkVerified,
              child: _checking
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text('Continue'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _resent ? null : _sendVerificationEmail,
              child: const Text('Resend email'),
            ),
          ],
        ),
      ),
    );
  }
}
