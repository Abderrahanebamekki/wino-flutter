import 'package:flutter/material.dart';

import 'package:winop/screens/home_screen.dart';
import 'package:winop/screens/local_notification_service.dart';

import 'package:winop/service/auth_token_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationService.init();

  // TEST JWT TOKEN
  await AuthTokenService.saveToken(
    'eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjpbIlJPTEVfVVNFUiJdLCJzdWIiOiJhYmRlcnJhaG1hbmUuYmFtZWtraUB1bml2LWNvbnN0YW50aW5lMi5keiIsImlhdCI6MTc3ODU3ODk1OSwiZXhwIjoxNzg2MzU0OTU5fQ.6d-0NScwewuYAH6LvQgF6DYahvk4hsUOZTbGEzh-si4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Winop',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),

      home: const HomeScreen(),
    );
  }
}