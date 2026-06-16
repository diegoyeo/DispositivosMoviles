import 'package:flutter/material.dart';

import '../data/map_zones_data.dart';
import '../models/map_zone_model.dart';
import '../widgets/map_zone_widget.dart';

class CampusMapPage extends StatefulWidget {
  const CampusMapPage({super.key});

  @override
  State<CampusMapPage> createState() => _CampusMapPageState();
}

class _CampusMapPageState extends State<CampusMapPage> {
  final TransformationController _transformController =
      TransformationController();

  static const double _mapAspectRatio = 16 / 9;

  void _onZoneTapped(MapZone zone) {
    _showZoneInfo(zone);
  }

  void _showZoneInfo(MapZone zone) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(ctx).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: zone.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(zone.icono, color: zone.color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              zone.nombre,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              zone.descripcion,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa del Campus ESCOM'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary,
                cs.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map_rounded),
            tooltip: 'Restablecer vista',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(Icons.touch_app_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                const Text(
                  'Toca una zona para ver información',
                  style: TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.pinch_rounded,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Pellizca para hacer zoom',
                  style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                double mapWidth = constraints.maxWidth;
                double mapHeight = mapWidth / _mapAspectRatio;

                if (mapHeight > constraints.maxHeight) {
                  mapHeight = constraints.maxHeight;
                  mapWidth = mapHeight * _mapAspectRatio;
                }

                return Center(
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: SizedBox(
                      width: mapWidth,
                      height: mapHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/mapa_escom.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          ...escomZones.map(
                            (zone) => MapZoneWidget(
                              zone: zone,
                              mapWidth: mapWidth,
                              mapHeight: mapHeight,
                              onTap: () => _onZoneTapped(zone),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _legendItem(Colors.blue, 'Edificios'),
                  const SizedBox(width: 12),
                  _legendItem(Colors.teal, 'Laboratorios'),
                  const SizedBox(width: 12),
                  _legendItem(Colors.purple, 'Gobierno'),
                  const SizedBox(width: 12),
                  _legendItem(Colors.green, 'Deportes'),
                  const SizedBox(width: 12),
                  _legendItem(Colors.orange, 'Alimentos'),
                  const SizedBox(width: 12),
                  _legendItem(Colors.red, 'Entradas'),
                  const SizedBox(width: 12),
                  _legendItem(Colors.amber, 'Explanada'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }
}
