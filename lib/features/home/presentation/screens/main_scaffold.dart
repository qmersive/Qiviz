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

  // We have 5 slots in BottomNavBar, so we need 5 items in the Stack
  // Index 2 is the placeholder for the Floating Action Button
  final List<Widget> _screens = [
    const HomeScreen(),
    const DaresScreen(),
    const CreatePostScreen(), // This won't be seen via Nav, only via FAB
    const ChatListScreen(),
    const ProfileScreen(),
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
          // When clicking the plus, we can either navigate to the CreatePostScreen 
          // or just open it as a full-screen modal
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
        },
        backgroundColor: AppTheme.neonPink,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) return; // Prevent clicking the middle empty slot
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceDark,
        selectedItemColor: AppTheme.electricBlue,
        unselectedItemColor: AppTheme.textGrey,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_outlined), activeIcon: Icon(Icons.local_fire_department), label: 'Dares'),
          BottomNavigationBarItem(icon: SizedBox(height: 20), label: ''), // Empty slot for FAB
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
