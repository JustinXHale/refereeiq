// sources_tab.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'document_view_screen.dart';
import '../services/sources_search_bridge.dart';

class SourcesTab extends StatefulWidget {
  const SourcesTab({super.key});

  @override
  State<SourcesTab> createState() => _SourcesTabState();
}

class _SourcesTabState extends State<SourcesTab>
    with AutomaticKeepAliveClientMixin {
  static const String _catalogPath = 'assets/sources/catalog.json';
  static const List<String> _categoryOrder = [
    'All',
    'World Rugby',
    'USA Rugby',
    'MLR',
  ];
  static const Map<String, List<String>> _subcategoryOrder = {
    'World Rugby': ['All', 'XVs', '10s', 'Sevens', 'U19'],
  };

  final List<Map<String, dynamic>> _docs = [];

  List<String> _categories = ['All'];

  String _selectedCategory = 'All';
  String _selectedSubcategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _loadError;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadLawSources();
    SourcesSearchBridge.query.addListener(_handleExternalSearch);
  }

  Future<void> _loadLawSources() async {
    try {
      final docs = <Map<String, dynamic>>[];
      final rawCatalog = await rootBundle.loadString(_catalogPath);
      final catalog = jsonDecode(rawCatalog);
      if (catalog is! List) {
        throw Exception('catalog.json must be a list');
      }

      for (final entry in catalog) {
        if (entry is! Map) continue;
        final source = Map<String, dynamic>.from(entry);
        final path = (source['path'] ?? '').toString().trim();
        if (path.isEmpty) continue;
        String content = '';
        String title = (source['title'] ?? '').toString();
        try {
          if (path.toLowerCase().endsWith('.md')) {
            content = await rootBundle.loadString(path);
            if (title.isEmpty) {
              title = _extractTitle(content, path);
            }
          } else if (title.isEmpty) {
            title = path.split('/').last;
          }
          docs.add({
            'title': title,
            'subtitle': (source['subtitle'] ?? 'Source').toString(),
            'category': (source['category'] ?? 'World Rugby').toString(),
            'subcategory': (source['subcategory'] ?? 'XVs').toString(),
            'content': content,
            'assetPath': path,
            'path': path,
          });
        } catch (e) {
          if (kDebugMode) print('[sources] skip $path: $e');
        }
      }
      final categories = <String>{'All'};
      for (final doc in docs) {
        categories.add((doc['category'] ?? '').toString());
      }
      if (!mounted) return;
      setState(() {
        _docs
          ..clear()
          ..addAll(docs);
        _categories = _orderChips(
          categories.where((c) => c.isNotEmpty).toList(),
          _categoryOrder,
        );
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (kDebugMode) print('[sources] load error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load sources.';
      });
    }
  }

  String _extractTitle(String content, String path) {
    final lines = content.split('\n');
    final heading = lines.isNotEmpty ? lines.first.trim() : '';
    if (heading.startsWith('#')) {
      return heading.replaceFirst(RegExp(r'^#+\s*'), '').trim();
    }
    return path.split('/').last;
  }

  @override
  void dispose() {
    SourcesSearchBridge.query.removeListener(_handleExternalSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _handleExternalSearch() {
    final query = SourcesSearchBridge.query.value;
    if (query == null || query.isEmpty) return;
    setState(() {
      _searchQuery = query;
      _searchController.text = query;
      _selectedCategory = 'All';
      _selectedSubcategory = 'All';
    });
    SourcesSearchBridge.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final colorScheme = Theme.of(context).colorScheme;
    final subcategories = <String>{'All'};
    if (_selectedCategory != 'All' && _selectedCategory != 'MLR') {
      for (final doc in _docs) {
        if (doc['category'] == _selectedCategory) {
          subcategories.add((doc['subcategory'] ?? '').toString());
        }
      }
    }
    final subcategoryList = _selectedCategory == 'MLR'
        ? ['All']
        : _orderChips(
            subcategories.where((s) => s.isNotEmpty).toList(),
            _subcategoryOrder[_selectedCategory],
          );
    final filteredDocs = _docs.where((doc) {
      final categoryMatch =
          _selectedCategory == 'All' || doc['category'] == _selectedCategory;
      final subcategoryMatch = _selectedCategory == 'MLR'
          ? true
          : _selectedSubcategory == 'All' ||
              doc['subcategory'] == _selectedSubcategory;
      if (!subcategoryMatch) return false;
      if (!categoryMatch) return false;
      if (_searchQuery.isEmpty) return true;
      final hay = [
        doc['title'],
        doc['subtitle'],
        doc['content'],
      ].join(' ').toLowerCase();
      return hay.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_loadError != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: 12),
                    Text(_loadError!, style: GoogleFonts.inter(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadLawSources,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search laws...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Organization',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: GoogleFonts.inter()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedCategory = value;
                  _selectedSubcategory = 'All';
                });
              },
            ),
          ),
          if (_selectedCategory != 'All' && subcategoryList.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: subcategoryList.map((subcategory) {
                  final isSelected = _selectedSubcategory == subcategory;
                  return ChoiceChip(
                    label: Text(subcategory),
                    selected: isSelected,
                    selectedColor: colorScheme.primary,
                    onSelected: (_) {
                      setState(() {
                        _selectedSubcategory = subcategory;
                      });
                    },
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
          if (filteredDocs.isEmpty && _searchQuery.isNotEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: colorScheme.outlineVariant),
                      const SizedBox(height: 12),
                      Text(
                        'No results for "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Text('Clear search'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                return Card(
                  color: colorScheme.primaryContainer,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      doc['title'],
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(doc['subtitle'], style: GoogleFonts.inter()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DocumentViewScreen(document: doc),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

List<String> _orderChips(List<String> values, List<String>? preferredOrder) {
  if (preferredOrder == null || preferredOrder.isEmpty) {
    values.sort();
    return values;
  }
  final set = values.toSet();
  final ordered = <String>[];
  for (final value in preferredOrder) {
    if (set.remove(value)) ordered.add(value);
  }
  final remaining = set.toList()..sort();
  ordered.addAll(remaining);
  return ordered;
}
