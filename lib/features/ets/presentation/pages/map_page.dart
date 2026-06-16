import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.salonNombre,
    required this.userLat,
    required this.userLon,
  });

  final String salonNombre;
  final double userLat;
  final double userLon;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;

  static const double _escomLat = 19.50435;
  static const double _escomLon = -99.14670;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse(
      'https://www.openstreetmap.org/directions'
      '?engine=fossgis_osrm_foot'
      '&route=${widget.userLat},${widget.userLon};$_escomLat,$_escomLon'
      '#map=15/$_escomLat/$_escomLon',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _calcularDistancia(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final d = r * c;
    return d < 1
        ? '${(d * 1000).toStringAsFixed(0)} m de distancia'
        : '${d.toStringAsFixed(1)} km de distancia';
  }

  double _toRad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cómo llegar — ${widget.salonNombre}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Abrir en OpenStreetMap',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Mapa principal ─────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                (widget.userLat + _escomLat) / 2,
                (widget.userLon + _escomLon) / 2,
              ),
              initialZoom: 13,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dispositivos_moviles',
                maxZoom: 18,
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      LatLng(widget.userLat, widget.userLon),
                      LatLng(_escomLat, _escomLon),
                    ],
                    strokeWidth: 3.0,
                    color: cs.primary.withValues(alpha: 0.7),
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // ── Pin del alumno ──────────────────────────────────────
                  Marker(
                    point: LatLng(widget.userLat, widget.userLon),
                    width: 44,
                    height: 44,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (ctx, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  // ── Pin de ESCOM ────────────────────────────────────────
                  Marker(
                    point: LatLng(_escomLat, _escomLon),
                    width: 44,
                    height: 58,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (ctx, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(12, 8),
                            painter: _TrianglePainter(
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Card inferior con información ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<Offset>(
              tween: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (ctx, offset, child) => FractionalTranslation(
                translation: offset,
                child: child,
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.straighten_rounded,
                          color: cs.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _calcularDistancia(
                            widget.userLat,
                            widget.userLon,
                            _escomLat,
                            _escomLon,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Distancia aprox.',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ESCOM IPN — ${widget.salonNombre}\n'
                            'Av. Juan de Dios Bátiz, '
                            'Gustavo A. Madero, CDMX',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mapa: © OpenStreetMap contributors',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Botón centrar mapa ─────────────────────────────────────────────
          Positioned(
            bottom: 180,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'center_map',
              onPressed: () {
                _mapController.move(
                  LatLng(
                    (widget.userLat + _escomLat) / 2,
                    (widget.userLon + _escomLon) / 2,
                  ),
                  13,
                );
              },
              tooltip: 'Centrar mapa',
              child: const Icon(Icons.center_focus_strong_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
