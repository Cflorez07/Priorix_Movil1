class HistoriaClinicaModel {
  final String id;
  final String pacienteId;
  final String? pacienteNombre;
  final String? pacienteDocumento;
  final String atencionId;
  final String fecha;
  final String diagnostico;
  final String tratamiento;
  final String? antecedentes;
  final String? evolucion;
  final String? medicoNombre;

  const HistoriaClinicaModel({
    required this.id,
    required this.pacienteId,
    this.pacienteNombre,
    this.pacienteDocumento,
    required this.atencionId,
    required this.fecha,
    required this.diagnostico,
    required this.tratamiento,
    this.antecedentes,
    this.evolucion,
    this.medicoNombre,
  });

  String get fechaRegistro => fecha;

  factory HistoriaClinicaModel.fromJson(Map<String, dynamic> json) {
    return HistoriaClinicaModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      pacienteId: (json['pacienteId'] ?? json['idPaciente'] ?? '').toString(),
      pacienteNombre: json['pacienteNombre']?.toString() ??
          (json['paciente'] is Map ? '${json['paciente']['nombre']} ${json['paciente']['apellido']}'.trim() : null),
      pacienteDocumento: json['pacienteDocumento']?.toString() ??
          (json['paciente'] is Map ? json['paciente']['numeroDocumento']?.toString() : null),
      atencionId: (json['atencionId'] ?? json['idAtencion'] ?? '').toString(),
      fecha: (json['fecha'] ?? json['fechaRegistro'] ?? json['fechaHora'] ?? '').toString(),
      diagnostico: (json['diagnostico'] ?? '').toString(),
      tratamiento: (json['tratamiento'] ?? '').toString(),
      antecedentes: json['antecedentes']?.toString(),
      evolucion: json['evolucion']?.toString(),
      medicoNombre: json['medicoNombre']?.toString() ?? json['medico']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pacienteId': pacienteId,
        'atencionId': atencionId,
        'fecha': fecha,
        'diagnostico': diagnostico,
        'tratamiento': tratamiento,
        'antecedentes': antecedentes,
        'evolucion': evolucion,
      };
}
