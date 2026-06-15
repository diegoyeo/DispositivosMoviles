import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/ets_provider.dart';
import 'home_admin_page.dart';
import 'home_dashboard.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _enterCtrl;
  late final Animation<double> _animLogo;
  late final Animation<double> _animEmail;
  late final Animation<double> _animPassword;
  late final Animation<double> _animButton;
  late final Animation<double> _animLinks;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _animLogo = _stagger(0.00, 0.45);
    _animEmail = _stagger(0.15, 0.60);
    _animPassword = _stagger(0.30, 0.75);
    _animButton = _stagger(0.45, 0.90);
    _animLinks = _stagger(0.60, 1.00);
  }

  // Crea una animación con inicio y fin escalonados sobre el mismo controller
  Animation<double> _stagger(double start, double end) => CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  // ── Lógica de negocio INTACTA — no modificar ──────────────────────────────

  void _intentarLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena ambos campos')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.login(
      _emailController.text,
      _passwordController.text,
    );

    if (exito) {
      if (!mounted) return;

      Provider.of<EtsProvider>(context, listen: false).limpiarFiltros();

      if (auth.currentRole == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeAdminPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bienvenido, Alumno')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeDashboard()),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Correo o contraseña incorrectos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Helpers de UI ─────────────────────────────────────────────────────────

  // Envuelve un widget en fade + slide desde abajo usando la animación dada
  Widget _slideIn(Animation<double> anim, Widget child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.primary),
        filled: true,
        fillColor: cs.surface.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primaryContainer, cs.surface],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // ── Logo + título ────────────────────────────────────────
                _slideIn(
                  _animLogo,
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'MOVIDA',
                        style: tt.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          letterSpacing: 3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestor de ETS · ESCOM',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Tarjeta glassmorphism con los campos ─────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          _slideIn(
                            _animEmail,
                            _buildField(
                              controller: _emailController,
                              label: 'Correo Institucional',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _slideIn(
                            _animPassword,
                            _buildField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              icon: Icons.lock_outline_rounded,
                              obscureText: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Botón principal ──────────────────────────────────────
                _slideIn(
                  _animButton,
                  _GradientButton(
                    label: 'Iniciar Sesión',
                    onPressed: _intentarLogin,
                  ),
                ),

                const SizedBox(height: 4),

                // ── Links secundarios ────────────────────────────────────
                _slideIn(
                  _animLinks,
                  Column(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        ),
                        child: Text(
                          '¿No tienes cuenta? Regístrate como Alumno',
                          style: TextStyle(color: cs.primary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<EtsProvider>(context, listen: false)
                              .limpiarFiltros();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeDashboard(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              cs.onSurface.withValues(alpha: 0.45),
                        ),
                        child: const Text(
                          'Entrar como Invitado (Solo ver examenes)',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón con gradiente + animación de escala al presionar
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  const _GradientButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
