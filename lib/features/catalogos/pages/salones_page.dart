import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/catalogos_provider.dart';
import '../models/salon_model.dart';

class SalonesPage extends StatefulWidget {
  const SalonesPage({super.key});

  @override
  State<SalonesPage> createState() => _SalonesPageState();
}

class _SalonesPageState extends State<SalonesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogosProvider>().loadSalones();
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
        title: const Text('Gestión de Salones'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSheet(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo salón'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CatalogosProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          }
          if (provider.salones.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Sin salones registrados', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.salones.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final salon = provider.salones[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade100,
                    child: const Icon(Icons.door_front_door_outlined, color: Colors.deepPurple),
                  ),
                  title: Text(salon.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text([
                    if (salon.edificio.isNotEmpty) salon.edificio,
                    if (salon.capacidad != null) 'Cap. ${salon.capacidad}',
                  ].join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.deepPurple),
                        onPressed: () => _showSheet(context, salon),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, salon),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSheet(BuildContext ctx, SalonModel? existing) {
    final nombreCtrl = TextEditingController(text: existing?.nombre ?? '');
    final edificioCtrl = TextEditingController(text: existing?.edificio ?? '');
    final capacidadCtrl = TextEditingController(text: existing?.capacidad?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Nuevo salón' : 'Editar salón',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre (ej. 3002)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: edificioCtrl,
                  decoration: const InputDecoration(labelText: 'Edificio (ej. Edificio 3)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacidadCtrl,
                  decoration: const InputDecoration(labelText: 'Capacidad (opcional)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.of(sheetCtx).pop();
                      final cap = capacidadCtrl.text.trim().isNotEmpty ? int.tryParse(capacidadCtrl.text.trim()) : null;
                      final provider = ctx.read<CatalogosProvider>();
                      final ok = existing == null
                          ? await provider.addSalon(nombre: nombreCtrl.text.trim(), edificio: edificioCtrl.text.trim(), capacidad: cap)
                          : await provider.updateSalon(existing.id, nombre: nombreCtrl.text.trim(), edificio: edificioCtrl.text.trim(), capacidad: cap);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(ok ? (existing == null ? 'Salón creado' : 'Salón actualizado') : (provider.lastError ?? 'Error')),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ));
                    },
                    child: Text(existing == null ? 'Crear' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext ctx, SalonModel salon) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar salón'),
        content: Text('¿Eliminar "${salon.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final provider = ctx.read<CatalogosProvider>();
              final ok = await provider.deleteSalon(salon.id);
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(ok ? 'Salón eliminado' : (provider.lastError ?? 'Error al eliminar')),
                backgroundColor: ok ? Colors.green : Colors.red,
              ));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
