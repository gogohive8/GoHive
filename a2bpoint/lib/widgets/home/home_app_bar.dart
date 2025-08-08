// widgets/home/home_app_bar.dart
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedTabIndex;
  final TabController tabController;

  const HomeAppBar({
    Key? key,
    required this.selectedTabIndex,
    required this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF9F6F2),
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabButton('Goals', 0),
          const SizedBox(width: 8),
          _buildTabButton('Events', 1),
          const SizedBox(width: 8),
          _buildTabButton('Challenge', 2),
        ],
      ),
      actions: [
        IconButton(
          icon: Image.asset('assets/images/messages_icon.png', height: 24),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () => tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(175, 203, 234, 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? const Color(0xFFAFCBEA)
                : const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}