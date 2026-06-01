import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ets_model.dart';

class EtsLocalDataSource {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'ets_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Crear tabla de Exámenes (Ya incluye la columna 'carrera')
        await db.execute('''
          CREATE TABLE exams (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            materia TEXT,
            fecha TEXT,
            turno TEXT,
            salon TEXT,
            profesor TEXT,
            carrera TEXT,
            semestre INTEGER
          )
        ''');

        // 2. Crear tabla de Usuarios
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            apellido TEXT,
            correo TEXT UNIQUE,
            password TEXT,
            rol TEXT 
          )
        ''');
        // Tabla para relacionar alumnos con sus examenes guardados
        await db.execute('''
          CREATE TABLE saved_exams (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            correo TEXT,
            exam_id INTEGER,
            UNIQUE(correo, exam_id) -- Evita que guarden el mismo examen dos veces
          )
        ''');

        // 3. Precargar al ADMINISTRADOR
        await db.rawInsert('''
          INSERT INTO users (nombre, apellido, correo, password, rol)
          VALUES ('Admin', 'Sistema', 'admin@escom.ipn.mx', 'admin123', 'admin')
        ''');

        // 4. Precargar TODOS los exámenes de ISC
        await db.execute('''
          INSERT INTO exams (materia, fecha, turno, salon, profesor, carrera, semestre) VALUES 
          -- Semestre 1
          ('Cálculo (ISC)', '15-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 1),
          ('Análisis Vectorial (ISC)', '15-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 1),
          ('Matemáticas Discretas (ISC)', '16-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 1),
          ('Comunicación Oral y Escrita (ISC)', '16-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 1),
          ('Fundamentos de Programación (ISC)', '17-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 1),
          -- Semestre 2
          ('Álgebra Lineal (ISC)', '17-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 2),
          ('Cálculo Aplicado (ISC)', '18-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 2),
          ('Mecánica y Electromagnetismo (ISC)', '18-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 2),
          ('Ingeniería, Ética y Sociedad (ISC)', '19-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 2),
          ('Fundamentos Económicos (ISC)', '19-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 2),
          ('Algoritmos y Estructuras de Datos (ISC)', '20-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 2),
          -- Semestre 3
          ('Ecuaciones Diferenciales (ISC)', '20-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 3),
          ('Circuitos Eléctricos (ISC)', '22-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 3),
          ('Fundamentos de Diseño Digital (ISC)', '22-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 3),
          ('Bases de Datos (ISC)', '23-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 3),
          ('Finanzas Empresariales (ISC)', '23-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 3),
          ('Paradigmas de Programación (ISC)', '24-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 3),
          ('Análisis y Diseño de Algoritmos (ISC)', '24-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 3),
          -- Semestre 4
          ('Probabilidad y Estadística (ISC)', '25-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 4),
          ('Matemáticas Avanzadas para la Ingeniería (ISC)', '25-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 4),
          ('Electrónica Analógica (ISC)', '26-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 4),
          ('Diseño de Sistemas Digitales (ISC)', '26-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 4),
          ('Tecnologías para el Desarrollo de Aplicaciones Web (ISC)', '27-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 4),
          ('Sistemas Operativos (ISC)', '27-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 4),
          ('Teoría de la Computación (ISC)', '29-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 4),
          -- Semestre 5
          ('Procesamiento Digital de Señales (ISC)', '29-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 5),
          ('Instrumentación y Control (ISC)', '30-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 5),
          ('Arquitectura de Computadoras (ISC)', '30-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 5),
          ('Análisis y Diseño de Sistemas (ISC)', '01-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 5),
          ('Formulación y Evaluación de Proyectos Informáticos (ISC)', '01-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 5),
          ('Compiladores (ISC)', '02-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 5),
          ('Redes de Computadoras (ISC)', '02-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 5),
          -- Semestre 6
          ('Sistemas en Chip (ISC)', '03-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 6),
          ('Métodos Cuantitativos para la Toma de Decisiones (ISC)', '03-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 6),
          ('Ingeniería de Software (ISC)', '04-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 6),
          ('Inteligencia Artificial (ISC)', '04-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 6),
          ('Aplicaciones para Comunicaciones en Red (ISC)', '06-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 6),
          -- Semestre 7
          ('Desarrollo de Aplicaciones Móviles Nativas (ISC)', '06-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Sistemas Distribuidos (ISC)', '07-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Administración de Servicios en Red (ISC)', '07-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          -- Semestre 8
          ('Desarrollo de Habilidades Sociales para la Alta Dirección (ISC)', '08-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Gestión Empresarial (ISC)', '08-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Liderazgo Personal (ISC)', '09-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          -- Optativas ISC (Asignadas como semestre 7 y 8 genéricos)
          ('Computer Graphics (Opt. ISC)', '10-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Genetic Algorithms (Opt. ISC)', '10-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Machine Learning (Opt. ISC)', '11-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Bioinformatics (Opt. ISC)', '11-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Natural Language Processing (Opt. ISC)', '13-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Virtual and Augmented Reality (Opt. ISC)', '13-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Big Data (Opt. ISC)', '14-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Computing Selected Topics I (Opt. ISC)', '14-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Data Mining (Opt. ISC)', '15-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Image Analysis (Opt. ISC)', '15-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Virtual Instrumentation (Opt. ISC)', '16-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Cellula Automata (Opt. ISC)', '16-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('High Technology Enterprise Management (Opt. ISC)', '17-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Statistical Tools For Data Analytics (Opt. ISC)', '17-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 7),
          ('Computer Security (Opt. ISC)', '18-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Introduction to Cryptography (Opt. ISC)', '18-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Software Quality Assurance and Design Patterns (Opt. ISC)', '20-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('IT Governance (Opt. ISC)', '20-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Selected Topics of Cryptography (Opt. ISC)', '21-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Web Client and Backend Development Frameworks (Opt. ISC)', '21-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Complex Systems (Opt. ISC)', '22-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Computing Selected Topics II (Opt. ISC)', '22-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Economic Engineering (Opt. ISC)', '23-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Internet of Things (Opt. ISC)', '23-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Virtual Instrumentation Applications (Opt. ISC)', '24-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Embedded Systems (Opt. ISC)', '24-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'ISC', 8),
          ('Non Relational Databases (Opt. ISC)', '25-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'ISC', 8)
        ''');

        // 5. Precargar TODOS los exámenes de LCD
        await db.execute('''
          INSERT INTO exams (materia, fecha, turno, salon, profesor, carrera, semestre) VALUES 
          -- Semestre 1
          ('Fundamentos de Programación (LCD)', '15-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 1),
          ('Matemáticas Discretas (LCD)', '15-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 1),
          ('Cálculo (LCD)', '16-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 1),
          ('Comunicación Oral y Escrita (LCD)', '16-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 1),
          ('Introducción a la ciencia de datos (LCD)', '17-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 1),
          -- Semestre 2
          ('Algoritmos y Estructuras de Datos (LCD)', '17-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 2),
          ('Álgebra Lineal (LCD)', '18-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 2),
          ('Cálculo Multivariable (LCD)', '18-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 2),
          ('Ética y Legalidad (LCD)', '19-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 2),
          ('Fundamentos Económicos (LCD)', '19-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 2),
          -- Semestre 3
          ('Análisis y Diseño de Algoritmos (LCD)', '20-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 3),
          ('Programación para Ciencia de Datos (LCD)', '20-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 3),
          ('Probabilidad (LCD)', '22-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 3),
          ('Bases de Datos (LCD)', '22-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 3),
          ('Métodos Numéricos (LCD)', '23-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 3),
          ('Finanzas Empresariales (LCD)', '23-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 3),
          -- Semestre 4
          ('Desarrollo de Aplicaciones Web (LCD)', '24-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 4),
          ('Cómputo de Alto Desempeño (LCD)', '24-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 4),
          ('Estadística (LCD)', '25-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 4),
          ('Base de Datos Avanzadas (LCD)', '25-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 4),
          ('Desarrollo de Aplicaciones para Análisis de Datos (LCD)', '26-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 4),
          ('Liderazgo Personal (LCD)', '26-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 4),
          -- Semestre 5
          ('Minería de Datos (LCD)', '27-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 5),
          ('Matemáticas Avanzadas para Ciencia de Datos (LCD)', '27-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 5),
          ('Procesos Estocásticos (LCD)', '29-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 5),
          ('Aprendizaje de Máquina e Inteligencia Artificial (LCD)', '29-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 5),
          ('Analítica y Visualización de Datos (LCD)', '30-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 5),
          ('Metodología de la investigación y divulgación científica (LCD)', '30-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 5),
          -- Semestre 6
          ('Modelado Predictivo (LCD)', '01-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 6),
          ('Procesamiento de Lenguaje Natural (LCD)', '01-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 6),
          ('Análisis de Series de Tiempo (LCD)', '02-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 6),
          ('Analítica Avanzada de Datos (LCD)', '02-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 6),
          -- Semestre 7
          ('Big Data (LCD)', '03-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 7),
          ('Modelos Econométricos (LCD)', '03-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 7),
          ('Administración de Proyectos de TI (LCD)', '04-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 7),
          -- Semestre 8
          ('Desarrollo de Habilidades Sociales para la Alta Dirección (LCD)', '06-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 8),
          ('Gestión Empresarial (LCD)', '07-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 8),
          -- Optativas LCD
          ('Estadística avanzada (Opt. LCD)', '08-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 7),
          ('Temas selectos de inteligencia artificial (Opt. LCD)', '09-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 7),
          ('Temas selectos de aprendizaje profundo (Opt. LCD)', '09-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 7),
          ('Temas selectos de procesamiento de lenguaje natural (Opt. LCD)', '10-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 7),
          ('Bioinformática básica (Opt. LCD)', '10-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 7),
          ('Bionformática avanzada (Opt. LCD)', '11-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 7),
          ('Sistemas de información geográfica (Opt. LCD)', '11-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 7),
          ('Ciberseguridad (Opt. LCD)', '13-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 8),
          ('Protección de datos (Opt. LCD)', '13-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 8),
          ('Innovación y emprendimientos tecnológico (Opt. LCD)', '14-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 8),
          ('Propiedad intelectual (Opt. LCD)', '14-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 8),
          ('Simulación básica (Opt. LCD)', '15-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'LCD', 8),
          ('Simulación avanzada (Opt. LCD)', '15-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'LCD', 8)
        ''');

        // 6. Precargar TODOS los exámenes de IIA
        await db.execute('''
          INSERT INTO exams (materia, fecha, turno, salon, profesor, carrera, semestre) VALUES 
          -- Semestre 1
          ('Fundamentos de Programación (IIA)', '15-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 1),
          ('Matemáticas Discretas (IIA)', '15-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 1),
          ('Cálculo (IIA)', '16-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 1),
          ('Comunicación Oral y Escrita (IIA)', '16-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 1),
          ('Mecánica y Electromagnetismo (IIA)', '17-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 1),
          ('Fundamentos Económicos (IIA)', '17-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 1),
          -- Semestre 2
          ('Algoritmos y Estructuras de Datos (IIA)', '18-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 2),
          ('Fundamentos de Diseño Digital (IIA)', '18-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 2),
          ('Cálculo Multivariable (IIA)', '19-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 2),
          ('Ingeniería, Ética y Sociedad (IIA)', '19-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 2),
          ('Álgebra Lineal (IIA)', '20-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 2),
          ('Finanzas Empresariales (IIA)', '20-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 2),
          -- Semestre 3
          ('Análisis y Diseño de Algoritmos (IIA)', '22-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 3),
          ('Paradigmas de Programación (IIA)', '22-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 3),
          ('Ecuaciones Diferenciales (IIA)', '23-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 3),
          ('Bases de Datos (IIA)', '23-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 3),
          ('Diseño de Sistemas Digitales (IIA)', '24-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 3),
          ('Liderazgo Personal (IIA)', '24-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 3),
          -- Semestre 4
          ('Fundamentos de Inteligencia Artificial (IIA)', '25-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 4),
          ('Probabilidad y Estadística (IIA)', '25-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 4),
          ('Matemáticas Avanzadas para la Ingeniería (IIA)', '26-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 4),
          ('Tecnologías para el Desarrollo de Aplicaciones Web (IIA)', '26-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 4),
          ('Análisis y Diseño de Sistemas (IIA)', '27-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 4),
          ('Procesamiento Digital de Imágenes (IIA)', '27-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 4),
          -- Semestre 5
          ('Aprendizaje de Máquina (IIA)', '29-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 5),
          ('Visión Artificial (IIA)', '29-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 5),
          ('Teoría de la Computación (IIA)', '30-Junio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 5),
          ('Procesamiento de Señales (IIA)', '30-Junio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 5),
          ('Algoritmos Bioinspirados (IIA)', '01-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 5),
          ('Tecnologías de Lenguaje Natural (IIA)', '01-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 5),
          -- Semestre 6
          ('Cómputo Paralelo (IIA)', '02-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 6),
          ('Redes Neuronales y Aprendizaje Profundo (IIA)', '02-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 6),
          ('Ingeniería de Software para Sistemas Inteligentes (IIA)', '03-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 6),
          ('Metodología de la Investigación y Divulgación Científica (IIA)', '03-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 6),
          -- Semestre 7
          ('Reconocimiento de Voz (IIA)', '04-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 7),
          ('Formulación y Evaluación de Proyectos Informáticos (IIA)', '04-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 7),
          -- Semestre 8
          ('Gestión Empresarial (IIA)', '06-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 8),
          ('Desarrollo de Habilidades Sociales para la Alta Dirección (IIA)', '06-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 8),
          -- Optativas IIA
          ('Innovación y emprendimiento tecnológico (Opt. IIA)', '07-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 7),
          ('Propiedad Intelectual (Opt. IIA)', '07-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 7),
          ('Aplicaciones de lenguaje natural (Opt. IIA)', '08-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 7),
          ('Sistemas multiagentes (Opt. IIA)', '08-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 7),
          ('Aplicaciones de sistemas multiagentes (Opt. IIA)', '09-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 7),
          ('Minería de datos (Opt. IIA)', '09-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 7),
          ('Big data (Opt. IIA)', '10-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 7),
          ('Temas selectos de inteligencia artificial (Opt. IIA)', '10-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 8),
          ('Cómputo en la nube (Opt. IIA)', '11-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 8),
          ('Técnicas de programación para robots móviles (Opt. IIA)', '11-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 8),
          ('Interacción humano-máquina (Opt. IIA)', '13-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 8),
          ('Programación de dispositivos móviles (Opt. IIA)', '13-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 8),
          ('Aplicaciones de inteligencia artificial en sistemas embebidos (Opt. IIA)', '14-Julio-2026', 'Matutino', 'Por asignar', 'Profesor Asignado', 'IIA', 8),
          ('Tópicos selectos de algoritmos bioinspirados (Opt. IIA)', '14-Julio-2026', 'Vespertino', 'Por asignar', 'Profesor Asignado', 'IIA', 8)
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
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Método para obtener todos los exámenes
  // Método para obtener todos los exámenes ordenados alfabéticamente
  Future<List<EtsModel>> getExams() async {
    final db = await database;

    // 👇 Solo agregamos el parámetro orderBy apuntando a la columna 'materia'
    final List<Map<String, dynamic>> maps = await db.query(
      'exams',
      orderBy: 'materia ASC', // ASC significa de la A a la Z
    );

    return maps.map((e) => EtsModel.fromJson(e)).toList();
  }
  // --- MÉTODOS DE AUTENTICACIÓN ---

  // 1. Registrar un alumno nuevo en la base de datos
  Future<bool> registerUser(
    String nombre,
    String apellido,
    String correo,
    String password,
  ) async {
    final db = await database;
    try {
      await db.insert('users', {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'password': password,
        'rol': 'alumno',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 2. Validar credenciales y regresar el rol ('admin' o 'alumno')
  Future<String?> loginUser(String correo, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'correo = ? AND password = ?',
      whereArgs: [correo, password],
    );

    if (maps.isNotEmpty) {
      return maps.first['rol'] as String; // Regresa 'admin' o 'alumno'
    }
    return null; // Credenciales incorrectas
  }

  // Guardar un examen en el calendario interno del alumno
  // Cambiamos 'int examId' por 'String materia'
  Future<void> saveExamToUser(String correo, String materia) async {
    final db = await database;

    // 1. Buscamos el ID real de la materia en la tabla exams
    final exam = await db.query(
      'exams',
      columns: ['id'],
      where: 'materia = ?',
      whereArgs: [materia],
    );

    if (exam.isNotEmpty) {
      final realId = exam.first['id']; // Obtenemos el ID verdadero (ej. 15)

      // 2. Ahora sí lo guardamos en la tabla relacional
      await db.insert(
        'saved_exams',
        {'correo': correo, 'exam_id': realId},
        conflictAlgorithm:
            ConflictAlgorithm.ignore, // Ignora si ya lo había guardado
      );
    }
  }

  // Obtener solo los examenes guardados por un alumno en especifico
  Future<List<EtsModel>> getSavedExamsForUser(String correo) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT exams.* FROM exams
      INNER JOIN saved_exams ON exams.id = saved_exams.exam_id
      WHERE saved_exams.correo = ?
    ''',
      [correo],
    );

    return maps.map((e) => EtsModel.fromJson(e)).toList();
  }

  // Quitar un examen del calendario interno del alumno
  Future<void> removeExamFromUser(String correo, String materia) async {
    final db = await database;

    // Buscamos el ID de la materia
    final exam = await db.query(
      'exams',
      columns: ['id'],
      where: 'materia = ?',
      whereArgs: [materia],
    );

    if (exam.isNotEmpty) {
      final realId = exam.first['id'];

      // Lo borramos de la tabla relacional
      await db.delete(
        'saved_exams',
        where: 'correo = ? AND exam_id = ?',
        whereArgs: [correo, realId],
      );
    }
  }

  // Insertar un nuevo examen en el catálogo general
  Future<void> addExam(
    String materia,
    String carrera,
    int semestre,
    String fecha,
    String turno,
    String salon,
    String profesor,
  ) async {
    final db = await database;
    await db.insert('exams', {
      'materia': materia,
      'carrera': carrera,
      'semestre': semestre,
      'fecha': fecha,
      'turno': turno,
      'salon': salon,
      'profesor': profesor,
    });
  }

  // Eliminar un examen del catálogo general de forma definitiva
  Future<void> deleteExam(String materia) async {
    final db = await database;
    await db.delete('exams', where: 'materia = ?', whereArgs: [materia]);
  }

  // --- MÓDULO DE AUTENTICACIÓN (REGISTRO REAL) ---
  Future<bool> register(
    String nombre,
    String apellido,
    String correo,
    String password,
  ) async {
    try {
      final db = await database;

      // Sanitizamos los datos antes de guardarlos
      final emailLimpio = correo.trim().toLowerCase();

      await db.insert('users', {
        'nombre': nombre,
        'apellido': apellido,
        'correo': emailLimpio,
        'password': password.trim(),
      });

      return true; // Se guardó correctamente en SQLite
    } catch (e) {
      return false; // Falló (probablemente el correo ya estaba registrado)
    }
  }

  // Actualizar los datos de un examen existente
  Future<void> updateExam(
    String oldMateria,
    String materia,
    String carrera,
    int semestre,
    String fecha,
    String turno,
    String salon,
    String profesor,
  ) async {
    final db = await database;
    await db.update(
      'exams',
      {
        'materia': materia,
        'carrera': carrera,
        'semestre': semestre,
        'fecha': fecha,
        'turno': turno,
        'salon': salon,
        'profesor': profesor,
      },
      where: 'materia = ?',
      whereArgs: [oldMateria],
    );
  }
}
