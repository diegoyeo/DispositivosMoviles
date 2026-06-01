import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ets_provider.dart';
import 'ets_home_page.dart';
import 'register_page.dart';
import 'admin_dashboard_page.dart'; // <--- Aquí está el famoso import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _intentarLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena ambos campos')),
      );
      return;
    }

    // Leemos el provider
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.login(
      _emailController.text,
      _passwordController.text,
    );

    if (exito) {
      if (!mounted) return;

      // Limpiamos los filtros antes de entrar para que no se queden pegados
      Provider.of<EtsProvider>(context, listen: false).limpiarFiltros();

      // --- LOGICA DE REDIRECCIÓN (ADMIN VS ALUMNO) ---
      if (auth.currentRole == 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autenticado como Administrador')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bienvenido, Alumno')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EtsHomePage()),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo o contraseña incorrectos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de ETS - ESCOM'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.school, size: 100, color: Colors.blue),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo Institucional',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _intentarLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Iniciar Sesion',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('¿No tienes cuenta? Registrate como Alumno'),
            ),

            TextButton(
              onPressed: () {
                // Limpiamos también si entra como invitado
                Provider.of<EtsProvider>(
                  context,
                  listen: false,
                ).limpiarFiltros();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const EtsHomePage()),
                );
              },
              child: const Text(
                'Entrar como Invitado (Solo ver examenes)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
