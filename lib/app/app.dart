import 'package:flutter/material.dart';

import '../core/session/app_session.dart';
import '../core/session/app_session_scope.dart';
import '../features/auth/login_screen.dart';
import '../features/shell/app_shell_screen.dart';
import 'router.dart';
import 'theme.dart';

class HhlApp extends StatefulWidget {
  const HhlApp({super.key});

  @override
  State<HhlApp> createState() => _HhlAppState();
}

class _HhlAppState extends State<HhlApp> {
  final AppSession _session = AppSession();
  late final Future<void> _restoreFuture;

  @override
  void initState() {
    super.initState();
    _restoreFuture = _session.restore();
  }

  @override
  Widget build(BuildContext context) {
    return AppSessionScope(
      session: _session,
      child: FutureBuilder<void>(
        future: _restoreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return MaterialApp(
              title: 'HHL Care',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              home: const _LaunchScreen(),
            );
          }

          return MaterialApp(
            title: 'HHL Care',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: _session.isAuthenticated
                ? const AppShellScreen()
                : const LoginScreen(),
            routes: AppRouter.routes,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
