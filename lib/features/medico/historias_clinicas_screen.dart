import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/theme/priorix_theme.dart';
import '../../models/models.dart';

class HistoriasClinicasScreen extends StatefulWidget {
  final String? pacienteIdFiltro;
  final String? pacienteNombreFiltro;

  const HistoriasClinicasScreen({
    super.key,
    this.pacienteIdFiltro,
    this.pacienteNombreFiltro,
  });

  @override
  State<HistoriasClinicasScreen> createState() => _HistoriasClinicasScreenState();
}

class _HistoriasClinicasScreenState extends State<HistoriasClinicasScreen> {
  final _searchCtrl = TextEditingController();
  List<PacienteModel> _pacientes = [];
  PacienteModel? _pacienteSeleccionado;
  List<HistoriaClinicaModel> _historias = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // 1. Cargar lista de pacientes para selector rápido
      List<PacienteModel> pacientes = [];
      if (OfflineSyncService.instance.isOnline) {
        try {
          pacientes = await ApiClient.instance.getPacientes();
        } catch (_) {
          pacientes = await OfflineSyncService.instance.getPacientesOffline();
        }
      } else {
        pacientes = await OfflineSyncService.instance.getPacientesOffline();
      }

      _pacientes = pacientes;

      // 2. Determinar paciente a consultar
      if (widget.pacienteIdFiltro != null && widget.pacienteIdFiltro!.isNotEmpty) {
        _pacienteSeleccionado = pacientes.firstWhere(
          (p) => p.id == widget.pacienteIdFiltro,
          orElse: () => PacienteModel(
            id: widget.pacienteIdFiltro!,
            tipoDocumento: 'CC',
            numeroDocumento: '',
            nombre: widget.pacienteNombreFiltro ?? 'Paciente seleccionado',
            apellido: '',
          ),
        );
      } else if (pacientes.isNotEmpty) {
        // Seleccionamos el primer paciente disponible por defecto
        _pacienteSeleccionado = pacientes.first;
      }

      // 3. Cargar historias del paciente seleccionado (o generales)
      await _cargarHistorias(pacienteId: _pacienteSeleccionado?.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar las historias clínicas: $e';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _cargarHistorias({String? pacienteId}) async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final res = await ApiClient.instance.getHistorias(pacienteId: pacienteId ?? _pacienteSeleccionado?.id);
      if (mounted) {
        setState(() {
          _historias = res;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ocurrió un error al consultar las historias. Intente de nuevo.';
          _cargando = false;
        });
      }
    }
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
        title: const Text('Historias Clínicas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () => _cargarHistorias(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Selector de paciente (cuando no viene pre-filtrado)
                if (widget.pacienteIdFiltro == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Card(
                      color: PriorixColors.cardSecondary,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PacienteModel>(
                            value: _pacienteSeleccionado,
                            isExpanded: true,
                            hint: const Text('Seleccionar paciente...', style: TextStyle(color: PriorixColors.textSecondary, fontSize: 14)),
                            dropdownColor: PriorixColors.card,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: PriorixColors.primaryBlue),
                            items: _pacientes.map((p) {
                              return DropdownMenuItem<PacienteModel>(
                                value: p,
                                child: Text(
                                  '${p.nombreCompleto} (${p.tipoDocumento} ${p.numeroDocumento})',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (p) {
                              if (p != null) {
                                setState(() => _pacienteSeleccionado = p);
                                _cargarHistorias(pacienteId: p.id);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                Expanded(child: _buildBody()),
              ],
            ),
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
              const Icon(Icons.cloud_off_rounded, size: 48, color: PriorixColors.nivel1Rojo),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: PriorixColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _inicializar(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_historias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open_rounded, size: 54, color: PriorixColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                _pacienteSeleccionado != null
                    ? 'Sin historias para ${_pacienteSeleccionado!.nombreCompleto}'
                    : 'No se encontraron historias clínicas',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Las historias clínicas se generan automáticamente al finalizar la atención médica de un paciente en lista de espera.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _historias.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final h = _historias[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        h.pacienteNombre ?? _pacienteSeleccionado?.nombreCompleto ?? 'Paciente',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      h.fechaRegistro,
                      style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                if (h.medicoNombre != null && h.medicoNombre!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Médico: ${h.medicoNombre}', style: const TextStyle(color: PriorixColors.primaryBlue, fontSize: 13)),
                ],
                const Divider(height: 20),
                if (h.diagnostico.isNotEmpty) ...[
                  const Text('Diagnóstico:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(h.diagnostico, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                ],
                if (h.tratamiento.isNotEmpty) ...[
                  const Text('Tratamiento prescrito:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(h.tratamiento, style: const TextStyle(fontSize: 13, color: PriorixColors.textSecondary)),
                ],
                if (h.antecedentes != null && h.antecedentes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Antecedentes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(h.antecedentes!, style: const TextStyle(fontSize: 13, color: PriorixColors.textSecondary)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
