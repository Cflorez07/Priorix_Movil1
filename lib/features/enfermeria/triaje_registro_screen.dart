import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/theme/priorix_theme.dart';
import '../../core/widgets/priorix_logo.dart';
import '../../models/models.dart';
import 'camara_triaje_screen.dart';

class TriajeRegistroScreen extends StatefulWidget {
  final String? pacienteIdPreseleccionado;

  const TriajeRegistroScreen({super.key, this.pacienteIdPreseleccionado});

  @override
  State<TriajeRegistroScreen> createState() => _TriajeRegistroScreenState();
}

class _TriajeRegistroScreenState extends State<TriajeRegistroScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();

  List<PacienteModel> _pacientes = [];
  PacienteModel? _pacienteSeleccionado;
  bool _cargandoPacientes = true;
  bool _guardando = false;

  final _sintomasCtrl = TextEditingController();
  final _fcCtrl = TextEditingController(text: '80');
  final _frCtrl = TextEditingController(text: '18');
  final _paCtrl = TextEditingController(text: '120/80');
  final _tempCtrl = TextEditingController(text: '36.5');
  final _spo2Ctrl = TextEditingController(text: '98');
  final _alergiasCtrl = TextEditingController();
  final _antecedentesCtrl = TextEditingController();

  int _dolor = 2;
  String _consciencia = 'Alerta';

  // Foto adjunta
  String? _fotoPath;
  String? _fotoBase64;

  final List<String> _opcionesConsciencia = [
    'Alerta',
    'Respuesta verbal',
    'Respuesta al dolor',
    'Inconsciente',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarPacientes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sintomasCtrl.dispose();
    _fcCtrl.dispose();
    _frCtrl.dispose();
    _paCtrl.dispose();
    _tempCtrl.dispose();
    _spo2Ctrl.dispose();
    _alergiasCtrl.dispose();
    _antecedentesCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Protección ante llamadas entrantes o segundo plano (Sección 7.4):
    // El estado del formulario se preserva automáticamente en memoria.
  }

  Future<void> _cargarPacientes() async {
    try {
      List<PacienteModel> res = [];
      if (OfflineSyncService.instance.isOnline) {
        try {
          res = await ApiClient.instance.getPacientes();
        } catch (_) {
          res = await OfflineSyncService.instance.getPacientesOffline();
        }
      } else {
        res = await OfflineSyncService.instance.getPacientesOffline();
      }

      if (mounted) {
        setState(() {
          _pacientes = res;
          if (widget.pacienteIdPreseleccionado != null) {
            final match = res.where((p) => p.id == widget.pacienteIdPreseleccionado);
            if (match.isNotEmpty) {
              _pacienteSeleccionado = match.first;
            }
          }
          if (_pacienteSeleccionado == null && _pacientes.isNotEmpty) {
            _pacienteSeleccionado = _pacientes.first;
          }
          _cargandoPacientes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoPacientes = false);
    }
  }

  // Regla multicriterio idéntica a Triaje.java / Triaje.prePersist()
  NivelTriaje get _nivelCalculado {
    final sat = int.tryParse(_spo2Ctrl.text) ?? 98;
    final temp = double.tryParse(_tempCtrl.text) ?? 36.5;
    final fc = int.tryParse(_fcCtrl.text) ?? 80;

    return TriajeModel.evaluarPrioridad(
      consciencia: _consciencia,
      saturacion: sat,
      temperatura: temp,
      frecuenciaCardiaca: fc,
      dolor: _dolor,
    );
  }

  bool _hayCambiosSinGuardar() {
    return _sintomasCtrl.text.isNotEmpty || _fotoPath != null || _dolor != 2;
  }

  Future<bool> _confirmarDescarte() async {
    if (!_hayCambiosSinGuardar()) return true;

    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PriorixColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PriorixColors.border),
        ),
        title: const Text('¿Descartar triaje en progreso?'),
        content: const Text(
          'Tienes datos ingresados en el formulario de triaje. Si sales ahora, se perderán.',
          style: TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: PriorixColors.nivel1Rojo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Descartar y salir'),
          ),
        ],
      ),
    );

    return salir ?? false;
  }

  Future<void> _abrirCamara() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const CamaraTriajeScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _fotoPath = result['path'];
        _fotoBase64 = result['base64'];
      });
    }
  }

  Future<void> _crearNuevoPacienteModal() async {
    final docCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    String tipoDoc = 'CC';
    String sexo = 'M';

    final nuevoPaciente = await showDialog<PacienteModel>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: PriorixColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: PriorixColors.border),
          ),
          title: const Text('Registrar nuevo paciente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 95,
                      child: DropdownButtonFormField<String>(
                        value: tipoDoc,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Tipo *',
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'CC', child: Text('CC')),
                          DropdownMenuItem(value: 'TI', child: Text('TI')),
                          DropdownMenuItem(value: 'CE', child: Text('CE')),
                          DropdownMenuItem(value: 'PAS', child: Text('PAS')),
                        ],
                        onChanged: (v) => setModalState(() => tipoDoc = v ?? 'CC'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: docCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Documento *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombres *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: apellidoCtrl,
                  decoration: const InputDecoration(labelText: 'Apellidos *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: sexo,
                  decoration: const InputDecoration(labelText: 'Sexo biológico *'),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Masculino')),
                    DropdownMenuItem(value: 'F', child: Text('Femenino')),
                  ],
                  onChanged: (v) => setModalState(() => sexo = v ?? 'M'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (docCtrl.text.trim().isEmpty || nombreCtrl.text.trim().isEmpty || apellidoCtrl.text.trim().isEmpty) {
                  return;
                }
                final p = PacienteModel(
                  id: const Uuid().v4(),
                  tipoDocumento: tipoDoc,
                  numeroDocumento: docCtrl.text.trim(),
                  nombre: nombreCtrl.text.trim(),
                  apellido: apellidoCtrl.text.trim(),
                  telefono: telCtrl.text.trim(),
                  sexo: sexo,
                );
                Navigator.pop(ctx, p);
              },
              style: FilledButton.styleFrom(
                backgroundColor: PriorixColors.primaryBlue,
                foregroundColor: const Color(0xFF0F1B2D),
              ),
              child: const Text('Guardar paciente'),
            ),
          ],
        ),
      ),
    );

    if (nuevoPaciente != null) {
      if (OfflineSyncService.instance.isOnline) {
        try {
          final guardado = await ApiClient.instance.crearPaciente(nuevoPaciente);
          setState(() {
            _pacientes.insert(0, guardado);
            _pacienteSeleccionado = guardado;
          });
        } catch (_) {
          await OfflineSyncService.instance.savePacienteOffline(nuevoPaciente);
          setState(() {
            _pacientes.insert(0, nuevoPaciente);
            _pacienteSeleccionado = nuevoPaciente;
          });
        }
      } else {
        await OfflineSyncService.instance.savePacienteOffline(nuevoPaciente);
        setState(() {
          _pacientes.insert(0, nuevoPaciente);
          _pacienteSeleccionado = nuevoPaciente;
        });
      }
    }
  }

  Future<void> _guardarTriaje() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pacienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona o registra un paciente.')),
      );
      return;
    }

    setState(() => _guardando = true);

    final nivel = _nivelCalculado;
    final triaje = TriajeModel(
      id: const Uuid().v4(),
      pacienteId: _pacienteSeleccionado!.id,
      pacienteNombre: _pacienteSeleccionado!.nombreCompleto,
      pacienteDocumento: _pacienteSeleccionado!.numeroDocumento,
      nivel: nivel,
      frecuenciaCardiaca: int.tryParse(_fcCtrl.text) ?? 80,
      frecuenciaRespiratoria: int.tryParse(_frCtrl.text) ?? 18,
      presionArterial: _paCtrl.text.trim(),
      temperatura: double.tryParse(_tempCtrl.text) ?? 36.5,
      saturacionOxigeno: int.tryParse(_spo2Ctrl.text) ?? 98,
      nivelDolor: _dolor,
      estadoConsciencia: _consciencia,
      sintomas: _sintomasCtrl.text.trim(),
      observaciones: 'Alergias: ${_alergiasCtrl.text.trim()} | Ant: ${_antecedentesCtrl.text.trim()}',
      fechaHora: DateTime.now().toIso8601String(),
    );

    try {
      if (OfflineSyncService.instance.isOnline) {
        try {
          await ApiClient.instance.crearTriaje(triaje);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: PriorixColors.colorPorNivel(nivel.nivel),
                content: Text('Triaje guardado exitosamente · Paciente en lista de espera (${nivel.titulo})'),
              ),
            );
            Navigator.pop(context, true);
          }
          return;
        } catch (_) {
          // Si falla la petición online, fallback inmediato a SQLite
        }
      }

      // Modo sin conexión: se guarda en SQLite cifrado
      await OfflineSyncService.instance.saveTriajeOffline(triaje, fotoBase64: _fotoBase64);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PriorixColors.nivel2Naranja,
            content: Text(
              'Sin conexión · Triaje guardado en el teléfono (${nivel.titulo}). Se enviará al volver la red.',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nivel = _nivelCalculado;
    final colorNivel = PriorixColors.colorPorNivel(nivel.nivel);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final salir = await _confirmarDescarte();
        if (salir && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: PriorixColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () async {
              final salir = await _confirmarDescarte();
              if (salir && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Atrás',
          ),
          title: const Text('Registrar Triaje', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        body: _cargandoPacientes
            ? const Center(child: CircularProgressIndicator(color: PriorixColors.primaryBlue))
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        children: [
                          // Banner de Prioridad Calculada en Vivo
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorNivel.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colorNivel, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorNivel,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        PriorixColors.nombreNivel(nivel.nivel),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: colorNivel,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Prioridad asignada automáticamente según signos clínicos y dolor.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: PriorixColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Sección 1: Selección de Paciente
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Paciente',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                      TextButton.icon(
                                        onPressed: _crearNuevoPacienteModal,
                                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                        label: const Text('Nuevo paciente'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: PriorixColors.primaryBlue,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<PacienteModel>(
                              value: _pacienteSeleccionado,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_search_rounded, size: 20),
                              ),
                              items: _pacientes.map((p) {
                                return DropdownMenuItem<PacienteModel>(
                                  value: p,
                                  child: Text(
                                    '${p.nombreCompleto} (${p.tipoDocumento} ${p.numeroDocumento})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (p) => setState(() => _pacienteSeleccionado = p),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sección 2: Signos Vitales
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Signos Vitales y Estado Clínico',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _fcCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'FC (lpm)',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _frCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'FR (rpm)',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _paCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'PA (mmHg)',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _tempCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Temp (°C)',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _spo2Ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'SpO₂ (%)',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _consciencia,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Consciencia',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    ),
                                    items: _opcionesConsciencia.map((c) {
                                      return DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) => setState(() => _consciencia = v ?? 'Alerta'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sección 3: Escala de Dolor (0 - 10)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Nivel de Dolor (EVA)',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                Text(
                                  '$_dolor / 10',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: colorNivel,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _dolor.toDouble(),
                              min: 0,
                              max: 10,
                              divisions: 10,
                              activeColor: colorNivel,
                              onChanged: (v) => setState(() => _dolor = v.round()),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sección 4: Síntomas y Fotografía
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Síntomas y Motivo de Consulta *',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _sintomasCtrl,
                              maxLines: 3,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Describe los síntomas del paciente' : null,
                              decoration: const InputDecoration(
                                hintText: 'Ej. Dolor torácico opresivo de 30 min de evolución...',
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Botón de Fotografía (CU-06)
                            if (_fotoPath == null)
                              OutlinedButton.icon(
                                onPressed: _abrirCamara,
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Adjuntar foto de la lesión (Cámara)'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  foregroundColor: PriorixColors.primaryBlue,
                                  side: const BorderSide(color: PriorixColors.border),
                                ),
                              )
                            else ...[
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_fotoPath!),
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Fotografía clínica adjunta',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: PriorixColors.nivel1Rojo),
                                    onPressed: () => setState(() {
                                      _fotoPath = null;
                                      _fotoBase64 = null;
                                    }),
                                    tooltip: 'Quitar foto',
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botón Guardar Triaje
                    ElevatedButton(
                      onPressed: _guardando ? null : _guardarTriaje,
                      child: _guardando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0F1B2D),
                              ),
                            )
                          : const Text('GUARDAR TRIAJE Y ASIGNAR A FILA'),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
