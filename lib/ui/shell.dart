import 'package:flutter/cupertino.dart';

import '../core/theme.dart';
import 'screens/channels_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_screen.dart';
import 'screens/settings_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _tabs = <Widget>[
    HomeScreen(),
    LiveScreen(),
    ChannelsScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: p.backgroundAlt.withValues(alpha: 0.98),
        activeColor: p.accent,
        inactiveColor: p.textMuted,
        border: Border(top: BorderSide(color: p.border)),
        iconSize: 23,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            activeIcon: Icon(CupertinoIcons.house_fill),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.play_circle),
            activeIcon: Icon(CupertinoIcons.play_circle_fill),
            label: 'En vivo',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.tv),
            activeIcon: Icon(CupertinoIcons.tv_fill),
            label: 'Canales',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bookmark),
            activeIcon: Icon(CupertinoIcons.bookmark_fill),
            label: 'Guardados',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            activeIcon: Icon(CupertinoIcons.settings_solid),
            label: 'Ajustes',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(builder: (_) => _tabs[index]);
      },
    );
  }
}
