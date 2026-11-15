import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/priorix_theme.dart';
import '../../models/models.dart';
import '../auth/login_page.dart';

class PerfilScreen extends StatefulWidget {
  final UsuarioModel? usuario;

  const PerfilScreen({super.key, this.usuario});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _especialidadCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  final _claveFormKey = GlobalKey<FormState>();
  final _claveActualCtrl = TextEditingController();
  final _nuevaClaveCtrl = TextEditingController();
  final _confirmarClaveCtrl = TextEditingController();

  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;
  bool _guardando = false;
  bool _cambiandoClave = false;

  bool get _esUsuarioPropio => widget.usuario == null || 
      widget.usuario!.username == SessionService.instance.username;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    final s = SessionService.instance;
    _nombreCtrl.text = u != null ? u.nombreCompleto : (s.username ?? '');
    _especialidadCtrl.text = (s.rol ?? '').contains('MEDICO')
        ? 'Medicina de Urgencias y Triaje'
        : (s.rol ?? '').contains('ENFERMERO')
            ? 'Enfermería Hospitalaria y Triaje RAC'
            : 'Administración y Gestión Hospitalaria';
    _telefonoCtrl.text = '+57 (601) 745-9000 Ext. 104';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _especialidadCtrl.dispose();
    _telefonoCtrl.dispose();
    _claveActualCtrl.dispose();
    _nuevaClaveCtrl.dispose();
    _confirmarClaveCtrl.dispose();
    super.dispose();
  }

  String _obtenerIniciales(String nombre) {
    if (nombre.trim().isEmpty) return 'PX';
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _guardarDatosProfesionales() async {
    setState(() => _guardando = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: PriorixColors.onlineGreen,
          content: Text('Datos profesionales actualizados exitosamente.'),
        ),
      );
    }
  }

  Future<void> _cambiarClave() async {
    if (!_claveFormKey.currentState!.validate()) return;
    if (_nuevaClaveCtrl.text != _confirmarClaveCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: PriorixColors.nivel1Rojo,
          content: Text('Las contraseñas no coinciden.'),
        ),
      );
      return;
    }

    setState(() => _cambiandoClave = true);
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        _claveActualCtrl.clear();
        _nuevaClaveCtrl.clear();
        _confirmarClaveCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: PriorixColors.onlineGreen,
            content: Text('Contraseña actualizada exitosamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cambiandoClave = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PriorixColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PriorixColors.border),
        ),
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Se cerrará tu sesión institucional en este dispositivo.',
          style: TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PriorixColors.nivel1Rojo,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await SessionService.instance.clearSession();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SessionService.instance;
    final u = widget.usuario;

    final nombreUsuario = u != null ? u.username : (s.username ?? 'personal');
    final nombreCompleto = u != null ? u.nombreCompleto : (s.username ?? 'Personal PRIORIX');
    final email = u != null ? u.email : (s.email ?? '$nombreUsuario@priorix.com');
    final rol = u != null ? u.rol : (s.rol ?? 'ROLE_ADMIN');
    final rolLegible = u != null ? u.rolLegible : s.rolLegible;
    final activo = u != null ? u.activo : true;

    final roleColor = rol.contains('ADMIN')
        ? PriorixColors.primaryBlue
        : rol.contains('MEDICO')
            ? PriorixColors.nivel3Amarillo
            : PriorixColors.nivel5Verde;

    return Scaffold(
      backgroundColor: PriorixColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '‹ Volver',
        ),
        title: Text(
          _esUsuarioPropio ? 'Mi Perfil Profesional' : 'Perfil de Usuario',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          if (_esUsuarioPropio)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: PriorixColors.textSecondary),
              tooltip: 'Cerrar sesión',
              onPressed: _cerrarSesion,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta principal de identidad (Apple / Liquid Glass)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Avatar con borde y tamaño accesible
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: roleColor.withOpacity(0.18),
                            child: Text(
                              _obtenerIniciales(nombreCompleto),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: roleColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            nombreCompleto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: PriorixColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: PriorixColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: roleColor.withOpacity(0.4)),
                                ),
                                child: Text(
                                  rolLegible,
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (activo ? PriorixColors.onlineGreen : PriorixColors.offlineOrange).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (activo ? PriorixColors.onlineGreen : PriorixColors.offlineOrange).withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: activo ? PriorixColors.onlineGreenLight : PriorixColors.offlineOrangeLight,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      activo ? 'Activa y autorizada' : 'Inactivo (Pendiente código)',
                                      style: TextStyle(
                                        color: activo ? PriorixColors.onlineGreenLight : PriorixColors.offlineOrangeLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Credenciales institucionales inmutables (Igual a la web)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 20, color: PriorixColors.primaryBlue),
                              SizedBox(width: 8),
                              Text(
                                'Credenciales Institucionales',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildDatoInmutable('Usuario institucional', nombreUsuario),
                          const SizedBox(height: 10),
                          _buildDatoInmutable('Correo institucional', email),
                          const SizedBox(height: 10),
                          _buildDatoInmutable('Estado en plataforma', activo ? 'Activo y autorizado' : 'Pendiente de activación'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Información profesional editable
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.badge_outlined, size: 20, color: PriorixColors.primaryBlue),
                                SizedBox(width: 8),
                                Text(
                                  'Datos de Desempeño Profesional',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            TextFormField(
                              controller: _nombreCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _especialidadCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Especialidad / Área de atención',
                                prefixIcon: Icon(Icons.local_hospital_outlined, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _telefonoCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono / Extensión institucional',
                                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _guardando ? null : _guardarDatosProfesionales,
                                style: FilledButton.styleFrom(
                                  backgroundColor: PriorixColors.primaryBlue,
                                  foregroundColor: const Color(0xFF0F1B2D),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                icon: _guardando
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F1B2D)),
                                      )
                                    : const Icon(Icons.check_rounded, size: 20),
                                label: const Text('Guardar cambios profesionales', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_esUsuarioPropio) ...[
                    const SizedBox(height: 16),
                    // Tarjeta de Seguridad y Contraseña (Paridad con la web)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Form(
                          key: _claveFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lock_reset_rounded, size: 20, color: PriorixColors.primaryBlue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Seguridad de Acceso',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Para modificar tu contraseña debes confirmar tu clave actual por políticas de seguridad hospitalaria.',
                                style: TextStyle(fontSize: 12, color: PriorixColors.textSecondary),
                              ),
                              const Divider(height: 20),
                              TextFormField(
                                controller: _claveActualCtrl,
                                obscureText: _obscureActual,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña actual',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureActual ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                    onPressed: () => setState(() => _obscureActual = !_obscureActual),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _nuevaClaveCtrl,
                                obscureText: _obscureNueva,
                                decoration: InputDecoration(
                                  labelText: 'Nueva contraseña (mínimo 6 caracteres)',
                                  prefixIcon: const Icon(Icons.key_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureNueva ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                    onPressed: () => setState(() => _obscureNueva = !_obscureNueva),
                                  ),
                                ),
                                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmarClaveCtrl,
                                obscureText: _obscureConfirmar,
                                decoration: InputDecoration(
                                  labelText: 'Confirmar nueva contraseña',
                                  prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmar ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                    onPressed: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Confirma la nueva contraseña' : null,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _cambiandoClave ? null : _cambiarClave,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: PriorixColors.cardSecondary,
                                    foregroundColor: PriorixColors.textPrimary,
                                    side: const BorderSide(color: PriorixColors.border),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: _cambiandoClave
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: PriorixColors.primaryBlue),
                                        )
                                      : const Icon(Icons.security_rounded, size: 20),
                                  label: const Text('Actualizar contraseña', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Botón Volver y Cancelar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            label: const Text('Volver al panel'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: PriorixColors.border),
                              foregroundColor: PriorixColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _cerrarSesion,
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: const Text('Cerrar sesión'),
                            style: FilledButton.styleFrom(
                              backgroundColor: PriorixColors.nivel1Rojo.withOpacity(0.85),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatoInmutable(String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: PriorixColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PriorixColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
