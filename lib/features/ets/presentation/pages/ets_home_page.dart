import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ets_provider.dart';

class EtsHomePage extends StatelessWidget {
  const EtsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final etsProvider = Provider.of<EtsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis ETS precargados'),
        backgroundColor: Colors.blueAccent,
      ),
      body: etsProvider.exams.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Ruedita de carga
          : ListView.builder(
              itemCount: etsProvider.exams.length,
              itemBuilder: (context, index) {
                final exam = etsProvider.exams[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.book, color: Colors.blue),
                    title: Text(exam.materia, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Fecha: ${exam.fecha} | Salón: ${exam.salon}'),
                    trailing: Text('Sem: ${exam.semestre}'),
                  ),
                );
              },
            ),
    );
  }
}