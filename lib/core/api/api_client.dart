import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/models.dart';
import '../services/session_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException(this.statusCode, this.message, [this.details]);

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  static const String _defaultUrl = 'http://10.0.2.2:8080';
  String _baseUrl = _defaultUrl;
  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 25);

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    var clean = url.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    _baseUrl = clean;
  }

  Future<void> init() async {
    final savedUrl = await SessionService.instance.getServerUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    } else {
      // En Web, Windows o Desktop, el backend corre en localhost
      if (kIsWeb) {
        _baseUrl = 'http://localhost:8080';
      } else {
        try {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            _baseUrl = 'http://localhost:8080';
          }
        } catch (_) {}
      }
    }
  }

  Map<String, String> _headers([String? token]) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    final activeToken = token ?? SessionService.instance.token;
    if (activeToken != null && activeToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $activeToken';
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(utf8.decode(response.bodyBytes)) : null;

    if (status >= 200 && status < 300) {
      return body;
    }

    if (status == 401) {
      SessionService.instance.handleSessionExpired();
      throw ApiException(401, 'Sesión expirada o credenciales incorrectas.');
    }

    if (status == 403) {
      throw ApiException(403, 'No tienes permisos suficientes para realizar esta acción.');
    }

    if (status == 404) {
      throw ApiException(404, body is Map ? (body['error'] ?? 'Elemento no encontrado.') : 'Elemento no encontrado.');
    }

    if (status == 409) {
      throw ApiException(409, body is Map ? (body['error'] ?? 'El registro ya fue procesado o tomado por otro usuario.') : 'Conflicto al procesar.');
    }

    final msg = body is Map ? (body['error'] ?? body['message'] ?? 'Error del servidor ($status)') : 'Error del servidor ($status)';
    throw ApiException(status, msg.toString(), body);
  }

  // ===================== AUTENTICACIÓN =====================

  Future<AuthResponseModel> login(String emailOrUsername, String password) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/auth/login');
      final res = await _client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({
              'email': emailOrUsername.trim(),
              'username': emailOrUsername.trim(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      final data = _handleResponse(res) as Map<String, dynamic>;
      final auth = AuthResponseModel.fromJson(data);
      await SessionService.instance.saveSession(auth);
      return auth;
    } on SocketException {
      throw ApiException(0, 'No se pudo conectar al servidor PRIORIX en $_baseUrl. Verifica tu conexión de red.');
    } on TimeoutException {
      throw ApiException(408, 'Tiempo de espera agotado al conectar con el servidor.');
    }
  }

  Future<void> enviarCodigoActivacion(String email) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/auth/enviar-codigo?email=${Uri.encodeComponent(email.trim())}');
      final res = await _client.post(uri, headers: _headers()).timeout(_timeout);
      if (res.statusCode >= 400) {
        throw ApiException(res.statusCode, res.body.isNotEmpty ? res.body : 'Error al enviar código.');
      }
    } on SocketException {
      throw ApiException(0, 'Se requiere conexión a Internet para enviar el código de activación.');
    }
  }

  Future<AuthResponseModel> verificarCodigoActivacion(String email, String code) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/v1/auth/verificar?email=${Uri.encodeComponent(email.trim())}&code=${Uri.encodeComponent(code.trim())}',
      );
      final res = await _client.post(uri, headers: _headers()).timeout(_timeout);
      final data = _handleResponse(res) as Map<String, dynamic>;
      final auth = AuthResponseModel.fromJson(data);
      await SessionService.instance.saveSession(auth);
      return auth;
    } on SocketException {
      throw ApiException(0, 'Se requiere conexión a Internet para activar la cuenta.');
    }
  }

  Future<UsuarioModel> getMe() async {
    final uri = Uri.parse('$_baseUrl/api/v1/me');
    final res = await _client.get(uri, headers: _headers()).timeout(_timeout);
    final data = _handleResponse(res) as Map<String, dynamic>;
    return UsuarioModel.fromJson(data);
  }

  // ===================== PACIENTES =====================

  Future<List<PacienteModel>> getPacientes({String? q}) async {
    final query = (q != null && q.isNotEmpty) ? '?q=${Uri.encodeComponent(q)}' : '';
    final uri = Uri.parse('$_baseUrl/api/v1/pacientes$query');
    final res = await _client.get(uri, headers: _headers()).timeout(_timeout);
    final data = _handleResponse(res);
    if (data is List) {
      return data.map((e) => PacienteModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<PacienteModel> crearPaciente(PacienteModel paciente) async {
    final uri = Uri.parse('$_baseUrl/api/v1/pacientes');
    final res = await _client
        .post(uri, headers: _headers(), body: jsonEncode(paciente.toJson()))
        .timeout(_timeout);
    final data = _handleResponse(res) as Map<String, dynamic>;
    return PacienteModel.fromJson(data);
  }

  Future<PacienteModel> actualizarPaciente(PacienteModel paciente) async {
    final uri = Uri.parse('$_baseUrl/api/v1/pacientes/${paciente.id}');
    final res = await _client
        .put(uri, headers: _headers(), body: jsonEncode(paciente.toJson()))
        .timeout(_timeout);
    final data = _handleResponse(res) as Map<String, dynamic>;
    return PacienteModel.fromJson(data);
  }

  Future<void> eliminarPaciente(String id) async {
    final uri = Uri.parse('$_baseUrl/api/v1/pacientes/$id');
    final res = await _client.delete(uri, headers: _headers()).timeout(_timeout);
    _handleResponse(res);
  }

  // ===================== TRIAJES =====================

  Future<TriajeModel> crearTriaje(TriajeModel triaje) async {
    final uri = Uri.parse('$_baseUrl/api/v1/triajes');
    final res = await _client
        .post(uri, headers: _headers(), body: jsonEncode(triaje.toJson()))
        .timeout(_timeout);
    final data = _handleResponse(res) as Map<String, dynamic>;
    return TriajeModel.fromJson(data);
  }

  Future<List<TriajeModel>> getMisTriajes() async {
    final uri = Uri.parse('$_baseUrl/api/v1/triajes/mios');
    final res = await _client.get(uri, headers: _headers()).timeout(_timeout);
    final data = _handleResponse(res);
    if (data is List) {
      return data.map((e) => TriajeModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ===================== LISTA DE ESPERA =====================

  Future<List<ItemListaEsperaModel>> getListaEspera() async {
    final uri = Uri.parse('$_baseUrl/api/v1/lista-espera');
    final res = await _client.get(uri, headers: _headers()).timeout(_timeout);
    final data = _handleResponse(res);
    if (data is List) {
      return data.map((e) => ItemListaEsperaModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ===================== ATENCIONES =====================

  Future<AtencionModel> iniciarAtencion(String idTriaje) async {
    final uri = Uri.parse('$_baseUrl/api/v1/atenciones/iniciar/$idTriaje');
    final res = await _client.post(uri, headers: _headers()).timeout(_timeout);
    final data = _handleResponse(res) as Map<String, dynamic>;
    return AtencionModel.fromJson(data);
  }

  Future<List<AtencionModel>> getAtencionesEnProceso() async {
    final uri = Uri.parse('$_baseUrl/api/v1/atenciones/en-proceso');
    final res = await _client.get(uri, headers: _headers()).timeout(_timeout);
    final data = _handleResponse(res);
    if (data is List) {
      return data.map((e) => AtencionModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<AtencionModel> finalizarAtencion(
    String idAtencion, {
    required String diagnostico,
    required String tratamiento,
    String? examenFisico,
    String? observaciones,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/atenciones/$idAtencion/finalizar');
    final res = await _client
        .put(
          uri,
          headers: _headers(),
          body: jsonEncode({
            'diagnostico': diagnostico,
            'tratamiento': tratamiento,
            'examenFisico': examenFisico ?? '',
            'observaciones': observaciones ?? '',
          }),
        )
        .timeout(_timeout);
    final data = _handleResponse(res) as Map<String, dynamic>;
    return AtencionModel.fromJson(data);
  }

  // ===================== HISTORIAS CLÍNICAS =====================

  Future<HistoriaClinicaModel> crearHistoriaDesdeAtencion(String idAtencion) async {
    final uri = Uri.parse('$_baseUrl/api/v1/historias/desde-atencion/$idAtencion');
    final res = await _client.post(uri, headers: _headers()).timeout(_timeout);
    final data = _handleResponse(res) as Map<String, dynamic>;
    return HistoriaClinicaModel.fromJson(data);
  }

  Future<List<HistoriaClinicaModel>> getHistorias({String? pacienteId}) async {
    final query = (pacienteId != null && pacienteId.trim().isNotEmpty) ? '?pacienteId=${Uri.encodeComponent(pacienteId.trim())}' : '';
    final uri = Uri.parse('$_baseUrl/api/v1/historias$query');
    try {
      final res = await _client.get(uri, headers: _headers()).timeout(_timeout);
      // Si el backend requiere pacienteId (400) y no se envió ninguno, retornamos lista vacía sin error
      if (res.statusCode == 400 && (pacienteId == null || pacienteId.trim().isEmpty)) {
        return [];
      }
      final data = _handleResponse(res);
      if (data is List) {
        return data.map((e) => HistoriaClinicaModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on ApiException catch (e) {
      if (e.statusCode == 400 && (pacienteId == null || pacienteId.trim().isEmpty)) {
        return [];
      }
      rethrow;
    }
  }

  // ===================== EMERGENCIAS / PACIENTES NN =====================

  Future<EmergenciaModel> crearEmergencia(EmergenciaModel emergencia) async {
    final uri = Uri.parse('$_baseUrl/api/v1/emergencias');
    final res = await _client
        .post(uri, headers: _headers(), body: jsonEncode(emergencia.toJson()))
        .timeout(_timeout);
    final data = _handleResponse(res) as Map<String, dynamic>;
    return EmergenciaModel.fromJson(data);
  }

  Future<List<EmergenciaModel>> getEmergenciasPendientes() async {
    final uri = Uri.parse('$_baseUrl/api/v1/emergencias/pendientes');
    final res = await _client.get(uri, headers: _headers()).timeout(_timeout);
    final data = _handleResponse(res);
    if (data is List) {
      return data.map((e) => EmergenciaModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> identificarEmergencia(String emergenciaId, String pacienteId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/emergencias/$emergenciaId/identificar?pacienteId=${Uri.encodeComponent(pacienteId)}');
    final res = await _client.post(uri, headers: _headers()).timeout(_timeout);
    _handleResponse(res);
  }

  // ===================== USUARIOS (ADMIN) =====================

  Future<List<UsuarioModel>> getUsuarios({String? q}) async {
    final query = (q != null && q.isNotEmpty) ? '?q=${Uri.encodeComponent(q)}' : '';
    final uri = Uri.parse('$_baseUrl/api/v1/usuarios$query');
    final res = await _client.get(uri, headers: _headers()).timeout(_timeout);
    final data = _handleResponse(res);
    if (data is List) {
      return data.map((e) => UsuarioModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<UsuarioModel> crearUsuario({
    required String username,
    required String email,
    required String password,
    required String rol,
    String? nombre,
    String? apellido,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/usuarios');
    final res = await _client
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
            'rol': rol,
            'nombre': nombre,
            'apellido': apellido,
          }),
        )
        .timeout(_timeout);
    final data = _handleResponse(res) as Map<String, dynamic>;
    return UsuarioModel.fromJson(data);
  }

  Future<void> toggleUsuarioActivo(String id, bool valor) async {
    final uri = Uri.parse('$_baseUrl/api/v1/usuarios/$id/activo?valor=$valor');
    final res = await _client.put(uri, headers: _headers()).timeout(_timeout);
    _handleResponse(res);
  }

  Future<void> eliminarUsuario(String id) async {
    final uri = Uri.parse('$_baseUrl/api/v1/usuarios/$id');
    final res = await _client.delete(uri, headers: _headers()).timeout(_timeout);
    _handleResponse(res);
  }

  // ===================== REPORTES (ADMIN) =====================

  Future<ReporteResumenModel> getReportes({String? fechaInicio, String? fechaFin, int? nivel, String? medico}) async {
    final params = <String>[];
    if (fechaInicio != null) params.add('fechaInicio=${Uri.encodeComponent(fechaInicio)}');
    if (fechaFin != null) params.add('fechaFin=${Uri.encodeComponent(fechaFin)}');
    if (nivel != null) params.add('nivel=$nivel');
    if (medico != null && medico.isNotEmpty) params.add('medico=${Uri.encodeComponent(medico)}');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';

    final uri = Uri.parse('$_baseUrl/api/v1/reportes$query');
    final res = await _client.get(uri, headers: _headers()).timeout(_timeout);
    final data = _handleResponse(res) as Map<String, dynamic>;
    return ReporteResumenModel.fromJson(data);
  }
}
