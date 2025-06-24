// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/welcome_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/sources_screen.dart';
import 'screens/sources_tab.dart';
import 'screens/challenge_screen.dart';
import 'screens/leaderboard_tab.dart';
import 'screens/shop_screen.dart';
import 'screens/shop_cart_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/email_signup_screen.dart';
import 'screens/ask_sofia_screen.dart';
import 'models/cart_item.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const RefereeIQApp());
}

class RefereeIQApp extends StatelessWidget {
  const RefereeIQApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Updated brand yellow to #FBD823
    final Color brandYellow = const Color(0xFFFBD823);
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: brandYellow,
      brightness: Brightness.light,
      primary: brandYellow,
      onPrimary: const Color(0xFF212121),
      secondary: const Color(0xFF212121),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF212121),
      background: Colors.white,
      onBackground: const Color(0xFF212121),
      error: Colors.red,
      onError: Colors.white,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RefereeIQ',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.background,
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/signup': (context) => const EmailSignUpScreen(),
        '/challenge': (context) => const ChallengeScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CartItem> _cart = [];

  void _addToCart(CartItem item) {
    setState(() => _cart.add(item));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to cart!')),
    );
  }

  static const List<Tab> _tabs = [
    Tab(icon: Icon(Icons.menu_book), text: 'Sources'),
    Tab(icon: Icon(Icons.chat), text: 'Ask Sofia'),
    Tab(icon: Icon(Icons.flag), text: 'Challenge'),
    Tab(icon: Icon(Icons.shopping_cart), text: 'Shop'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Widget> _screens = [
      const SourcesTab(),
      const AskSofiaScreen(),
      const ChallengeScreen(),
      ShopScreen(cart: _cart, onAddToCart: _addToCart),
    ];

    return DefaultTabController(
      length: _tabs.length,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/app_icon.png',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 8),
              Text(
                'RefereeIQ',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopCartScreen(cart: _cart),
                      ),
                    );
                  },
                ),
                if (_cart.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_cart.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: TabBarView(children: _screens),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Row(
              children: [
                Image.asset('assets/icons/app_icon.png', width: 40, height: 40),
                const SizedBox(width: 12),
                Text(
                  'RefereeIQ',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
          ),
        ],
      ),
    );
  }
}
