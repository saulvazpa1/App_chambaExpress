
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/estado_conexion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ChambaExpressApp());
}

class ChambaExpressApp extends StatelessWidget {
  const ChambaExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChambaExpress',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),

      builder: (context, child) {
        return EstadoConexion(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
