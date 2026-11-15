import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/priorix_theme.dart';
import '../../models/models.dart';
import 'atencion_medica_screen.dart';

class ListaEsperaScreen extends StatefulWidget {
  final bool selectModeOnly;

  const ListaEsperaScreen({super.key, this.selectModeOnly = false});

  @override
  State<ListaEsperaScreen> createState() => _ListaEsperaScreenState();
}

class _ListaEsperaScreenState extends State<ListaEsperaScreen> {
  List<ItemListaEsperaModel> _items = [];
  bool _cargando = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarLista();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _cargarLista(silencioso: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarLista({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final res = await ApiClient.instance.getListaEspera();
      if (mounted) {
        // Ordenar por nivel (1 a 5) y luego por tiempo de espera descendente
        res.sort((a, b) {
          final compNivel = a.nivel.nivel.compareTo(b.nivel.nivel);
          if (compNivel != 0) return compNivel;
          return b.tiempoEsperaMinutos.compareTo(a.tiempoEsperaMinutos);
        });

        setState(() {
          _items = res;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted && !silencioso) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Future<void> _iniciarAtencion(ItemListaEsperaModel item) async {
    try {
      final atencion = await ApiClient.instance.iniciarAtencion(item.idTriaje);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AtencionMedicaScreen(atencionInicial: atencion),
          ),
        ).then((_) => _cargarLista());
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PriorixColors.nivel1Rojo,
            content: Text(e.statusCode == 409
                ? 'El paciente ya fue asignado o está siendo atendido por otro médico.'
                : 'Error al iniciar atención: ${e.message}'),
          ),
        );
        _cargarLista();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: PriorixColors.nivel1Rojo, content: Text('Error: $e')),
        );
        _cargarLista();
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
        title: const Text('Lista de Espera Priorizada', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () => _cargarLista(),
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
              const Icon(Icons.cloud_off_rounded, size: 50, color: PriorixColors.nivel1Rojo),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: PriorixColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => _cargarLista(), child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    // Contadores por nivel
    final c1 = _items.where((i) => i.nivel.nivel == 1).length;
    final c2 = _items.where((i) => i.nivel.nivel == 2).length;
    final c3 = _items.where((i) => i.nivel.nivel == 3).length;
    final c4 = _items.where((i) => i.nivel.nivel == 4).length;
    final c5 = _items.where((i) => i.nivel.nivel == 5).length;

    return RefreshIndicator(
      onRefresh: () => _cargarLista(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Barra de contadores por nivel (I a V)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chipContador('I Rojo', c1, PriorixColors.nivel1Rojo),
                const SizedBox(width: 8),
                _chipContador('II Naranja', c2, PriorixColors.nivel2Naranja),
                const SizedBox(width: 8),
                _chipContador('III Amarillo', c3, PriorixColors.nivel3Amarillo),
                const SizedBox(width: 8),
                _chipContador('IV Azul', c4, PriorixColors.nivel4Azul),
                const SizedBox(width: 8),
                _chipContador('V Verde', c5, PriorixColors.nivel5Verde),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_outline_rounded, size: 54, color: PriorixColors.nivel5Verde),
                  SizedBox(height: 14),
                  Text(
                    'No hay pacientes en espera',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Todos los pacientes en urgencias han sido asignados o atendidos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            for (final item in _items) ...[
              _buildItemCard(item),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _chipContador(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 6),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemListaEsperaModel item) {
    final color = PriorixColors.colorPorNivel(item.nivel.nivel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 1.2),
                  ),
                  child: Text(
                    PriorixColors.nombreNivel(item.nivel.nivel),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: PriorixColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      item.tiempoEsperaMinutos > 0 ? '${item.tiempoEsperaMinutos} min espera' : 'Recién ingresado',
                      style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.pacienteNombre,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            if (item.pacienteDocumento.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Documento: ${item.pacienteDocumento}',
                  style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Motivo: ${item.sintomas}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: PriorixColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: PriorixColors.cardSecondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Dolor: ${item.nivelDolor}/10',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _iniciarAtencion(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PriorixColors.primaryBlue,
                    foregroundColor: const Color(0xFF0F1B2D),
                    minimumSize: const Size(130, 40),
                  ),
                  icon: const Icon(Icons.medical_services_rounded, size: 16),
                  label: const Text('ATENDER'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
