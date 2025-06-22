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
  String selectedSize = 'M';
  int quantity = 1;

  final List<String> sizes = ['XS', 'S', 'M', 'L', 'XL'];

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
                // Product image
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, size: 100, color: Colors.grey),
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
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                // Size selector
                const Text('Select Size:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: sizes.map((size) {
                    final isSelected = size == selectedSize;
                    return ChoiceChip(
                      label: Text(size),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          selectedSize = size;
                        });
                      },
                      selectedColor: colorScheme.primary.withOpacity(0.8),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Quantity selector
                const Text('Quantity:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: quantity > 1
                          ? () {
                        setState(() {
                          quantity--;
                        });
                      }
                          : null,
                    ),
                    Text(quantity.toString(), style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() {
                          quantity++;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Add to Cart button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
