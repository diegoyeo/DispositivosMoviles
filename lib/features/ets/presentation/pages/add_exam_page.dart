import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ets_provider.dart';

class AddExamPage extends StatefulWidget {
  const AddExamPage({super.key});

  @override
  State<AddExamPage> createState() => _AddExamPageState();
}

class _AddExamPageState extends State<AddExamPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto para los campos
  final _materiaController = TextEditingController();
  final _fechaController = TextEditingController();
  final _salonController = TextEditingController();
  final _profesorController = TextEditingController();

  // Variables para los menús desplegables
  String _carreraSeleccionada = 'ISC';
  String _turnoSeleccionado = 'Matutino';
  int _semestreSeleccionado = 1;

  void _guardarExamen() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<EtsProvider>(context, listen: false);

      await provider.agregarNuevoExamen(
        _materiaController.text,
        _carreraSeleccionada,
        _semestreSeleccionado,
        _fechaController.text,
        _turnoSeleccionado,
        _salonController.text,
        _profesorController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Examen registrado correctamente')),
      );

      Navigator.pop(context); // Regresamos al Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nuevo ETS'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _materiaController,
                decoration: const InputDecoration(
                  labelText: 'Unidad de Aprendizaje (Materia)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _carreraSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Carrera',
                        border: OutlineInputBorder(),
                      ),
                      items: ['ISC', 'LCD', 'IIA']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _carreraSeleccionada = val!),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _semestreSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Semestre',
                        border: OutlineInputBorder(),
                      ),
                      items: [1, 2, 3, 4, 5, 6, 7, 8]
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _semestreSeleccionado = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _fechaController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha (ej. 15-Junio-2026)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _turnoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Turno',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Matutino', 'Vespertino']
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _turnoSeleccionado = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _salonController,
                decoration: const InputDecoration(
                  labelText: 'Salón',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _profesorController,
                decoration: const InputDecoration(
                  labelText: 'Profesor Titular',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _guardarExamen,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Examen'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
