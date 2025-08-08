import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffoldSimple extends StatelessWidget {
  final Widget child;

  const MainScaffoldSimple({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNavigationSimple(),
    );
  }
}

class MainBottomNavigationSimple extends StatelessWidget {
  const MainBottomNavigationSimple({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    
    int getCurrentIndex() {
      if (currentLocation.startsWith('/home')) return 0;
      if (currentLocation.startsWith('/all-trips')) return 1;
      if (currentLocation.startsWith('/expenses')) return 2;
      if (currentLocation.startsWith('/settings')) return 3;
      return 0;
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: getCurrentIndex(),
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2196F3), // Blue
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_travel_outlined),
          activeIcon: Icon(Icons.card_travel),
          label: 'All Trips',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Expenses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/all-trips');
            break;
          case 2:
            context.go('/expenses');
            break;
          case 3:
            context.go('/settings');
            break;
        }
      },
    );
  }
}
