import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_service.dart';

/// In-app admin: feature flags, prompts, AI config, admin UID list (callable-backed).
class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen>
    with SingleTickerProviderStateMixin {
  final _admin = AdminService();
  late TabController _tabs;

  bool _loading = true;
  String? _error;

  bool _challengeEnabled = false;
  bool _sourcesEnabled = false;
  bool _shopEnabled = false;

  late TextEditingController _sofiaPrompt;
  late TextEditingController _challengePrompt;
  late TextEditingController _verifyPrompt;

  late TextEditingController _activeProvider;
  late TextEditingController _chatModel;
  late TextEditingController _simpleChatModel;
  late TextEditingController _challengeModel;
  late TextEditingController _tempChat;
  late TextEditingController _tempChallenge;
  late TextEditingController _providersJson;
  bool _advancedProvidersOpen = false;

  Map<String, dynamic> _fullAi = {};

  List<String> _adminUids = [];
  final _newAdminUid = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _sofiaPrompt = TextEditingController();
    _challengePrompt = TextEditingController();
    _verifyPrompt = TextEditingController();
    _activeProvider = TextEditingController();
    _chatModel = TextEditingController();
    _simpleChatModel = TextEditingController();
    _challengeModel = TextEditingController();
    _tempChat = TextEditingController();
    _tempChallenge = TextEditingController();
    _providersJson = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _sofiaPrompt.dispose();
    _challengePrompt.dispose();
    _verifyPrompt.dispose();
    _activeProvider.dispose();
    _chatModel.dispose();
    _simpleChatModel.dispose();
    _challengeModel.dispose();
    _tempChat.dispose();
    _tempChallenge.dispose();
    _providersJson.dispose();
    _newAdminUid.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await _admin.getConfig();
      if (!mounted) return;
      if (!snap.isAdmin) {
        setState(() {
          _loading = false;
          _error = 'You do not have admin access.';
        });
        return;
      }
      _applySnapshot(snap);
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applySnapshot(AdminConfigSnapshot snap) {
    final f = snap.features;
    _challengeEnabled = f['challengeEnabled'] == true;
    _sourcesEnabled = f['sourcesEnabled'] == true;
    _shopEnabled = f['shopEnabled'] == true;

    final p = snap.prompts;
    _sofiaPrompt.text = p['sofiaSystem'] as String? ?? '';
    _challengePrompt.text = p['challengeSystem'] as String? ?? '';
    _verifyPrompt.text = p['verifySystem'] as String? ?? '';

    _fullAi = Map<String, dynamic>.from(snap.ai);
    final active = snap.ai['activeProvider'] as String? ?? 'openai';
    _activeProvider.text = active;
    final providers = Map<String, dynamic>.from(
      snap.ai['providers'] as Map? ?? {},
    );
    final entry = Map<String, dynamic>.from(
      providers[active] as Map? ?? {},
    );
    _chatModel.text = entry['chatModel'] as String? ?? '';
    _simpleChatModel.text = entry['simpleChatModel'] as String? ?? '';
    _challengeModel.text = entry['challengeModel'] as String? ?? '';
    final temp = Map<String, dynamic>.from(entry['temperature'] as Map? ?? {});
    _tempChat.text = '${temp['chat'] ?? 0.6}';
    _tempChallenge.text = '${temp['challenge'] ?? 0.4}';
    _providersJson.text = const JsonEncoder.withIndent('  ').convert(providers);

    _adminUids = List<String>.from(snap.adminUids);
  }

  Future<void> _saveFeatures() async {
    try {
      await _admin.updateFeatures({
        'challengeEnabled': _challengeEnabled,
        'sourcesEnabled': _sourcesEnabled,
        'shopEnabled': _shopEnabled,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feature flags saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _savePrompts() async {
    try {
      await _admin.updatePrompts({
        'sofiaSystem': _sofiaPrompt.text,
        'challengeSystem': _challengePrompt.text,
        'verifySystem': _verifyPrompt.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompts saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Map<String, dynamic> _providersFromStructuredFields() {
    final active = _activeProvider.text.trim().isEmpty
        ? 'openai'
        : _activeProvider.text.trim();
    final base = Map<String, dynamic>.from(
      _fullAi['providers'] as Map? ?? {},
    );
    final merged = <String, dynamic>{};
    for (final e in base.entries) {
      merged[e.key.toString()] =
          Map<String, dynamic>.from(e.value as Map? ?? {});
    }
    final entry = Map<String, dynamic>.from(
      merged[active] as Map? ?? {},
    );
    entry['chatModel'] = _chatModel.text.trim();
    entry['simpleChatModel'] = _simpleChatModel.text.trim();
    entry['challengeModel'] = _challengeModel.text.trim();
    entry['temperature'] = {
      'chat': double.tryParse(_tempChat.text.trim()) ?? 0.6,
      'challenge': double.tryParse(_tempChallenge.text.trim()) ?? 0.4,
    };
    merged[active] = entry;
    return merged;
  }

  Map<String, dynamic> _buildProvidersForSave() {
    if (_advancedProvidersOpen) {
      final decoded = jsonDecode(_providersJson.text);
      if (decoded is! Map) {
        throw const FormatException('providers JSON must be an object');
      }
      return Map<String, dynamic>.from(decoded);
    }
    return _providersFromStructuredFields();
  }

  Future<void> _saveAi() async {
    try {
      final providers = _buildProvidersForSave();
      final active = _activeProvider.text.trim().isEmpty
          ? 'openai'
          : _activeProvider.text.trim();
      await _admin.updateAi({
        'activeProvider': active,
        'providers': providers,
      });
      if (!mounted) return;
      _fullAi = {..._fullAi, 'activeProvider': active, 'providers': providers};
      _providersJson.text =
          const JsonEncoder.withIndent('  ').convert(providers);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI config saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _addAdmin() async {
    final uid = _newAdminUid.text.trim();
    if (uid.isEmpty) return;
    try {
      final uids = await _admin.addAdmin(uid);
      if (!mounted) return;
      setState(() {
        _adminUids = uids;
        _newAdminUid.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin added')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _removeAdmin(String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove admin'),
        content: Text('Remove UID\n$uid'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final r = await _admin.removeAdmin(uid);
      if (!mounted) return;
      setState(() => _adminUids = r.uids);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.selfRemoved ? 'You were removed as admin' : 'Admin removed')),
      );
      if (r.selfRemoved) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin console'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Features'),
            Tab(text: 'Prompts'),
            Tab(text: 'AI'),
            Tab(text: 'Admins'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _featuresTab(),
          _promptsTab(),
          _aiTab(),
          _adminsTab(),
        ],
      ),
    );
  }

  Widget _featuresTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Daily challenge'),
          subtitle: const Text('challengeEnabled'),
          value: _challengeEnabled,
          onChanged: (v) => setState(() => _challengeEnabled = v),
        ),
        SwitchListTile(
          title: const Text('Sources'),
          subtitle: const Text('sourcesEnabled'),
          value: _sourcesEnabled,
          onChanged: (v) => setState(() => _sourcesEnabled = v),
        ),
        SwitchListTile(
          title: const Text('Shop'),
          subtitle: const Text('shopEnabled'),
          value: _shopEnabled,
          onChanged: (v) => setState(() => _shopEnabled = v),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saveFeatures,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save feature flags'),
        ),
      ],
    );
  }

  Widget _promptsTab() {
    Widget field(String label, TextEditingController c) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: label,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        field('Sofia system (sofiaSystem)', _sofiaPrompt),
        field('Challenge system (challengeSystem)', _challengePrompt),
        field('Verify system (verifySystem)', _verifyPrompt),
        FilledButton.icon(
          onPressed: _savePrompts,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save prompts'),
        ),
      ],
    );
  }

  Widget _aiTab() {
    final scheme = Theme.of(context).colorScheme;
    Widget tf(String label, TextEditingController c, {String? hint}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        tf('Active provider', _activeProvider, hint: 'openai'),
        tf('Chat model', _chatModel),
        tf('Simple chat model', _simpleChatModel),
        tf('Challenge model', _challengeModel),
        tf('Temperature — chat', _tempChat),
        tf('Temperature — challenge', _tempChallenge),
        ExpansionTile(
          title: const Text('Advanced: providers JSON'),
          subtitle: Text(
            _advancedProvidersOpen
                ? 'Saving uses JSON below'
                : 'Optional full providers map',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          initiallyExpanded: false,
          onExpansionChanged: (open) {
            setState(() {
              _advancedProvidersOpen = open;
              if (open) {
                _providersJson.text = const JsonEncoder.withIndent('  ')
                    .convert(_providersFromStructuredFields());
              }
            });
          },
          children: [
            SizedBox(
              height: 240,
              child: TextField(
                controller: _providersJson,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saveAi,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save AI config'),
        ),
      ],
    );
  }

  Widget _adminsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Allowed Firebase Auth UIDs',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._adminUids.map(
          (uid) => ListTile(
            title: Text(uid, style: const TextStyle(fontFamily: 'monospace')),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeAdmin(uid),
            ),
          ),
        ),
        const Divider(height: 32),
        TextField(
          controller: _newAdminUid,
          decoration: const InputDecoration(
            labelText: 'New admin UID',
            border: OutlineInputBorder(),
          ),
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _addAdmin,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add admin'),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Reload config'),
        ),
      ],
    );
  }
}
