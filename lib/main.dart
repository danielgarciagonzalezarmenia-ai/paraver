import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/dlive_client.dart';
import 'data/local_store.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final store = await LocalStore.create();
  final state = AppState(store: store, client: DliveClient());
  await state.bootstrap();
  runApp(ParaVerApp(state: state));
  unawaited(state.refreshIfNeeded());
}
