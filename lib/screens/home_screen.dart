import 'package:flutter/material.dart';
import 'package:RefereeIQ/screens/ask_sofia_screen.dart';
import 'package:RefereeIQ/screens/challenge_screen.dart';
import 'package:RefereeIQ/screens/shop_screen.dart';
import 'package:RefereeIQ/screens/sources_tab.dart';
import 'package:RefereeIQ/models/cart_item.dart';
import 'package:RefereeIQ/widgets/app_drawer.dart';
import 'package:RefereeIQ/widgets/cart_icon_with_badge.dart';
import 'package:RefereeIQ/services/feature_flags_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _featureService = FeatureFlagsService();
  final List<CartItem> _cart = [];

  void _addToCart(CartItem item) {
    setState(() {
      final existing = _cart.firstWhere(
        (c) => c.product['name'] == item.product['name'] && c.size == item.size,
        orElse: () {
          _cart.add(item);
          return item;
        },
      );
      if (existing != item) existing.quantity++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<bool>(
      stream: _featureService.watchChallengeEnabled(),
      builder: (context, challengeSnapshot) {
        return StreamBuilder<bool>(
          stream: _featureService.watchSourcesEnabled(),
          builder: (context, sourcesSnapshot) {
            return StreamBuilder<bool>(
              stream: _featureService.watchShopEnabled(),
              builder: (context, shopSnapshot) {
                final challengeEnabled = challengeSnapshot.data == true;
                final sourcesEnabled = sourcesSnapshot.data == true;
                final shopEnabled = shopSnapshot.data == true;

                final tabs = <Tab>[
                  const Tab(icon: Icon(Icons.chat), text: 'Ask Sofia'),
                  if (challengeEnabled)
                    const Tab(icon: Icon(Icons.flag), text: 'Challenge'),
                  if (sourcesEnabled)
                    const Tab(icon: Icon(Icons.library_books), text: 'Sources'),
                  if (shopEnabled)
                    const Tab(icon: Icon(Icons.store), text: 'Shop'),
                ];

                final hasMultipleTabs = tabs.length > 1;

                return DefaultTabController(
                  key: ValueKey('$challengeEnabled-$sourcesEnabled-$shopEnabled'),
                  length: tabs.length,
                  child: Builder(
                    builder: (tabContext) {
                      void openSourcesTab() {
                        if (!sourcesEnabled) return;
                        final controller = DefaultTabController.of(tabContext);
                        int idx = 1;
                        if (challengeEnabled) idx++;
                        controller.animateTo(idx);
                      }

                      final screens = <Widget>[
                        AskSofiaScreen(onOpenSources: openSourcesTab),
                        if (challengeEnabled) const ChallengeScreen(),
                        if (sourcesEnabled) const SourcesTab(),
                        if (shopEnabled)
                          ShopScreen(cart: _cart, onAddToCart: _addToCart),
                      ];

                      return Scaffold(
                        appBar: AppBar(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          title: Row(
                            children: [
                              Image.asset('assets/icons/app_icon.png',
                                  height: 28),
                              const SizedBox(width: 8),
                              Text(
                                'RefereeIQ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                          actions: shopEnabled
                              ? [CartIconWithBadge(cart: _cart)]
                              : null,
                          bottom: hasMultipleTabs
                              ? TabBar(tabs: tabs)
                              : null,
                        ),
                        drawer: const AppDrawer(),
                        body: hasMultipleTabs
                            ? TabBarView(children: screens)
                            : AskSofiaScreen(onOpenSources: openSourcesTab),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
