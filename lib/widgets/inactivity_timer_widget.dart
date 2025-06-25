import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

/// Widget que muestra el tiempo restante hasta el logout automático
class InactivityTimerWidget extends StatefulWidget {
  final bool showWarning;
  final int warningThresholdMinutes;

  const InactivityTimerWidget({
    Key? key,
    this.showWarning = true,
    this.warningThresholdMinutes = 1,
  }) : super(key: key);

  @override
  State<InactivityTimerWidget> createState() => _InactivityTimerWidgetState();
}

class _InactivityTimerWidgetState extends State<InactivityTimerWidget> {
  Timer? _displayTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startDisplayTimer();
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    super.dispose();
  }

  void _startDisplayTimer() {
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _timeRemaining = authService.timeUntilLogout;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (!authService.isAuthenticated) {
          return const SizedBox.shrink();
        }

        final shouldShowWarning = widget.showWarning && 
            _timeRemaining.inMinutes < widget.warningThresholdMinutes &&
            _timeRemaining.inSeconds > 0;

        if (!shouldShowWarning && !_shouldAlwaysShow()) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getBorderColor(),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(),
                size: 16,
                color: _getTextColor(),
              ),
              const SizedBox(width: 6),
              Text(
                _getDisplayText(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _shouldAlwaysShow() {
    // Mostrar siempre en modo debug o si quieres que sea visible
    return false; // Cambiar a true si quieres que siempre sea visible
  }

  Color _getBackgroundColor() {
    if (_timeRemaining.inMinutes < 1 && _timeRemaining.inSeconds > 0) {
      return Colors.red[100]!;
    } else if (_timeRemaining.inMinutes < 2) {
      return Colors.orange[100]!;
    } else {
      return Colors.blue[100]!;
    }
  }

  Color _getBorderColor() {
    if (_timeRemaining.inMinutes < 1 && _timeRemaining.inSeconds > 0) {
      return Colors.red[300]!;
    } else if (_timeRemaining.inMinutes < 2) {
      return Colors.orange[300]!;
    } else {
      return Colors.blue[300]!;
    }
  }

  Color _getTextColor() {
    if (_timeRemaining.inMinutes < 1 && _timeRemaining.inSeconds > 0) {
      return Colors.red[700]!;
    } else if (_timeRemaining.inMinutes < 2) {
      return Colors.orange[700]!;
    } else {
      return Colors.blue[700]!;
    }
  }

  IconData _getIcon() {
    if (_timeRemaining.inMinutes < 1 && _timeRemaining.inSeconds > 0) {
      return Icons.warning_rounded;
    } else if (_timeRemaining.inMinutes < 2) {
      return Icons.access_time_rounded;
    } else {
      return Icons.timer_outlined;
    }
  }

  String _getDisplayText() {
    final minutes = _timeRemaining.inMinutes;
    final seconds = _timeRemaining.inSeconds % 60;
    
    if (_timeRemaining.inSeconds <= 0) {
      return 'Sesión expirada';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}