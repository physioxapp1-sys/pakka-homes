import 'package:flutter/material.dart';

import 'data/auth_repository.dart';
import 'data/auth_scope.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthRepository();
  // Restores a previous session if there is one. Browsing never needs it, so
  // a failure here must not block startup.
  await auth.restore();
  runApp(PakkaHomesApp(auth: auth));
}

class PakkaHomesApp extends StatelessWidget {
  const PakkaHomesApp({super.key, required this.auth});

  final AuthRepository auth;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: auth,
      child: MaterialApp(
        title: 'Pakka Homes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: AppColors.orange,
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
