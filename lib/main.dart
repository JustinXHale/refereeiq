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
import 'screens/ask_sofia_screen.dart'; // Your new Ask Sofia screen

void main() {
  runApp(RefereeIQApp());
}

class RefereeIQApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: Color(0xFFFADC44),
      brightness: Brightness.light,
      primary: Color(0xFFFADC44),
      onPrimary: Color(0xFF212121),
      secondary: Color(0xFF212121),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF212121),
      background: Colors.white,
      onBackground: Color(0xFF212121),
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
          elevation: 0, // REMOVE SHADOW / BORDER
          scrolledUnderElevation: 0, // Material 3 no border on scroll
          shadowColor: Colors.transparent, // Fully transparent
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/settings': (context) => SettingsScreen(),
        '/signup': (context) => EmailSignUpScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static List<Widget> _screens = const [
    SourcesScreen(),
    AskSofiaScreen(), // Updated to use your new tabbed screen
    ChallengeScreen(),
    ShopScreen(),
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
              textStyle: TextStyle(
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
            unselectedLabelColor: Color(0xFF555555),
            tabs: _tabs,
          ),
        ),
        drawer: AppDrawer(),
        body: TabBarView(
          children: _screens,
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
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
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}