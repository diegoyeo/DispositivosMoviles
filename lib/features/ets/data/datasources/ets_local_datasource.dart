import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ets_model.dart';

class EtsLocalDataSource {
  static Database? _database;

  // Obtener la instancia de la base de datos (Singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Inicializar la base de datos
  Future<Database> _initDB() async {
    // Definimos la ruta del archivo .db
    String path = join(await getDatabasesPath(), 'ets_database.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Crear la tabla de exámenes
        await db.execute('''
          CREATE TABLE exams (
            materia TEXT,
            fecha TEXT,
            turno TEXT,
            salon TEXT,
            profesor TEXT,
            carrera TEXT,
            semestre INTEGER
          )
        ''');

        // 2. Insertar datos precargados (Semilla)
        await db.rawInsert('''
          INSERT INTO exams (materia, fecha, turno, salon, profesor, carrera, semestre)
          VALUES 
          ('Dispositivos Móviles', '15-Junio-2026', 'Vespertino', '101', 'Pérez', 'Sistemas', 8),
          ('Redes de Computadoras', '18-Junio-2026', 'Matutino', '204', 'García', 'Sistemas', 7),
          ('Cálculo', '20-Junio-2026', 'Matutino', '105', 'Martínez', 'Sistemas', 1)
        ''');
      },
    );
  }

  // Método para guardar un nuevo examen (Manual)
  Future<void> saveExam(EtsModel exam) async {
    final db = await database;
    await db.insert(
      'exams', 
      exam.toJson(), 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  // Método para obtener todos los exámenes de la base de datos
  Future<List<EtsModel>> getExams() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('exams');
    
    // Convertimos la lista de Mapas a lista de EtsModel
    return maps.map((e) => EtsModel.fromJson(e)).toList();
  }
}