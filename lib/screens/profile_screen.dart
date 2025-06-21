// profile_screen.dart (Material Design Updated)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/affiliation_dropdown.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _email = '';
  String _affiliation = 'Referee';
  String _affiliationDetail = '';

  final List<String> _affiliationOptions = [
    'Referee',
    'Player',
    'Coach',
    'Fan',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 16),
              AffiliationDropdown(
                value: _affiliation,
                options: _affiliationOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _affiliation = value;
                      _affiliationDetail = '';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildAffiliationDetailField(),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  textStyle: GoogleFonts.inter(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onPressed: _submitForm,
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAffiliationDetailField() {
    String label;
    String hint;

    switch (_affiliation) {
      case 'Referee':
        label = 'Referee Association';
        hint = 'Enter your referee association';
        break;
      case 'Player':
      case 'Coach':
        label = 'Team Affiliation';
        hint = 'Enter your team name';
        break;
      case 'Fan':
      default:
        label = 'Favorite Team';
        hint = 'Enter your favorite rugby team';
        break;
    }

    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
      onSaved: (value) => _affiliationDetail = value!,
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      print('Name: $_name');
      print('Email: $_email');
      print('Affiliation: $_affiliation');
      print('Affiliation Detail: $_affiliationDetail');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
    }
  }
}
