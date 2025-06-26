import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _favoriteTeamController;
  late TextEditingController _cityController;
  String? _state;
  late TextEditingController _detailController;

  // Affiliation & future
  String? _affiliation;
  late Future<void> _loadFuture;
  bool _loading = false;
  File? _image;

  final List<String> _states = [
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA',
    'KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT',
    'VA','WA','WV','WI','WY'
  ];

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
    if (_image != null) {
      // TODO: upload to storage and set photoURL
      profile['photoURL'] = _image!.path;
    }

    try {
      await _authService.saveUserProfile(user.uid, profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                        labelText: 'Email', border: OutlineInputBorder()),
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  // Favorite Team
                  TextFormField(
                    controller: _favoriteTeamController,
                    decoration: const InputDecoration(
                      labelText: 'Favorite Team',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // City & State row
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
                              .map((s) => DropdownMenuItem(
                              value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _state = v),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Affiliation
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Affiliation',
                      border: OutlineInputBorder(),
                    ),
                    value: _affiliation,
                    items: ['Referee', 'Player', 'Coach', 'Fan']
                        .map((a) => DropdownMenuItem(
                        value: a, child: Text(a)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _affiliation = v;
                      _detailController.clear();
                    }),
                    hint: const Text('Choose Affiliation'),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Conditional detail
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
                  const SizedBox(height: 16),
                  // Photo upload
                  if (_image != null)
                    Image.file(_image!, height: 100, width: 100),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 48),
                      textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: _pickImage,
                    child: const Text('Upload Photo'),
                  ),
                  const SizedBox(height: 24),
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
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text('Save Profile'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
