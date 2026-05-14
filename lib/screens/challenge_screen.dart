// Fixed version of challenge_screen.dart
import 'package:flutter/material.dart';
import 'package:RefereeIQ/screens/daily_challenge_tab.dart';
import 'package:RefereeIQ/screens/leaderboard_tab.dart';
import 'package:RefereeIQ/screens/history_tab.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(text: 'Daily Challenge'),
    Tab(text: 'Leaderboard'),
    Tab(text: 'History'),
  ];

  final List<Widget> _screens = const [
    DailyChallengeTab(),
    LeaderboardTab(),
    HistoryTab(),
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
      body: Column(
        children: [
          Container(
            color: colorScheme.primary,
            child: TabBar(
              controller: _tabController,
              tabs: _tabs,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
