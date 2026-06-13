class CarreraModel {
  final int id;
  final String nombre;
  final String descripcion;

  const CarreraModel({required this.id, required this.nombre, required this.descripcion});

  factory CarreraModel.fromJson(Map<String, dynamic> json) => CarreraModel(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'nombre': nombre, 'descripcion': descripcion};
}
