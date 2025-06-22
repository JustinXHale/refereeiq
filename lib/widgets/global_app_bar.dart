// lib/widgets/global_app_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/cart_icon_with_badge.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int cartItemCount;
  final VoidCallback onCartPressed;

  const GlobalAppBar({
    super.key,
    required this.cartItemCount,
    required this.onCartPressed,
  });

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
      actions: [
        IconButton(
          icon: CartIconWithBadge(
            itemCount: cartItemCount,
            onPressed: onCartPressed,
          ),
          onPressed: onCartPressed,
        ),
      ],
      bottom: TabBar(
        isScrollable: false,
        indicatorColor: colorScheme.onPrimary,
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: const Color(0xFF555555),
        tabs: const [
          Tab(icon: Icon(Icons.menu_book), text: 'Sources'),
          Tab(icon: Icon(Icons.chat), text: 'Ask Sofia'),
          Tab(icon: Icon(Icons.flag), text: 'Challenge'),
          Tab(icon: Icon(Icons.shopping_cart), text: 'Shop'),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}
