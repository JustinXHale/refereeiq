// product_bottom_sheet.dart (corrected layout)

import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class ProductBottomSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(CartItem) onAddToCart;

  const ProductBottomSheet({super.key, required this.product, required this.onAddToCart});

  @override
  State<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends State<ProductBottomSheet> {
  late String selectedSize;
  int quantity = 1;

  List<String> get _sizes {
    final raw = widget.product['availableSizes'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).toList();
    }
    return ['XS', 'S', 'M', 'L', 'XL'];
  }

  @override
  void initState() {
    super.initState();
    selectedSize = _sizes.first;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image placeholder
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.image, size: 100, color: colorScheme.outlineVariant),
                ),
                const SizedBox(height: 16),
                // Product name + price
                Text(
                  widget.product['name'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${widget.product['price'].toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
                ),
                if (widget.product['availableSizes'] != null) ...[
                  const SizedBox(height: 24),
                  const Text('Select Size:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _sizes.map((size) {
                      return ChoiceChip(
                        label: Text(size),
                        selected: size == selectedSize,
                        onSelected: (_) => setState(() => selectedSize = size),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                // Quantity selector
                const Text('Quantity:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Decrease quantity',
                      onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                    ),
                    Text(quantity.toString(), style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Increase quantity',
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Add to Cart button
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: () {
                    final item = CartItem(
                      product: widget.product,
                      size: selectedSize,
                      quantity: quantity,
                    );
                    widget.onAddToCart(item);
                    Navigator.pop(context);
                  },
                  child: const Text('Add to Cart'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
