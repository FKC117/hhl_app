import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/shell/app_shell_screen.dart';

class AppRoutes {
  static const login = '/';
  static const shell = '/home';

  const AppRoutes._();
}

class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.shell: (_) => const AppShellScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case AppRoutes.shell:
        return MaterialPageRoute<void>(
          builder: (_) => const AppShellScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
    }
  }

  const AppRouter._();
}
