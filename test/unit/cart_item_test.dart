import 'package:flutter_test/flutter_test.dart';
import 'package:RefereeIQ/models/cart_item.dart';

void main() {
  group('CartItem', () {
    group('totalPrice', () {
      test(
          'Given quantity 1 and price 29.99, '
          'When totalPrice is accessed, '
          'Then returns 29.99', () {
        final item = CartItem(
          product: {'name': 'Rugby Ball', 'price': 29.99},
          size: 'M',
        );

        expect(item.totalPrice, equals(29.99));
      });

      test(
          'Given quantity 3 and price 10.00, '
          'When totalPrice is accessed, '
          'Then returns 30.00', () {
        final item = CartItem(
          product: {'name': 'Test Item', 'price': 10.00},
          size: 'L',
          quantity: 3,
        );

        expect(item.totalPrice, equals(30.00));
      });

      test(
          'Given integer price in product map, '
          'When totalPrice is accessed, '
          'Then returns correct double', () {
        final item = CartItem(
          product: {'name': 'Rugby Jersey', 'price': 50},
          size: 'S',
          quantity: 2,
        );

        expect(item.totalPrice, equals(100.0));
      });
    });

    group('quantity', () {
      test(
          'Given no quantity provided, '
          'When CartItem created, '
          'Then defaults to 1', () {
        final item = CartItem(
          product: {'name': 'Item', 'price': 5.0},
          size: 'One Size',
        );

        expect(item.quantity, equals(1));
      });

      test(
          'Given quantity is mutable, '
          'When quantity incremented, '
          'Then totalPrice updates accordingly', () {
        final item = CartItem(
          product: {'name': 'Item', 'price': 10.0},
          size: 'M',
          quantity: 1,
        );

        item.quantity++;

        expect(item.quantity, equals(2));
        expect(item.totalPrice, equals(20.0));
      });
    });

    group('size', () {
      test(
          'Given size is mutable, '
          'When size changed, '
          'Then reflects new value', () {
        final item = CartItem(
          product: {'name': 'Item', 'price': 10.0},
          size: 'S',
        );

        item.size = 'XL';

        expect(item.size, equals('XL'));
      });
    });
  });
}
