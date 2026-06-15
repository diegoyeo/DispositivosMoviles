import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/notification_service.dart';
import '../providers/auth_provider.dart';
import 'home_dashboard.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _enterCtrl;
  late final Animation<double> _animNombre;
  late final Animation<double> _animApellido;
  late final Animation<double> _animEmail;
  late final Animation<double> _animPassword;
  late final Animation<double> _animButton;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _animNombre = _stagger(0.00, 0.45);
    _animApellido = _stagger(0.15, 0.60);
    _animEmail = _stagger(0.30, 0.75);
    _animPassword = _stagger(0.45, 0.90);
    _animButton = _stagger(0.60, 1.00);
    _passwordController.addListener(_onPasswordChanged);
  }

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  void _onPasswordChanged() => setState(() {});

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe incluir al menos una mayúscula';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Debe incluir al menos una minúscula';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      return 'Debe incluir al menos un símbolo especial';
    }
    return null;
  }

  Widget _buildRequirements(ColorScheme cs) {
    final p = _passwordController.text;
    final checks = <(bool, String)>[
      (p.length >= 8, 'Mínimo 8 caracteres'),
      (p.contains(RegExp(r'[A-Z]')), 'Una mayúscula'),
      (p.contains(RegExp(r'[a-z]')), 'Una minúscula'),
      (p.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]')),
          r'Un símbolo especial (!@#$%...)'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: checks.map((req) {
        final ok = req.$1;
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  ok
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  key: ValueKey(ok),
                  size: 14,
                  color: ok ? cs.primary : cs.error,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                req.$2,
                style: TextStyle(
                  fontSize: 12,
                  color: ok ? cs.primary : cs.error,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Lógica de negocio INTACTA — no modificar ──────────────────────────────

  void _registrar() async {
    if (_nombreController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Llena todos los campos')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.register(
      _nombreController.text,
      _apellidoController.text,
      _emailController.text,
      _passwordController.text,
    );

    if (exito) {
      await NotificationService().showImmediateNotification(
        id: 0,
        title: '¡Bienvenido a MOVIDA!',
        body: 'Tu cuenta fue creada exitosamente.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('¡Cuenta creada exitosamente! Bienvenido')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Ese correo ya está registrado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Helpers de UI ─────────────────────────────────────────────────────────

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
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.primary),
        suffixIcon: suffixIcon,
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

    final p = _passwordController.text;
    final allValid = p.length >= 8 &&
        p.contains(RegExp(r'[A-Z]')) &&
        p.contains(RegExp(r'[a-z]')) &&
        p.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: Text(
          'Registro de Alumno',
          style: TextStyle(color: cs.onSurface),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.secondaryContainer, cs.surface],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // ── Encabezado ───────────────────────────────────────────
                Text(
                  'Crear cuenta',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Completa tus datos para registrarte',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // ── Tarjeta glassmorphism ────────────────────────────────
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
                            _animNombre,
                            _buildField(
                              controller: _nombreController,
                              label: 'Nombre',
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _slideIn(
                            _animApellido,
                            _buildField(
                              controller: _apellidoController,
                              label: 'Apellidos',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: cs.primary,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRequirements(cs),
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
                    label: 'Crear Cuenta',
                    onPressed: allValid ? _registrar : null,
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
  final VoidCallback? onPressed;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEnabled = widget.onPressed != null;
    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isEnabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed!();
              }
            : null,
        onTapCancel:
            isEnabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.secondary, cs.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: cs.secondary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: cs.onSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
