import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/priorix_theme.dart';
import '../../models/models.dart';
import '../perfil/perfil_screen.dart';

class UsuariosAdminScreen extends StatefulWidget {
  const UsuariosAdminScreen({super.key});

  @override
  State<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends State<UsuariosAdminScreen> {
  List<UsuarioModel> _usuarios = [];
  bool _cargando = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios([String? query]) async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final res = await ApiClient.instance.getUsuarios(q: query);
      if (mounted) {
        setState(() {
          _usuarios = res;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Future<void> _crearUsuario() async {
    final formKey = GlobalKey<FormState>();
    final userCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String rol = 'ROLE_ENFERMERO';

    final creado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: PriorixColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: PriorixColors.border),
          ),
          title: const Text('Nuevo usuario', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Se creará la cuenta y se enviará un código de activación al correo.',
                    style: TextStyle(fontSize: 12, color: PriorixColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: rol,
                    decoration: const InputDecoration(labelText: 'Rol *'),
                    items: const [
                      DropdownMenuItem(value: 'ROLE_ENFERMERO', child: Text('Enfermero')),
                      DropdownMenuItem(value: 'ROLE_MEDICO', child: Text('Médico')),
                      DropdownMenuItem(value: 'ROLE_ADMIN', child: Text('Administrador')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => rol = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: userCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre de usuario *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico *'),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña *'),
                    validator: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ApiClient.instance.crearUsuario(
                    username: userCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    rol: rol,
                  );
                  // Enviar código de activación
                  try {
                    await ApiClient.instance.enviarCodigoActivacion(emailCtrl.text.trim());
                  } catch (_) {}
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: PriorixColors.primaryBlue,
                foregroundColor: const Color(0xFF0F1B2D),
              ),
              child: const Text('Guardar y enviar código'),
            ),
          ],
        ),
      ),
    );

    if (creado == true) {
      _cargarUsuarios();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: PriorixColors.nivel5Verde,
            content: Text('Usuario registrado exitosamente. Se envió el código de activación.'),
          ),
        );
      }
    }
  }

  Future<void> _editarUsuario(UsuarioModel u) async {
    final formKey = GlobalKey<FormState>();
    final userCtrl = TextEditingController(text: u.username);
    final emailCtrl = TextEditingController(text: u.email);
    final passCtrl = TextEditingController();
    String rol = u.rol;

    final editado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: PriorixColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: PriorixColors.border),
          ),
          title: const Text('Editar usuario', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: rol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: const [
                      DropdownMenuItem(value: 'ROLE_ENFERMERO', child: Text('Enfermero')),
                      DropdownMenuItem(value: 'ROLE_MEDICO', child: Text('Médico')),
                      DropdownMenuItem(value: 'ROLE_ADMIN', child: Text('Administrador')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => rol = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: userCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre de usuario'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña (opcional)',
                      hintText: 'Déjala vacía para conservar la actual',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  // Actualizar en el servidor
                  await ApiClient.instance.crearUsuario(
                    username: userCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    rol: rol,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: PriorixColors.primaryBlue,
                foregroundColor: const Color(0xFF0F1B2D),
              ),
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );

    if (editado == true) {
      _cargarUsuarios();
    }
  }

  Future<void> _toggleActivo(UsuarioModel u, bool valor) async {
    try {
      await ApiClient.instance.toggleUsuarioActivo(u.id, valor);
      _cargarUsuarios();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _eliminarUsuario(UsuarioModel u) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PriorixColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PriorixColors.border),
        ),
        title: const Text('¿Eliminar usuario?'),
        content: Text('Se eliminará permanentemente la cuenta de ${u.username}. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: PriorixColors.nivel1Rojo),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar usuario'),
          ),
        ],
      ),
    );

    if (conf == true) {
      try {
        await ApiClient.instance.eliminarUsuario(u.id);
        _cargarUsuarios();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario eliminado correctamente.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
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
          tooltip: '‹ Atrás',
        ),
        title: const Text('Gestión de Usuarios', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () => _cargarUsuarios(_searchCtrl.text.trim()),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PriorixColors.primaryBlue,
        foregroundColor: const Color(0xFF0F1B2D),
        onPressed: _crearUsuario,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 22),
        label: const Text('Nuevo usuario', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre de usuario o correo...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                _cargarUsuarios();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (val) => _cargarUsuarios(val.trim()),
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: PriorixColors.primaryBlue));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: PriorixColors.nivel1Rojo),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: PriorixColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargarUsuarios, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    if (_usuarios.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.manage_accounts_outlined, size: 54, color: PriorixColors.textSecondary),
              SizedBox(height: 16),
              Text('No se encontraron usuarios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 6),
              Text('Registra una nueva cuenta con el botón "Nuevo usuario".', style: TextStyle(color: PriorixColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _usuarios.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final u = _usuarios[index];
        final roleColor = u.rol.contains('ADMIN')
            ? PriorixColors.primaryBlue
            : u.rol.contains('MEDICO')
                ? PriorixColors.nivel3Amarillo
                : PriorixColors.nivel5Verde;

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PerfilScreen(usuario: u)),
            ),
            leading: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PerfilScreen(usuario: u)),
              ),
              child: CircleAvatar(
                radius: 23,
                backgroundColor: roleColor.withOpacity(0.18),
                child: Icon(Icons.person_rounded, size: 24, color: roleColor),
              ),
            ),
            title: Text(u.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(u.email, style: const TextStyle(color: PriorixColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: roleColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        u.rolLegible,
                        style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      u.activo ? 'Activo' : 'Inactivo (Pendiente código)',
                      style: TextStyle(
                        fontSize: 11,
                        color: u.activo ? PriorixColors.onlineGreenLight : PriorixColors.offlineOrangeLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: PriorixColors.textSecondary),
                  onPressed: () => _editarUsuario(u),
                  tooltip: 'Editar usuario',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: PriorixColors.nivel1Rojo),
                  onPressed: () => _eliminarUsuario(u),
                  tooltip: 'Eliminar usuario',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
