import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../api/api_client.dart';
import 'encryption_service.dart';

enum SyncItemStatus { pendiente, sincronizado, error }

class SyncQueueItem {
  final String id;
  final String tipoOperacion; // PACIENTE, TRIAJE, ATENCION, HISTORIA, EMERGENCIA
  final String recordId;
  final String payloadEncrypted;
  final String fechaCreacion;
  final SyncItemStatus estado;
  final int intentos;
  final String? errorMessage;

  SyncQueueItem({
    required this.id,
    required this.tipoOperacion,
    required this.recordId,
    required this.payloadEncrypted,
    required this.fechaCreacion,
    this.estado = SyncItemStatus.pendiente,
    this.intentos = 0,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tipo_operacion': tipoOperacion,
    'record_id': recordId,
    'payload_encrypted': payloadEncrypted,
    'fecha_creacion': fechaCreacion,
    'estado': estado.name,
    'intentos': intentos,
    'error_message': errorMessage,
  };

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) => SyncQueueItem(
    id: map['id'] as String,
    tipoOperacion: map['tipo_operacion'] as String,
    recordId: map['record_id'] as String,
    payloadEncrypted: map['payload_encrypted'] as String,
    fechaCreacion: map['fecha_creacion'] as String,
    estado: SyncItemStatus.values.byName(map['estado'] as String? ?? 'pendiente'),
    intentos: (map['intentos'] as int?) ?? 0,
    errorMessage: map['error_message'] as String?,
  );
}

class OfflineSyncService extends ChangeNotifier {
  static final OfflineSyncService instance = OfflineSyncService._();
  OfflineSyncService._();

  static const _uuid = Uuid();
  sql.Database? _db;
  bool _isOnline = true;
  int _pendingCount = 0;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  StreamSubscription? _connSub;

  bool get isOnline => _isOnline;
  int get pendingCount => _pendingCount;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> init() async {
    await EncryptionService.instance.init();
    await _initDatabase();
    await _checkConnectivity();

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();

      if (!wasOnline && _isOnline) {
        syncPendingData();
      }
    });

    await _refreshPendingCount();
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _isOnline = results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      _isOnline = true;
    }
    notifyListeners();
  }

  Future<void> _initDatabase() async {
    if (kIsWeb) {
      debugPrint('[OfflineSyncService] En navegador Web, SQLite nativo no aplica (aplica en dispositivos Android/iOS).');
      return;
    }
    try {
      final databasesPath = await sql.getDatabasesPath();
      final path = p.join(databasesPath, 'priorix_offline_v2.db');

      _db = await sql.openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
          // Cola unificada de sincronización
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sync_queue (
              id TEXT PRIMARY KEY,
              tipo_operacion TEXT NOT NULL,
              record_id TEXT NOT NULL,
              payload_encrypted TEXT NOT NULL,
              fecha_creacion TEXT NOT NULL,
              estado TEXT NOT NULL,
              intentos INTEGER NOT NULL DEFAULT 0,
              error_message TEXT
            )
          ''');

          // Triajes guardados offline
          await db.execute('''
            CREATE TABLE IF NOT EXISTS triajes_offline (
              id TEXT PRIMARY KEY,
              paciente_id TEXT,
              paciente_nombre TEXT,
              frecuencia_cardiaca INTEGER,
              frecuencia_respiratoria INTEGER,
              presion_arterial TEXT,
              temperatura REAL,
              saturacion_oxigeno INTEGER,
              nivel_dolor INTEGER,
              estado_consciencia TEXT,
              sintomas_cifrados TEXT,
              nivel INTEGER,
              foto_base64 TEXT,
              fecha_hora TEXT
            )
          ''');

          // Pacientes registrados offline
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pacientes_offline (
              id TEXT PRIMARY KEY,
              tipo_documento TEXT,
              documento TEXT,
              nombre TEXT,
              apellido TEXT,
              telefono TEXT,
              fecha_nacimiento TEXT,
              sexo TEXT,
              direccion TEXT,
              eps TEXT,
              nombre_contacto TEXT,
              telefono_contacto TEXT,
              fecha_creacion TEXT
            )
          ''');

          // Atenciones médicas offline
          await db.execute('''
            CREATE TABLE IF NOT EXISTS atenciones_offline (
              id TEXT PRIMARY KEY,
              triaje_id TEXT,
              diagnostico_cifrado TEXT,
              tratamiento_cifrado TEXT,
              observaciones_cifradas TEXT,
              fecha_hora TEXT
            )
          ''');

          // Historias clínicas offline
          await db.execute('''
            CREATE TABLE IF NOT EXISTS historias_offline (
              id TEXT PRIMARY KEY,
              atencion_id TEXT,
              paciente_id TEXT,
              resumen_cifrado TEXT,
              fecha_hora TEXT
            )
          ''');

          // Emergencias / N.N. offline
          await db.execute('''
            CREATE TABLE IF NOT EXISTS emergencias_offline (
              id TEXT PRIMARY KEY,
              tipo TEXT,
              descripcion_cifrada TEXT,
              fecha_hora TEXT
            )
          ''');
        },
      );
    } catch (e) {
      debugPrint('Error inicializando SQLite offline: $e');
    }
  }

  // ==================== TRIAJES ====================

  Future<void> saveTriajeOffline(TriajeModel triaje, {String? fotoBase64}) async {
    if (_db == null) return;
    try {
      final payloadJson = jsonEncode({
        ...triaje.toJson(),
        if (fotoBase64 != null) 'fotoBase64': fotoBase64,
      });
      final encryptedPayload = await EncryptionService.instance.encrypt(payloadJson);
      final sintomasCifrados = await EncryptionService.instance.encrypt(triaje.sintomas);
      final now = DateTime.now().toIso8601String();

      await _db!.transaction((txn) async {
        await txn.insert(
          'triajes_offline',
          {
            'id': triaje.id,
            'paciente_id': triaje.pacienteId,
            'paciente_nombre': triaje.pacienteNombre ?? '',
            'frecuencia_cardiaca': triaje.frecuenciaCardiaca,
            'frecuencia_respiratoria': triaje.frecuenciaRespiratoria,
            'presion_arterial': triaje.presionArterial,
            'temperatura': triaje.temperatura,
            'saturacion_oxigeno': triaje.saturacionOxigeno,
            'nivel_dolor': triaje.nivelDolor,
            'estado_consciencia': triaje.estadoConsciencia,
            'sintomas_cifrados': sintomasCifrados,
            'nivel': triaje.nivel.nivel,
            'foto_base64': fotoBase64,
            'fecha_hora': triaje.fechaHora ?? now,
          },
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );

        await txn.insert(
          'sync_queue',
          SyncQueueItem(
            id: _uuid.v4(),
            tipoOperacion: 'TRIAJE',
            recordId: triaje.id,
            payloadEncrypted: encryptedPayload,
            fechaCreacion: now,
          ).toMap(),
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      });

      await _refreshPendingCount();
    } catch (e) {
      debugPrint('Error guardando triaje offline: $e');
    }
  }

  // ==================== PACIENTES ====================

  Future<void> savePacienteOffline(PacienteModel paciente) async {
    if (_db == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      final payloadJson = jsonEncode(paciente.toJson());
      final encryptedPayload = await EncryptionService.instance.encrypt(payloadJson);

      await _db!.transaction((txn) async {
        await txn.insert(
          'pacientes_offline',
          {
            'id': paciente.id,
            'tipo_documento': paciente.tipoDocumento,
            'documento': paciente.documento,
            'nombre': paciente.nombre,
            'apellido': paciente.apellido,
            'telefono': paciente.telefono,
            'fecha_nacimiento': paciente.fechaNacimiento,
            'sexo': paciente.sexo,
            'direccion': paciente.direccion,
            'eps': paciente.eps,
            'nombre_contacto': paciente.nombreContactoEmergencia,
            'telefono_contacto': paciente.telefonoContactoEmergencia,
            'fecha_creacion': now,
          },
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );

        await txn.insert(
          'sync_queue',
          SyncQueueItem(
            id: _uuid.v4(),
            tipoOperacion: 'PACIENTE',
            recordId: paciente.id,
            payloadEncrypted: encryptedPayload,
            fechaCreacion: now,
          ).toMap(),
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      });

      await _refreshPendingCount();
    } catch (e) {
      debugPrint('Error guardando paciente offline: $e');
    }
  }

  // ==================== ATENCIONES ====================

  Future<void> saveAtencionOffline({
    required String atencionId,
    required String diagnostico,
    required String tratamiento,
    String? observaciones,
  }) async {
    if (_db == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      final payloadJson = jsonEncode({
        'atencionId': atencionId,
        'diagnostico': diagnostico,
        'tratamiento': tratamiento,
        'observaciones': observaciones ?? '',
      });
      final encryptedPayload = await EncryptionService.instance.encrypt(payloadJson);

      await _db!.transaction((txn) async {
        await txn.insert(
          'atenciones_offline',
          {
            'id': atencionId,
            'triaje_id': '',
            'diagnostico_cifrado': await EncryptionService.instance.encrypt(diagnostico),
            'tratamiento_cifrado': await EncryptionService.instance.encrypt(tratamiento),
            'observaciones_cifradas': await EncryptionService.instance.encrypt(observaciones ?? ''),
            'fecha_hora': now,
          },
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );

        await txn.insert(
          'sync_queue',
          SyncQueueItem(
            id: _uuid.v4(),
            tipoOperacion: 'ATENCION',
            recordId: atencionId,
            payloadEncrypted: encryptedPayload,
            fechaCreacion: now,
          ).toMap(),
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      });

      await _refreshPendingCount();
    } catch (e) {
      debugPrint('Error guardando atencion offline: $e');
    }
  }

  // ==================== HISTORIAS CLÍNICAS ====================

  Future<void> saveHistoriaOffline({required String atencionId}) async {
    if (_db == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      final payloadJson = jsonEncode({'atencionId': atencionId});
      final encryptedPayload = await EncryptionService.instance.encrypt(payloadJson);

      await _db!.transaction((txn) async {
        await txn.insert(
          'historias_offline',
          {
            'id': _uuid.v4(),
            'atencion_id': atencionId,
            'paciente_id': '',
            'resumen_cifrado': '',
            'fecha_hora': now,
          },
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );

        await txn.insert(
          'sync_queue',
          SyncQueueItem(
            id: _uuid.v4(),
            tipoOperacion: 'HISTORIA',
            recordId: atencionId,
            payloadEncrypted: encryptedPayload,
            fechaCreacion: now,
          ).toMap(),
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      });

      await _refreshPendingCount();
    } catch (e) {
      debugPrint('Error guardando historia offline: $e');
    }
  }

  // ==================== EMERGENCIAS / N.N. ====================

  Future<void> saveEmergenciaOffline(EmergenciaModel emergencia) async {
    if (_db == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      final payloadJson = jsonEncode(emergencia.toJson());
      final encryptedPayload = await EncryptionService.instance.encrypt(payloadJson);
      final encryptedDesc = await EncryptionService.instance.encrypt(emergencia.descripcion);

      await _db!.transaction((txn) async {
        await txn.insert(
          'emergencias_offline',
          {
            'id': emergencia.id,
            'tipo': emergencia.tipo,
            'descripcion_cifrada': encryptedDesc,
            'fecha_hora': (emergencia.fechaHora != null && emergencia.fechaHora!.isNotEmpty)
                ? emergencia.fechaHora
                : now,
          },
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );

        await txn.insert(
          'sync_queue',
          SyncQueueItem(
            id: _uuid.v4(),
            tipoOperacion: 'EMERGENCIA',
            recordId: emergencia.id,
            payloadEncrypted: encryptedPayload,
            fechaCreacion: now,
          ).toMap(),
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      });

      await _refreshPendingCount();
    } catch (e) {
      debugPrint('Error guardando emergencia offline: $e');
    }
  }

  Future<List<EmergenciaModel>> getEmergenciasOffline() async {
    if (_db == null) return [];
    try {
      final rows = await _db!.query('emergencias_offline');
      final list = <EmergenciaModel>[];
      for (final r in rows) {
        final descCifrada = r['descripcion_cifrada']?.toString() ?? '';
        final desc = await EncryptionService.instance.decrypt(descCifrada);
        list.add(EmergenciaModel(
          id: r['id'].toString(),
          tipo: r['tipo']?.toString() ?? 'NN',
          descripcion: desc,
          estado: 'PENDIENTE',
          fechaHora: r['fecha_hora']?.toString() ?? '',
        ));
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  // ==================== CONSULTAS OFFLINE ====================

  Future<List<PacienteModel>> getPacientesOffline() async {
    if (_db == null) return [];
    try {
      final rows = await _db!.query('pacientes_offline');
      return rows.map<PacienteModel>((r) => PacienteModel(
        id: r['id'].toString(),
        tipoDocumento: r['tipo_documento']?.toString() ?? 'CC',
        numeroDocumento: r['documento']?.toString() ?? '',
        nombre: r['nombre']?.toString() ?? '',
        apellido: r['apellido']?.toString() ?? '',
        telefono: r['telefono']?.toString(),
        fechaNacimiento: r['fecha_nacimiento']?.toString(),
        sexo: r['sexo']?.toString(),
        direccion: r['direccion']?.toString(),
        eps: r['eps']?.toString(),
        nombreContactoEmergencia: r['nombre_contacto']?.toString(),
        telefonoContactoEmergencia: r['telefono_contacto']?.toString(),
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TriajeModel>> getTriajesOffline() async {
    if (_db == null) return [];
    try {
      final rows = await _db!.query('triajes_offline');
      final list = <TriajeModel>[];
      for (final r in rows) {
        final rawSintomas = r['sintomas_cifrados']?.toString() ?? '';
        final sintomas = await EncryptionService.instance.decrypt(rawSintomas);
        list.add(TriajeModel(
          id: r['id'].toString(),
          pacienteId: r['paciente_id'].toString(),
          pacienteNombre: r['paciente_nombre']?.toString(),
          frecuenciaCardiaca: (r['frecuencia_cardiaca'] as int?) ?? 80,
          frecuenciaRespiratoria: (r['frecuencia_respiratoria'] as int?) ?? 18,
          presionArterial: (r['presion_arterial'] ?? '120/80').toString(),
          temperatura: (r['temperatura'] as num?)?.toDouble() ?? 36.5,
          saturacionOxigeno: (r['saturacion_oxigeno'] as int?) ?? 98,
          nivelDolor: (r['nivel_dolor'] as int?) ?? 0,
          estadoConsciencia: (r['estado_consciencia'] ?? 'Alerta').toString(),
          sintomas: sintomas,
          nivel: NivelTriaje.fromNivel(r['nivel']),
          fechaHora: r['fecha_hora']?.toString(),
        ));
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  // ==================== SINCRONIZACIÓN AUTOMÁTICA ====================

  Future<void> _refreshPendingCount() async {
    if (_db == null) return;
    try {
      final res = await _db!.rawQuery(
        "SELECT COUNT(*) as cnt FROM sync_queue WHERE estado != 'sincronizado'",
      );
      _pendingCount = (res.first['cnt'] as int?) ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  /// Sincroniza la cola en estricto orden cronológico (FIFO).
  Future<void> syncPendingData() async {
    if (_db == null || !_isOnline || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Obtener ítems pendientes ordenados por fecha de creación
      final rows = await _db!.query(
        'sync_queue',
        where: "estado != 'sincronizado'",
        orderBy: 'fecha_creacion ASC',
      );

      for (final row in rows) {
        final item = SyncQueueItem.fromMap(row);
        bool success = false;
        String? errorDetail;

        try {
          final payloadRaw = await EncryptionService.instance.decrypt(item.payloadEncrypted);
          final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;

          switch (item.tipoOperacion) {
            case 'PACIENTE':
              final p = PacienteModel.fromJson(payload);
              await ApiClient.instance.crearPaciente(p);
              await _db!.delete('pacientes_offline', where: 'id = ?', whereArgs: [item.recordId]);
              success = true;
              break;

            case 'TRIAJE':
              final t = TriajeModel.fromJson(payload);
              await ApiClient.instance.crearTriaje(t);
              await _db!.delete('triajes_offline', where: 'id = ?', whereArgs: [item.recordId]);
              success = true;
              break;

            case 'ATENCION':
              await ApiClient.instance.finalizarAtencion(
                payload['atencionId'] as String,
                diagnostico: payload['diagnostico'] as String? ?? '',
                tratamiento: payload['tratamiento'] as String? ?? '',
                observaciones: payload['observaciones'] as String?,
              );
              await _db!.delete('atenciones_offline', where: 'id = ?', whereArgs: [item.recordId]);
              success = true;
              break;

            case 'HISTORIA':
              await ApiClient.instance.crearHistoriaDesdeAtencion(payload['atencionId'] as String);
              await _db!.delete('historias_offline', where: 'atencion_id = ?', whereArgs: [item.recordId]);
              success = true;
              break;

            case 'EMERGENCIA':
              final em = EmergenciaModel.fromJson(payload);
              await ApiClient.instance.crearEmergencia(em);
              await _db!.delete('emergencias_offline', where: 'id = ?', whereArgs: [item.recordId]);
              success = true;
              break;
          }
        } on ApiException catch (e) {
          errorDetail = e.message;
          // Si el registro ya fue sincronizado previamente o existe conflicto 409
          if (e.statusCode == 409) {
            success = true; // Se considera resuelto para no bloquear la cola
          }
        } catch (e) {
          errorDetail = e.toString();
        }

        if (success) {
          // Eliminamos de la cola de sincronización únicamente tras confirmación real
          await _db!.delete('sync_queue', where: 'id = ?', whereArgs: [item.id]);
        } else {
          // Registramos el fallo y sumamos intento para reintentar luego
          await _db!.update(
            'sync_queue',
            {
              'estado': SyncItemStatus.error.name,
              'intentos': item.intentos + 1,
              'error_message': errorDetail,
            },
            where: 'id = ?',
            whereArgs: [item.id],
          );
        }
      }

      _lastSyncTime = DateTime.now();
      await _refreshPendingCount();
    } catch (e) {
      debugPrint('Error general en sincronización offline: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }
}
