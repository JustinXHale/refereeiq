import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
<<<<<<< Updated upstream

import 'screens/welcome_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/sources_screen.dart';
import 'screens/sources_tab.dart';
import 'screens/challenge_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/shop_cart_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/email_signup_screen.dart';
import 'screens/ask_sofia_screen.dart';
import 'widgets/global_app_bar.dart';
import 'models/cart_item.dart';
=======
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'firebase_options.dart';
import 'package:RefereeIQ/services/auth_service.dart';
import 'package:RefereeIQ/screens/auth_gate.dart';
import 'package:RefereeIQ/screens/welcome_screen.dart';
import 'package:RefereeIQ/screens/complete_profile_screen.dart';
import 'package:RefereeIQ/screens/verify_email_screen.dart';
import 'package:RefereeIQ/screens/email_signup_screen.dart';
import 'package:RefereeIQ/screens/email_login_screen.dart';
import 'package:RefereeIQ/screens/ask_sofia_screen.dart';
import 'package:RefereeIQ/screens/challenge_screen.dart';
import 'package:RefereeIQ/screens/profile_screen.dart';
import 'package:RefereeIQ/screens/settings_screen.dart';
import 'package:RefereeIQ/widgets/global_app_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:RefereeIQ/services/notification_service.dart';


>>>>>>> Stashed changes

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
<<<<<<< Updated upstream
=======
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(NotificationService.firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();

  if (kDebugMode) {
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }
>>>>>>> Stashed changes

  runApp(const RefereeIQApp());
}

class RefereeIQApp extends StatelessWidget {
  const RefereeIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFADC44),
      brightness: Brightness.light,
      primary: const Color(0xFFFADC44),
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
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      initialRoute: '/',
      routes: {
<<<<<<< Updated upstream
        '/': (context) => const WelcomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/signup': (context) => const EmailSignUpScreen(),
        '/challenge': (context) => const ChallengeScreen(),
=======
        '/': (context)               => const AuthGate(),
        '/welcome': (context)        => const WelcomeScreen(),
        '/verify-email': (context)   => const VerifyEmailScreen(),
        '/signup': (context)         => const EmailSignUpScreen(),
        '/login': (context)          => const EmailLoginScreen(),
        '/complete-profile': (context) => const CompleteProfileScreen(),
        '/home': (context)           => const HomeScreen(),
        '/profile': (context)        => const ProfileScreen(),
        '/settings': (context)       => const SettingsScreen(),
        '/ask-sofia': (context)      => const AskSofiaScreen(),
        '/challenge': (context)      => const ChallengeScreen(),
>>>>>>> Stashed changes
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

<<<<<<< Updated upstream
class _HomeScreenState extends State<HomeScreen> {
  List<CartItem> _cart = [];

  void _addToCart(CartItem item) {
    setState(() {
      _cart.add(item);
    });
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
      AskSofiaScreen(),
      const ChallengeScreen(),
      ShopScreen(
        cart: _cart,
        onAddToCart: _addToCart,
      ),
    ];

    return DefaultTabController(
      length: _tabs.length,
      // set initialIndex to 1 so Ask Sofia is the first tab
      initialIndex: 1,
      child: Scaffold(
        appBar: GlobalAppBar(
          cartItemCount: _cart.length,
          onCartPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopCartScreen(cart: _cart),
              ),
            );
          },
        ),
        drawer: const AppDrawer(),
        body: TabBarView(
          children: _screens,
=======
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = [
    const Tab(icon: Icon(Icons.chat), text: 'Ask Sofia'),
    const Tab(icon: Icon(Icons.flag), text: 'Challenge'),
  ];

  final List<Widget> _screens = [
    const AskSofiaScreen(),
    const ChallengeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icons/app_icon.png',
              height: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'RefereeIQ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ],
>>>>>>> Stashed changes
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: Colors.black54,
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: _screens,
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
<<<<<<< Updated upstream
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            child: Center(
              child: Text(
                'RefereeIQ',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
=======
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() ?? {};
              final name     = data['name']        as String? ?? 'User';
              final role     = data['affiliation'] as String? ?? 'Referee';
              final photoUrl = data['photoURL']    as String?;
              final isNetworkImage = photoUrl != null && photoUrl.startsWith('http');

              return DrawerHeader(
                decoration: BoxDecoration(color: colorScheme.primary),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: isNetworkImage
                          ? NetworkImage(photoUrl!)
                          : null,
                      child: !isNetworkImage
                          ? const Icon(Icons.person, size: 32, color: Colors.black)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary)),
                        const SizedBox(height: 4),
                        Text(role,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colorScheme.onPrimary)),
                      ],
                    ),
                  ],
>>>>>>> Stashed changes
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Image.asset(
                  'assets/icons/app_icon.png',
                  height: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'RefereeIQ',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}