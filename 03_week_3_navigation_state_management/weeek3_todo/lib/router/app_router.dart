import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/todo_page.dart';
import '../pages/stats_page.dart';
import '../pages/product_page.dart';

// Konfigurasi GoRouter dengan StatefulShellRoute untuk NavigationBar
final router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.list),
                label: 'Daftar',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart),
                label: 'Statistik',
              ),
            ],
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TodoPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductPage(),
    ),
  ],
);
