import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/splash_screen.dart';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  late final GoRouter router = GoRouter(
    refreshListenable: authService,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isInitialized = authService.isInitialized;
      final isAuthenticated = authService.isAuthenticated;
      final currentLocation = state.fullPath;

      debugPrint('Router redirect - initialized: $isInitialized, authenticated: $isAuthenticated, location: $currentLocation');

      // Si no está inicializado, mantener en splash
      if (!isInitialized && currentLocation != '/splash') {
        return '/splash';
      }

      // Si ya está inicializado
      if (isInitialized) {
        // Si está autenticado y está en login o splash, ir a welcome
        if (isAuthenticated && (currentLocation == '/login' || currentLocation == '/splash')) {
          return '/welcome';
        }
        
        // Si no está autenticado y no está en login, ir a login
        if (!isAuthenticated && currentLocation != '/login') {
          return '/login';
        }
      }

      return null; // No redirigir
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${state.error}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Reiniciar'),
            ),
          ],
        ),
      ),
    ),
  );
}