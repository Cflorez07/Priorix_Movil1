import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/api_client.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/theme/priorix_theme.dart';
import '../../models/models.dart';

class EmergenciaNnScreen extends StatefulWidget {
  const EmergenciaNnScreen({super.key});

  @override
  State<EmergenciaNnScreen> createState() => _EmergenciaNnScreenState();
}

class _EmergenciaNnScreenState extends State<EmergenciaNnScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _descCtrl = TextEditingController();
  final _origenCtrl = TextEditingController();
  String _tipo = 'VIVO';
  bool _enviando = false;

  List<EmergenciaModel> _pendientes = [];
  bool _cargandoPendientes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarPendientes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descCtrl.dispose();
    _origenCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPendientes() async {
    setState(() => _cargandoPendientes = true);
    try {
      List<EmergenciaModel> res = [];
      if (OfflineSyncService.instance.isOnline) {
        try {
          res = await ApiClient.instance.getEmergenciasPendientes();
        } catch (_) {
          res = await OfflineSyncService.instance.getEmergenciasOffline();
        }
      } else {
        res = await OfflineSyncService.instance.getEmergenciasOffline();
      }

      if (mounted) {
        setState(() {
          _pendientes = res;
          _cargandoPendientes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoPendientes = false);
    }
  }

  Future<void> _registrarEmergencia() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una breve descripción del estado del paciente.')),
      );
      return;
    }

    setState(() => _enviando = true);

    final em = EmergenciaModel(
      id: const Uuid().v4(),
      tipo: _tipo,
      descripcion: '${_descCtrl.text.trim()} ${_origenCtrl.text.trim().isNotEmpty ? "· Procedencia: ${_origenCtrl.text.trim()}" : ""}',
      estado: 'PENDIENTE',
      fechaHora: DateTime.now().toIso8601String(),
    );

    try {
      if (OfflineSyncService.instance.isOnline) {
        try {
          await ApiClient.instance.crearEmergencia(em);
        } catch (_) {
          await OfflineSyncService.instance.saveEmergenciaOffline(em);
        }
      } else {
        await OfflineSyncService.instance.saveEmergenciaOffline(em);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: PriorixColors.nivel1Rojo,
            content: Text('¡INGRESO CRÍTICO ACTIVADO! Paciente N.N. derivado a Lista de Espera con prioridad.'),
          ),
        );
        _descCtrl.clear();
        _origenCtrl.clear();
        _cargarPendientes();
        _tabController.animateTo(1);
      }
    } catch (e) {
      await OfflineSyncService.instance.saveEmergenciaOffline(em);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PriorixColors.nivel2Naranja,
            content: Text('Ingreso guardado en el teléfono ($e). Prioridad activa.'),
          ),
        );
        _tabController.animateTo(1);
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '‹ Atrás',
        ),
        title: const Text('Atención Inmediata · Emergencias', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PriorixColors.nivel1Rojo,
          tabs: const [
            Tab(icon: Icon(Icons.emergency), text: 'Ingreso Rápido'),
            Tab(icon: Icon(Icons.person_search), text: 'Pacientes NN'),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormIngreso(),
                _buildListaNN(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormIngreso() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PriorixColors.nivel1Rojo.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PriorixColors.nivel1Rojo),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: PriorixColors.nivel1Rojo, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'PROTOCOLO CRÍTICO:\nLa falta de datos administrativos o identificación NO bloqueará la atención médica inmediata.',
                  style: TextStyle(color: PriorixColors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Estado del paciente crítico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'VIVO', label: Text('Paciente Vivo (Crítico)')),
            ButtonSegment(value: 'FALLECIDO', label: Text('Ingreso Fallecido')),
          ],
          selected: {_tipo},
          onSelectionChanged: (val) => setState(() => _tipo = val.first),
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: _descCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Descripción clínica inmediata',
            hintText: 'Ej. Masculino aprox 35 años, politraumatismo severo, inconsciente en camilla...',
          ),
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: _origenCtrl,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.local_shipping_outlined),
            labelText: 'Móvil de ambulancia / Ubicación de rescate',
            hintText: 'Ej. Ambulancia SAMU #12 / Carrera 10 con 26',
          ),
        ),

        const SizedBox(height: 26),

        ElevatedButton.icon(
          onPressed: _enviando ? null : _registrarEmergencia,
          style: ElevatedButton.styleFrom(
            backgroundColor: PriorixColors.red,
            minimumSize: const Size.fromHeight(54),
          ),
          icon: _enviando
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.bolt_rounded),
          label: Text(
            _enviando ? 'PROCESANDO...' : 'ACTIVAR INGRESO INMEDIATO A TRIAJE',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildListaNN() {
    if (_cargandoPendientes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendientes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle_outline, size: 52, color: PriorixColors.green),
              SizedBox(height: 12),
              Text('No hay pacientes N.N. pendientes de identificar.', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Todos los ingresos críticos cuentan con identidad confirmada.', style: TextStyle(color: PriorixColors.muted)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendientes.length,
      itemBuilder: (context, index) {
        final em = _pendientes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: PriorixColors.nivel1Rojo.withOpacity(0.2),
              child: const Icon(Icons.person_search, color: PriorixColors.nivel1Rojo),
            ),
            title: Text('Paciente N.N. #${em.id.substring(0, em.id.length > 8 ? 8 : em.id.length)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(em.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (em.fechaHora != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(em.fechaHora!.split('T').first, style: const TextStyle(color: PriorixColors.muted, fontSize: 12)),
                  ),
              ],
            ),
            trailing: FilledButton.tonal(
              onPressed: () => _dialogIdentificar(em),
              child: const Text('Identificar'),
            ),
          ),
        );
      },
    );
  }

  void _dialogIdentificar(EmergenciaModel em) async {
    final docCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final apeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Identificar Paciente N.N.'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa los datos identificados del paciente para vincular su historia clínica:'),
            const SizedBox(height: 12),
            TextField(controller: docCtrl, decoration: const InputDecoration(labelText: 'Documento de identidad')),
            const SizedBox(height: 8),
            TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nombres')),
            const SizedBox(height: 8),
            TextField(controller: apeCtrl, decoration: const InputDecoration(labelText: 'Apellidos')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (docCtrl.text.trim().isEmpty || nomCtrl.text.trim().isEmpty) return;
              try {
                final nuevoP = await ApiClient.instance.crearPaciente(
                  PacienteModel(
                    id: const Uuid().v4(),
                    tipoDocumento: 'CC',
                    numeroDocumento: docCtrl.text.trim(),
                    nombre: nomCtrl.text.trim(),
                    apellido: apeCtrl.text.trim(),
                  ),
                );
                await ApiClient.instance.identificarEmergencia(em.id, nuevoP.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _cargarPendientes();
              } catch (_) {
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
  }
}
