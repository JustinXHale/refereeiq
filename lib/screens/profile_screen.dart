// Fixed profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../widgets/affiliation_dropdown.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _states = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
  ];

  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _favoriteTeamController;
  late TextEditingController _cityController;
  late TextEditingController _detailController;

  String? _state;
  String? _affiliation;
  String? _remotePhotoUrl;
  File? _image;
  bool _loading = false;
  late Future<void> _loadFuture;

  int _dailyScore = 0;
  int _monthlyScore = 0;
  int _lifetimeScore = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _favoriteTeamController = TextEditingController();
    _cityController = TextEditingController();
    _detailController = TextEditingController();
    _loadFuture = _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteTeamController.dispose();
    _cityController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _authService.getUserProfile(user.uid);
    final data = doc.data() ?? {};
    _nameController.text = data['name'] ?? '';
    _emailController.text = user.email ?? '';
    _favoriteTeamController.text = data['favoriteTeam'] ?? '';
    _cityController.text = data['city'] ?? '';
    _state = data['state'];
    _affiliation = data['affiliation'];

    final rawUrl = data['photoURL'] as String?;
    if (rawUrl != null && (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))) {
      _remotePhotoUrl = rawUrl;
    }

    final scoreSnap = await FirebaseFirestore.instance.collection('leaderboard').doc(user.uid).get();
    final scores = scoreSnap.data() ?? {};
    _dailyScore = scores['daily'] ?? 0;
    _monthlyScore = scores['monthly'] ?? 0;
    _lifetimeScore = scores['lifetime'] ?? 0;

    if (_affiliation == 'Referee') {
      _detailController.text = data['refereeAssociation'] ?? '';
    } else if (_affiliation == 'Player' || _affiliation == 'Coach') {
      _detailController.text = data['homeTeam'] ?? '';
    }

    setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<String> _uploadToStorage(File file) async {
    final uid = _auth.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref().child('profile_pics/$uid.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      setState(() => _loading = false);
      return;
    }

    final profile = <String, dynamic>{
      'name': _nameController.text.trim(),
      'favoriteTeam': _favoriteTeamController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _state,
      'affiliation': _affiliation,
    };

    if (_affiliation == 'Referee') {
      profile['refereeAssociation'] = _detailController.text.trim();
    } else if (_affiliation == 'Player' || _affiliation == 'Coach') {
      profile['homeTeam'] = _detailController.text.trim();
    }

    try {
      if (_image != null) {
        final url = await _uploadToStorage(_image!);
        profile['photoURL'] = url;
        _remotePhotoUrl = url;
      }
      await _authService.saveUserProfile(user.uid, profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : (_remotePhotoUrl != null ? NetworkImage(_remotePhotoUrl!) : null) as ImageProvider?,
                      child: (_image == null && _remotePhotoUrl == null)
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _favoriteTeamController,
                        decoration: const InputDecoration(
                          labelText: 'Favorite Team',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'State',
                                border: OutlineInputBorder(),
                              ),
                              value: _state,
                              items: _states
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _state = v),
                              validator: (val) => val == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Affiliation',
                          border: OutlineInputBorder(),
                        ),
                        value: _affiliation,
                        items: ['Referee', 'Player', 'Coach', 'Fan']
                            .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _affiliation = v;
                          _detailController.clear();
                        }),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      if (_affiliation == 'Referee')
                        TextFormField(
                          controller: _detailController,
                          decoration: const InputDecoration(
                            labelText: 'Referee Association',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      if (_affiliation == 'Player' || _affiliation == 'Coach')
                        TextFormField(
                          controller: _detailController,
                          decoration: const InputDecoration(
                            labelText: 'Home Team',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 56),
                          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _loading ? null : _submitForm,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Profile'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Leaderboard Points',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade50,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildScoreColumn('Today', _dailyScore),
                            _buildScoreColumn('Month', _monthlyScore),
                            _buildScoreColumn('Lifetime', _lifetimeScore),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreColumn(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }
}