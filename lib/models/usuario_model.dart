class UsuarioModel {
  final String id;
  final String username;
  final String email;
  final String? nombre;
  final String? apellido;
  final String rol;
  final bool activo;

  const UsuarioModel({
    required this.id,
    required this.username,
    required this.email,
    this.nombre,
    this.apellido,
    required this.rol,
    this.activo = true,
  });

  String get nombreCompleto {
    final n = (nombre ?? '').trim();
    final a = (apellido ?? '').trim();
    if (n.isEmpty && a.isEmpty) return username;
    return '$n $a'.trim();
  }

  String get rolLegible {
    switch (rol.toUpperCase()) {
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
        return rol;
    }
  }

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      username: (json['username'] ?? json['nombreUsuario'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      nombre: json['nombre']?.toString(),
      apellido: json['apellido']?.toString(),
      rol: (json['rol'] ?? json['role'] ?? 'ROLE_ENFERMERO').toString(),
      activo: json['activo'] == true || json['activo'] == null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'nombre': nombre,
        'apellido': apellido,
        'rol': rol,
        'activo': activo,
      };
}

class AuthResponseModel {
  final String token;
  final String tipo;
  final String username;
  final String email;
  final String rol;

  const AuthResponseModel({
    required this.token,
    required this.tipo,
    required this.username,
    required this.email,
    required this.rol,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: (json['token'] ?? json['accessToken'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'Bearer').toString(),
      username: (json['nombreUsuario'] ?? json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      rol: (json['rol'] ?? json['role'] ?? 'ROLE_ENFERMERO').toString(),
    );
  }
}
