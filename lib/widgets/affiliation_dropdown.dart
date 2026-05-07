import 'package:flutter/material.dart';

class AffiliationDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final Function(String?) onChanged;

  const AffiliationDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Affiliation',
        border: OutlineInputBorder(),
      ),
      items: options.map((aff) {
        return DropdownMenuItem<String>(
          value: aff,
          child: Text(aff),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) =>
      (value == null || value.isEmpty) ? 'Please select affiliation' : null,
    );
  }
}
