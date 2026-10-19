import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/services/role_manager.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/error_screen.dart'; // Écran d'erreur

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await RoleManager.initializeDefaultAdmin(); // Assurez-vous que l'admin par défaut est créé
  } catch (e) {
    runApp(const ErrorScreen()); // En cas d'erreur, montre l'écran d'erreur
    return;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COVID-19 Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}