import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/services/biometric_service.dart';
import '../providers/auth_provider.dart';
import '../providers/ets_provider.dart';
import 'home_admin_page.dart';
import 'home_dashboard.dart';
import 'register_page.dart';

// 3 estados del botón biométrico en login
enum _BioBtnState { stateA, stateB, stateC }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.autoTriggerBiometric = false});
  final bool autoTriggerBiometric;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _enterCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _animLogo;
  late final Animation<double> _animEmail;
  late final Animation<double> _animPassword;
  late final Animation<double> _animButton;
  late final Animation<double> _animLinks;
  late final Animation<double> _animBio;
  late final Animation<double> _pulseAnim;

  bool _bioDeviceSupported = false;
  _BioBtnState _bioBtnState = _BioBtnState.stateA;
  bool _rememberCorreo = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _animLogo = _stagger(0.00, 0.45);
    _animEmail = _stagger(0.15, 0.60);
    _animPassword = _stagger(0.30, 0.75);
    _animButton = _stagger(0.45, 0.90);
    _animLinks = _stagger(0.60, 1.00);
    _animBio = _stagger(0.70, 1.00);

    _loadInitialData();
  }

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  Future<void> _loadInitialData() async {
    // 1. Cargar correo guardado
    final prefs = await SharedPreferences.getInstance();
    final savedCorreo = prefs.getString('last_user_correo');
    if (!mounted) return;
    if (savedCorreo != null) {
      _emailController.text = savedCorreo;
      setState(() => _rememberCorreo = true);
    }

    // 2. Detectar soporte biométrico
    final available = await BiometricService.isAvailable();
    if (!mounted) return;
    if (!available) return; // botón oculto si no hay hardware

    setState(() => _bioDeviceSupported = true);

    // 3. Determinar estado del botón — solo depende de isBiometricLinked()
    final linked = await BiometricService.isBiometricLinked();
    if (!mounted) return;
    if (linked) {
      setState(() => _bioBtnState = _BioBtnState.stateC);
    } else if (savedCorreo != null) {
      setState(() => _bioBtnState = _BioBtnState.stateB);
    } else {
      setState(() => _bioBtnState = _BioBtnState.stateA);
    }

    // 4. Auto-disparar si viene del splash con sesión activa
    if (widget.autoTriggerBiometric && linked) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _authenticateBiometric();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Lógica de negocio ─────────────────────────────────────────────────────

  Future<void> _intentarLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena ambos campos')),
      );
      return;
    }

    final correo = _emailController.text.trim();
    final password = _passwordController.text;

    // Capturar providers antes del primer await
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ets = Provider.of<EtsProvider>(context, listen: false);

    final exito = await auth.login(correo, password);
    if (!mounted) return;

    if (!exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Correo o contraseña incorrectos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ets.limpiarFiltros();

    // ADMIN: nunca guardar correo ni mostrar diálogo de huella
    if (auth.currentRole == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeAdminPage()),
      );
      return;
    }

    // ALUMNO: manejar "Recordar correo"
    final prefs = await SharedPreferences.getInstance();
    if (_rememberCorreo) {
      await prefs.setString('last_user_correo', correo);
    } else {
      await prefs.remove('last_user_correo');
    }
    if (!mounted) return;

    // Mostrar diálogo de vinculación de huella si aplica
    final bioAvailable = await BiometricService.isAvailable();
    final bioLinked = await BiometricService.isBiometricLinked();
    if (!mounted) return;

    if (bioAvailable && !bioLinked) {
      await _showBiometricLinkDialog(correo, password);
      if (!mounted) return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeDashboard()),
    );
  }

  Future<void> _authenticateBiometric() async {
    final authed = await BiometricService.authenticate();
    if (!mounted) return;
    if (!authed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autenticación fallida. Intenta con tu contraseña'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final creds = await BiometricService.getCredentials();
    if (creds == null || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ets = Provider.of<EtsProvider>(context, listen: false);
    final ok = await auth.login(creds['correo']!, creds['password']!);
    if (!mounted) return;

    if (!ok) {
      await BiometricService.clearCredentials();
      if (!mounted) return;
      setState(() => _bioBtnState = _BioBtnState.stateB);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Credenciales desactualizadas. Inicia sesión manualmente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Nunca permitir acceso biométrico de admin (por si acaso)
    if (auth.currentRole == 'admin') {
      await BiometricService.clearCredentials();
      if (!mounted) return;
      setState(() => _bioBtnState = _BioBtnState.stateB);
      return;
    }

    ets.limpiarFiltros();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeDashboard()),
    );
  }

  Future<void> _showBiometricLinkDialog(String correo, String password) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (context, _, _) =>
          _BiometricLinkDialog(correo: correo, password: password),
    );
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

  Widget _buildBioButton(ColorScheme cs) {
    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    switch (_bioBtnState) {
      case _BioBtnState.stateA:
        return OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                content: const Text(
                    'Inicia sesión al menos una vez y marca "Recordar correo"'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
          },
          icon: Icon(Icons.fingerprint,
              color: cs.onSurface.withValues(alpha: 0.4)),
          label: Text(
            'Debes iniciar sesión primero',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
          ),
          style: buttonStyle.copyWith(
            side: WidgetStatePropertyAll(
                BorderSide(color: cs.onSurface.withValues(alpha: 0.2))),
          ),
        );

      case _BioBtnState.stateB:
        return OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                content: const Text(
                    'Ve a Ajustes → Cuenta para vincular tu huella digital'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
          },
          icon: Icon(Icons.fingerprint,
              color: cs.primary.withValues(alpha: 0.6)),
          label: Text(
            'Vincula tu huella en Ajustes',
            style: TextStyle(color: cs.primary.withValues(alpha: 0.7)),
          ),
          style: buttonStyle.copyWith(
            backgroundColor:
                WidgetStatePropertyAll(cs.primary.withValues(alpha: 0.06)),
            side: WidgetStatePropertyAll(
                BorderSide(color: cs.primary.withValues(alpha: 0.4))),
          ),
        );

      case _BioBtnState.stateC:
        return OutlinedButton.icon(
          onPressed: _authenticateBiometric,
          icon: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Transform.scale(
              scale: _pulseAnim.value,
              child: Icon(Icons.fingerprint, color: cs.primary),
            ),
          ),
          label: Text(
            'Entrar con huella digital',
            style: TextStyle(color: cs.primary),
          ),
          style: buttonStyle.copyWith(
            side: WidgetStatePropertyAll(BorderSide(color: cs.primary)),
          ),
        );
    }
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
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
                          // Checkbox recordar correo
                          _slideIn(
                            _animPassword,
                            CheckboxListTile(
                              value: _rememberCorreo,
                              onChanged: (v) =>
                                  setState(() => _rememberCorreo = v ?? false),
                              title: Text(
                                'Recordar correo',
                                style: tt.bodyMedium
                                    ?.copyWith(color: cs.onSurface),
                              ),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              activeColor: cs.primary,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
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

                // ── Botón biométrico (3 estados, visible si el dispositivo lo soporta)
                if (_bioDeviceSupported)
                  _slideIn(
                    _animBio,
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildBioButton(cs),
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

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo post-login para vincular huella (solo alumno, solo si no vinculada)
// ─────────────────────────────────────────────────────────────────────────────

class _BiometricLinkDialog extends StatefulWidget {
  const _BiometricLinkDialog({required this.correo, required this.password});
  final String correo;
  final String password;

  @override
  State<_BiometricLinkDialog> createState() => _BiometricLinkDialogState();
}

class _BiometricLinkDialogState extends State<_BiometricLinkDialog> {
  bool _linking = false;

  Future<void> _activarHuella() async {
    setState(() => _linking = true);
    final authed = await BiometricService.authenticate();
    if (!mounted) return;
    if (!authed) {
      setState(() => _linking = false);
      Navigator.of(context).pop();
      return;
    }
    await BiometricService.saveCredentials(
      correo: widget.correo,
      password: widget.password,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content:
            const Text('¡Huella vinculada! La próxima vez entra con tu huella'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  Future<void> _ahoraNo() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('bio_asked_count') ?? 0) + 1;
    await prefs.setInt('bio_asked_count', count);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('¿Quieres entrar más rápido?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fingerprint, size: 72, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Activa el inicio de sesión con huella digital para entrar '
            'sin escribir tu contraseña la próxima vez.',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _linking ? null : _ahoraNo,
          style: TextButton.styleFrom(
            foregroundColor: cs.onSurface.withValues(alpha: 0.6),
          ),
          child: const Text('Ahora no'),
        ),
        FilledButton.icon(
          onPressed: _linking ? null : _activarHuella,
          icon: _linking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.fingerprint, size: 18),
          label: const Text('Activar huella'),
        ),
      ],
    );
  }
}
