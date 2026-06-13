class SalonModel {
  final int id;
  final String nombre;
  final String edificio;
  final int? capacidad;

  const SalonModel({required this.id, required this.nombre, required this.edificio, this.capacidad});

  factory SalonModel.fromJson(Map<String, dynamic> json) => SalonModel(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        edificio: json['edificio'] as String? ?? '',
        capacidad: json['capacidad'] as int?,
      );

  Map<String, dynamic> toJson() => {'nombre': nombre, 'edificio': edificio, 'capacidad': capacidad};

  String get displayName => edificio.isNotEmpty ? '$nombre — $edificio' : nombre;
}
