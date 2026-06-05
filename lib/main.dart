import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/local_notification_service.dart';
import 'service/auth_token_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await LocalNotificationService.init();

  final hasToken = await AuthTokenService.hasToken();

  runApp(MyApp(hasToken: hasToken));
}

class MyApp extends StatelessWidget {
  final bool hasToken;

  const MyApp({super.key, required this.hasToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Winop',
      theme: AppTheme.light,
      home: hasToken ? const HomeScreen() : const EntryScreen(),
    );
  }
}
