import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/local_notification_service.dart';
import 'service/auth_token_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await LocalNotificationService.init();

  await AuthTokenService.saveToken(
'eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjpbIlJPTEVfVVNFUiJdLCJzdWIiOiJhYmRlcnJhaG1hbmUuYmFtZWtraUB1bml2LWNvbnN0YW50aW5lMi5keiIsImlhdCI6MTc4MDM0NTU2MCwiZXhwIjoxNzg4MTIxNTYwfQ.hKIJ8bNJyMaoOkrdjykWsI9l4XFK-5cNG_hyiVuQU0g'  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Winop',
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
