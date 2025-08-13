// profile_screen.dart — unified self/other profile with conditional editing

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? viewUid; // whose profile to view; null = current user

  const ProfileScreen({super.key, this.viewUid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _states = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY'
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

  bool get isSelf {
    final me = _auth.currentUser?.uid;
    return widget.viewUid == null || widget.viewUid == me;
  }

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
    final me = _auth.currentUser;
    if (me == null && widget.viewUid == null) return;

    final uidToLoad = widget.viewUid ?? me!.uid;

    final doc = await _authService.getUserProfile(uidToLoad);
    final data = doc.data() ?? {};

    _nameController.text = data['name'] ?? '';
    _emailController.text = data['email'] ?? (isSelf ? (me?.email ?? '') : '');
    _favoriteTeamController.text = data['favoriteTeam'] ?? '';
    _cityController.text = data['city'] ?? '';
    _state = data['state'];
    _affiliation = data['affiliation'];

    final rawUrl = data['photoURL'] as String?;
    if (rawUrl != null &&
        (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))) {
      _remotePhotoUrl = rawUrl;
    } else {
      _remotePhotoUrl = null;
    }

    final scoreSnap = await FirebaseFirestore.instance.collection('leaderboard')
        .doc(uidToLoad)
        .get();
    final scores = scoreSnap.data() ?? {};
    _dailyScore = scores['daily'] ?? 0;
    _monthlyScore = scores['monthly'] ?? 0;
    _lifetimeScore = scores['lifetime'] ?? 0;

    if (_affiliation == 'Referee') {
      _detailController.text = data['refereeAssociation'] ?? '';
    } else if (_affiliation == 'Player' || _affiliation == 'Coach') {
      _detailController.text = data['homeTeam'] ?? '';
    } else {
      _detailController.clear();
    }

    setState(() {});
  }

  Future<void> _pickImage() async {
    if (!isSelf) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75);
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
    if (!isSelf) return;
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
      'photoURL': _remotePhotoUrl,
      // keep whatever’s already set if no new upload
    };

    if (_affiliation == 'Referee') {
      profile['refereeAssociation'] = _detailController.text.trim();
      profile.remove('homeTeam');
    } else if (_affiliation == 'Player' || _affiliation == 'Coach') {
      profile['homeTeam'] = _detailController.text.trim();
      profile.remove('refereeAssociation');
    } else {
      profile.remove('homeTeam');
      profile.remove('refereeAssociation');
    }

    try {
      if (_image != null) {
        final url = await _uploadToStorage(_image!);
        profile['photoURL'] = url;
        _remotePhotoUrl = url;
      }
      await _authService.saveUserProfile(user.uid, profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==== Delete Account flow ====
  Future<void> _deleteAccount() async {
    if (!isSelf) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text(
                'Delete account?', style: TextStyle(color: Colors.black)),
            content: const Text(
              'This permanently deletes your account and profile data. This cannot be undone.',
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                    'Cancel', style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                    'Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      final usesPassword = user.providerData.any((p) =>
      p.providerId == 'password');

      String? currentPassword;
      if (usesPassword) {
        currentPassword = await _askForPassword();
        if (currentPassword == null || currentPassword.isEmpty) return;
      }

      setState(() => _loading = true);

      await _authService.deleteAccount(currentPassword: currentPassword);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted')),
      );
      // Return to welcome; auth listener will also handle this in most apps
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _askForPassword() async {
    String? password;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Confirm Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                    'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                )
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                )
            ),
          ],
        );
      },
    );
    return password;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: isSelf ? _pickImage : null,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : (_remotePhotoUrl != null ? NetworkImage(
                          _remotePhotoUrl!) : null) as ImageProvider?,
                      child: (_image == null && _remotePhotoUrl == null)
                          ? const Icon(
                          Icons.person, size: 60, color: Colors.grey)
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
                        enabled: isSelf,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                        isSelf ? (val!.isEmpty
                            ? 'Required'
                            : null) : null,
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
                        enabled: isSelf,
                        decoration: const InputDecoration(
                          labelText: 'Favorite Team',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                        isSelf ? (val!.isEmpty
                            ? 'Required'
                            : null) : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              enabled: isSelf,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                              isSelf ? (val!.isEmpty
                                  ? 'Required'
                                  : null) : null,
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
                              items: _states.map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: isSelf ? (v) =>
                                  setState(() => _state = v) : null,
                              validator: (val) =>
                              isSelf ? (val == null
                                  ? 'Required'
                                  : null) : null,
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
                            .map((a) =>
                            DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: isSelf
                            ? (v) =>
                            setState(() {
                              _affiliation = v;
                              _detailController.clear();
                            })
                            : null,
                        validator: (val) =>
                        isSelf ? (val == null
                            ? 'Required'
                            : null) : null,
                      ),
                      const SizedBox(height: 16),
                      if (_affiliation == 'Referee')
                        TextFormField(
                          controller: _detailController,
                          enabled: isSelf,
                          decoration: const InputDecoration(
                            labelText: 'Referee Association',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                          isSelf ? (val!.isEmpty
                              ? 'Required'
                              : null) : null,
                        ),
                      if (_affiliation == 'Player' || _affiliation == 'Coach')
                        TextFormField(
                          controller: _detailController,
                          enabled: isSelf,
                          decoration: const InputDecoration(
                            labelText: 'Home Team',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                          isSelf ? (val!.isEmpty
                              ? 'Required'
                              : null) : null,
                        ),
                      const SizedBox(height: 24),

                      if (isSelf)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 56),
                            textStyle: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _loading ? null : _submitForm,
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors
                              .white)
                              : const Text('Save Profile'),
                        ),

                      const SizedBox(height: 24),
                      Text(
                        'Leaderboard Points',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.bold),
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

                      const SizedBox(height: 32),

                      if (isSelf)
                        TextButton(
                          onPressed: _loading ? null : _deleteAccount,
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                              decoration: TextDecoration.underline,
                            ),
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
        Text(value.toString(), style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
      ],
    );
  }
}
