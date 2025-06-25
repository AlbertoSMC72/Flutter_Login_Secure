import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

/// Widget que detecta la actividad del usuario y notifica al AuthService
class ActivityDetector extends StatelessWidget {
  final Widget child;

  const ActivityDetector({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Detecta eventos de puntero (toques, movimientos, etc.)
      onPointerDown: (_) => _registerActivity(context),
      onPointerMove: (_) => _registerActivity(context),
      onPointerUp: (_) => _registerActivity(context),
      onPointerCancel: (_) => _registerActivity(context),
      onPointerSignal: (_) => _registerActivity(context),
      
      // El child se renderiza normalmente
      child: child,
    );
  }

  void _registerActivity(BuildContext context) {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isAuthenticated) {
        authService.registerActivity();
      }
    } catch (e) {
      debugPrint('Error registrando actividad: $e');
    }
  }
}