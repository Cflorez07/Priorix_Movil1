class EmergenciaModel {
  final String id;
  final String tipo; // VIVO, FALLECIDO
  final String descripcion;
  final String estado; // PENDIENTE, IDENTIFICADO
  final String? pacienteId;
  final String? fechaHora;
  final String? fotoUrl;

  const EmergenciaModel({
    required this.id,
    required this.tipo,
    required this.descripcion,
    this.estado = 'PENDIENTE',
    this.pacienteId,
    this.fechaHora,
    this.fotoUrl,
  });

  bool get esPendiente => estado == 'PENDIENTE';

  factory EmergenciaModel.fromJson(Map<String, dynamic> json) {
    return EmergenciaModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'VIVO').toString(),
      descripcion: (json['descripcion'] ?? json['motivo'] ?? '').toString(),
      estado: (json['estado'] ?? 'PENDIENTE').toString(),
      pacienteId: json['pacienteId']?.toString(),
      fechaHora: json['fechaHora']?.toString() ?? json['fecha']?.toString(),
      fotoUrl: json['fotoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'descripcion': descripcion,
        'estado': estado,
        'pacienteId': pacienteId,
        'fechaHora': fechaHora,
      };
}
