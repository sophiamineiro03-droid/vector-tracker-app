import 'package:flutter/foundation.dart';

@immutable
class Agente {
  final String id;
  final String? userId;
  final String? municipioId;
  final String nome;
  final String? email;
  final String? registroMatricula;
  final bool? ativo;
  final DateTime? createdAt;

  // Campos join
  final String? municipioNome;
  final List<String> localidades;

  const Agente({
    required this.id,
    this.userId,
    this.municipioId,
    required this.nome,
    this.email,
    this.registroMatricula,
    this.ativo,
    this.createdAt,
    this.municipioNome,
    this.localidades = const [],
  });

  factory Agente.fromMap(Map<String, dynamic> map) {
    // Lógica para extrair os nomes das localidades da nova estrutura da query
    final agentesLocalidadesData = map['agentes_localidades'] as List?;
    final List<String> localidadesNomes = [];
    if (agentesLocalidadesData != null) {
      for (var item in agentesLocalidadesData) {
        if (item is Map<String, dynamic> && item.containsKey('localidades')) {
          final localidadeData = item['localidades'];
          if (localidadeData is Map<String, dynamic> && localidadeData.containsKey('nome')) {
            localidadesNomes.add(localidadeData['nome']);
          }
        }
      }
    }

    return Agente(
      id: map['id'] ?? '',
      userId: map['user_id'],
      municipioId: map['municipio_id'],
      nome: map['nome'] ?? 'Nome não encontrado',
      email: map['email'],
      registroMatricula: map['registro_matricula'],
      ativo: map['ativo'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      municipioNome: map['municipios'] != null ? map['municipios']['nome'] : 'Município não encontrado',
      localidades: localidadesNomes,
    );
  }

  Agente copyWith({
    String? id,
    String? userId,
    String? municipioId,
    String? nome,
    String? email,
    String? registroMatricula,
    bool? ativo,
    DateTime? createdAt,
    String? municipioNome,
    List<String>? localidades,
  }) {
    return Agente(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      municipioId: municipioId ?? this.municipioId,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      registroMatricula: registroMatricula ?? this.registroMatricula,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      municipioNome: municipioNome ?? this.municipioNome,
      localidades: localidades ?? this.localidades,
    );
  }
}
