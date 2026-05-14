import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../screens/shop_cart_screen.dart';

class CartIconWithBadge extends StatelessWidget {
  final List<CartItem> cart;

  const CartIconWithBadge({super.key, required this.cart});

  int get _totalItems => cart.fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    final count = _totalItems;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: count > 0 ? 'Shopping cart, $count items' : 'Shopping cart',
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Shopping cart',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopCartScreen(cart: cart),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
