import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/ets_exam.dart';
import '../providers/ets_provider.dart';

class EditExamPage extends StatefulWidget {
  final EtsExam exam; // Recibimos el examen a editar

  const EditExamPage({super.key, required this.exam});

  @override
  State<EditExamPage> createState() => _EditExamPageState();
}

class _EditExamPageState extends State<EditExamPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _materiaController;
  late TextEditingController _fechaController;
  late TextEditingController _salonController;
  late TextEditingController _profesorController;

  late String _carreraSeleccionada;
  late String _turnoSeleccionado;
  late int _semestreSeleccionado;

  @override
  void initState() {
    super.initState();
    // Precargamos los controladores con los datos actuales del examen
    _materiaController = TextEditingController(text: widget.exam.materia);
    _fechaController = TextEditingController(text: widget.exam.fecha);
    _salonController = TextEditingController(text: widget.exam.salon);
    // Si tu entidad maneja profesor o campos similares, los mapeamos aquí
    _profesorController = TextEditingController(text: 'Por asignar');

    _carreraSeleccionada = widget.exam.carrera;
    _turnoSeleccionado = widget.exam.turno;
    _semestreSeleccionado = widget.exam.semestre;
  }

  @override
  void dispose() {
    _materiaController.dispose();
    _fechaController.dispose();
    _salonController.dispose();
    _profesorController.dispose();
    super.dispose();
  }

  void _actualizarExamen() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<EtsProvider>(context, listen: false);

      // Enviamos el nombre original (widget.exam.materia) para el WHERE
      await provider.actualizarExamen(
        widget.exam.materia,
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
        const SnackBar(content: Text('Examen actualizado correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Datos del ETS'),
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
                  labelText: 'Materia',
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
                        labelText: 'Fecha',
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
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _actualizarExamen,
                icon: const Icon(Icons.check),
                label: const Text('Guardar Cambios'),
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
