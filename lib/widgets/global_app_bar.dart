// lib/widgets/global_app_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlobalAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
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
        tabs: const [
          Tab(icon: Icon(Icons.chat), text: 'Ask Sofia'),
          Tab(icon: Icon(Icons.flag), text: 'Challenge'),
          Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
