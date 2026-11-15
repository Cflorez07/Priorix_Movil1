import 'package:flutter/material.dart';
import '../core/theme/priorix_theme.dart';

enum NivelTriaje {
  rojo(1, 'Nivel I · Reanimación', 'Atención inmediata', PriorixColors.nivel1Rojo),
  naranja(2, 'Nivel II · Emergencia', 'Atención hasta 15 min', PriorixColors.nivel2Naranja),
  amarillo(3, 'Nivel III · Urgencia', 'Atención hasta 30 min', PriorixColors.nivel3Amarillo),
  azul(4, 'Nivel IV · Prioritario', 'Atención hasta 60 min', PriorixColors.nivel4Azul),
  verde(5, 'Nivel V · No urgente', 'Atención hasta 120 min', PriorixColors.nivel5Verde);

  final int nivel;
  final String titulo;
  final String descripcion;
  final Color color;

  const NivelTriaje(this.nivel, this.titulo, this.descripcion, this.color);

  static NivelTriaje fromNivel(dynamic val) {
    final n = int.tryParse(val.toString()) ?? 3;
    switch (n) {
      case 1:
        return NivelTriaje.rojo;
      case 2:
        return NivelTriaje.naranja;
      case 3:
        return NivelTriaje.amarillo;
      case 4:
        return NivelTriaje.azul;
      case 5:
        return NivelTriaje.verde;
      default:
        return NivelTriaje.amarillo;
    }
  }

  static NivelTriaje fromColorName(String name) {
    switch (name.toLowerCase().trim()) {
      case 'rojo':
      case 'red':
      case 'nivel_1_rojo':
        return NivelTriaje.rojo;
      case 'naranja':
      case 'orange':
      case 'nivel_2_naranja':
        return NivelTriaje.naranja;
      case 'amarillo':
      case 'yellow':
      case 'nivel_3_amarillo':
        return NivelTriaje.amarillo;
      case 'azul':
      case 'blue':
      case 'nivel_4_azul':
        return NivelTriaje.azul;
      case 'verde':
      case 'green':
      case 'nivel_5_verde':
        return NivelTriaje.verde;
      default:
        return NivelTriaje.amarillo;
    }
  }
}

class TriajeModel {
  final String id;
  final String pacienteId;
  final String? pacienteNombre;
  final String? pacienteDocumento;
  final NivelTriaje nivel;
  final int frecuenciaCardiaca;
  final int frecuenciaRespiratoria;
  final String presionArterial;
  final double temperatura;
  final int saturacionOxigeno;
  final int nivelDolor;
  final String estadoConsciencia;
  final String sintomas;
  final String? observaciones;
  final String? fechaHora;
  final String? enfermeroUsername;
  final bool offline;

  const TriajeModel({
    required this.id,
    required this.pacienteId,
    this.pacienteNombre,
    this.pacienteDocumento,
    required this.nivel,
    required this.frecuenciaCardiaca,
    required this.frecuenciaRespiratoria,
    required this.presionArterial,
    required this.temperatura,
    required this.saturacionOxigeno,
    required this.nivelDolor,
    required this.estadoConsciencia,
    required this.sintomas,
    this.observaciones,
    this.fechaHora,
    this.enfermeroUsername,
    this.offline = false,
  });

  factory TriajeModel.fromJson(Map<String, dynamic> json) {
    final nivelRaw = json['nivel'] ?? json['nivelTriaje'] ?? json['prioridad'];
    final colorRaw = json['nivelColor']?.toString() ?? '';

    NivelTriaje n = NivelTriaje.amarillo;
    if (colorRaw.isNotEmpty) {
      n = NivelTriaje.fromColorName(colorRaw);
    } else if (nivelRaw != null) {
      n = NivelTriaje.fromNivel(nivelRaw);
    }

    return TriajeModel(
      id: (json['id'] ?? '').toString(),
      pacienteId: (json['pacienteId'] ?? json['paciente_id'] ?? '').toString(),
      pacienteNombre: json['pacienteNombre']?.toString(),
      pacienteDocumento: json['pacienteDocumento']?.toString(),
      nivel: n,
      frecuenciaCardiaca: (json['frecuenciaCardiaca'] as num?)?.toInt() ?? 80,
      frecuenciaRespiratoria: (json['frecuenciaRespiratoria'] as num?)?.toInt() ?? 18,
      presionArterial: (json['presionArterial'] ?? '120/80').toString(),
      temperatura: (json['temperatura'] as num?)?.toDouble() ?? 36.5,
      saturacionOxigeno: (json['saturacionOxigeno'] as num?)?.toInt() ?? 98,
      nivelDolor: (json['nivelDolor'] as num?)?.toInt() ?? 0,
      estadoConsciencia: (json['estadoConsciencia'] ?? 'Alerta').toString(),
      sintomas: (json['sintomas'] ?? '').toString(),
      observaciones: json['observaciones']?.toString(),
      fechaHora: (json['fechaRegistro'] ?? json['horaRegistro'] ?? json['fechaHora'])?.toString(),
      enfermeroUsername: json['enfermero']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pacienteId': pacienteId,
        'pacienteNombre': pacienteNombre,
        'frecuenciaCardiaca': frecuenciaCardiaca,
        'frecuenciaRespiratoria': frecuenciaRespiratoria,
        'presionArterial': presionArterial,
        'temperatura': temperatura,
        'saturacionOxigeno': saturacionOxigeno,
        'nivelDolor': nivelDolor,
        'estadoConsciencia': estadoConsciencia,
        'sintomas': sintomas,
        'nivel': nivel.nivel,
        'nivelColor': nivel == NivelTriaje.rojo
            ? 'Rojo'
            : nivel == NivelTriaje.naranja
                ? 'Naranja'
                : nivel == NivelTriaje.amarillo
                    ? 'Amarillo'
                    : nivel == NivelTriaje.azul
                        ? 'Azul'
                        : 'Verde',
      };

  String get horaLegible {
    if (fechaHora == null || fechaHora!.isEmpty) return 'Reciente';
    try {
      final dt = DateTime.parse(fechaHora!);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return fechaHora!;
    }
  }

  /// Evalúa la prioridad médica idéntica a Triaje.java / Triaje.evaluarPrioridadMedica()
  static NivelTriaje evaluarPrioridad({
    required String consciencia,
    required int saturacion,
    required double temperatura,
    required int frecuenciaCardiaca,
    required int dolor,
  }) {
    // 1. Regla de Oro: Si está inconsciente, es ROJO (Nivel 1)
    if (consciencia.toLowerCase().contains('inconsciente')) {
      return NivelTriaje.rojo;
    }
    // 2. Regla de Oxígeno: Saturación menor a 90% es ROJO (Nivel 1)
    if (saturacion < 90) {
      return NivelTriaje.rojo;
    }
    // 3. Regla de Fiebre alta: Temperatura >= 40.0°C es NARANJA (Nivel 2)
    if (temperatura >= 40.0) {
      return NivelTriaje.naranja;
    }

    // 4. Clasificación por dolor (fallback institucional)
    if (dolor >= 8) return NivelTriaje.rojo;
    if (dolor >= 6) return NivelTriaje.naranja;
    if (dolor >= 4) return NivelTriaje.amarillo;
    if (dolor >= 2) return NivelTriaje.azul;
    return NivelTriaje.verde;
  }
}
