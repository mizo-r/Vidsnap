import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vidsnap/features/downloads/downloads_screen.dart';
import 'package:vidsnap/features/history/history_screen.dart';
import 'package:vidsnap/features/home/home_screen.dart';
import 'package:vidsnap/features/settings/settings_screen.dart';
import 'package:vidsnap/features/whatsapp/whatsapp_status_screen.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';

/// Builds the GoRouter with bottom-nav shell.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/whatsapp',
            name: 'whatsapp',
            builder: (context, state) => const WhatsAppStatusScreen(),
          ),
          GoRoute(
            path: '/downloads',
            name: 'downloads',
            builder: (context, state) => const DownloadsScreen(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

class _ScaffoldWithNav extends StatelessWidget {
  const _ScaffoldWithNav({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_pathForIndex(i)),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l10n.navWhatsApp,
          ),
          NavigationDestination(
            icon: const Icon(Icons.download_outlined),
            selectedIcon: const Icon(Icons.download),
            label: l10n.navDownloads,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/whatsapp')) return 1;
    if (location.startsWith('/downloads')) return 2;
    if (location.startsWith('/history')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  String _pathForIndex(int i) {
    switch (i) {
      case 1:
        return '/whatsapp';
      case 2:
        return '/downloads';
      case 3:
        return '/history';
      case 4:
        return '/settings';
      default:
        return '/home';
    }
  }
}
