import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  String _email = '';
  bool _loading = false;
  String? _message;

  InputDecoration _themedInput(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await _authService.sendPasswordResetEmail(_email);
      setState(() => _message = 'Password reset email sent!');
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.startsWith('Password') ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              TextFormField(
                decoration: _themedInput('Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                val != null && val.contains('@') ? null : 'Enter a valid email',
                onSaved: (val) => _email = val!,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                onPressed: _loading ? null : _sendResetEmail,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send Reset Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
