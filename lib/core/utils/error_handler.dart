import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/router.dart';
import '../services/api_exception.dart';
import '../../features/ets/presentation/pages/login_page.dart';
import '../../features/ets/presentation/providers/auth_provider.dart';

class ErrorHandler {
  static void show(BuildContext context, Object error) {
    Color backgroundColor;
    IconData icon;
    String message;

    if (error is ApiException) {
      message = error.message;
      switch (error.type) {
        case ApiErrorType.timeout || ApiErrorType.noConnection:
          backgroundColor = Colors.orange.shade700;
          icon = Icons.wifi_off_rounded;
        case ApiErrorType.unauthorized:
          backgroundColor = Colors.red.shade700;
          icon = Icons.lock_outline_rounded;
          _handleUnauthorized();
        case ApiErrorType.serverError:
          backgroundColor = Colors.red.shade800;
          icon = Icons.dns_rounded;
        case ApiErrorType.conflict:
          backgroundColor = Colors.orange.shade800;
          icon = Icons.warning_amber_rounded;
        default:
          backgroundColor = Colors.red.shade700;
          icon = Icons.error_outline_rounded;
      }
    } else {
      message = error.toString().replaceFirst('Exception: ', '');
      backgroundColor = Colors.red.shade700;
      icon = Icons.error_outline_rounded;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: error is ApiException &&
                  error.type == ApiErrorType.noConnection
              ? SnackBarAction(
                  label: 'Reintentar',
                  textColor: Colors.white,
                  onPressed: () {},
                )
              : null,
        ),
      );
  }

  static void _handleUnauthorized() {
    Future.delayed(const Duration(seconds: 2), () {
      navigatorKey.currentContext?.read<AuthProvider>().logoutSilent();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    });
  }
}
