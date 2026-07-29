import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../planner/outfit_planner_screen.dart';
import '../profile/profile_screen.dart';
import '../wardrobe/wardrobe_statistics_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    OutfitPlannerScreen(),
    WardrobeStatisticsScreen(),
    ProfileScreen(),
  ];

  void _changePage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
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
              Icons.bar_chart_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.bar_chart,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: "İstatistik",
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
