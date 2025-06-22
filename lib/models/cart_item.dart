// cart_item.dart

class CartItem {
  final Map<String, dynamic> product;
  final String size;
  int quantity;   // Mutable quantity so it can be updated in cart

  CartItem({
    required this.product,
    required this.size,
    required this.quantity,
  });

  double get totalPrice => product['price'] * quantity;
}
