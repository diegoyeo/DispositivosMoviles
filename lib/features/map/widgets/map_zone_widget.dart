import 'package:flutter/material.dart';

import '../models/map_zone_model.dart';

class MapZoneWidget extends StatefulWidget {
  final MapZone zone;
  final double mapWidth;
  final double mapHeight;
  final VoidCallback onTap;

  const MapZoneWidget({
    super.key,
    required this.zone,
    required this.mapWidth,
    required this.mapHeight,
    required this.onTap,
  });

  @override
  State<MapZoneWidget> createState() => _MapZoneWidgetState();
}

class _MapZoneWidgetState extends State<MapZoneWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final left = zone.left * widget.mapWidth;
    final top = zone.top * widget.mapHeight;
    final width = zone.width * widget.mapWidth;
    final height = zone.height * widget.mapHeight;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (ctx, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: zone.color.withValues(alpha: 0.20),
              border: Border.all(
                color: zone.color.withValues(alpha: 0.60),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: zone.color.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  zone.icono,
                  color: Colors.white,
                  size: width < 40 ? 10 : 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
