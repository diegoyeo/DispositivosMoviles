import 'package:flutter/material.dart';

class MapZone {
  final String id;
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;
  final double left;
  final double top;
  final double width;
  final double height;

  const MapZone({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
