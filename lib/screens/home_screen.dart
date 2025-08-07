import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RefereeIQ/screens/ask_sofia_screen.dart';
import 'package:RefereeIQ/screens/challenge_screen.dart';
import 'package:RefereeIQ/widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

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
            Image.asset('assets/icons/app_icon.png', height: 28),
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
