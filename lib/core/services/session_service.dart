import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/models.dart';

class SessionService extends ChangeNotifier {
  static final SessionService instance = SessionService._();
  SessionService._();

  static const _keyToken = 'priorix_jwt_token';
  static const _keyUser = 'priorix_username';
  static const _keyEmail = 'priorix_email';
  static const _keyRol = 'priorix_rol';
  static const _keyServerUrl = 'priorix_server_url';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  String? _username;
  String? _email;
  String? _rol;

  String? get token => _token;
  String? get username => _username;
  String? get email => _email;
  String? get rol => _rol;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  String get rolLegible {
    switch ((_rol ?? '').toUpperCase()) {
      case 'ROLE_ADMIN':
      case 'ADMIN':
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'ROLE_ENFERMERO':
      case 'ENFERMERO':
      case 'ENFERMERÍA':
        return 'Enfermero';
      case 'ROLE_MEDICO':
      case 'MEDICO':
      case 'MÉDICO':
        return 'Médico';
      default:
        return _rol ?? 'Usuario';
    }
  }

  Future<void> init() async {
    _token = await _storage.read(key: _keyToken);
    _username = await _storage.read(key: _keyUser);
    _email = await _storage.read(key: _keyEmail);
    _rol = await _storage.read(key: _keyRol);
    notifyListeners();
  }

  Future<void> saveSession(AuthResponseModel auth) async {
    _token = auth.token;
    _username = auth.username;
    _email = auth.email;
    _rol = auth.rol;

    await _storage.write(key: _keyToken, value: auth.token);
    await _storage.write(key: _keyUser, value: auth.username);
    await _storage.write(key: _keyEmail, value: auth.email);
    await _storage.write(key: _keyRol, value: auth.rol);
    notifyListeners();
  }

  Future<void> clearSession() async {
    _token = null;
    _username = null;
    _email = null;
    _rol = null;

    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyRol);
    notifyListeners();
  }

  Future<String?> getServerUrl() async {
    return await _storage.read(key: _keyServerUrl);
  }

  Future<void> setServerUrl(String url) async {
    await _storage.write(key: _keyServerUrl, value: url);
  }

  void handleSessionExpired() {
    clearSession();
  }
}
