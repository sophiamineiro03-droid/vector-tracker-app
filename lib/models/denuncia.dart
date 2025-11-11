import 'package:flutter/foundation.dart';

@immutable
class Denuncia {
  final String id;
  final String? descricao;
  final double? latitude;
  final double? longitude;
  final String? rua;
  final String? bairro;
  final String? cidade;
  final String? localidade_id;
  final String? estado;
  final String? numero;
  final String? complemento;
  final String? foto_url;
  final DateTime? createdAt;
  final String? status;

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'latitude': latitude,
      'longitude': longitude,
      'rua': rua,
      'bairro': bairro,
      'cidade': cidade,
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
    );
  }
}
