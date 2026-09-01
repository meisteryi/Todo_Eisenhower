import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/todo_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

import 'services/notification_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  await NotificationService().init();
  await NotificationService().requestPermissions();

  final provider = TodoProvider();
  runApp(MyApp(provider: provider));
}

class MyApp extends StatelessWidget {
  final TodoProvider provider;

  const MyApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        return MaterialApp(
          title: '아이젠하워 투두',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('ko', 'KR'),
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode:
              ThemeMode.system, // Automatic Dark/Light based on system settings
          home: HomeScreen(provider: provider),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
