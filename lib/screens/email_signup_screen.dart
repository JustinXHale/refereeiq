import 'package:flutter/material.dart';
import '../widgets/affiliation_dropdown.dart';

class EmailSignUpScreen extends StatefulWidget {
  const EmailSignUpScreen({super.key});

  @override
  State<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends State<EmailSignUpScreen> {
  String affiliation = 'Referee';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AffiliationDropdown(
              value: affiliation,
              options: const ['Referee', 'Player', 'Coach', 'Fan'],
              onChanged: (newValue) {
                setState(() {
                  affiliation = newValue ?? 'Referee';
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
