class Agente {
  final String id;
  final String nome;
  final String? email;
  final String? telefone;
  final String? cargo;
  final String? municipioId;
  final String? municipioNome;
  final String? codigoIbge;
  final String? setorId;
  final String? localidade;
  final bool? ativo;
  final DateTime? createdAt;

  Agente({
    required this.id,
    required this.nome,
    this.email,
    this.telefone,
    this.cargo,
    this.municipioId,
    this.municipioNome,
    this.codigoIbge,
    this.setorId,
    this.localidade,
    this.ativo,
    this.createdAt,
  });

  factory Agente.fromMap(Map<String, dynamic> map) {
    return Agente(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String?,
      telefone: map['telefone'] as String?,
      cargo: map['cargo'] as String?,
      municipioId: map['municipio_id'] as String?,
      setorId: map['setor_id'] as String?,
      localidade: map['setores']?['nome'] as String?,
      ativo: map['ativo'] as bool?,
      createdAt: DateTime.tryParse(map['created_at'] ?? ''),
      municipioNome: map['municipios']?['nome'] as String?,
      codigoIbge: map['municipios']?['codigo_ibge'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cargo': cargo,
      'municipio_id': municipioId,
      'setor_id': setorId,
      'ativo': ativo,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
