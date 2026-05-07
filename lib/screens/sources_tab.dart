// sources_tab.dart

import 'dart:convert';

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
            child: Center(child: Text(_loadError!, style: GoogleFonts.inter())),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Wrap(
              spacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: colorScheme.primary,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                      _selectedSubcategory = 'All';
                    });
                  },
                  labelStyle: GoogleFonts.inter(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
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
                    selectedColor: const Color(0xFFF0CF1E),
                    onSelected: (_) {
                      setState(() {
                        _selectedSubcategory = subcategory;
                      });
                    },
                    labelStyle: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                return Card(
                  color: const Color(0xFFFEF7E6),
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
