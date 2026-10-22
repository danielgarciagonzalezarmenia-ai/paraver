import 'package:flutter/cupertino.dart';

import '../models/playback_target.dart';
import 'screens/player_screen.dart';

Future<void> openPlayer(BuildContext context, PlaybackTarget target) {
  if (target.sources.isEmpty) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sin señal disponible'),
        content: const Text(
          'Este contenido no tiene una fuente reproducible en este momento.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    return Future.value();
  }
  return Navigator.of(context).push(
    CupertinoPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PlayerScreen(target: target),
    ),
  );
}
