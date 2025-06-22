// shop_screen.dart (corrected to work with main.dart cart + filters + products)

import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import 'shop_cart_screen.dart';
import 'cart_icon_with_badge.dart';
import 'product_bottom_sheet.dart';

class ShopScreen extends StatelessWidget {
  final List<CartItem> cart;
  final Function(CartItem) onAddToCart;

  const ShopScreen({super.key, required this.cart, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Map<String, dynamic>> demoProducts = [
      {
        "name": "Rugby Ball",
        "price": 29.99,
        "category": "Balls",
      },
      {
        "name": "Rugby Shoes",
        "price": 79.99,
        "category": "Footwear",
      },
      {
        "name": "Rugby Jersey",
        "price": 49.99,
        "category": "Apparel",
      },
      {
        "name": "Training Cones",
        "price": 19.99,
        "category": "Accessories",
      },
      {
        "name": "Rugby Shorts",
        "price": 39.99,
        "category": "Apparel",
      },
      {
        "name": "Water Bottle",
        "price": 9.99,
        "category": "Accessories",
      },
    ];

    final List<String> allCategories =
    demoProducts.map((p) => p["category"] as String).toSet().toList();

    final ValueNotifier<Set<String>> selectedCategories = ValueNotifier({});

    return Scaffold(
      appBar: AppBar(
        title: const Text('RefereeIQ Shop'),
      ),
      body: Column(
        children: [
          // Category filters (horizontal scroll)
          Container(
            height: 50,
            margin: const EdgeInsets.only(top: 8),
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: selectedCategories,
              builder: (context, selected, _) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: allCategories.map((category) {
                    final isSelected = selected.contains(category);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (bool sel) {
                          selectedCategories.value = {
                            ...selectedCategories.value
                          }..toggle(category);
                        },
                        selectedColor: colorScheme.primary.withOpacity(0.8),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: selectedCategories,
              builder: (context, selected, _) {
                final filteredProducts = demoProducts.where((product) {
                  final String category = product["category"] as String;
                  return selected.isEmpty || selected.contains(category);
                }).toList();

                return GridView.builder(
                  itemCount: filteredProducts.length,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => ProductBottomSheet(
                            product: product,
                            onAddToCart: onAddToCart,
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image placeholder
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
                              ),
                            ),
                            // Product info
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product["name"],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "\$${product["price"].toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension _ToggleSet<T> on Set<T> {
  void toggle(T value) {
    if (contains(value)) {
      remove(value);
    } else {
      add(value);
    }
  }
}
