import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:RefereeIQ/widgets/cart_icon_with_badge.dart';
import 'package:RefereeIQ/models/cart_item.dart';

// Minimal router stub to absorb Navigator.push from the badge tap
class _FakeRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(body: Text('Cart')),
    );
  }
}

Widget _wrap(Widget child) => MaterialApp(
      onGenerateRoute: _FakeRoutes.onGenerateRoute,
      home: Scaffold(appBar: AppBar(actions: [child])),
    );

CartItem _makeItem({int quantity = 1}) => CartItem(
      product: {'name': 'Rugby Ball', 'price': 10.0},
      size: 'M',
      quantity: quantity,
    );

void main() {
  group('CartIconWithBadge', () {
    testWidgets(
        'Given empty cart, '
        'When rendered, '
        'Then shopping cart icon shown and no badge text', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap(CartIconWithBadge(cart: const [])));

      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      expect(find.text('1'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets(
        'Given cart with 1 item quantity 3, '
        'When rendered, '
        'Then badge shows "3"', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cart = [_makeItem(quantity: 3)];
      await tester.pumpWidget(_wrap(CartIconWithBadge(cart: cart)));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets(
        'Given cart with two items totaling 9, '
        'When rendered, '
        'Then badge shows "9"', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cart = [_makeItem(quantity: 5), _makeItem(quantity: 4)];
      await tester.pumpWidget(_wrap(CartIconWithBadge(cart: cart)));

      expect(find.text('9'), findsOneWidget);
    });

    testWidgets(
        'Given cart with 11 total items, '
        'When rendered, '
        'Then badge shows "9+" (capped display)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cart = [_makeItem(quantity: 11)];
      await tester.pumpWidget(_wrap(CartIconWithBadge(cart: cart)));

      expect(find.text('9+'), findsOneWidget);
      expect(find.text('11'), findsNothing);
    });

    testWidgets(
        'Given cart icon tapped, '
        'When tapped, '
        'Then navigates to cart screen', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cart = [_makeItem(quantity: 1)];
      await tester.pumpWidget(_wrap(CartIconWithBadge(cart: cart)));

      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();

      expect(find.text('Your Cart'), findsOneWidget);
    });
  });
}
