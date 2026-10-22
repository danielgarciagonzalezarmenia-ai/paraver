import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'data/local_store.dart';
import 'state/app_state.dart';
import 'ui/shell.dart';

class ParaVerApp extends StatefulWidget {
  const ParaVerApp({super.key, required this.state});

  final AppState state;

  @override
  State<ParaVerApp> createState() => _ParaVerAppState();
}

class _ParaVerAppState extends State<ParaVerApp> with WidgetsBindingObserver {
  late Brightness _systemBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {
      _systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final choice = widget.state.themeChoice;
        final isDark = switch (choice) {
          ThemeChoice.dark => true,
          ThemeChoice.light => false,
          ThemeChoice.system => _systemBrightness == Brightness.dark,
        };
        final palette = isDark ? Palette.dark : Palette.light;
        return AppScope(
          state: widget.state,
          child: PaletteScope(
            palette: palette,
            child: CupertinoApp(
              title: 'ParaVer',
              debugShowCheckedModeBanner: false,
              theme: ParaVerTheme.cupertino(palette),
              locale: const Locale('es', 'CO'),
              supportedLocales: const [
                Locale('es', 'CO'),
                Locale('es'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                GlobalCupertinoLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              home: const AppShell(),
            ),
          ),
        );
      },
    );
  }
}
