// cart_item.dart (model)

class CartItem {
  final Map<String, dynamic> product;
  final String size;
  final int quantity;

  CartItem({
    required this.product,
    required this.size,
    required this.quantity,
  });

  double get totalPrice {
    return (product['price'] as double) * quantity;
  }
}
