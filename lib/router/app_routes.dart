import 'package:flutter/material.dart';

import 'package:RefereeIQ/screens/welcome_screen.dart';
import 'package:RefereeIQ/screens/email_signup_screen.dart';
import 'package:RefereeIQ/screens/email_login_screen.dart';
import 'package:RefereeIQ/screens/verify_email_screen.dart';
import 'package:RefereeIQ/screens/complete_profile_screen.dart';
import 'package:RefereeIQ/screens/home_screen.dart';
import 'package:RefereeIQ/screens/profile_screen.dart';
import 'package:RefereeIQ/screens/settings_screen.dart';
import 'package:RefereeIQ/screens/ask_sofia_screen.dart';
import 'package:RefereeIQ/screens/challenge_screen.dart';
import 'package:RefereeIQ/screens/query_history_screen.dart';
import 'package:RefereeIQ/screens/shop_cart_screen.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const WelcomeScreen(),
    '/welcome': (context) => const WelcomeScreen(),
    '/signup': (context) => const EmailSignUpScreen(),
    '/login': (context) => const EmailLoginScreen(),
    '/verify-email': (context) => const VerifyEmailScreen(),
    '/complete-profile': (context) => const CompleteProfileScreen(),
    '/home': (context) => const HomeScreen(),
    '/profile': (context) => const ProfileScreen(),
    '/settings': (context) => const SettingsScreen(),
    '/ask-sofia': (context) => const AskSofiaScreen(),
    '/challenge': (context) => const ChallengeScreen(),
    '/query-history': (context) => const QueryHistoryScreen(),
    '/shop-cart': (context) => ShopCartScreen(cart: const []),
  };
}
