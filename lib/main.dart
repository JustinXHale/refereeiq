import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
import 'package:RefereeIQ/screens/leaderboard_tab.dart';
import 'package:RefereeIQ/screens/profile_screen.dart';
import 'package:RefereeIQ/screens/settings_screen.dart';
import 'package:RefereeIQ/widgets/global_app_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ⚠️ Only for local/debug builds: disable the Android reCAPTCHA/SafetyNet check
  if (kDebugMode) {
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

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
        '/leaderboard': (context)    => const LeaderboardTab(),
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
  static const List<Tab> _tabs = [
    Tab(icon: Icon(Icons.chat), text: 'Ask Sofia'),
    Tab(icon: Icon(Icons.flag), text: 'Challenge'),
    Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const AskSofiaScreen(),
      const ChallengeScreen(),
      const LeaderboardTab(),
    ];

    return DefaultTabController(
      length: _tabs.length,
      initialIndex: 0,
      child: Scaffold(
        appBar: GlobalAppBar(),
        drawer: const AppDrawer(),
        body: TabBarView(children: _screens),
        bottomNavigationBar: Material(
          color: Theme.of(context).colorScheme.primary,
          child: TabBar(
            tabs: _tabs,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Colors.black54,
          ),
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
            decoration: BoxDecoration(color: colorScheme.primary),
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
            onTap: () async {
              await AuthService().signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
            },
          ),
        ],
      ),
    );
  }
}
