import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitdine2_flutter/services/auth_provider.dart';
import 'package:splitdine2_flutter/services/session_provider.dart';
import 'package:splitdine2_flutter/screens/splash_screen.dart';
import 'package:splitdine2_flutter/config/app_config.dart';

void main() {
  // Print configuration on app start
  AppConfig.printConfig();
  runApp(const SplitDineApp());
}

class SplitDineApp extends StatelessWidget {
  const SplitDineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => SessionProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: AppConfig.isDebugMode,
      ),
    );
  }
}


