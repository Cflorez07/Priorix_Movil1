import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/theme/priorix_theme.dart';

class CamaraTriajeScreen extends StatefulWidget {
  const CamaraTriajeScreen({super.key});

  @override
  State<CamaraTriajeScreen> createState() => _CamaraTriajeScreenState();
}

class _CamaraTriajeScreenState extends State<CamaraTriajeScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  String? _errorMessage;
  XFile? _capturedImage;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No se detectó ninguna cámara disponible en este dispositivo.';
        });
        return;
      }

      // Priorizar cámara trasera para registro de lesiones
      final selectedCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        if (e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt') {
          _errorMessage = 'Permiso de cámara denegado. Puedes otorgarlo en Ajustes o continuar sin foto.';
        } else {
          _errorMessage = 'Error al acceder a la cámara: ${e.description ?? e.code}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Error inesperado al inicializar la cámara: $e';
      });
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    try {
      final file = await controller.takePicture();
      if (mounted) {
        setState(() {
          _capturedImage = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar imagen: $e')),
        );
      }
    }
  }

  Future<void> _confirmPicture() async {
    if (_capturedImage == null) return;
    try {
      final bytes = await File(_capturedImage!.path).readAsBytes();
      final base64String = base64Encode(bytes);
      if (mounted) {
        Navigator.of(context).pop({
          'path': _capturedImage!.path,
          'base64': base64String,
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop({'path': _capturedImage!.path});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Fotografía Clínica de Triaje', style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        child: _capturedImage != null
            ? _buildPreviewCaptured()
            : _buildCameraView(),
      ),
    );
  }

  Widget _buildPreviewCaptured() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Image.file(
              File(_capturedImage!.path),
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          color: PriorixColors.card,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _capturedImage = null),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tomar otra'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PriorixColors.textPrimary,
                    side: const BorderSide(color: PriorixColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmPicture,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Adjuntar foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PriorixColors.primaryBlue,
                    foregroundColor: const Color(0xFF0F1B2D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraView() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: PriorixColors.primaryBlue),
            SizedBox(height: 16),
            Text('Iniciando cámara...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, size: 64, color: PriorixColors.nivel2Naranja),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PriorixColors.cardSecondary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continuar sin foto'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: Text('Cámara no lista', style: TextStyle(color: Colors.white)));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: CameraPreview(controller)),

        // Controles de disparo y flash en la parte inferior
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () async {
                  try {
                    final nextMode = _flashOn ? FlashMode.off : FlashMode.torch;
                    await controller.setFlashMode(nextMode);
                    setState(() => _flashOn = !_flashOn);
                  } catch (_) {}
                },
              ),
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
