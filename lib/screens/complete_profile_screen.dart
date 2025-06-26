// CompleteProfileScreen
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  String _name = '';
  String _favoriteTeam = '';
  String _city = '';
  String? _state;
  String? _affiliation;
  String _refereeAssociation = '';
  String _homeTeam = '';
  File? _image;

  static const _usStates = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
  ];

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final uid = _auth.currentUser!.uid;
    final data = {
      'name': _name,
      'email': _auth.currentUser!.email,
      'favoriteTeam': _favoriteTeam,
      'city': _city,
      'state': _state,
      'affiliation': _affiliation,
      'photoURL': _image?.path ?? '',
    };
    if (_affiliation == 'Referee') data['refereeAssociation'] = _refereeAssociation;
    if (_affiliation == 'Player' || _affiliation == 'Coach') data['homeTeam'] = _homeTeam;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));

    Navigator.pushReplacementNamed(context, '/home');
  }

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

  @override
  Widget build(BuildContext context) {
    final userEmail = _auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icons/app_icon.png', width: 32, height: 32),
            const SizedBox(width: 8),
            const Text('Complete Your Profile'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name
              TextFormField(
                decoration: _themedInput('Name'),
                onSaved: (v) => _name = v!.trim(),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Email (disabled)
              TextFormField(
                decoration: _themedInput('Email'),
                initialValue: userEmail,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Favorite Team
              TextFormField(
                decoration: _themedInput('Favorite Team'),
                onSaved: (v) => _favoriteTeam = v!.trim(),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // City & State row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: _themedInput('City'),
                      onSaved: (v) => _city = v!.trim(),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _themedInput('State'),
                      hint: const Text('Choose State'),
                      value: _state,
                      items: _usStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _state = v),
                      validator: (v) => v == null ? 'Required' : null,
                      onSaved: (v) => _state = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Affiliation
              DropdownButtonFormField<String>(
                decoration: _themedInput('Affiliation'),
                hint: const Text('Choose Affiliation'),
                value: _affiliation,
                items: const [
                  'Referee', 'Player', 'Coach', 'Fan'
                ].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => _affiliation = v),
                validator: (v) => v == null ? 'Required' : null,
                onSaved: (v) => _affiliation = v,
              ),
              const SizedBox(height: 16),

              // Conditional fields
              if (_affiliation == 'Referee') ...[
                TextFormField(
                  decoration: _themedInput('Referee Association'),
                  onSaved: (v) => _refereeAssociation = v!.trim(),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],
              if (_affiliation == 'Player' || _affiliation == 'Coach') ...[
                TextFormField(
                  decoration: _themedInput('Home Team'),
                  onSaved: (v) => _homeTeam = v!.trim(),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Photo upload
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFADC44),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _pickImage,
                child: const Text('Upload Photo'),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFADC44),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _submit,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
