import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalogos_provider.dart';
import '../models/carrera_model.dart';

class CarrerasPage extends StatefulWidget {
  const CarrerasPage({super.key});

  @override
  State<CarrerasPage> createState() => _CarrerasPageState();
}

class _CarrerasPageState extends State<CarrerasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogosProvider>().loadCarreras();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      child: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Carreras'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSheet(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nueva carrera'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Consumer<CatalogosProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          }
          if (provider.carreras.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Sin carreras registradas', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 80,
            ),
            itemCount: provider.carreras.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final carrera = provider.carreras[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(carrera.nombre.substring(0, 1), style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(carrera.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: carrera.descripcion.isNotEmpty ? Text(carrera.descripcion) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.deepPurple),
                        onPressed: () => _showSheet(context, carrera),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(carrera),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }

  void _showSheet(BuildContext ctx, CarreraModel? existing) {
    final nombreCtrl = TextEditingController(text: existing?.nombre ?? '');
    final descCtrl = TextEditingController(text: existing?.descripcion ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(sheetCtx).padding.bottom;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetCtx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + bottomPadding + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existing == null ? 'Nueva carrera' : 'Editar carrera',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre (ej. ISC)', border: OutlineInputBorder()),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.of(sheetCtx).pop();
                            final provider = ctx.read<CatalogosProvider>();
                            final ok = existing == null
                                ? await provider.addCarrera(nombre: nombreCtrl.text.trim(), descripcion: descCtrl.text.trim())
                                : await provider.updateCarrera(existing.id, nombre: nombreCtrl.text.trim(), descripcion: descCtrl.text.trim());
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(ok ? (existing == null ? 'Carrera creada' : 'Carrera actualizada') : (provider.lastError ?? 'Error')),
                              backgroundColor: ok ? Colors.green : Colors.red,
                            ));
                          },
                          child: Text(existing == null ? 'Crear' : 'Guardar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(CarreraModel carrera) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar carrera'),
        content: Text('¿Eliminar "${carrera.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final provider = context.read<CatalogosProvider>();
              final ok = await provider.deleteCarrera(carrera.id);
              if (!mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(provider.error ?? 'No puedes eliminar una carrera que tiene exámenes registrados'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Carrera eliminada'),
                  backgroundColor: Colors.green,
                ));
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
