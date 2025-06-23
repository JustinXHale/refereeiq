// lib/models/cart_item.dart

class CartItem {
  /// The product data (e.g., name, price, availableSizes)
  final Map<String, dynamic> product;

  /// Currently selected size for this cart item
  String size;

  /// Quantity of this item in cart
  int quantity;

  CartItem({
    required this.product,
    required this.size,
    this.quantity = 1,
  });

  /// Calculates total price for this item
  double get totalPrice => ((product['price'] as num) * quantity).toDouble();
}
