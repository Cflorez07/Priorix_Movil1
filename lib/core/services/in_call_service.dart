import 'dart:async';
import 'package:flutter/foundation.dart';

/// Servicio global que gestiona el estado de llamada telefónica activa o entrante
/// permitiendo al usuario continuar usando la aplicación sin interrupciones ni pérdida de datos.
class InCallService extends ChangeNotifier {
  InCallService._();
  static final InCallService instance = InCallService._();

  bool _isCallActive = false;
  bool _hasIncomingNotification = false;
  String _callerName = 'Urgencias Hospital Central';
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  Timer? _incomingDismissTimer;

  bool get isCallActive => _isCallActive;
  bool get hasIncomingNotification => _hasIncomingNotification;
  String get callerName => _callerName;
  int get callDurationSeconds => _callDurationSeconds;

  String get formattedDuration {
    final m = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Dispara el evento real de llamada entrante con la "nubecita" superior flotante
  /// y auto-desaparición a los 6 segundos.
  void triggerIncomingCall({String callerName = 'Urgencias Hospital Central'}) {
    _callerName = callerName;
    _hasIncomingNotification = true;
    _incomingDismissTimer?.cancel();
    _incomingDismissTimer = Timer(const Duration(seconds: 6), () {
      _hasIncomingNotification = false;
      notifyListeners();
    });
    notifyListeners();
  }

  void dismissIncomingNotification() {
    _incomingDismissTimer?.cancel();
    _hasIncomingNotification = false;
    notifyListeners();
  }

  void answerIncomingCall() {
    dismissIncomingNotification();
    startCall(callerName: _callerName);
  }

  void startCall({String callerName = 'Urgencias Hospital Central'}) {
    _isCallActive = true;
    _callerName = callerName;
    _callDurationSeconds = 0;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDurationSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void endCall() {
    _isCallActive = false;
    _callTimer?.cancel();
    _callTimer = null;
    _callDurationSeconds = 0;
    notifyListeners();
  }

  void toggleCall() {
    if (_isCallActive) {
      endCall();
    } else {
      triggerIncomingCall();
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _incomingDismissTimer?.cancel();
    super.dispose();
  }
}
