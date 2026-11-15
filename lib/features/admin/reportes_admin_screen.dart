import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/priorix_theme.dart';
import '../../models/models.dart';

class ReportesAdminScreen extends StatefulWidget {
  const ReportesAdminScreen({super.key});

  @override
  State<ReportesAdminScreen> createState() => _ReportesAdminScreenState();
}

class _ReportesAdminScreenState extends State<ReportesAdminScreen> {
  ReporteResumenModel _resumen = const ReporteResumenModel();
  bool _cargando = true;
  String? _error;

  // Filtros
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  int? _nivelFiltro;
  String? _medicoFiltro;

  final _medicoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  @override
  void dispose() {
    _medicoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarReportes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final fi = _fechaInicio != null ? _fechaInicio!.toIso8601String().substring(0, 10) : null;
      final ff = _fechaFin != null ? _fechaFin!.toIso8601String().substring(0, 10) : null;

      final res = await ApiClient.instance.getReportes(
        fechaInicio: fi,
        fechaFin: ff,
        nivel: _nivelFiltro,
        medico: _medicoFiltro,
      );
      if (mounted) {
        setState(() {
          _resumen = res;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('Timeout')
              ? 'El servidor tardó más de lo esperado en generar las métricas. Verifica que el backend Spring Boot esté activo en el puerto 8080 y pulsa Reintentar.'
              : e.toString();
          _cargando = false;
        });
      }
    }
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PriorixColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Filtrar estadísticas',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 16),
              // Nivel
              DropdownButtonFormField<int?>(
                value: _nivelFiltro,
                decoration: const InputDecoration(labelText: 'Nivel de urgencia'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos los niveles')),
                  DropdownMenuItem(value: 1, child: Text('Nivel I · Rojo (Reanimación)')),
                  DropdownMenuItem(value: 2, child: Text('Nivel II · Naranja (Emergencia)')),
                  DropdownMenuItem(value: 3, child: Text('Nivel III · Amarillo (Urgencia)')),
                  DropdownMenuItem(value: 4, child: Text('Nivel IV · Azul (Prioritario)')),
                  DropdownMenuItem(value: 5, child: Text('Nivel V · Verde (No urgente)')),
                ],
                onChanged: (v) => setModalState(() => _nivelFiltro = v),
              ),
              const SizedBox(height: 12),
              // Médico
              TextField(
                controller: _medicoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Médico tratante',
                  hintText: 'Usuario o nombre del médico',
                  prefixIcon: Icon(Icons.medical_services_outlined, size: 20),
                ),
                onChanged: (v) => _medicoFiltro = v.trim().isEmpty ? null : v.trim(),
              ),
              const SizedBox(height: 16),
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _fechaInicio = null;
                          _fechaFin = null;
                          _nivelFiltro = null;
                          _medicoFiltro = null;
                          _medicoCtrl.clear();
                        });
                        Navigator.pop(ctx);
                        _cargarReportes();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PriorixColors.textSecondary,
                        side: const BorderSide(color: PriorixColors.border),
                      ),
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _cargarReportes();
                      },
                      child: const Text('Aplicar filtros'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriorixColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '‹ Atrás',
        ),
        title: const Text('Reportes y Estadísticas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: _abrirFiltros,
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filtros',
          ),
          IconButton(
            onPressed: _cargarReportes,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: PriorixColors.primaryBlue));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 50, color: PriorixColors.nivel1Rojo),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: PriorixColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargarReportes, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final totalTriajes = _resumen.totalTriajes > 0
        ? _resumen.totalTriajes
        : (_resumen.nivel1Rojo + _resumen.nivel2Naranja + _resumen.nivel3Amarillo + _resumen.nivel4Verde + _resumen.nivel5Azul);

    return RefreshIndicator(
      onRefresh: _cargarReportes,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Resumen Hospitalario', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              if (_nivelFiltro != null || _medicoFiltro != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: PriorixColors.primaryBlue.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text('Filtros activos', style: TextStyle(fontSize: 11, color: PriorixColors.primaryBlue, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Métricas 2x2
          Row(
            children: [
              Expanded(
                child: _cardMetrica(
                  'Triajes realizados',
                  '$totalTriajes',
                  Icons.assignment_outlined,
                  PriorixColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _cardMetrica(
                  'Atenciones médicas',
                  '${_resumen.totalAtenciones}',
                  Icons.medical_services_outlined,
                  PriorixColors.nivel5Verde,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _cardMetrica(
                  'Pacientes en espera',
                  '${_resumen.pacientesEnEspera}',
                  Icons.pending_actions_rounded,
                  PriorixColors.nivel2Naranja,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _cardMetrica(
                  'Pacientes totales',
                  '${_resumen.totalPacientes}',
                  Icons.person_outline_rounded,
                  PriorixColors.deepBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text('Atenciones por Nivel de Prioridad', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 6),
          const Text(
            'Distribución de atenciones clasificadas por urgencia (Resolución 5596 / Mánchester).',
            style: TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Orden oficial: 1 Rojo, 2 Naranja, 3 Amarillo, 4 Azul, 5 Verde
          _barraNivel('Nivel I · Reanimación', _resumen.nivel1Rojo, totalTriajes, PriorixColors.nivel1Rojo),
          const SizedBox(height: 10),
          _barraNivel('Nivel II · Emergencia', _resumen.nivel2Naranja, totalTriajes, PriorixColors.nivel2Naranja),
          const SizedBox(height: 10),
          _barraNivel('Nivel III · Urgencia', _resumen.nivel3Amarillo, totalTriajes, PriorixColors.nivel3Amarillo),
          const SizedBox(height: 10),
          _barraNivel('Nivel IV · Prioritario', _resumen.nivel5Azul, totalTriajes, PriorixColors.nivel4Azul),
          const SizedBox(height: 10),
          _barraNivel('Nivel V · No urgente', _resumen.nivel4Verde, totalTriajes, PriorixColors.nivel5Verde),

          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, color: PriorixColors.primaryBlue, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Información compartida y sincronizada en tiempo real con MongoDB mediante la API institucional de PRIORIX.',
                      style: TextStyle(color: PriorixColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardMetrica(String titulo, String valor, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.18),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barraNivel(String label, int cantidad, int total, Color color) {
    final porcentaje = total > 0 ? (cantidad / total) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Text(
                  '$cantidad (${(porcentaje * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: porcentaje.clamp(0.0, 1.0),
                backgroundColor: PriorixColors.cardSecondary,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
