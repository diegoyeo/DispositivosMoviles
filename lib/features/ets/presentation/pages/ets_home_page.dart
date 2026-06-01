import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ets_provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import 'exam_detail_page.dart';
import 'saved_exams_page.dart';

class EtsHomePage extends StatelessWidget {
  const EtsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final etsProvider = Provider.of<EtsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final esInvitado = auth.currentRole == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examenes Disponibles'),
        backgroundColor: Colors.blueAccent,
      ),

      // --- MENU LATERAL (DRAWER) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    esInvitado ? 'Modo Invitado' : 'Alumno ESCOM',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),

            // --- BOTON DE MIS ETS GUARDADOS ---
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Mis ETS Guardados'),
              onTap: () {
                Navigator.pop(context);
                if (esInvitado) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inicia sesion para guardar examenes'),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedExamsPage(),
                    ),
                  );
                }
              },
            ),
            const Divider(),

            // --- BOTON DE LOGIN / LOGOUT ---
            ListTile(
              leading: Icon(
                esInvitado ? Icons.login : Icons.logout,
                color: esInvitado ? Colors.blue : Colors.red,
              ),
              title: Text(
                esInvitado ? 'Iniciar Sesion' : 'Cerrar Sesion',
                style: TextStyle(color: esInvitado ? Colors.blue : Colors.red),
              ),
              onTap: () {
                // 👇 LIMPIAMOS LOS FILTROS ANTES DE SALIR (ARREGLO BUG 2)
                etsProvider.limpiarFiltros();

                if (!esInvitado) auth.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),

      // --- CUERPO DE LA PANTALLA (BUSCADOR Y LISTA) ---
      body: Column(
        children: [
          // 1. ZONA DE FILTROS
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (valor) => etsProvider.buscarPorMateria(valor),
                  decoration: InputDecoration(
                    labelText: 'Buscar Unidad de Aprendizaje...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Carrera',
                          border: OutlineInputBorder(),
                        ),
                        value: etsProvider.carreraSeleccionada ?? 'Todas',
                        items: ['Todas', 'ISC', 'LCD', 'IIA']
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (valor) =>
                            etsProvider.filtrarPorCarrera(valor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Semestre',
                          border: OutlineInputBorder(),
                        ),
                        value: etsProvider.semestreSeleccionado ?? 'Todos',
                        items: ['Todos', '1', '2', '3', '4', '5', '6', '7', '8']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (valor) =>
                            etsProvider.filtrarPorSemestre(valor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // 2. LISTA DINAMICA DE RESULTADOS
          Expanded(
            child: etsProvider.examenesFiltrados.isEmpty
                ? const Center(child: Text('No se encontraron resultados'))
                : ListView.builder(
                    itemCount: etsProvider.examenesFiltrados.length,
                    itemBuilder: (context, index) {
                      final exam = etsProvider.examenesFiltrados[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.book,
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          exam.materia,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${exam.carrera} - Semestre ${exam.semestre}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExamDetailPage(exam: exam),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
