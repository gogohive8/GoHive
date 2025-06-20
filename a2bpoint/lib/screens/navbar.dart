import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const Navbar({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/home.png')),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/search.png')),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/add.png')),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/profile.png')),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/ai_mentor.png')),
          label: 'AI Mentor',
        ),
      ],
      selectedItemColor: const Color(0xFFAFCBEA), // Голубой
      unselectedItemColor: const Color(0xFF333333), // Серый
      backgroundColor: const Color(0xFFF9F6F2), // Светло-бежевый
      elevation: 5,
    );
  }
}
