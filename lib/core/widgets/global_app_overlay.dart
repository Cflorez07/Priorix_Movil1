import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/in_call_service.dart';
import '../services/offline_sync_service.dart';
import '../theme/priorix_theme.dart';

/// Overlay global presente en TODA la aplicación (cualquier pantalla).
/// - Gestiona la notificación tipo "nubecita" superior de llamada entrante (auto-dismiss 6s).
/// - Gestiona la insignia circular flotante de llamada en curso (draggable).
/// - Gestiona el banner único y claro de Modo Avión / Sin Conexión y sincronización SQLite.
/// - Permite interactuar con la app con total normalidad sin interrumpir llamadas ni perder datos.
class GlobalAppOverlay extends StatefulWidget {
  final Widget? child;

  const GlobalAppOverlay({super.key, this.child});

  @override
  State<GlobalAppOverlay> createState() => _GlobalAppOverlayState();
}

class _GlobalAppOverlayState extends State<GlobalAppOverlay> with WidgetsBindingObserver {
  Offset _callBadgeOffset = const Offset(16, 80);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      debugPrint('[PRIORIX] App en segundo plano o llamada activa.');
    }
  }

  void _mostrarDetallesLlamada(BuildContext context) {
    final call = InCallService.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: PriorixColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: PriorixColors.border),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: call,
          builder: (ctx, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PriorixColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_rounded, color: Color(0xFF16A34A), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Llamada en curso',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              call.callerName,
                              style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: PriorixColors.cardSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          call.formattedDuration,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: PriorixColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PriorixColors.cardSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PriorixColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: PriorixColors.primaryBlue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Puedes navegar libremente por cualquier parte de la app. Los datos del formulario se mantendrán intactos.',
                            style: TextStyle(fontSize: 12, color: PriorixColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          label: const Text('Continuar en la app'),
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
                          onPressed: () {
                            call.endCall();
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.call_end_rounded),
                          label: const Text('Finalizar llamada'),
                          style: FilledButton.styleFrom(
                            backgroundColor: PriorixColors.nivel1Rojo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final badgeTop = _callBadgeOffset.dy.clamp(
      MediaQuery.of(context).padding.top + 10,
      screenSize.height - 120,
    );
    final badgeRight = _callBadgeOffset.dx.clamp(10.0, screenSize.width - 90);

    return Stack(
      children: [
        // 1. Contenido principal de la pantalla
        if (widget.child != null) widget.child!,

        // 2. Banner único y claro de "Modo Avión / Desconectado" (Sin truncar, sin duplicados)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ListenableBuilder(
            listenable: OfflineSyncService.instance,
            builder: (context, _) {
              final isOnline = OfflineSyncService.instance.isOnline;
              final pending = OfflineSyncService.instance.pendingCount;

              if (isOnline && pending == 0) return const SizedBox.shrink();

              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: !isOnline
                            ? const Color(0xFF2C1E10)
                            : const Color(0xFF0F2618),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isOnline ? PriorixColors.offlineOrange : PriorixColors.onlineGreen,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !isOnline ? Icons.airplanemode_active_rounded : Icons.sync_rounded,
                            color: !isOnline ? PriorixColors.offlineOrangeLight : PriorixColors.onlineGreenLight,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  !isOnline
                                      ? 'Modo sin conexión activo'
                                      : 'Conexión activa • Sincronizando',
                                  style: TextStyle(
                                    color: !isOnline ? PriorixColors.offlineOrangeLight : PriorixColors.onlineGreenLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  !isOnline
                                      ? 'Datos guardados en SQLite local cifrado${pending > 0 ? " ($pending cambios pendientes)" : ""}.'
                                      : 'Enviando $pending registro(s) pendiente(s) a la base de datos central...',
                                  style: const TextStyle(
                                    color: PriorixColors.textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (pending > 0 && isOnline)
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: PriorixColors.onlineGreenLight,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => OfflineSyncService.instance.syncPendingData(),
                              child: const Text('Sincronizar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 3. Notificación flotante tipo "nubecita" superior de llamada entrante
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ListenableBuilder(
            listenable: InCallService.instance,
            builder: (context, _) {
              final call = InCallService.instance;
              if (!call.hasIncomingNotification) return const SizedBox.shrink();

              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162338),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF22C55E), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Llamada entrante',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF22C55E),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  call.callerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: PriorixColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botón Contestar
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(40, 36),
                            ),
                            onPressed: () => call.answerIncomingCall(),
                            child: const Text('Atender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          // Botón cerrar nubecita
                          InkWell(
                            borderRadius: BorderRadius.circular(99),
                            onTap: () => call.dismissIncomingNotification(),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.close_rounded, size: 20, color: PriorixColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 4. Insignia flotante "Llamada en curso" (Cuando ya está contestada)
        Positioned(
          top: badgeTop,
          right: badgeRight,
          child: ListenableBuilder(
            listenable: InCallService.instance,
            builder: (context, _) {
              final call = InCallService.instance;
              if (!call.isCallActive) return const SizedBox.shrink();

              return GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _callBadgeOffset = Offset(
                      _callBadgeOffset.dx - details.delta.dx,
                      _callBadgeOffset.dy + details.delta.dy,
                    );
                  });
                },
                onTap: () => _mostrarDetallesLlamada(context),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment(-0.2, -0.3),
                        colors: [
                          Color(0xFF22C55E),
                          Color(0xFF15803D),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.45),
                          blurRadius: 14,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 16),
                        const SizedBox(height: 2),
                        const Text(
                          'Llamada\nen curso',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          call.formattedDuration,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 5. Botón de prueba SOLO bajo kDebugMode en posición no invasiva
        if (kDebugMode)
          Positioned(
            bottom: 8,
            right: 8,
            child: Focus(
              canRequestFocus: false,
              descendantsAreFocusable: true,
              child: ListenableBuilder(
                listenable: InCallService.instance,
                builder: (context, _) {
                  final isCall = InCallService.instance.isCallActive;
                  return Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.75,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: () => InCallService.instance.toggleCall(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: PriorixColors.card.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: PriorixColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCall ? Icons.call_end : Icons.phone_callback_rounded,
                                size: 12,
                                color: isCall ? PriorixColors.nivel1Rojo : const Color(0xFF22C55E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCall ? 'Fin prueba' : 'Test llamada',
                                style: const TextStyle(fontSize: 10, color: PriorixColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
