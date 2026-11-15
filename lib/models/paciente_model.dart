class PacienteModel {
  final String id;
  final String tipoDocumento;
  final String numeroDocumento;
  final String nombre;
  final String apellido;
  final String? fechaNacimiento;
  final String? genero;
  final String? sexo;
  final String? telefono;
  final String? direccion;
  final String? eps;
  final String? contactoEmergencia;
  final String? telefonoEmergencia;
  final String? nombreContactoEmergencia;
  final String? telefonoContactoEmergencia;
  final bool esNN;

  const PacienteModel({
    required this.id,
    required this.tipoDocumento,
    String? numeroDocumento,
    String? documento,
    required this.nombre,
    required this.apellido,
    this.fechaNacimiento,
    this.genero,
    this.sexo,
    this.telefono,
    this.direccion,
    this.eps,
    this.contactoEmergencia,
    this.telefonoEmergencia,
    this.nombreContactoEmergencia,
    this.telefonoContactoEmergencia,
    this.esNN = false,
  }) : numeroDocumento = numeroDocumento ?? documento ?? '';

  String get documento => numeroDocumento;
  String get nombreCompleto => '$nombre $apellido'.trim();
  String get identificacion => esNN ? 'N.N. (Sin identificar)' : '$tipoDocumento $numeroDocumento';

  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    final numDoc = (json['numeroDocumento'] ?? json['documento'] ?? '').toString();
    final isNN = json['esNN'] == true || numDoc.toUpperCase().startsWith('NN');
    final sex = (json['sexo'] ?? json['genero'])?.toString();
    final cNom = (json['nombreContactoEmergencia'] ?? json['contactoEmergencia'])?.toString();
    final cTel = (json['telefonoContactoEmergencia'] ?? json['telefonoEmergencia'])?.toString();

    return PacienteModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      tipoDocumento: (json['tipoDocumento'] ?? (isNN ? 'NN' : 'CC')).toString(),
      numeroDocumento: numDoc,
      nombre: (json['nombre'] ?? (isNN ? 'Paciente N.N.' : '')).toString(),
      apellido: (json['apellido'] ?? '').toString(),
      fechaNacimiento: json['fechaNacimiento']?.toString(),
      genero: sex,
      sexo: sex,
      telefono: json['telefono']?.toString(),
      direccion: json['direccion']?.toString(),
      eps: json['eps']?.toString(),
      contactoEmergencia: cNom,
      telefonoEmergencia: cTel,
      nombreContactoEmergencia: cNom,
      telefonoContactoEmergencia: cTel,
      esNN: isNN,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipoDocumento': tipoDocumento,
        'documento': numeroDocumento,
        'numeroDocumento': numeroDocumento,
        'nombre': nombre,
        'apellido': apellido,
        'fechaNacimiento': fechaNacimiento,
        'sexo': sexo ?? genero,
        'genero': sexo ?? genero,
        'telefono': telefono,
        'direccion': direccion,
        'eps': eps,
        'contactoEmergencia': contactoEmergencia ?? nombreContactoEmergencia,
        'nombreContactoEmergencia': nombreContactoEmergencia ?? contactoEmergencia,
        'telefonoEmergencia': telefonoEmergencia ?? telefonoContactoEmergencia,
        'telefonoContactoEmergencia': telefonoContactoEmergencia ?? telefonoEmergencia,
        'esNN': esNN,
      };
}
