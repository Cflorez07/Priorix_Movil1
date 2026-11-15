import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/api_client.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/theme/priorix_theme.dart';
import '../../models/models.dart';

class PacientesAdminScreen extends StatefulWidget {
  const PacientesAdminScreen({super.key});

  @override
  State<PacientesAdminScreen> createState() => _PacientesAdminScreenState();
}

class _PacientesAdminScreenState extends State<PacientesAdminScreen> {
  final _searchCtrl = TextEditingController();
  List<PacienteModel> _pacientes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPacientes({String? query}) async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      List<PacienteModel> res = [];
      if (OfflineSyncService.instance.isOnline) {
        try {
          res = await ApiClient.instance.getPacientes(q: query);
        } catch (_) {
          res = await OfflineSyncService.instance.getPacientesOffline();
        }
      } else {
        res = await OfflineSyncService.instance.getPacientesOffline();
      }

      if (mounted) {
        setState(() {
          _pacientes = res;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Future<void> _guardarPaciente({PacienteModel? existente}) async {
    final formKey = GlobalKey<FormState>();
    String tipoDoc = existente?.tipoDocumento ?? 'CC';
    String sexo = existente?.sexo ?? 'M';
    final docCtrl = TextEditingController(text: existente?.numeroDocumento ?? '');
    final nomCtrl = TextEditingController(text: existente?.nombre ?? '');
    final apeCtrl = TextEditingController(text: existente?.apellido ?? '');
    final telCtrl = TextEditingController(text: existente?.telefono ?? '');
    final fechaNacCtrl = TextEditingController(text: existente?.fechaNacimiento ?? '');
    final dirCtrl = TextEditingController(text: existente?.direccion ?? '');
    final epsCtrl = TextEditingController(text: existente?.eps ?? '');
    final contactoCtrl = TextEditingController(text: existente?.contactoEmergencia ?? '');
    final telContactoCtrl = TextEditingController(text: existente?.telefonoEmergencia ?? '');

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: PriorixColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: PriorixColors.border),
          ),
          title: Text(
            existente == null ? 'Registrar paciente' : 'Editar paciente',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
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
                          onChanged: (val) {
                            if (val != null) setDlgState(() => tipoDoc = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: docCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Documento *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(labelText: 'Nombres *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: apeCtrl,
                    decoration: const InputDecoration(labelText: 'Apellidos *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: telCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Teléfono'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: sexo,
                          decoration: const InputDecoration(labelText: 'Sexo *'),
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('Masculino')),
                            DropdownMenuItem(value: 'F', child: Text('Femenino')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDlgState(() => sexo = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: fechaNacCtrl,
                          decoration: const InputDecoration(labelText: 'F. Nac (YYYY-MM-DD)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: epsCtrl,
                          decoration: const InputDecoration(labelText: 'EPS'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: dirCtrl,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: contactoCtrl,
                    decoration: const InputDecoration(labelText: 'Contacto emergencia'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: telContactoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono contacto'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final p = PacienteModel(
                    id: existente?.id ?? const Uuid().v4(),
                    tipoDocumento: tipoDoc,
                    documento: docCtrl.text.trim(),
                    nombre: nomCtrl.text.trim(),
                    apellido: apeCtrl.text.trim(),
                    telefono: telCtrl.text.trim(),
                    fechaNacimiento: fechaNacCtrl.text.trim(),
                    sexo: sexo,
                    direccion: dirCtrl.text.trim(),
                    eps: epsCtrl.text.trim(),
                    nombreContactoEmergencia: contactoCtrl.text.trim(),
                    telefonoContactoEmergencia: telContactoCtrl.text.trim(),
                  );

                  if (OfflineSyncService.instance.isOnline) {
                    try {
                      if (existente == null) {
                        await ApiClient.instance.crearPaciente(p);
                      } else {
                        await ApiClient.instance.actualizarPaciente(p);
                      }
                    } catch (_) {
                      await OfflineSyncService.instance.savePacienteOffline(p);
                    }
                  } else {
                    await OfflineSyncService.instance.savePacienteOffline(p);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
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

    if (guardado == true) {
      _cargarPacientes();
    }
  }

  Future<void> _eliminarPaciente(PacienteModel p) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PriorixColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PriorixColors.border),
        ),
        title: const Text('¿Eliminar paciente?'),
        content: Text('Se eliminará el registro de ${p.nombreCompleto}. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: PriorixColors.nivel1Rojo),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (conf == true) {
      try {
        await ApiClient.instance.eliminarPaciente(p.id);
        _cargarPacientes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente eliminado correctamente.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
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
        title: const Text('Gestión de Pacientes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () => _cargarPacientes(query: _searchCtrl.text.trim()),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PriorixColors.primaryBlue,
        foregroundColor: const Color(0xFF0F1B2D),
        onPressed: () => _guardarPaciente(),
        icon: const Icon(Icons.person_add_rounded, size: 22),
        label: const Text('Nuevo paciente', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Buscar por cédula o nombre...',
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                _cargarPacientes();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (q) => _cargarPacientes(query: q.trim()),
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
              const Icon(Icons.error_outline_rounded, size: 48, color: PriorixColors.nivel1Rojo),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: PriorixColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => _cargarPacientes(), child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    if (_pacientes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded, size: 54, color: PriorixColors.textSecondary),
              SizedBox(height: 16),
              Text('No hay pacientes registrados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 6),
              Text('Registra un paciente con el botón "Nuevo paciente".', style: TextStyle(color: PriorixColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _pacientes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = _pacientes[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 23,
              backgroundColor: PriorixColors.primaryBlue.withOpacity(0.18),
              child: const Icon(Icons.person_rounded, size: 24, color: PriorixColors.primaryBlue),
            ),
            title: Text(p.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('${p.tipoDocumento} ${p.numeroDocumento}', style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 13)),
                if (p.eps != null && p.eps!.isNotEmpty)
                  Text('EPS: ${p.eps}', style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: PriorixColors.textSecondary),
                  onPressed: () => _guardarPaciente(existente: p),
                  tooltip: 'Editar paciente',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: PriorixColors.nivel1Rojo),
                  onPressed: () => _eliminarPaciente(p),
                  tooltip: 'Eliminar paciente',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
