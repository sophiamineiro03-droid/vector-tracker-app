import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

class CommunityEditProfileScreen extends StatefulWidget {
  const CommunityEditProfileScreen({super.key});

  @override
  State<CommunityEditProfileScreen> createState() => _CommunityEditProfileScreenState();
}

class _CommunityEditProfileScreenState extends State<CommunityEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  
  File? _imageFile;
  String? _currentPhotoUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // 1. Tenta carregar do CACHE LOCAL primeiro
    try {
      final box = await Hive.openBox('auth_cache');
      final cachedData = box.get('user_profile_${user.id}');
      
      if (cachedData != null) {
        if (mounted) {
          setState(() {
            _nomeController.text = cachedData['nome'] ?? '';
            _currentPhotoUrl = cachedData['foto_url'];
            _isLoading = false; 
          });
        }
      }
    } catch (e) {
      // Ignore
    }

    // 2. Tenta atualizar ONLINE
    try {
      final data = await Supabase.instance.client
          .from('cidadaos')
          .select('nome, foto_url')
          .eq('user_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _nomeController.text = data['nome'] ?? '';
          _currentPhotoUrl = data['foto_url'];
          _isLoading = false;
        });
        
        try {
          final box = await Hive.openBox('auth_cache');
          await box.put('user_profile_${user.id}', data);
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
           setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null) return _currentPhotoUrl;

    try {
      final fileExt = _imageFile!.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/avatar_$timestamp.$fileExt';
      
      await Supabase.instance.client.storage
          .from('profile_pictures')
          .upload(fileName, _imageFile!, fileOptions: const FileOptions(upsert: false));

      final imageUrl = Supabase.instance.client.storage
          .from('profile_pictures')
          .getPublicUrl(fileName);
      
      return '$imageUrl?t=$timestamp';
    } catch (e) {
      debugPrint('Erro detalhado no upload: $e');
      throw Exception('Erro no upload: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      // 1. Upload da imagem
      String? photoUrl = await _uploadImage(userId);

      // 2. Atualiza tabela
      await Supabase.instance.client.from('cidadaos').update({
        'nome': _nomeController.text.trim(),
        'foto_url': photoUrl,
      }).eq('user_id', userId);
      
      // 3. Atualiza Cache Local Imediatamente
      try {
        final box = await Hive.openBox('auth_cache');
        await box.put('user_profile_$userId', {
           'nome': _nomeController.text.trim(),
           'foto_url': photoUrl,
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception:', '').trim();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao salvar: $errorMessage'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _isSaving = true);

    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null) {
        throw Exception('E-mail não encontrado.');
      }

      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verifique seu E-mail'),
            content: Text(
                'Um link para redefinição de senha foi enviado para $email. Siga as instruções no e-mail para criar uma nova senha.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar e-mail: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Editar Perfil'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isSaving ? null : _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                            ),
                            child: ClipOval(
                              child: _imageFile != null
                                  ? Image.file(
                                      _imageFile!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : (_currentPhotoUrl != null
                                      ? SmartImage(
                                          imageSource: _currentPhotoUrl!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.person, size: 60, color: Colors.grey)),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 18,
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                          if (_isSaving)
                            const Positioned.fill(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Informe seu nome' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('SALVAR ALTERAÇÕES', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Alterar Senha'),
                        onPressed: _isSaving ? null : _resetPassword,
                         style: OutlinedButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
