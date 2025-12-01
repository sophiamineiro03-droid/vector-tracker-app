import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  String _userName = 'Carregando...';
  String? _userPhotoUrl;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    
    // PRÉ-CARREGAMENTO: Busca a lista de municípios em segundo plano
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DenunciaService>(context, listen: false).fetchMunicipios();
    });
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _userName = 'Visitante';
        _isGuest = true;
      });
      return;
    }

    // 1. Tenta carregar do CACHE LOCAL primeiro (funciona offline)
    try {
      // Abre (ou pega) a caixa de cache de autenticação
      final box = await Hive.openBox('auth_cache');
      final cachedData = box.get('user_profile_${user.id}');
      
      if (cachedData != null) {
        setState(() {
          _userName = cachedData['nome'] ?? 'Usuário';
          _userPhotoUrl = cachedData['foto_url'];
          _isGuest = false;
        });
      }
    } catch (e) {
      // Ignora erro de cache
    }

    // 2. Tenta atualizar do SERVIDOR (se tiver internet)
    try {
      final data = await Supabase.instance.client
          .from('cidadaos')
          .select('nome, foto_url')
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        if (mounted) {
          setState(() {
            _userName = data['nome'] ?? 'Usuário';
            _userPhotoUrl = data['foto_url'];
            _isGuest = false;
          });
        }
        
        // Atualiza o cache
        try {
          final box = await Hive.openBox('auth_cache');
          await box.put('user_profile_${user.id}', data);
        } catch (_) {}
        
      } else {
         if (mounted && _userName == 'Carregando...') {
            setState(() {
              _userName = 'Usuário sem Perfil';
              _isGuest = false;
            });
         }
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfil online: $e');
      // Se falhar online e não tinha cache, mostra erro ou mantém "Carregando..."
      if (_userName == 'Carregando...') {
         setState(() => _userName = 'Usuário (Offline)');
      }
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Portal da Comunidade'),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Registrar Denúncia'),
              onPressed: () {
                Navigator.pushNamed(context, '/denuncia');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt),
              label: const Text('Minhas Denúncias'),
              onPressed: () {
                Navigator.pushNamed(context, '/minhas_denuncias');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.school),
              label: const Text('Seção Educativa'),
              onPressed: () {
                Navigator.pushNamed(context, '/educacao');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF39A2AE), Color(0xFF2979FF)],
              ),
            ),
            accountName: Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text(_isGuest ? 'Modo Visitante' : (Supabase.instance.client.auth.currentUser?.email ?? '')),
            currentAccountPicture: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: ClipOval(
                child: _userPhotoUrl != null
                    ? SmartImage(
                        imageSource: _userPhotoUrl!,
                        fit: BoxFit.cover,
                        width: 72,
                        height: 72,
                      )
                    : const Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
          ),
          if (!_isGuest) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar Dados Cadastrais'),
              onTap: () async {
                Navigator.pop(context); // Fecha o Drawer
                // Navega para edição e aguarda retorno
                final result = await Navigator.pushNamed(context, '/community_profile_edit');
                if (result == true) {
                   // Se salvou alterações, recarrega o perfil
                   _loadUserProfile();
                }
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Permissões do App'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context, 
                builder: (c) => AlertDialog(
                  title: const Text('Permissões'),
                  content: const Text('Para funcionar corretamente, o app precisa de acesso à Câmera (fotos) e Localização (GPS). Verifique as configurações do seu celular.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                )
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Políticas de Privacidade'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context, 
                builder: (c) => AlertDialog(
                  title: const Text('Privacidade'),
                  content: const Text('Em breve.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar'))],
                )
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Relatar um Problema'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/report_problem');
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(_isGuest ? Icons.login : Icons.logout, color: Colors.red),
            title: Text(_isGuest ? 'Fazer Login' : 'Sair da Conta', style: const TextStyle(color: Colors.red)),
            onTap: () {
              _signOut();
            },
          ),
        ],
      ),
    );
  }
}
