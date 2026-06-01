import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/ets_exam.dart';
import '../providers/auth_provider.dart';
import '../providers/ets_provider.dart';
import 'login_page.dart';

class ExamDetailPage extends StatelessWidget {
  final EtsExam exam;

  const ExamDetailPage({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final etsProv = Provider.of<EtsProvider>(
      context,
    ); // Quitamos el listen:false para que reaccione al cambio de botón
    final esInvitado = auth.currentRole == null;

    // Verificamos si este examen en específico ya está en la lista de guardados
    final yaEstaGuardado = etsProv.estaGuardado(exam.materia);

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.materia),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(2),
                  },
                  children: [
                    _buildTableRow('Materia:', exam.materia),
                    _buildTableRow('Carrera:', exam.carrera),
                    _buildTableRow('Semestre:', exam.semestre.toString()),
                    _buildTableRow('Fecha:', exam.fecha),
                    _buildTableRow('Turno:', exam.turno),
                    _buildTableRow('Salón:', exam.salon),
                    _buildTableRow('Profesor:', exam.profesor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- LÓGICA DINÁMICA DE BOTONES ---
            if (esInvitado)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión para guardar'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                ),
              )
            else if (yaEstaGuardado)
              // BOTÓN PARA ELIMINAR
              ElevatedButton.icon(
                onPressed: () async {
                  await etsProv.eliminarExamInterno(
                    auth.currentEmail!,
                    exam.materia,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Eliminado de tu calendario interno'),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark_remove),
                label: const Text('Quitar de mi calendario'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              )
            else
              // BOTÓN PARA GUARDAR
              ElevatedButton.icon(
                onPressed: () async {
                  await etsProv.guardarExamInterno(
                    auth.currentEmail!,
                    exam.materia,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Guardado en tu calendario interno con éxito',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark),
                label: const Text('Guardar en mi calendario'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
