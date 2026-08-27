import 'package:flutter/material.dart';
import 'providers/todo_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

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
