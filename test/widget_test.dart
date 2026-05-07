import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:RefereeIQ/models/cart_item.dart';
import 'package:RefereeIQ/screens/shop_cart_screen.dart';
import 'package:RefereeIQ/widgets/cart_icon_with_badge.dart';

void main() {
  group('Smoke tests — widget trees build without error', () {
    testWidgets('MaterialApp with basic scaffold renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('RefereeIQ'))),
        ),
      );

      expect(find.text('RefereeIQ'), findsOneWidget);
    });

    testWidgets('ShopCartScreen renders empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopCartScreen(cart: []),
        ),
      );

      expect(find.text('Your Cart'), findsOneWidget);
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('ShopCartScreen renders items and total', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cart = [
        CartItem(
          product: {'name': 'Rugby Ball', 'price': 29.99},
          size: 'M',
          quantity: 2,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ShopCartScreen(cart: cart),
        ),
      );

      expect(find.text('Rugby Ball'), findsOneWidget);
      expect(find.text('\$59.98'), findsOneWidget);
    });

    testWidgets('CartIconWithBadge renders with zero count', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: null,
            body: CartIconWithBadge(cart: []),
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });
  });
}
