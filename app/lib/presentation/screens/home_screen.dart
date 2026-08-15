import 'package:flutter/material.dart';
import 'package:smart_landmarks2/core/theme/app_theme.dart';
import 'package:smart_landmarks2/presentation/screens/activity/activity_screen.dart';
import 'package:smart_landmarks2/presentation/screens/add/add_landmark_screen.dart';
import 'package:smart_landmarks2/presentation/screens/landmarks/landmarks_screen.dart';
import 'package:smart_landmarks2/presentation/screens/map/map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    MapScreen(),
    LandmarksScreen(),
    ActivityScreen(),
    AddLandmarkScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: _screens),
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: AppColors.surface,
            elevation: 0,
            animationDuration: const Duration(milliseconds: 300),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.format_list_bulleted_rounded),
                selectedIcon: Icon(Icons.format_list_bulleted_rounded),
                label: 'List',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'Trips',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline_rounded),
                selectedIcon: Icon(Icons.add_circle_rounded),
                label: 'Add',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
