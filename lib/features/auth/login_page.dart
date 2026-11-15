import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/priorix_theme.dart';
import '../../core/widgets/priorix_logo.dart';
import '../dashboard/role_dashboard.dart';
import 'activar_cuenta_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _cargando = false;
  String? _mensajeError;
  String? _mensajeExito;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final usuario = _usuarioController.text.trim();
    final pass = _passwordController.text.trim();

    if (usuario.isEmpty || pass.isEmpty) {
      setState(() {
        _mensajeError = 'Por favor ingresa tu usuario y contraseña.';
        _mensajeExito = null;
      });
      return;
    }

    setState(() {
      _cargando = true;
      _mensajeError = null;
      _mensajeExito = null;
    });

    try {
      final auth = await ApiClient.instance.login(usuario, pass);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RoleDashboard(
              role: SessionService.instance.rolLegible,
              previewMode: false,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _mensajeError = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensajeError = 'Error al conectar con el servidor: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirActivarCuenta() async {
    final activada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ActivarCuentaScreen()),
    );
    if (activada == true && mounted) {
      setState(() {
        _mensajeExito = 'Cuenta activada. Ya puedes iniciar sesión.';
        _mensajeError = null;
      });
    }
  }

  void _mostrarRecuperarClave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PriorixColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PriorixColors.border),
        ),
        title: const Text(
          'Recuperar contraseña',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'Para restablecer tu contraseña, ingresa al portal web de PRIORIX en la opción «¿Olvidaste tu contraseña?» o comunícate con el administrador del sistema hospitalario.',
          style: TextStyle(color: PriorixColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: PriorixColors.primaryBlue,
              foregroundColor: const Color(0xFF0F1B2D),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _configurarServidor() async {
    final ctrl = TextEditingController(text: ApiClient.instance.baseUrl);
    final nuevaUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PriorixColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PriorixColors.border),
        ),
        title: const Text('Servidor Backend PRIORIX'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indica la URL base de la API REST de Spring Boot:',
              style: TextStyle(fontSize: 13, color: PriorixColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'URL del Backend',
                hintText: 'http://10.0.2.2:8080 o http://localhost:8080',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Emulador Android: http://10.0.2.2:8080\n• Teléfono físico: http://<IP_DE_TU_PC>:8080\n• Web / Windows: http://localhost:8080',
              style: TextStyle(fontSize: 11, color: PriorixColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: PriorixColors.primaryBlue,
              foregroundColor: const Color(0xFF0F1B2D),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevaUrl != null && nuevaUrl.isNotEmpty) {
      ApiClient.instance.setBaseUrl(nuevaUrl);
      await SessionService.instance.setServerUrl(nuevaUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Servidor configurado en: $nuevaUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriorixColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Configurar servidor',
            icon: const Icon(Icons.settings_ethernet, size: 20, color: PriorixColors.textSecondary),
            onPressed: _configurarServidor,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logotipo institucional idéntico a la Web
                  const PriorixLogo(
                    size: 80,
                    showText: true,
                    showSlogan: true,
                  ),

                  const SizedBox(height: 32),

                  // Tarjeta contenedora de formulario (Estilo Web .sec .lc)
                  Card(
                    color: PriorixColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: PriorixColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: PriorixColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Mensaje de éxito si viene de activar cuenta
                          if (_mensajeExito != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14382A),
                                borderRadius: BorderRadius.circular(8),
                                border: const Border(
                                  left: BorderSide(color: PriorixColors.nivel5Verde, width: 4),
                                ),
                              ),
                              child: Text(
                                _mensajeExito!,
                                style: const TextStyle(fontSize: 13, color: PriorixColors.textPrimary),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Mensaje de error (al estilo .al .er)
                          if (_mensajeError != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C1618),
                                borderRadius: BorderRadius.circular(8),
                                border: const Border(
                                  left: BorderSide(color: PriorixColors.nivel1Rojo, width: 4),
                                ),
                              ),
                              child: Text(
                                _mensajeError!,
                                style: const TextStyle(fontSize: 13, color: PriorixColors.textPrimary),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Campo Usuario (idéntico al de la web)
                          const Text(
                            'Usuario',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: PriorixColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _usuarioController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Ingresa tu usuario',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Campo Contraseña (idéntico al de la web)
                          const Text(
                            'Contraseña',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: PriorixColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Ingresa tu contraseña',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Botón Iniciar sesión
                          ElevatedButton(
                            onPressed: _cargando ? null : _iniciarSesion,
                            child: _cargando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0F1B2D),
                                    ),
                                  )
                                : const Text('Iniciar sesión'),
                          ),

                          const SizedBox(height: 16),

                          // Enlace ¿Olvidaste tu contraseña?
                          Center(
                            child: TextButton(
                              onPressed: _mostrarRecuperarClave,
                              style: TextButton.styleFrom(
                                foregroundColor: PriorixColors.primaryBlue,
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),

                          const Divider(height: 24),

                          // Enlace Activar cuenta (para cuentas creadas por el admin)
                          Center(
                            child: TextButton.icon(
                              onPressed: _abrirActivarCuenta,
                              icon: const Icon(Icons.mark_email_read_outlined, size: 16),
                              label: const Text('Activar cuenta con código'),
                              style: TextButton.styleFrom(
                                foregroundColor: PriorixColors.textSecondary,
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
