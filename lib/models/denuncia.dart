class Denuncia {
  final String id;
  final String? comunidadeId;
  final String? municipioId;
  final String? setorId;
  final String? descricao;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final bool sincronizado;

  final String? rua;
  final String? numero;
  final String? bairro;

  Denuncia({
    required this.id,
    this.comunidadeId,
    this.municipioId,
    this.setorId,
    this.descricao,
    this.status = 'pendente',
    this.latitude,
    this.longitude,
    this.createdAt,
    this.sincronizado = false,
    this.rua,
    this.numero,
    this.bairro,
  });

  factory Denuncia.fromMap(Map<String, dynamic> map) {
    return Denuncia(
      id: map['id'] as String,
      comunidadeId: map['comunidade_id'] as String?,
      municipioId: map['municipio_id'] as String?,
      setorId: map['setor_id'] as String?,
      descricao: map['descricao'] as String?,
      status: map['status'] as String? ?? 'pendente',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] ?? ''),
      sincronizado: map['sincronizado'] as bool? ?? false,
      rua: map['rua'] as String?,
      numero: map['numero'] as String?,
      bairro: map['bairro'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'comunidade_id': comunidadeId,
      'municipio_id': municipioId,
      'setor_id': setorId,
      'descricao': descricao,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt?.toIso8601String(),
      'sincronizado': sincronizado,
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
    };
  }
}
