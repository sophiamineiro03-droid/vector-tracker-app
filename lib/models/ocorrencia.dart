import 'package:vector_tracker_app/models/ocorrencia_enums.dart';

class Ocorrencia {
  final String id;
  final String? agente_id;
  final String? denuncia_id;
  final String? localidade_id;
  final List<TipoAtividade>? tipo_atividade;
  final DateTime? data_atividade;
  final String? numero_pit;
  final String? endereco;
  final String? numero;
  final String? complemento;
  final double? latitude;
  final double? longitude;
  final String? codigo_localidade;
  final String? categoria_localidade;
  final Pendencia? pendencia_pesquisa;
  final Pendencia? pendencia_borrifacao;
  final String? nome_morador;
  final int? numero_anexo;
  final SituacaoImovel? situacao_imovel;
  final String? tipo_parede;
  final String? tipo_teto;
  final bool? melhoria_habitacional;
  final String? vestigios_intradomicilio;
  final int? barbeiros_intradomicilio;
  final String? vestigios_peridomicilio;
  final int? barbeiros_peridomicilio;
  final String? inseticida;
  final int? numero_cargas;
  final String? codigo_etiqueta;
  final List<String>? localImagePaths;
  final List<String>? fotos_urls;
  final DateTime? created_at;
  final bool sincronizado;

  // Campos que existem APENAS no App, não no banco de dados
  final String? municipio_id_ui;
  final String? municipioNome; // <<<< ADICIONADO
  final String? localidade_ui;
  final String? setor_id_ui;

  Ocorrencia({
    required this.id,
    this.agente_id,
    this.denuncia_id,
    this.localidade_id,
    this.tipo_atividade,
    this.data_atividade,
    this.numero_pit,
    this.endereco,
    this.numero,
    this.complemento,
    this.latitude,
    this.longitude,
    this.codigo_localidade,
    this.categoria_localidade,
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
    this.codigo_etiqueta,
    this.localImagePaths,
    this.fotos_urls,
    this.created_at,
    required this.sincronizado,
    this.municipio_id_ui,
    this.municipioNome, // <<<< ADICIONADO
    this.localidade_ui,
    this.setor_id_ui,
  });

  factory Ocorrencia.fromMap(Map<String, dynamic> map) {
    String? extractedMunicipioNome;
    // Lógica para extrair o nome do município de um join com localidades e municípios
    if (map['localidades'] != null && map['localidades'] is Map<String, dynamic>) {
      final localidadesData = map['localidades'] as Map<String, dynamic>;
      if (localidadesData['municipios'] != null &&
          localidadesData['municipios'] is Map<String, dynamic>) {
        final municipiosData = localidadesData['municipios'] as Map<String, dynamic>;
        extractedMunicipioNome = municipiosData['nome'];
      }
    }

    return Ocorrencia(
      id: map['id'] ?? '',
      agente_id: map['agente_id'],
      denuncia_id: map['denuncia_id'],
      localidade_id: map['localidade_id'],
      municipioNome: extractedMunicipioNome, // <<<< ADICIONADO
      tipo_atividade: map['tipo_atividade'] is List
          ? (map['tipo_atividade'] as List)
              .map((e) => TipoAtividade.values.firstWhere((v) => v.name == e,
                  orElse: () => TipoAtividade.pesquisa))
              .toList()
          : [],
      data_atividade: map['data_atividade'] != null
          ? DateTime.parse(map['data_atividade'])
          : null,
      numero_pit: map['numero_pit'],
      endereco: map['endereco'],
      numero: map['numero'],
      complemento: map['complemento'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      codigo_localidade: map['codigo_localidade'],
      categoria_localidade: map['categoria_localidade'],
      pendencia_pesquisa: map['pendencia_pesquisa'] != null
          ? Pendencia.values
              .firstWhere((e) => e.name == map['pendencia_pesquisa'])
          : null,
      pendencia_borrifacao: map['pendencia_borrifacao'] != null
          ? Pendencia.values
              .firstWhere((e) => e.name == map['pendencia_borrifacao'])
          : null,
      nome_morador: map['nome_morador'],
      numero_anexo: map['numero_anexo'],
      situacao_imovel: map['situacao_imovel'] != null
          ? SituacaoImovel.values
              .firstWhere((e) => e.name == map['situacao_imovel'])
          : null,
      tipo_parede: map['tipo_parede'],
      tipo_teto: map['tipo_teto'],
      melhoria_habitacional: map['melhoria_habitacional'],
      vestigios_intradomicilio: map['vestigios_intradomicilio'],
      barbeiros_intradomicilio: map['barbeiros_intradomicilio'],
      vestigios_peridomicilio: map['vestigios_peridomicilio'],
      barbeiros_peridomicilio: map['barbeiros_peridomicilio'],
      inseticida: map['inseticida'],
      numero_cargas: map['numero_cargas'],
      codigo_etiqueta: map['codigo_etiqueta'],
      localImagePaths: map['localImagePaths'] != null
          ? List<String>.from(map['localImagePaths'])
          : [],
      fotos_urls: map['fotos_urls'] != null
          ? List<String>.from(map['fotos_urls'])
          : [],
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      sincronizado: map['sincronizado'] ?? false,
      municipio_id_ui: map['municipio_id_ui'],
      localidade_ui: map['localidade_ui'],
      setor_id_ui: map['setor_id_ui'],
    );
  }

  Map<String, dynamic> toMap() {
    // CORREÇÃO: Apenas campos que existem no banco de dados são incluídos.
    return {
      'id': id,
      'agente_id': agente_id,
      'denuncia_id': denuncia_id,
      'localidade_id': localidade_id,
      'tipo_atividade': tipo_atividade?.map((e) => e.name).toList(),
      'data_atividade': data_atividade?.toIso8601String(),
      'numero_pit': numero_pit,
      'endereco': endereco,
      'numero': numero,
      'complemento': complemento,
      'latitude': latitude,
      'longitude': longitude,
      'codigo_localidade': codigo_localidade,
      'categoria_localidade': categoria_localidade,
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
      'codigo_etiqueta': codigo_etiqueta,
      'created_at': created_at?.toIso8601String(),
      'fotos_urls': fotos_urls,
    };
  }

  Ocorrencia copyWith({
    String? id,
    String? agente_id,
    String? denuncia_id,
    String? localidade_id,
    List<TipoAtividade>? tipo_atividade,
    DateTime? data_atividade,
    String? numero_pit,
    String? endereco,
    String? numero,
    String? complemento,
    double? latitude,
    double? longitude,
    String? codigo_localidade,
    String? categoria_localidade,
    Pendencia? pendencia_pesquisa,
    Pendencia? pendencia_borrifacao,
    String? nome_morador,
    int? numero_anexo,
    SituacaoImovel? situacao_imovel,
    String? tipo_parede,
    String? tipo_teto,
    bool? melhoria_habitacional,
    String? vestigios_intradomicilio,
    int? barbeiros_intradomicilio,
    String? vestigios_peridomicilio,
    int? barbeiros_peridomicilio,
    String? inseticida,
    int? numero_cargas,
    String? codigo_etiqueta,
    List<String>? localImagePaths,
    List<String>? fotos_urls,
    DateTime? created_at,
    bool? sincronizado,
    String? municipio_id_ui,
    String? municipioNome, // <<<< ADICIONADO
    String? localidade_ui,
    String? setor_id_ui,
  }) {
    return Ocorrencia(
      id: id ?? this.id,
      agente_id: agente_id ?? this.agente_id,
      denuncia_id: denuncia_id ?? this.denuncia_id,
      localidade_id: localidade_id ?? this.localidade_id,
      tipo_atividade: tipo_atividade ?? this.tipo_atividade,
      data_atividade: data_atividade ?? this.data_atividade,
      numero_pit: numero_pit ?? this.numero_pit,
      endereco: endereco ?? this.endereco,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      codigo_localidade: codigo_localidade ?? this.codigo_localidade,
      categoria_localidade: categoria_localidade ?? this.categoria_localidade,
      pendencia_pesquisa: pendencia_pesquisa ?? this.pendencia_pesquisa,
      pendencia_borrifacao: pendencia_borrifacao ?? this.pendencia_borrifacao,
      nome_morador: nome_morador ?? this.nome_morador,
      numero_anexo: numero_anexo ?? this.numero_anexo,
      situacao_imovel: situacao_imovel ?? this.situacao_imovel,
      tipo_parede: tipo_parede ?? this.tipo_parede,
      tipo_teto: tipo_teto ?? this.tipo_teto,
      melhoria_habitacional:
          melhoria_habitacional ?? this.melhoria_habitacional,
      vestigios_intradomicilio:
          vestigios_intradomicilio ?? this.vestigios_intradomicilio,
      barbeiros_intradomicilio:
          barbeiros_intradomicilio ?? this.barbeiros_intradomicilio,
      vestigios_peridomicilio:
          vestigios_peridomicilio ?? this.vestigios_peridomicilio,
      barbeiros_peridomicilio:
          barbeiros_peridomicilio ?? this.barbeiros_peridomicilio,
      inseticida: inseticida ?? this.inseticida,
      numero_cargas: numero_cargas ?? this.numero_cargas,
      codigo_etiqueta: codigo_etiqueta ?? this.codigo_etiqueta,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      fotos_urls: fotos_urls ?? this.fotos_urls,
      created_at: created_at ?? this.created_at,
      sincronizado: sincronizado ?? this.sincronizado,
      municipio_id_ui: municipio_id_ui ?? this.municipio_id_ui,
      municipioNome: municipioNome ?? this.municipioNome, // <<<< ADICIONADO
      localidade_ui: localidade_ui ?? this.localidade_ui,
      setor_id_ui: setor_id_ui ?? this.setor_id_ui,
    );
  }
}
