import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/theme/priorix_theme.dart';
import '../../models/models.dart';
import 'historias_clinicas_screen.dart';

class AtencionMedicaScreen extends StatefulWidget {
  final AtencionModel? atencionInicial;

  const AtencionMedicaScreen({super.key, this.atencionInicial});

  @override
  State<AtencionMedicaScreen> createState() => _AtencionMedicaScreenState();
}

class _AtencionMedicaScreenState extends State<AtencionMedicaScreen> {
  final _formKey = GlobalKey<FormState>();

  AtencionModel? _atencionActual;
  List<AtencionModel> _atencionesEnProceso = [];
  bool _cargandoLista = false;
  bool _guardando = false;

  final _diagnosticoCtrl = TextEditingController();
  final _tratamientoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.atencionInicial != null) {
      _atencionActual = widget.atencionInicial;
      _poblarCampos(widget.atencionInicial!);
    } else {
      _cargarAtencionesEnProceso();
    }
  }

  @override
  void dispose() {
    _diagnosticoCtrl.dispose();
    _tratamientoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  void _poblarCampos(AtencionModel atencion) {
    _diagnosticoCtrl.text = atencion.diagnostico ?? '';
    _tratamientoCtrl.text = atencion.tratamiento ?? '';
    _observacionesCtrl.text = atencion.observaciones ?? '';
  }

  Future<void> _cargarAtencionesEnProceso() async {
    setState(() => _cargandoLista = true);
    try {
      final res = await ApiClient.instance.getAtencionesEnProceso();
      if (mounted) {
        setState(() {
          _atencionesEnProceso = res;
          _cargandoLista = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoLista = false);
    }
  }

  Future<void> _finalizarAtencion() async {
    if (_atencionActual == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      if (OfflineSyncService.instance.isOnline) {
        try {
          await ApiClient.instance.finalizarAtencion(
            _atencionActual!.id,
            diagnostico: _diagnosticoCtrl.text.trim(),
            tratamiento: _tratamientoCtrl.text.trim(),
            observaciones: _observacionesCtrl.text.trim(),
          );

          // Crear historia clínica desde la atención
          try {
            await ApiClient.instance.crearHistoriaDesdeAtencion(_atencionActual!.id);
          } catch (_) {}

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: PriorixColors.nivel5Verde,
                content: Text('Atención finalizada e Historia Clínica registrada con éxito.'),
              ),
            );
            Navigator.pop(context, true);
          }
          return;
        } catch (_) {}
      }

      // Offline fallback: guardar en SQLite cifrado
      await OfflineSyncService.instance.saveAtencionOffline(
        atencionId: _atencionActual!.id,
        diagnostico: _diagnosticoCtrl.text.trim(),
        tratamiento: _tratamientoCtrl.text.trim(),
        observaciones: _observacionesCtrl.text.trim(),
      );
      await OfflineSyncService.instance.saveHistoriaOffline(atencionId: _atencionActual!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: PriorixColors.nivel2Naranja,
            content: Text('Sin conexión · Atención guardada en el teléfono. Se sincronizará al volver la red.'),
          ),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _verHistoriaClinica() {
    if (_atencionActual == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoriasClinicasScreen(
          pacienteIdFiltro: _atencionActual!.pacienteId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_atencionActual == null) {
      return Scaffold(
        backgroundColor: PriorixColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '‹ Atrás',
          ),
          title: const Text('Atenciones Médicas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildListaAtenciones(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PriorixColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '‹ Atrás',
        ),
        title: Text(
          'Atención · ${_atencionActual!.pacienteNombre ?? "Paciente"}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'Ver historia clínica del paciente',
            icon: const Icon(Icons.folder_shared_outlined),
            onPressed: _verHistoriaClinica,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Resumen del Triaje y Datos del Paciente
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: PriorixColors.primaryBlue.withOpacity(0.18),
                            child: const Icon(Icons.person_rounded, color: PriorixColors.primaryBlue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _atencionActual!.pacienteNombre ?? 'Paciente',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                                if (_atencionActual!.pacienteDocumento != null)
                                  Text(
                                    'Doc: ${_atencionActual!.pacienteDocumento}',
                                    style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _verHistoriaClinica,
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: const Text('Historia'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PriorixColors.primaryBlue,
                              side: const BorderSide(color: PriorixColors.border),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      if (_atencionActual!.motivoConsulta != null && _atencionActual!.motivoConsulta!.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          'Motivo del triaje: ${_atencionActual!.motivoConsulta}',
                          style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Sección: Diagnóstico Médico
              const Text('Diagnóstico Médico *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _diagnosticoCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ej. Síndrome coronario agudo sin elevación del ST...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El diagnóstico es obligatorio' : null,
              ),

              const SizedBox(height: 18),

              // Sección: Tratamiento y Conducta
              const Text('Tratamiento y Plan *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tratamientoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Medicamentos, dosis, vía de administración e interconsultas...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El tratamiento es obligatorio' : null,
              ),

              const SizedBox(height: 18),

              // Sección: Observaciones
              const Text('Observaciones Clínicas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observacionesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Evolución, signos de alarma o recomendaciones...',
                ),
              ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _guardando ? null : _finalizarAtencion,
                icon: _guardando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF0F1B2D), strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_guardando ? 'GUARDANDO...' : 'GUARDAR ATENCIÓN E HISTORIA'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildListaAtenciones() {
    if (_cargandoLista) {
      return const Center(child: CircularProgressIndicator(color: PriorixColors.primaryBlue));
    }

    if (_atencionesEnProceso.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medical_services_outlined, size: 54, color: PriorixColors.textSecondary),
              SizedBox(height: 14),
              Text('No tienes atenciones en proceso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 6),
              Text('Selecciona un paciente en la Lista de espera para iniciar la atención.', style: TextStyle(color: PriorixColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _atencionesEnProceso.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = _atencionesEnProceso[index];
        return Card(
          child: ListTile(
            title: Text(a.pacienteNombre ?? 'Paciente', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Iniciada: ${a.fechaHoraInicio ?? "Hoy"}', style: const TextStyle(color: PriorixColors.textSecondary)),
            trailing: ElevatedButton(
              onPressed: () => setState(() {
                _atencionActual = a;
                _poblarCampos(a);
              }),
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 36)),
              child: const Text('Continuar'),
            ),
          ),
        );
      },
    );
  }
}
