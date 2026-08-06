import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../planner/outfit_planner_screen.dart';
import '../profile/profile_screen.dart';
import '../wardrobe/wardrobe_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _changePage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onOpenWardrobe: () {
          _changePage(1);
        },
      ),
      const WardrobeScreen(),
      const OutfitPlannerScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _changePage,

        height: 72,
        elevation: 8,

        backgroundColor: Theme.of(context).colorScheme.surface,

        indicatorColor: Theme.of(context).colorScheme.primaryContainer,

        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.home,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: "Ana Sayfa",
          ),

          NavigationDestination(
            icon: Icon(
              Icons.checkroom_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.checkroom,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: "Gardırobum",
          ),

          NavigationDestination(
            icon: Icon(
              Icons.calendar_month_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.calendar_month,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: "Planlayıcı",
          ),

          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}
