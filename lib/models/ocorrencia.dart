import 'package:vector_tracker_app/models/ocorrencia_enums.dart';

class Ocorrencia {
  final String id;
  final String? agente_id;
  final String? denuncia_id;
  final String? municipio_id;
  final String? setor_id;

  // Dados da Atividade
  final TipoAtividade? tipo_atividade;
  final DateTime? data_atividade;
  final String? numero_pit;

  // Dados do Domicílio
  final String? codigo_localidade;
  final String? categoria_localidade;
  final String? localidade;
  final String? endereco;
  final String? numero;
  final String? complemento;

  // Pendências
  final Pendencia? pendencia_pesquisa;
  final Pendencia? pendencia_borrifacao;

  // Morador
  final String? nome_morador;
  final int? numero_anexo;

  // Situação do imóvel
  final SituacaoImovel? situacao_imovel;

  // Tipo de parede e teto
  final String? tipo_parede;
  final String? tipo_teto;

  // Melhoria Habitacional (bool)
  final bool? melhoria_habitacional;

  // Captura de Triatomíneo
  final String? vestigios_intradomicilio;
  final int? barbeiros_intradomicilio;
  final String? vestigios_peridomicilio;
  final int? barbeiros_peridomicilio;

  // Borrifação
  final String? inseticida;
  final int? numero_cargas;
  final String? codigo_etiqueta; // RESTAURADO

  // Localização
  final double? latitude;
  final double? longitude;

  // Controle
  final bool sincronizado;
  final String status;
  final DateTime? created_at;

  // Apenas local
  final List<String>? localImagePaths;

  Ocorrencia({
    required this.id,
    this.agente_id,
    this.denuncia_id,
    this.municipio_id,
    this.setor_id,
    this.tipo_atividade,
    this.data_atividade,
    this.numero_pit,
    this.codigo_localidade,
    this.categoria_localidade,
    this.localidade,
    this.endereco,
    this.numero,
    this.complemento,
    this.pendencia_pesquisa,
    this.pendencia_borrifacao,
    this.nome_morador,
    this.numero_anexo,
    this.situacao_imovel,
    this.tipo_parede,
    this.tipo_teto,
    this.melhoria_habitacional,
    this.vestigios_intradomicilio,
    this.barbeiros_intradomicilio,
    this.vestigios_peridomicilio,
    this.barbeiros_peridomicilio,
    this.inseticida,
    this.numero_cargas,
    this.codigo_etiqueta, // RESTAURADO
    this.latitude,
    this.longitude,
    this.sincronizado = false,
    this.status = 'pendente',
    this.created_at,
    this.localImagePaths,
  });

  factory Ocorrencia.fromMap(Map<String, dynamic> map) {
    return Ocorrencia(
      id: map['id'] as String,
      agente_id: map['agente_id'] as String?,
      denuncia_id: map['denuncia_id'] as String?,
      municipio_id: map['municipio_id'] as String?,
      setor_id: map['setor_id'] as String?,
      tipo_atividade: map['tipo_atividade'] != null ? TipoAtividade.values.firstWhere((e) => e.name == map['tipo_atividade'], orElse: () => TipoAtividade.pesquisa) : null,
      data_atividade: DateTime.tryParse(map['data_atividade'] ?? ''),
      numero_pit: map['numero_pit'] as String?,
      codigo_localidade: map['codigo_localidade'] as String?,
      categoria_localidade: map['categoria_localidade'] as String?,
      localidade: map['localidade'] as String?,
      endereco: map['endereco'] as String?,
      numero: map['numero'] as String?,
      complemento: map['complemento'] as String?,
      pendencia_pesquisa: map['pendencia_pesquisa'] != null ? Pendencia.values.firstWhere((e) => e.name == map['pendencia_pesquisa'], orElse: () => Pendencia.semPendencias) : null,
      pendencia_borrifacao: map['pendencia_borrifacao'] != null ? Pendencia.values.firstWhere((e) => e.name == map['pendencia_borrifacao'], orElse: () => Pendencia.semPendencias) : null,
      nome_morador: map['nome_morador'] as String?,
      numero_anexo: map['numero_anexo'] as int?,
      situacao_imovel: map['situacao_imovel'] != null ? SituacaoImovel.values.firstWhere((e) => e.name == map['situacao_imovel'], orElse: () => SituacaoImovel.nova) : null,
      tipo_parede: map['tipo_parede'] as String?,
      tipo_teto: map['tipo_teto'] as String?,
      melhoria_habitacional: map['melhoria_habitacional'] as bool?,
      vestigios_intradomicilio: map['vestigios_intradomicilio'] as String?,
      barbeiros_intradomicilio: map['barbeiros_intradomicilio'] as int?,
      vestigios_peridomicilio: map['vestigios_peridomicilio'] as String?,
      barbeiros_peridomicilio: map['barbeiros_peridomicilio'] as int?,
      inseticida: map['inseticida'] as String?,
      numero_cargas: map['numero_cargas'] as int?,
      codigo_etiqueta: map['codigo_etiqueta'] as String?, // RESTAURADO
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      sincronizado: map['sincronizado'] as bool? ?? false,
      status: map['status'] as String? ?? 'pendente',
      created_at: DateTime.tryParse(map['created_at'] ?? ''),
      localImagePaths: (map['localImagePaths'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agente_id': agente_id,
      'denuncia_id': denuncia_id,
      'municipio_id': municipio_id,
      'setor_id': setor_id,
      'tipo_atividade': tipo_atividade?.name,
      'data_atividade': data_atividade?.toIso8601String(),
      'numero_pit': numero_pit,
      'codigo_localidade': codigo_localidade,
      'categoria_localidade': categoria_localidade,
      'localidade': localidade,
      'endereco': endereco,
      'numero': numero,
      'complemento': complemento,
      'pendencia_pesquisa': pendencia_pesquisa?.name,
      'pendencia_borrifacao': pendencia_borrifacao?.name,
      'nome_morador': nome_morador,
      'numero_anexo': numero_anexo,
      'situacao_imovel': situacao_imovel?.name,
      'tipo_parede': tipo_parede,
      'tipo_teto': tipo_teto,
      'melhoria_habitacional': melhoria_habitacional,
      'vestigios_intradomicilio': vestigios_intradomicilio,
      'barbeiros_intradomicilio': barbeiros_intradomicilio,
      'vestigios_peridomicilio': vestigios_peridomicilio,
      'barbeiros_peridomicilio': barbeiros_peridomicilio,
      'inseticida': inseticida,
      'numero_cargas': numero_cargas,
      'codigo_etiqueta': codigo_etiqueta, // RESTAURADO
      'latitude': latitude,
      'longitude': longitude,
      'sincronizado': sincronizado,
      'status': status,
      'created_at': created_at?.toIso8601String(),
      'localImagePaths': localImagePaths,
    };
  }
}
