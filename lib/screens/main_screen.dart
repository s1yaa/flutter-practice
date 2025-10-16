import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'mentees_screen.dart';
import 'my_mentors_screen.dart';
import 'profile_screen.dart';
import 'requests_screen.dart';
import 'search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isMentor = authProvider.userProfile?.role == 'mentor';

    final List<Widget> screens = isMentor
        ? [
            HomeScreen(onTabChange: _changeTab),
            const MenteesScreen(),
            const RequestsScreen(),
            const ProfileScreen(),
          ]
        : [
            HomeScreen(onTabChange: _changeTab),
            const SearchScreen(),
            const MyMentorsScreen(),
            const ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = isMentor
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Mentees'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Mentors'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ];


    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _changeTab,
        items: navItems,
      ),
    );
  }
}