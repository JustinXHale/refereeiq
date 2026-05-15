import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

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
  Uint8List? _pickedImageBytes;

  static const _usStates = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _name = user.displayName ?? '';
    });

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (!mounted) return;
    if (data != null) {
      setState(() {
        _favoriteTeam = data['favoriteTeam'] ?? '';
        _city = data['city'] ?? '';
        _state = data['state'];
        _affiliation = data['affiliation'];
        _refereeAssociation = data['refereeAssociation'] ?? '';
        _homeTeam = data['homeTeam'] ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (mounted) setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<String?> _uploadPickedBytes(Uint8List bytes) async {
    final uid = _auth.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref().child('profile_pics/$uid.jpg');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final uid = _auth.currentUser!.uid;

    String photoURL = _auth.currentUser?.photoURL ?? '';
    if (_pickedImageBytes != null) {
      photoURL = await _uploadPickedBytes(_pickedImageBytes!) ?? photoURL;
    }

    final data = {
      'name': _name,
      'email': _auth.currentUser!.email,
      'favoriteTeam': _favoriteTeam,
      'city': _city,
      'state': _state,
      'affiliation': _affiliation,
      'photoURL': photoURL,
    };
    if (_affiliation == 'Referee') data['refereeAssociation'] = _refereeAssociation;
    if (_affiliation == 'Player' || _affiliation == 'Coach') data['homeTeam'] = _homeTeam;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  InputDecoration _themedInput(String label) =>
      InputDecoration(labelText: label);

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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final nav = Navigator.of(context);
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                nav.pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            itemBuilder: (BuildContext context) {
              return const [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Cancel & Logout'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: InkWell(
                  onTap: _pickImage,
                  customBorder: const CircleBorder(),
                  child: Builder(builder: (ctx) {
                    final cs = Theme.of(ctx).colorScheme;
                    return CircleAvatar(
                      radius: 48,
                      backgroundColor: cs.surfaceContainerHighest,
                      backgroundImage: _pickedImageBytes != null
                          ? MemoryImage(_pickedImageBytes!)
                          : (_auth.currentUser?.photoURL != null
                          ? CachedNetworkImageProvider(_auth.currentUser!.photoURL!)
                          : null),
                      child: _pickedImageBytes == null && _auth.currentUser?.photoURL == null
                          ? Icon(Icons.person, size: 48, color: cs.onSurfaceVariant)
                          : null,
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: _themedInput('Name'),
                initialValue: _name,
                onSaved: (v) => _name = v!.trim(),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _themedInput('Email'),
                initialValue: userEmail,
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _themedInput('Favorite Rugby Team'),
                initialValue: _favoriteTeam,
                onSaved: (v) => _favoriteTeam = v!.trim(),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: _themedInput('City'),
                      initialValue: _city,
                      onSaved: (v) => _city = v!.trim(),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _themedInput('State'),
                      hint: const Text('Choose State'),
                      initialValue: _state,
                      items: _usStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _state = v),
                      validator: (v) => v == null ? 'Required' : null,
                      onSaved: (v) => _state = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: _themedInput('Affiliation'),
                hint: const Text('Choose Affiliation'),
                initialValue: _affiliation,
                items: const [
                  'Referee', 'Player', 'Coach', 'Fan'
                ].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => _affiliation = v),
                validator: (v) => v == null ? 'Required' : null,
                onSaved: (v) => _affiliation = v,
              ),
              const SizedBox(height: 16),
              if (_affiliation == 'Referee') ...[
                TextFormField(
                  decoration: _themedInput('Referee Association'),
                  initialValue: _refereeAssociation,
                  onSaved: (v) => _refereeAssociation = v!.trim(),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],
              if (_affiliation == 'Player' || _affiliation == 'Coach') ...[
                TextFormField(
                  decoration: _themedInput('Home Team'),
                  initialValue: _homeTeam,
                  onSaved: (v) => _homeTeam = v!.trim(),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                style: FilledButton.styleFrom(
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
