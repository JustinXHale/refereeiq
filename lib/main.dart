// main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/welcome_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/sources_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/email_signup_screen.dart';
import 'screens/ask_sofia_screen.dart';

void main() {
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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final List<Widget> _screens = [
    const SourcesScreen(),
    AskSofiaScreen(), // NO CONST — stateful widget!
    const ChallengeScreen(),
    const ShopScreen(),
  ];

  static const List<Tab> _tabs = [
    Tab(icon: Icon(Icons.menu_book), text: 'Sources'),
    Tab(icon: Icon(Icons.chat), text: 'Ask Sofia'),
    Tab(icon: Icon(Icons.flag), text: 'Challenge'),
    Tab(icon: Icon(Icons.shopping_cart), text: 'Shop'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'RefereeIQ',
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: colorScheme.onPrimary,
            labelColor: colorScheme.onPrimary,
            unselectedLabelColor: const Color(0xFF555555),
            tabs: _tabs,
          ),
        ),
        drawer: const AppDrawer(),
        body: TabBarView(
          children: _screens,
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
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
                ),
              ),
            ),
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
        ],
      ),
    );
  }
}
