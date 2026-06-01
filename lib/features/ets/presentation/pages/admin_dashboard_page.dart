import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ets_provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import 'add_exam_page.dart';
import 'edit_exam_page.dart'; // Import de la nueva pantalla de edición

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _searchQuery = '';
  String _selectedCareer = 'Todas';
  final TextEditingController _searchController = TextEditingController();

  // --- HELPER PARA IGNORAR ACENTOS (Ideal para búsquedas) ---
  String _quitarAcentos(String texto) {
    const conAcento = 'áéíóúÁÉÍÓÚüÜñÑ';
    const sinAcento = 'aeiouAEIOUuUnN';
    String resultado = texto;
    for (int i = 0; i < conAcento.length; i++) {
      resultado = resultado.replaceAll(conAcento[i], sinAcento[i]);
    }
    return resultado;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etsProvider = Provider.of<EtsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    final catalogoCompleto = etsProvider.catalogoCompleto;

    final totalExamenes = catalogoCompleto.length;
    final totalISC = catalogoCompleto.where((e) => e.carrera == 'ISC').length;
    final totalLCD = catalogoCompleto.where((e) => e.carrera == 'LCD').length;
    final totalIIA = catalogoCompleto.where((e) => e.carrera == 'IIA').length;

    // LÓGICA DE FILTRADO CON IGNORADO DE ACENTOS
    final examenesMostrados = catalogoCompleto.where((exam) {
      final coincideCarrera =
          _selectedCareer == 'Todas' || exam.carrera == _selectedCareer;

      // Convertimos tanto el catálogo como la búsqueda a minúsculas y sin acentos
      final materiaLimpia = _quitarAcentos(exam.materia.toLowerCase());
      final queryLimpia = _quitarAcentos(_searchQuery.toLowerCase());

      final coincideTexto = materiaLimpia.contains(queryLimpia);

      return coincideCarrera && coincideTexto;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control Admin'),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Modo Administrador',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                auth.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas y Filtros',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  'Total',
                  totalExamenes.toString(),
                  Colors.blueAccent,
                  'Todas',
                ),
                _buildStatCard('ISC', totalISC.toString(), Colors.teal, 'ISC'),
                _buildStatCard(
                  'LCD',
                  totalLCD.toString(),
                  Colors.orange,
                  'LCD',
                ),
                _buildStatCard(
                  'IIA',
                  totalIIA.toString(),
                  Colors.redAccent,
                  'IIA',
                ),
              ],
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar materia (sin importar acentos)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Divider(thickness: 2),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Oferta',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${examenesMostrados.length} resultados',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: examenesMostrados.isEmpty
                  ? const Center(child: Text('No se encontraron materias'))
                  : ListView.builder(
                      itemCount: examenesMostrados.length,
                      itemBuilder: (context, index) {
                        final exam = examenesMostrados[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(
                              exam.materia,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${exam.carrera} | Semestre ${exam.semestre} | ${exam.fecha}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 👇 CONEXIÓN CON EDIT_EXAM_PAGE
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditExamPage(exam: exam),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Confirmar eliminación',
                                          ),
                                          content: Text(
                                            '¿Estás seguro de que deseas dar de baja el ETS de ${exam.materia}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await etsProvider
                                                    .borrarExamenDelCatalogo(
                                                      exam.materia,
                                                    );

                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Examen eliminado del catálogo',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Eliminar',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExamPage()),
          );
        },
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo ETS', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    Color color,
    String careerCode,
  ) {
    final isSelected = _selectedCareer == careerCode;

    return GestureDetector(
      onTap: () => setState(() => _selectedCareer = careerCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: isSelected ? 2.5 : 1.0),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
