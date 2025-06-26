import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _authService.signInWithEmail(_email, _password);
      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          setState(() {
            _error = 'Email not verified. A new verification link has been sent.';
            _loading = false;
          });
          return;
        }
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// High-contrast decoration for input fields
  InputDecoration themedInput(String label) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Email field
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: themedInput('Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                (val != null && val.contains('@')) ? null : 'Enter a valid email',
                onSaved: (val) => _email = val!,
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: themedInput('Password'),
                obscureText: true,
                validator: (val) =>
                (val != null && val.length >= 6) ? null : 'Min 6 characters',
                onSaved: (val) => _password = val!,
              ),
              const SizedBox(height: 8),

              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/reset-password'),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                onPressed: _loading ? null : _signIn,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}