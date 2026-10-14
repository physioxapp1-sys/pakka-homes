import 'package:flutter/material.dart';

import 'data/auth_repository.dart';
import 'data/auth_scope.dart';
import 'data/cart.dart';
import 'data/service_cart.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthRepository();
  final cart = Cart();
  final serviceCart = ServiceCart();
  // All three restore from the device. Browsing needs none of them, so a
  // failure in any must not block startup - each swallows its own errors.
  await auth.restore();
  await cart.restore();
  await serviceCart.restore();

  runApp(PakkaHomesApp(auth: auth, cart: cart, serviceCart: serviceCart));
}

class PakkaHomesApp extends StatelessWidget {
  const PakkaHomesApp({
    super.key,
    required this.auth,
    required this.cart,
    required this.serviceCart,
  });

  final AuthRepository auth;

  /// Groceries, and services. Separate because a basket of tomatoes becomes an
  /// order with a delivery slot, and a list of services becomes one booking.
  final Cart cart;
  final ServiceCart serviceCart;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: auth,
      child: CartScope(
        cart: cart,
        child: ServiceCartScope(
          cart: serviceCart,
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
      ),
    );
  }
}
