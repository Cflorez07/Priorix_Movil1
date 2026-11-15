import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/priorix_theme.dart';
import '../../core/widgets/priorix_logo.dart';

class ActivarCuentaScreen extends StatefulWidget {
  const ActivarCuentaScreen({super.key});

  @override
  State<ActivarCuentaScreen> createState() => _ActivarCuentaScreenState();
}

class _ActivarCuentaScreenState extends State<ActivarCuentaScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _enviandoCodigo = false;
  bool _activando = false;
  String? _mensajeInfo;
  String? _mensajeError;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _solicitarCodigo() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _mensajeError = 'Por favor ingresa tu correo institucional.';
        _mensajeInfo = null;
      });
      return;
    }

    setState(() {
      _enviandoCodigo = true;
      _mensajeError = null;
      _mensajeInfo = null;
    });

    try {
      await ApiClient.instance.enviarCodigoActivacion(email);
      if (mounted) {
        setState(() {
          _mensajeInfo = 'Código de 6 dígitos enviado a tu correo. Es válido por 10 minutos.';
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _mensajeError = e.message);
    } catch (e) {
      if (mounted) setState(() => _mensajeError = 'Error al enviar código: $e');
    } finally {
      if (mounted) setState(() => _enviandoCodigo = false);
    }
  }

  Future<void> _activarCuenta() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty || code.isEmpty) {
      setState(() {
        _mensajeError = 'Debes ingresar tu correo y el código de 6 dígitos.';
        _mensajeInfo = null;
      });
      return;
    }

    setState(() {
      _activando = true;
      _mensajeError = null;
      _mensajeInfo = null;
    });

    try {
      await ApiClient.instance.verificarCodigoActivacion(email, code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: PriorixColors.nivel5Verde,
            content: Text('Cuenta activada exitosamente. Ya puedes iniciar sesión.'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _mensajeError = e.message);
    } catch (e) {
      if (mounted) setState(() => _mensajeError = 'Error al activar la cuenta: $e');
    } finally {
      if (mounted) setState(() => _activando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriorixColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Atrás',
        ),
        title: const PriorixLogo(compact: true),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
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
                        'Activar cuenta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: PriorixColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Si tu cuenta fue creada por el administrador, ingresa tu correo para recibir o validar el código de activación.',
                        style: TextStyle(
                          color: PriorixColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_mensajeInfo != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PriorixColors.cardSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: const Border(
                              left: BorderSide(color: PriorixColors.primaryBlue, width: 4),
                            ),
                          ),
                          child: Text(
                            _mensajeInfo!,
                            style: const TextStyle(fontSize: 13, color: PriorixColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

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
                        const SizedBox(height: 16),
                      ],

                      // Campo de correo
                      const Text(
                        'Correo institucional',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'ejemplo@hospital.com',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _enviandoCodigo ? null : _solicitarCodigo,
                          icon: _enviandoCodigo
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Enviar o reenviar código'),
                          style: TextButton.styleFrom(
                            foregroundColor: PriorixColors.primaryBlue,
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Campo de código OTP
                      const Text(
                        'Código de 6 dígitos',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(
                          letterSpacing: 6,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          hintText: '123456',
                          counterText: '',
                          prefixIcon: Icon(Icons.key_rounded, size: 20),
                        ),
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _activando ? null : _activarCuenta,
                        child: _activando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0F1B2D),
                                ),
                              )
                            : const Text('ACTIVAR CUENTA'),
                      ),

                      const SizedBox(height: 14),

                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Volver al inicio de sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
