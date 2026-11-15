import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/priorix_theme.dart';
import '../../core/widgets/priorix_logo.dart';
import '../../models/models.dart';
import '../admin/pacientes_admin_screen.dart';
import '../admin/reportes_admin_screen.dart';
import '../admin/usuarios_admin_screen.dart';
import '../auth/login_page.dart';
import '../enfermeria/mis_triajes_screen.dart';
import '../enfermeria/triaje_registro_screen.dart';
import '../medico/atencion_medica_screen.dart';
import '../medico/historias_clinicas_screen.dart';
import '../medico/lista_espera_screen.dart';
import '../perfil/perfil_screen.dart';

class RoleDashboard extends StatefulWidget {
  const RoleDashboard({
    super.key,
    required this.role,
    this.previewMode = false,
  });

  final String role;
  final bool previewMode;

  @override
  State<RoleDashboard> createState() => _RoleDashboardState();
}

class _RoleDashboardState extends State<RoleDashboard> {
  ReporteResumenModel _resumen = const ReporteResumenModel();
  bool _cargandoMetricas = false;

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  Future<void> _cargarMetricas() async {
    if (widget.previewMode || !OfflineSyncService.instance.isOnline) return;
    setState(() => _cargandoMetricas = true);
    try {
      final res = await ApiClient.instance.getReportes();
      if (mounted) {
        setState(() {
          _resumen = res;
          _cargandoMetricas = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoMetricas = false);
    }
  }

  void _navegarA(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _cargarMetricas());
  }

  Future<void> _cerrarSesion() async {
    final pending = OfflineSyncService.instance.pendingCount;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PriorixColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PriorixColors.border),
        ),
        title: const Text('¿Cerrar sesión?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se cerrará tu sesión institucional en este dispositivo.',
              style: TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
            ),
            if (pending > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C1618),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(color: PriorixColors.nivel2Naranja, width: 4),
                  ),
                ),
                child: Text(
                  'Atención: Tienes $pending registro(s) pendiente(s) de sincronizar en SQLite. No se perderán, pero permanecerán en este teléfono hasta que inicies sesión nuevamente con red.',
                  style: const TextStyle(fontSize: 12, color: PriorixColors.textPrimary),
                ),
              ),
            ],
          ],
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
    final session = SessionService.instance;

    return ListenableBuilder(
      listenable: OfflineSyncService.instance,
      builder: (context, _) {
        final isOnline = OfflineSyncService.instance.isOnline;
        final pending = OfflineSyncService.instance.pendingCount;

        return Scaffold(
          backgroundColor: PriorixColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const PriorixLogo(compact: true),
            actions: [
              // Indicador de conexión (Sección 5)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline
                      ? PriorixColors.onlineGreen.withOpacity(0.18)
                      : PriorixColors.offlineOrange.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isOnline ? PriorixColors.onlineGreen : PriorixColors.offlineOrange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? PriorixColors.onlineGreenLight : PriorixColors.offlineOrangeLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'En línea' : 'Sin conexión',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? PriorixColors.onlineGreenLight : PriorixColors.offlineOrangeLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de sincronización manual de pendientes
              if (pending > 0)
                IconButton(
                  tooltip: '$pending pendientes de sincronizar en SQLite',
                  onPressed: () => OfflineSyncService.instance.syncPendingData(),
                  icon: Badge(
                    label: Text('$pending'),
                    backgroundColor: PriorixColors.offlineOrange,
                    child: const Icon(Icons.cloud_upload_outlined, color: PriorixColors.offlineOrangeLight),
                  ),
                ),

              // Botón Mi Perfil
              IconButton(
                tooltip: 'Mi perfil profesional',
                icon: const Icon(Icons.account_circle_outlined, color: PriorixColors.primaryBlue),
                onPressed: () => _navegarA(const PerfilScreen()),
              ),

              // Botón Cerrar sesión
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout_rounded, color: PriorixColors.textSecondary),
                onPressed: _cerrarSesion,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: RefreshIndicator(
                  onRefresh: _cargarMetricas,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      // Saludo e Identidad del Rol
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenido/a, ${session.username ?? "Personal"}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: PriorixColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.role,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: PriorixColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _navegarA(const PerfilScreen()),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: PriorixColors.cardSecondary,
                              child: Text(
                                (session.username != null && session.username!.isNotEmpty)
                                    ? session.username!.substring(0, 1).toUpperCase()
                                    : 'PX',
                                style: const TextStyle(
                                  color: PriorixColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Módulos específicos según el rol (Sección 4)
                      if (widget.role.toLowerCase().contains('admin'))
                        ..._buildAdminModules()
                      else if (widget.role.toLowerCase().contains('enferm'))
                        ..._buildNurseModules()
                      else
                        ..._buildDoctorModules(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== MÓDULOS ADMINISTRADOR (3 MÓDULOS) ====================

  List<Widget> _buildAdminModules() {
    return [
      _buildModuleCard(
        title: 'Gestión de usuarios',
        subtitle: 'Administra cuentas de médicos, enfermeros y administradores.',
        icon: Icons.manage_accounts_outlined,
        color: PriorixColors.primaryBlue,
        badgeText: 'Cuentas activas',
        onTap: () => _navegarA(const UsuariosAdminScreen()),
      ),
      const SizedBox(height: 14),
      _buildModuleCard(
        title: 'Gestión de pacientes',
        subtitle: 'Búsqueda por documento, registro, edición y datos clínicos.',
        icon: Icons.personal_injury_outlined,
        color: PriorixColors.deepBlue,
        badgeText: 'Pacientes',
        onTap: () => _navegarA(const PacientesAdminScreen()),
      ),
      const SizedBox(height: 14),
      _buildModuleCard(
        title: 'Reportes y estadísticas',
        subtitle: 'Filtros por médico, fechas y nivel de urgencia. Espera media y totales.',
        icon: Icons.bar_chart_rounded,
        color: PriorixColors.nivel5Verde,
        badgeText: 'Consolidado',
        onTap: () => _navegarA(const ReportesAdminScreen()),
      ),
    ];
  }

  // ==================== MÓDULOS ENFERMERÍA (2 MÓDULOS) ====================

  List<Widget> _buildNurseModules() {
    return [
      _buildModuleCard(
        title: 'Registrar triaje',
        subtitle: 'Captura signos vitales, escala de dolor (0-10), fotos de lesiones y asigna nivel a la fila.',
        icon: Icons.add_chart_rounded,
        color: PriorixColors.primaryBlue,
        badgeText: 'Nuevo triaje',
        onTap: () => _navegarA(const TriajeRegistroScreen()),
      ),
      const SizedBox(height: 14),
      _buildModuleCard(
        title: 'Triajes registrados',
        subtitle: 'Consulta el historial de pacientes valorados en el turno de hoy.',
        icon: Icons.assignment_turned_in_outlined,
        color: PriorixColors.nivel5Verde,
        badgeText: 'Historial del día',
        onTap: () => _navegarA(const MisTriajesScreen()),
      ),
    ];
  }

  // ==================== MÓDULO MÉDICO (1 MÓDULO PRINCIPAL) ====================

  List<Widget> _buildDoctorModules() {
    return [
      _buildModuleCard(
        title: 'Lista de espera priorizada',
        subtitle: 'Pacientes clasificados de I a V. Inicia la atención clínica y consulta su historia.',
        icon: Icons.pending_actions_rounded,
        color: PriorixColors.nivel1Rojo,
        badgeText: 'Fila de urgencias',
        onTap: () => _navegarA(const ListaEsperaScreen()),
      ),
      const SizedBox(height: 14),
      _buildModuleCard(
        title: 'Atenciones en proceso',
        subtitle: 'Retoma diagnósticos, tratamientos e historias clínicas en curso.',
        icon: Icons.medical_services_outlined,
        color: PriorixColors.primaryBlue,
        badgeText: 'En consultorio',
        onTap: () => _navegarA(const AtencionMedicaScreen()),
      ),
      const SizedBox(height: 14),
      _buildModuleCard(
        title: 'Historias clínicas',
        subtitle: 'Consulta antecedentes y registros clínicos anteriores de pacientes.',
        icon: Icons.folder_shared_outlined,
        color: PriorixColors.deepBlue,
        badgeText: 'Expedientes',
        onTap: () => _navegarA(const HistoriasClinicasScreen()),
      ),
    ];
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: PriorixColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PriorixColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: PriorixColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
