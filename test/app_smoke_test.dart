import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:paraver/app.dart';
import 'package:paraver/data/dlive_client.dart';
import 'package:paraver/data/local_store.dart';
import 'package:paraver/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the five main tabs with an empty cache', (tester) async {
    await initializeDateFormatting('es');
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();
    final state = AppState(store: store, client: DliveClient());
    await state.bootstrap();

    await tester.pumpWidget(ParaVerApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('En vivo'), findsOneWidget);
    expect(find.text('Canales'), findsOneWidget);
    expect(find.text('Guardados'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
