class ReporteResumenModel {
  final int totalTriajes;
  final int totalAtenciones;
  final int totalPacientes;
  final int totalUsuarios;
  final int nivel1Rojo;
  final int nivel2Naranja;
  final int nivel3Amarillo;
  final int nivel4Azul;
  final int nivel5Verde;
  final int pacientesEnEspera;

  const ReporteResumenModel({
    this.totalTriajes = 0,
    this.totalAtenciones = 0,
    this.totalPacientes = 0,
    this.totalUsuarios = 0,
    this.nivel1Rojo = 0,
    this.nivel2Naranja = 0,
    this.nivel3Amarillo = 0,
    this.nivel4Azul = 0,
    this.nivel5Verde = 0,
    this.pacientesEnEspera = 0,
  });

  // Getter de compatibilidad
  int get nivel4Verde => nivel5Verde;
  int get nivel5Azul => nivel4Azul;

  factory ReporteResumenModel.fromJson(Map<String, dynamic> json) {
    final porNivel = (json['porNivel'] ?? json['niveles']) as Map<String, dynamic>? ?? {};

    return ReporteResumenModel(
      totalTriajes: int.tryParse((json['totalTriajes'] ?? json['total'])?.toString() ?? '0') ?? 0,
      totalAtenciones: int.tryParse(json['totalAtenciones']?.toString() ?? '0') ?? 0,
      totalPacientes: int.tryParse(json['totalPacientes']?.toString() ?? '0') ?? 0,
      totalUsuarios: int.tryParse(json['totalUsuarios']?.toString() ?? '0') ?? 0,
      nivel1Rojo: int.tryParse((porNivel['Rojo'] ?? porNivel['rojo'] ?? porNivel['1'] ?? json['nivel1'])?.toString() ?? '0') ?? 0,
      nivel2Naranja: int.tryParse((porNivel['Naranja'] ?? porNivel['naranja'] ?? porNivel['2'] ?? json['nivel2'])?.toString() ?? '0') ?? 0,
      nivel3Amarillo: int.tryParse((porNivel['Amarillo'] ?? porNivel['amarillo'] ?? porNivel['3'] ?? json['nivel3'])?.toString() ?? '0') ?? 0,
      nivel4Azul: int.tryParse((porNivel['Azul'] ?? porNivel['azul'] ?? porNivel['4'] ?? json['nivel4'])?.toString() ?? '0') ?? 0,
      nivel5Verde: int.tryParse((porNivel['Verde'] ?? porNivel['verde'] ?? porNivel['5'] ?? json['nivel5'])?.toString() ?? '0') ?? 0,
      pacientesEnEspera: int.tryParse(json['pacientesEnEspera']?.toString() ?? '0') ?? 0,
    );
  }
}
