import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/error_handler.dart';
import 'api_exception.dart';

class LauncherService {
  // ── Ruta desde ubicación actual hasta ESCOM IPN Zacatenco ─────────────────

  static Future<void> openSalonRoute(
    BuildContext context,
    String salon,
  ) async {
    const double escomLat = 19.50435;
    const double escomLon = -99.14670;

    try {
      // Verificar si el servicio de ubicación está activo
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ErrorHandler.show(
            context,
            const ApiException(
              message: 'Activa el GPS de tu dispositivo para ver la ruta',
              type: ApiErrorType.unknown,
            ),
          );
        }
        return;
      }

      // Verificar y pedir permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ErrorHandler.show(
              context,
              const ApiException(
                message:
                    'Permiso de ubicación denegado. Actívalo en Ajustes del sistema',
                type: ApiErrorType.unknown,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.location_off,
                    color: Theme.of(ctx).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  const Text('Permiso requerido'),
                ],
              ),
              content: const Text(
                'El permiso de ubicación fue denegado permanentemente. '
                'Para ver la ruta ve a:\n\n'
                'Ajustes → Apps → MOVIDA → Permisos → Ubicación → Permitir',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Geolocator.openAppSettings();
                  },
                  child: const Text('Ir a Ajustes'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // SnackBar de progreso
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Obteniendo tu ubicación...'),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      // Obtener posición con timeout manual
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));

      final double userLat = position.latitude;
      final double userLon = position.longitude;

      // URL de OpenStreetMap con ruta OSRM
      final url = Uri.parse(
        'https://www.openstreetmap.org/directions'
        '?engine=fossgis_osrm_car'
        '&route=$userLat,$userLon;$escomLat,$escomLon'
        '#map=15/$escomLat/$escomLon',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: solo el mapa con pin en ESCOM
        final fallbackUrl = Uri.parse(
          'https://www.openstreetmap.org/'
          '?mlat=$escomLat&mlon=$escomLon&zoom=17',
        );
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } on TimeoutException {
      if (context.mounted) {
        ErrorHandler.show(
          context,
          const ApiException(
            message:
                'No se pudo obtener tu ubicación. Verifica que el GPS esté activo',
            type: ApiErrorType.timeout,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.show(context, e);
      }
    }
  }

  // ── Correo de soporte ──────────────────────────────────────────────────────

  static Future<void> openSupport({
    String subject = 'Soporte MOVIDA ETS ESCOM',
    String body = '',
  }) async {
    // Usar encodeComponent para que los espacios sean %20 y no +
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final url = Uri.parse(
      'mailto:cosmesantamariaosvaldo@gmail.com'
      '?subject=$encodedSubject'
      '&body=$encodedBody',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw const ApiException(
        message:
            'No se pudo abrir el correo. Escríbenos a: cosmesantamariaosvaldo@gmail.com',
        type: ApiErrorType.unknown,
      );
    }
  }

  // ── Obtener ubicación actual (centraliza la lógica de permisos GPS) ──────

  static Future<Position?> getCurrentLocation(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ErrorHandler.show(
          context,
          const ApiException(
            message: 'Activa el GPS de tu dispositivo para ver la ruta',
            type: ApiErrorType.unknown,
          ),
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ErrorHandler.show(
            context,
            const ApiException(
              message:
                  'Permiso de ubicación denegado. Actívalo en Ajustes del sistema',
              type: ApiErrorType.unknown,
            ),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                const SizedBox(width: 8),
                const Text('Permiso requerido'),
              ],
            ),
            content: const Text(
              'El permiso fue denegado permanentemente.\n\n'
              'Ve a: Ajustes → Apps → MOVIDA → Permisos → Ubicación → Permitir',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Geolocator.openAppSettings();
                },
                child: const Text('Ir a Ajustes'),
              ),
            ],
          ),
        );
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      if (context.mounted) {
        ErrorHandler.show(
          context,
          const ApiException(
            message:
                'No se pudo obtener tu ubicación. Verifica que el GPS esté activo',
            type: ApiErrorType.timeout,
          ),
        );
      }
      return null;
    }
  }

  // ── Mapa con pin en ESCOM (ajustes) ───────────────────────────────────────

  static Future<void> openEscomMap() async {
    final url = Uri.parse(
      'https://www.openstreetmap.org/?mlat=19.50435&mlon=-99.14670&zoom=17',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
