import 'package:flutter/material.dart';

import 'data/auth_repository.dart';
import 'data/auth_scope.dart';
import 'data/cart.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthRepository();
  final cart = Cart();
  // Both restore from the device. Browsing needs neither, so a failure in
  // either must not block startup - each swallows its own errors.
  await auth.restore();
  await cart.restore();

  runApp(PakkaHomesApp(auth: auth, cart: cart));
}

class PakkaHomesApp extends StatelessWidget {
  const PakkaHomesApp({super.key, required this.auth, required this.cart});

  final AuthRepository auth;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: auth,
      child: CartScope(
        cart: cart,
        child: MaterialApp(
          title: 'Pakka Homes',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: AppColors.green,
            scaffoldBackgroundColor: AppColors.background,
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
