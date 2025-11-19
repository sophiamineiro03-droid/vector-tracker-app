
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_tracker_app/models/agente.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({super.key});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  late Future<Agente?> _agentFuture;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _agentFuture = context.read<AgenteRepository>().getCurrentAgent();
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final imageFile = File(image.path);
      final repository = context.read<AgenteRepository>();
      await repository.uploadAvatar(imageFile);

      setState(() {
        // Força a recarga para exibir a nova imagem e limpar o cache da NetworkImage
        _agentFuture = repository.getCurrentAgent(forceRefresh: true);
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no upload: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _openAppSettings() {
    openAppSettings();
  }

  void _showPermissionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissões do Dispositivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PermissionTile(icon: Icons.location_on_outlined, title: 'Localização', subtitle: 'Coordenadas automáticas da ocorrência.', onTap: _openAppSettings),
            _PermissionTile(icon: Icons.camera_alt_outlined, title: 'Câmera', subtitle: 'Registro de fotos da ocorrência.', onTap: _openAppSettings),
            _PermissionTile(icon: Icons.storage_outlined, title: 'Armazenamento', subtitle: 'Salvar imagens temporariamente.', onTap: _openAppSettings),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('FECHAR')),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
    );
  }

  Widget _buildProfilePicture(BuildContext context, Agente agente) {
    final colorScheme = Theme.of(context).colorScheme;
    ImageProvider? backgroundImage;
    if (agente.avatarUrl != null && agente.avatarUrl!.isNotEmpty) {
      backgroundImage = NetworkImage('${agente.avatarUrl!}?t=${DateTime.now().millisecondsSinceEpoch}');
    }

    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12.0),
        image: backgroundImage != null ? DecorationImage(image: backgroundImage, fit: BoxFit.cover) : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (backgroundImage == null && !_isUploading)
            Icon(Icons.person_outline, size: 90, color: colorScheme.onSurfaceVariant),
          if (_isUploading)
            const CircularProgressIndicator(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: GradientAppBar(title: 'Perfil do Agente'),
      ),
      body: FutureBuilder<Agente?>(
        future: _agentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isUploading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Erro ao carregar os dados do agente.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => setState(() { 
                      _agentFuture = context.read<AgenteRepository>().getCurrentAgent(forceRefresh: true);
                    }), 
                    child: const Text('Tentar Novamente')
                  )
                ],
              ),
            );
          }

          final agente = snapshot.data!;
          final areaAtuacao = agente.localidades.map((loc) => loc.nome).join(', ');

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _agentFuture = context.read<AgenteRepository>().getCurrentAgent(forceRefresh: true);
              });
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(onTap: _isUploading ? null : _pickAndUploadImage, child: _buildProfilePicture(context, agente)),
                  const SizedBox(height: 16),
                  Text(agente.nome, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Área de atuação: $areaAtuacao', style: textTheme.bodyLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0), side: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _ProfileMenuListItem(icon: Icons.camera_alt, iconColor: Colors.orange.shade700, title: 'Alterar Foto do Perfil', onTap: _isUploading ? null : _pickAndUploadImage),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _ProfileMenuListItem(
                          icon: Icons.edit,
                          iconColor: Colors.blue.shade700,
                          title: 'Editar Dados Cadastrais',
                          onTap: () => Navigator.pushNamed(context, '/edit_agent_profile', arguments: agente),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _ProfileMenuListItem(icon: Icons.settings, iconColor: Colors.green.shade700, title: 'Permissões do Dispositivo', onTap: _showPermissionsDialog),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _ProfileMenuListItem(icon: Icons.shield, iconColor: Colors.purple.shade700, title: 'Políticas de Privacidade', onTap: () {}),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _ProfileMenuListItem(icon: Icons.feedback, iconColor: Colors.red.shade700, title: 'Relatar um Problema', onTap: () => Navigator.pushNamed(context, '/report_problem')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('ID: ${agente.userId}', style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Sair do App'),
                      onPressed: () async {
                        await GetIt.I.get<AgenteRepository>().clearAgentOnLogout();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileMenuListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onTap;

  const _ProfileMenuListItem({required this.icon, required this.iconColor, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon, color: iconColor), title: Text(title), trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: onTap);
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PermissionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), onTap: onTap);
  }
}
