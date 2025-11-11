import 'package:flutter/foundation.dart';
import 'package:vector_tracker_app/models/localidade_simples.dart';

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

  final String? municipioNome;
  final List<LocalidadeSimples> localidades;

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
    final agentesLocalidadesData = map['agentes_localidades'] as List?;
    final List<LocalidadeSimples> localidadesLista = [];
    
    if (agentesLocalidadesData != null) {
      for (var item in agentesLocalidadesData) {
        final localidadeData = item?['localidades'];
        if (localidadeData != null) {
          localidadesLista.add(LocalidadeSimples.fromMap(localidadeData));
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
      localidades: localidadesLista,
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
    List<LocalidadeSimples>? localidades,
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
