import 'package:flutter/foundation.dart';

@immutable
class Denuncia {
  final String id;
  final String? descricao;
  final double? latitude;
  final double? longitude;
  final String? rua;
  final String? bairro;
  final String? localidade;
  final String? cidade;
  final String? estado;
  final String? numero;
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
    this.localidade,
    this.cidade,
    this.estado,
    this.numero,
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
    String? localidade,
    String? cidade,
    String? estado,
    String? numero,
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
      localidade: localidade ?? this.localidade,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      numero: numero ?? this.numero,
      foto_url: foto_url ?? this.foto_url,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'gps_latitude': latitude,
      'gps_longitude': longitude,
      'rua': rua,
      'bairro': bairro,
      'localidade': localidade,
      'cidade': cidade,
      'estado': estado,
      'numero_casa': numero,
      'foto_url': foto_url,
      'criada_em': createdAt?.toIso8601String(),
      'status': status,
    };
  }

  factory Denuncia.fromMap(Map<String, dynamic> map) {
    return Denuncia(
      id: map['id'] ?? '',
      descricao: map['descricao'],
      latitude: map['gps_latitude']?.toDouble(),
      longitude: map['gps_longitude']?.toDouble(),
      rua: map['rua'],
      bairro: map['bairro'],
      localidade: map['localidade'],
      cidade: map['cidade'],
      estado: map['estado'],
      numero: map['numero_casa'],
      foto_url: map['foto_url'],
      createdAt: map['criada_em'] != null ? DateTime.parse(map['criada_em']) : null,
      status: map['status'],
    );
  }
}
