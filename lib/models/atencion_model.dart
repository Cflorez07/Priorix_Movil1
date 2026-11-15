import 'triaje_model.dart';

class AtencionModel {
  final String id;
  final String idTriaje;
  final String? pacienteId;
  final String? pacienteNombre;
  final String? pacienteDocumento;
  final NivelTriaje? nivelTriaje;
  final String? motivoConsulta;
  final String? estado; // EN_PROCESO, FINALIZADA
  final String? fechaInicio;
  final String? fechaFin;
  final String? examenFisico;
  final String? diagnostico;
  final String? tratamiento;
  final String? observaciones;
  final String? medicoNombre;

  const AtencionModel({
    required this.id,
    required this.idTriaje,
    this.pacienteId,
    this.pacienteNombre,
    this.pacienteDocumento,
    this.nivelTriaje,
    this.motivoConsulta,
    this.estado = 'EN_PROCESO',
    this.fechaInicio,
    this.fechaFin,
    this.examenFisico,
    this.diagnostico,
    this.tratamiento,
    this.observaciones,
    this.medicoNombre,
  });

  bool get enProceso => estado == 'EN_PROCESO' || estado == null;
  String? get fechaHoraInicio => fechaInicio;

  factory AtencionModel.fromJson(Map<String, dynamic> json) {
    NivelTriaje? nivel;
    if (json['nivel'] != null || json['nivelTriaje'] != null) {
      nivel = NivelTriaje.fromNivel(json['nivel'] ?? json['nivelTriaje']);
    }

    return AtencionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      idTriaje: (json['idTriaje'] ?? json['triajeId'] ?? '').toString(),
      pacienteId: json['pacienteId']?.toString(),
      pacienteNombre: json['pacienteNombre']?.toString() ??
          (json['paciente'] is Map ? '${json['paciente']['nombre']} ${json['paciente']['apellido']}'.trim() : null),
      pacienteDocumento: json['pacienteDocumento']?.toString() ??
          (json['paciente'] is Map ? json['paciente']['numeroDocumento']?.toString() : null),
      nivelTriaje: nivel,
      motivoConsulta: (json['motivoConsulta'] ?? json['sintomas'] ?? '').toString(),
      estado: (json['estado'] ?? 'EN_PROCESO').toString(),
      fechaInicio: (json['fechaInicio'] ?? json['fechaHoraInicio'] ?? json['fechaHora'])?.toString(),
      fechaFin: json['fechaFin']?.toString(),
      examenFisico: json['examenFisico']?.toString(),
      diagnostico: json['diagnostico']?.toString(),
      tratamiento: json['tratamiento']?.toString(),
      observaciones: json['observaciones']?.toString(),
      medicoNombre: json['medicoNombre']?.toString() ?? json['medico']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'idTriaje': idTriaje,
        'diagnostico': diagnostico,
        'tratamiento': tratamiento,
        'examenFisico': examenFisico,
        'observaciones': observaciones,
        'estado': estado,
      };
}

class ItemListaEsperaModel {
  final String idTriaje;
  final String pacienteId;
  final String pacienteNombre;
  final String pacienteDocumento;
  final NivelTriaje nivel;
  final String sintomas;
  final String fechaHora;
  final int tiempoEsperaMinutos;
  final int nivelDolor;

  const ItemListaEsperaModel({
    required this.idTriaje,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.pacienteDocumento,
    required this.nivel,
    required this.sintomas,
    required this.fechaHora,
    this.tiempoEsperaMinutos = 0,
    this.nivelDolor = 0,
  });

  factory ItemListaEsperaModel.fromJson(Map<String, dynamic> json) {
    final nivelRaw = json['nivel'] ?? json['nivelTriaje'] ?? json['prioridad'];
    final colorRaw = json['nivelColor']?.toString() ?? '';
    final nivel = colorRaw.isNotEmpty
        ? NivelTriaje.fromColorName(colorRaw)
        : NivelTriaje.fromNivel(nivelRaw);

    final dolor = int.tryParse((json['nivelDolor'] ?? json['dolor'] ?? 0).toString()) ?? 0;

    return ItemListaEsperaModel(
      idTriaje: (json['idTriaje'] ?? json['id'] ?? '').toString(),
      pacienteId: (json['pacienteId'] ?? json['idPaciente'] ?? '').toString(),
      pacienteNombre: (json['pacienteNombre'] ??
              (json['paciente'] is Map ? '${json['paciente']['nombre']} ${json['paciente']['apellido']}'.trim() : 'Paciente'))
          .toString(),
      pacienteDocumento: (json['pacienteDocumento'] ??
              (json['paciente'] is Map ? json['paciente']['numeroDocumento']?.toString() : ''))
          .toString(),
      nivel: nivel,
      sintomas: (json['sintomas'] ?? json['motivoConsulta'] ?? '').toString(),
      fechaHora: (json['fechaHora'] ?? json['fecha'] ?? '').toString(),
      tiempoEsperaMinutos: int.tryParse(json['tiempoEsperaMinutos']?.toString() ?? '0') ?? 0,
      nivelDolor: dolor,
    );
  }
}
