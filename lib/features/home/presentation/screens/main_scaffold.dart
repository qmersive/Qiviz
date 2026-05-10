import 'package:flutter/material.dart';
import 'package:qiviz/features/home/presentation/screens/home_screen.dart';
import 'package:qiviz/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:qiviz/features/dares/presentation/screens/dares_screen.dart';
import 'package:qiviz/features/profile/presentation/screens/profile_screen.dart';
import 'package:qiviz/features/dares/presentation/screens/create_post_screen.dart';
import 'package:qiviz/core/theme/app_theme.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // CRITICAL: This list MUST have exactly 5 items to match the BottomNavigationBar
  final List<Widget> _screens = [
    const HomeScreen(),        // Index 0
    const DaresScreen(),       // Index 1
    const CreatePostScreen(),  // Index 2 (Placeholder/FAB target)
    const ChatListScreen(),    // Index 3
    const ProfileScreen(),     // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open the upload screen as a full-screen modal
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
        },
        backgroundColor: AppTheme.neonPink,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // If user clicks the middle slot (index 2), we ignore it because the FAB handles it
          if (index == 2) return; 
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceDark,
        selectedItemColor: AppTheme.electricBlue,
        unselectedItemColor: AppTheme.textGrey,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_outlined), activeIcon: Icon(Icons.local_fire_department), label: 'Dares'),
          BottomNavigationBarItem(icon: SizedBox(height: 20), label: ''), // SLOT 2: SPACE FOR FAB
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
