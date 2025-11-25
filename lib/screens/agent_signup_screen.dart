import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class AgentSignupScreen extends StatefulWidget {
  const AgentSignupScreen({super.key});

  @override
  State<AgentSignupScreen> createState() => _AgentSignupScreenState();
}

class _AgentSignupScreenState extends State<AgentSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Dados para os seletores
  List<Map<String, dynamic>> _municipios = [];
  List<Map<String, dynamic>> _localidadesDisponiveis = [];
  
  String? _selectedMunicipioId;
  final List<String> _selectedLocalidadesIds = [];
  String _selectedLocalidadesNames = ""; // Para exibir no campo

  @override
  void initState() {
    super.initState();
    _loadMunicipios();
  }

  Future<void> _loadMunicipios() async {
    try {
      final response = await Supabase.instance.client
          .from('municipios')
          .select('id, nome')
          .order('nome');
      
      if (mounted) {
        setState(() {
          _municipios = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar municípios: $e')),
        );
      }
    }
  }

  Future<void> _loadLocalidades(String municipioId) async {
    setState(() {
      _isLoading = true;
      _localidadesDisponiveis = [];
      _selectedLocalidadesIds.clear();
      _selectedLocalidadesNames = "";
    });

    try {
      final response = await Supabase.instance.client
          .from('localidades')
          .select('id, nome, codigo')
          .eq('municipio_id', municipioId)
          .order('nome');

      if (mounted) {
        setState(() {
          _localidadesDisponiveis = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar localidades: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openLocalidadeSelector() async {
    if (_selectedMunicipioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um município primeiro.')),
      );
      return;
    }

    if (_localidadesDisponiveis.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma localidade encontrada para este município.')),
      );
      return;
    }

    // Mostra um Dialog com checkboxes
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Selecione as Localidades'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _localidadesDisponiveis.length,
                  itemBuilder: (context, index) {
                    final loc = _localidadesDisponiveis[index];
                    final isSelected = _selectedLocalidadesIds.contains(loc['id']);
                    return CheckboxListTile(
                      title: Text(loc['nome']),
                      subtitle: Text(loc['codigo'] ?? ''),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            _selectedLocalidadesIds.add(loc['id']);
                          } else {
                            _selectedLocalidadesIds.remove(loc['id']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    // Atualiza o texto de exibição
    setState(() {
      final selectedNames = _localidadesDisponiveis
          .where((loc) => _selectedLocalidadesIds.contains(loc['id']))
          .map((loc) => loc['nome'])
          .join(', ');
      _selectedLocalidadesNames = selectedNames;
    });
  }

  Future<void> _registerAgent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMunicipioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um município.')),
      );
      return;
    }

    if (_selectedLocalidadesIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione pelo menos uma localidade.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Cria o usuário na Autenticação
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'nome': _nameController.text.trim(),
          'municipio_id': _selectedMunicipioId, // Enviando metadados extras
        },
      );

      final user = authResponse.user;
      final session = authResponse.session;

      if (user == null) {
        throw 'Falha ao criar usuário.';
      }

      // IMPORTANTE: Se a confirmação de e-mail estiver ligada no Supabase, a sessão será nula
      // e o insert abaixo vai falhar com erro de RLS (Unauthorized).
      // Solução: Desligar "Confirm Email" no painel do Supabase.

      if (session == null) {
         throw 'Cadastro iniciado! Porém, verifique se a opção "Confirm Email" está desativada no Supabase, ou verifique seu e-mail antes de continuar.';
      }

      // 2. Cria o registro na tabela `agentes`
      final agenteResponse = await supabase.from('agentes').insert({
        'user_id': user.id,
        'nome': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'municipio_id': _selectedMunicipioId,
        'ativo': true, 
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final agenteId = agenteResponse['id'];

      // 3. Vincula as localidades na tabela `agentes_localidades`
      final List<Map<String, dynamic>> vinculos = _selectedLocalidadesIds.map((locId) {
        return {
          'agente_id': agenteId,
          'localidade_id': locId,
        };
      }).toList();

      if (vinculos.isNotEmpty) {
        await supabase.from('agentes_localidades').insert(vinculos);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/agent_home', (route) => false);
      }

    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de Autenticação: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no cadastro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: GradientAppBar(title: 'Cadastro de Agente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Preencha seus dados para criar uma conta de agente.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Informe seu nome' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Informe um e-mail válido' : null,
              ),
              const SizedBox(height: 16),

              // Senha
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v == null || v.length < 6 ? 'A senha deve ter no mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 24),

              const Divider(),
              const SizedBox(height: 16),
              const Text('Área de Atuação', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Município Dropdown
              DropdownButtonFormField<String>(
                value: _selectedMunicipioId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Município',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                items: _municipios.map((m) {
                  return DropdownMenuItem<String>(
                    value: m['id'],
                    child: Text(m['nome']),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMunicipioId = value;
                    });
                    _loadLocalidades(value);
                  }
                },
                validator: (v) => v == null ? 'Selecione um município' : null,
              ),
              const SizedBox(height: 16),

              // Localidades Seletor
              InkWell(
                onTap: _openLocalidadeSelector,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Localidades',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedLocalidadesNames.isEmpty 
                        ? 'Toque para selecionar...' 
                        : _selectedLocalidadesNames,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _selectedLocalidadesNames.isEmpty ? Colors.black54 : Colors.black87
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _registerAgent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CRIAR CONTA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
