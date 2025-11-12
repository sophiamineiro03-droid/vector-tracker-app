import 'package:flutter/foundation.dart';

@immutable
class Denuncia {
  final String id;
  final String? descricao;
  final double? latitude;
  final double? longitude;
  final String? rua;
  final String? bairro;
  final String? cidade; // Continua sendo o ID do município, para salvar no banco.
  final String? localidade_id;
  final String? estado;
  final String? numero;
  final String? complemento;
  final String? foto_url;
  final DateTime? createdAt;
  final String? status;

  // Campos NOVOS para exibição. Eles não existem na tabela 'denuncias',
  // mas serão preenchidos pelo Supabase usando um JOIN.
  final String? municipioNome;
  final String? localidadeNome;

  const Denuncia({
    required this.id,
    this.descricao,
    this.latitude,
    this.longitude,
    this.rua,
    this.bairro,
    this.cidade,
    this.localidade_id,
    this.estado,
    this.numero,
    this.complemento,
    this.foto_url,
    this.createdAt,
    this.status,
    this.municipioNome, // Adicionado
    this.localidadeNome, // Adicionado
  });

  Denuncia copyWith({
    String? id,
    String? descricao,
    double? latitude,
    double? longitude,
    String? rua,
    String? bairro,
    String? cidade,
    String? localidade_id,
    String? estado,
    String? numero,
    String? complemento,
    String? foto_url,
    DateTime? createdAt,
    String? status,
    String? municipioNome,
    String? localidadeNome,
  }) {
    return Denuncia(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rua: rua ?? this.rua,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      localidade_id: localidade_id ?? this.localidade_id,
      estado: estado ?? this.estado,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      foto_url: foto_url ?? this.foto_url,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      municipioNome: municipioNome ?? this.municipioNome,
      localidadeNome: localidadeNome ?? this.localidadeNome,
    );
  }

  Map<String, dynamic> toMap() {
    // Os campos de exibição (municipioNome) não são enviados ao salvar.
    return {
      'id': id,
      'descricao': descricao,
      'latitude': latitude,
      'longitude': longitude,
      'rua': rua,
      'bairro': bairro,
      'cidade': cidade, // Continua enviando o ID do município.
      'localidade_id': localidade_id,
      'estado': estado,
      'numero': numero,
      'complemento': complemento,
      'foto_url': foto_url,
      'created_at': createdAt?.toIso8601String(),
      'status': status,
    };
  }

  factory Denuncia.fromMap(Map<String, dynamic> map) {
    
    // Função auxiliar para extrair o nome de um mapa aninhado, 
    // que é como o Supabase retorna os dados de um JOIN.
    String? extrairNome(dynamic data) {
      if (data is Map && data.containsKey('nome')) {
        return data['nome'];
      }
      return null;
    }

    return Denuncia(
      id: map['id'] ?? '',
      descricao: map['descricao'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      rua: map['rua'],
      bairro: map['bairro'],
      cidade: map['cidade'],
      localidade_id: map['localidade_id'],
      estado: map['estado'],
      numero: map['numero'],
      complemento: map['complemento'],
      foto_url: map['foto_url'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      status: map['status'],

      // O Supabase retornará um mapa chamado 'municipios' com os dados do JOIN.
      municipioNome: extrairNome(map['municipios']), 
      localidadeNome: extrairNome(map['localidades']),
    );
  }
}
