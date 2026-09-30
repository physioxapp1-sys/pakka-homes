import 'package:flutter/widgets.dart';

import 'auth_repository.dart';

/// Makes the session reachable from any screen without threading it through
/// every constructor. Rebuilds dependents when sign-in state changes.
class AuthScope extends InheritedNotifier<AuthRepository> {
  const AuthScope({super.key, required AuthRepository auth, required super.child})
      : super(notifier: auth);

  static AuthRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope above this widget');
    return scope!.notifier!;
  }
}
