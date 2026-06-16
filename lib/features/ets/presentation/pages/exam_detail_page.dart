import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/launcher_service.dart';
import '../../../../../core/services/notification_service.dart';
import '../../../../../core/utils/error_handler.dart';
import '../../domain/entities/ets_exam.dart';
import '../providers/auth_provider.dart';
import '../providers/ets_provider.dart';
import 'login_page.dart';

class ExamDetailPage extends StatefulWidget {
  const ExamDetailPage({super.key, required this.exam});
  final EtsExam exam;

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final List<Animation<double>> _rowAnims;
  late final Animation<double> _animButton;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    // 7 filas escalonadas
    _rowAnims = List.generate(7, (i) {
      final start = i * 0.08;
      return CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(start, (start + 0.40).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic),
      );
    });
    _animButton = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.60, 1.00, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  // ── Parser de fecha (formato "15-junio-2026") ──────────────────────────────

  static const _meses = {
    'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4,
    'mayo': 5, 'junio': 6, 'julio': 7, 'agosto': 8,
    'septiembre': 9, 'octubre': 10, 'noviembre': 11, 'diciembre': 12,
  };

  DateTime _parseFecha(String s) {
    try {
      final p = s.toLowerCase().split('-');
      return DateTime(
        p.length == 3 ? int.parse(p[2]) : 2026,
        _meses[p[1]] ?? 6,
        int.parse(p[0]),
      );
    } catch (_) {
      return DateTime(2026, 6, 1);
    }
  }

  // ── Helpers de UI ─────────────────────────────────────────────────────────

  Widget _slideRow(Animation<double> anim, Widget child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.15, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      );

  Widget _detailRow({
    required String label,
    required String value,
    required IconData icon,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _turnoRow(String turno, ColorScheme cs, TextTheme tt) {
    final isMatutino = turno.toLowerCase().contains('matutino');
    final chipBg =
        isMatutino ? cs.secondaryContainer : cs.tertiaryContainer;
    final chipFg =
        isMatutino ? cs.onSecondaryContainer : cs.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Text(
              'Turno',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Chip(
            label: Text(
              turno,
              style: tt.labelMedium?.copyWith(
                color: chipFg,
                fontWeight: FontWeight.bold,
              ),
            ),
            avatar: Icon(
              isMatutino ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
              size: 14,
              color: chipFg,
            ),
            backgroundColor: chipBg,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // ── Lógica de negocio INTACTA ──────────────────────────────────────────────

  Widget _buildActionButton(
    bool esInvitado,
    bool yaEstaGuardado,
    EtsProvider etsProv,
    AuthProvider auth,
    ColorScheme cs,
  ) {
    if (esInvitado) {
      return _ActionButton(
        icon: Icons.login_rounded,
        label: 'Iniciar sesión para guardar',
        gradient: false,
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        ),
      );
    }

    if (yaEstaGuardado) {
      return _ActionButton(
        icon: Icons.bookmark_remove_rounded,
        label: 'Quitar de mi calendario',
        isDestructive: true,
        onPressed: () async {
          try {
            await etsProv.eliminarExamInterno(
              auth.currentEmail!,
              widget.exam.materia,
            );
            await NotificationService()
                .cancelNotification(widget.exam.materia.hashCode);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Eliminado de tu calendario interno'),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    }

    if (!widget.exam.visible) return const SizedBox.shrink();

    return _ActionButton(
      icon: Icons.bookmark_add_rounded,
      label: 'Guardar en mi calendario',
      gradient: true,
      onPressed: () async {
        try {
          await etsProv.guardarExamInterno(
            auth.currentEmail!,
            widget.exam.materia,
          );
          await NotificationService().scheduleExamNotification(
            id: widget.exam.materia.hashCode,
            examName: widget.exam.materia,
            examDate: _parseFecha(widget.exam.fecha),
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Examen guardado. Te recordaremos 1 día antes'),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final etsProv = Provider.of<EtsProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final esInvitado = auth.currentRole == null;
    final yaEstaGuardado = etsProv.estaGuardado(widget.exam.materia);

    final rows = [
      (label: 'Materia', value: widget.exam.materia, icon: Icons.menu_book_rounded),
      (label: 'Carrera', value: widget.exam.carrera, icon: Icons.school_rounded),
      (label: 'Semestre', value: widget.exam.semestre.toString(), icon: Icons.layers_rounded),
      (label: 'Fecha', value: widget.exam.fecha, icon: Icons.calendar_today_rounded),
      (label: 'Salón', value: widget.exam.salon, icon: Icons.room_rounded),
      (label: 'Profesor', value: widget.exam.profesor, icon: Icons.person_outline_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exam.materia,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primaryContainer, cs.surface],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Banner examen oculto ───────────────────────────────────
              if (yaEstaGuardado && !widget.exam.visible)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.amber.shade800),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Este examen ya no está disponible en la oferta actual',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Tarjeta glassmorphism ──────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 6 filas normales con animación escalonada
                        for (var i = 0; i < rows.length; i++) ...[
                          _slideRow(
                            _rowAnims[i],
                            _detailRow(
                              label: rows[i].label,
                              value: rows[i].value,
                              icon: rows[i].icon,
                              cs: cs,
                              tt: tt,
                            ),
                          ),
                          if (i < rows.length - 1)
                            Divider(
                              height: 1,
                              color: cs.outlineVariant.withValues(alpha: 0.4),
                            ),
                        ],
                        // Fila de turno con chip (índice 6)
                        Divider(
                          height: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                        _slideRow(
                          _rowAnims[6],
                          _turnoRow(widget.exam.turno, cs, tt),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Botones de acción ──────────────────────────────────────
              FadeTransition(
                opacity: _animButton,
                child: ScaleTransition(
                  scale: _animButton,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ActionButton(
                        icon: Icons.directions_rounded,
                        label: 'Cómo llegar al salón',
                        onPressed: () async {
                          final salon = widget.exam.salon;
                          if (salon.isEmpty ||
                              salon.toLowerCase().contains('por asignar')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'El salón aún no ha sido asignado. '
                                  'Se mostrará la ubicación de ESCOM',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                          await LauncherService.openSalonRoute(
                            context,
                            salon,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Se abrirá OpenStreetMap con la ruta a ESCOM',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ActionButton(
                        icon: Icons.mail_outline_rounded,
                        label: 'Contactar soporte',
                        onPressed: () async {
                          try {
                            await LauncherService.openSupport(
                              subject:
                                  'Consulta sobre ETS: ${widget.exam.materia}',
                              body: 'Hola, tengo una consulta sobre el ETS de '
                                  '${widget.exam.materia} programado para '
                                  '${widget.exam.fecha}.\n\n',
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ErrorHandler.show(context, e);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        esInvitado,
                        yaEstaGuardado,
                        etsProv,
                        auth,
                        cs,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Botón de acción con ícono animado (bookmark fill/unfill) ─────────────────

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.gradient = false,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool gradient;
  final bool isDestructive;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    BoxDecoration decoration;
    Color fgColor;

    if (widget.isDestructive) {
      decoration = BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.error.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
      fgColor = cs.onErrorContainer;
    } else if (widget.gradient) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      );
      fgColor = cs.onPrimary;
    } else {
      decoration = BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
      );
      fgColor = cs.onSurface.withValues(alpha: 0.7);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: decoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  widget.icon,
                  key: ValueKey(widget.icon),
                  color: fgColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
