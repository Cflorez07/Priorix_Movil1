import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/theme/priorix_theme.dart';
import '../../models/models.dart';

class MisTriajesScreen extends StatefulWidget {
  const MisTriajesScreen({super.key});

  @override
  State<MisTriajesScreen> createState() => _MisTriajesScreenState();
}

class _MisTriajesScreenState extends State<MisTriajesScreen> {
  List<TriajeModel> _triajes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarTriajes();
  }

  Future<void> _cargarTriajes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      List<TriajeModel> res = [];
      if (OfflineSyncService.instance.isOnline) {
        try {
          res = await ApiClient.instance.getMisTriajes();
        } catch (_) {
          res = await OfflineSyncService.instance.getTriajesOffline();
        }
      } else {
        res = await OfflineSyncService.instance.getTriajesOffline();
      }

      if (mounted) {
        setState(() {
          _triajes = res;
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
        title: const Text('Triajes Registrados', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: _cargarTriajes,
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
              const Icon(Icons.cloud_off_rounded, size: 48, color: PriorixColors.nivel1Rojo),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: PriorixColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargarTriajes, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    if (_triajes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_outlined, size: 54, color: PriorixColors.textSecondary),
              SizedBox(height: 16),
              Text(
                'No hay triajes registrados aún.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                'Los triajes que registres aparecerán en este historial con su nivel y hora.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PriorixColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarTriajes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _triajes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final t = _triajes[index];
          final color = PriorixColors.colorPorNivel(t.nivel.nivel);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          t.nivel.titulo,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        t.horaLegible,
                        style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.pacienteNombre ?? 'Paciente',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Síntomas: ${t.sintomas}',
                    style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _chipSigno('FC: ${t.frecuenciaCardiaca} lpm'),
                      _chipSigno('PA: ${t.presionArterial}'),
                      _chipSigno('SpO₂: ${t.saturacionOxigeno}%'),
                      _chipSigno('Temp: ${t.temperatura}°C'),
                      _chipSigno('Dolor: ${t.nivelDolor}/10'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chipSigno(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PriorixColors.cardSecondary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PriorixColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: PriorixColors.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
