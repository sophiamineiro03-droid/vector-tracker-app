
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'ocorrencia_siocchagas.g.dart';

@HiveType(typeId: 1)
class OcorrenciaSiocchagas extends HiveObject {
  @HiveField(0)
  late String localId;

  // Campos de Controle e Identificação
  @HiveField(1)
  String? municipio;
  @HiveField(2)
  String? agente_id;
  @HiveField(3)
  String? denuncia_id;
  @HiveField(4)
  String? status_envio;
  @HiveField(5)
  String? contexto_denuncia;

  // Dados da Atividade e Localização
  @HiveField(6)
  DateTime? data_atividade;
  @HiveField(7)
  String? tipo_atividade;
  @HiveField(8)
  String? numero_pit;
  @HiveField(9)
  String? codigo_localidade;
  @HiveField(10)
  String? categoria_localidade;
  @HiveField(11)
  String? localidade;
  @HiveField(12)
  String? endereco;
  @HiveField(13)
  String? numero;
  @HiveField(14)
  String? complemento;
  @HiveField(15)
  String? nome_morador;
  @HiveField(16)
  int? numero_anexo;

  // Adaptações Digitais (GPS e Mídia)
  @HiveField(17)
  double? gps_latitude;
  @HiveField(18)
  double? gps_longitude;
  @HiveField(19)
  String? foto_url_1;
  @HiveField(20)
  String? foto_url_2;
  @HiveField(21)
  String? foto_url_3;
  @HiveField(22)
  String? foto_url_4;

  // Dados do Domicílio
  @HiveField(23)
  String? situacao_imovel;
  @HiveField(24)
  String? tipo_parede;
  @HiveField(25)
  String? tipo_teto;
  @HiveField(26)
  bool? melhoria_habitacional;

  // Captura Triatomíneo
  @HiveField(27)
  String? triatomineo_intradomicilio;
  @HiveField(28)
  String? vestigios_intradomicilio;
  @HiveField(29)
  int? num_barbeiros_intradomicilio;
  @HiveField(30)
  String? triatomineo_peridomicilio;
  @HiveField(31)
  String? vestigios_peridomicilio;
  @HiveField(32)
  int? num_barbeiros_peridomicilio;

  // Borrifação e Pendências
  @HiveField(33)
  String? inseticida;
  @HiveField(34)
  int? numero_cargas;
  @HiveField(35)
  String? codigo_etiqueta;
  @HiveField(36)
  String? pendencia_pesquisa;
  @HiveField(37)
  String? pendencia_borrifacao;

  OcorrenciaSiocchagas({
    String? localId,
    this.municipio,
    this.agente_id,
    this.denuncia_id,
    this.status_envio = 'Local (Pendente de Sinc.)',
    this.contexto_denuncia,
    this.data_atividade,
    this.tipo_atividade,
    this.numero_pit,
    this.codigo_localidade,
    this.categoria_localidade,
    this.localidade,
    this.endereco,
    this.numero,
    this.complemento,
    this.nome_morador,
    this.numero_anexo,
    this.gps_latitude,
    this.gps_longitude,
    this.foto_url_1,
    this.foto_url_2,
    this.foto_url_3,
    this.foto_url_4,
    this.situacao_imovel,
    this.tipo_parede,
    this.tipo_teto,
    this.melhoria_habitacional,
    this.triatomineo_intradomicilio,
    this.vestigios_intradomicilio,
    this.num_barbeiros_intradomicilio,
    this.triatomineo_peridomicilio,
    this.vestigios_peridomicilio,
    this.num_barbeiros_peridomicilio,
    this.inseticida,
    this.numero_cargas,
    this.codigo_etiqueta,
    this.pendencia_pesquisa,
    this.pendencia_borrifacao,
  }) : localId = localId ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'municipio': municipio,
      'agente_id': agente_id,
      'denuncia_id': denuncia_id,
      'data_atividade': data_atividade?.toIso8601String(),
      'tipo_atividade': tipo_atividade,
      'numero_pit': numero_pit,
      'codigo_localidade': codigo_localidade,
      'categoria_localidade': categoria_localidade,
      'localidade': localidade,
      'endereco': endereco,
      'numero': numero,
      'complemento': complemento,
      'nome_morador': nome_morador,
      'numero_anexo': numero_anexo,
      'gps_latitude': gps_latitude,
      'gps_longitude': gps_longitude,
      'foto_url_1': foto_url_1,
      'foto_url_2': foto_url_2,
      'foto_url_3': foto_url_3,
      'foto_url_4': foto_url_4,
      'situacao_imovel': situacao_imovel,
      'tipo_parede': tipo_parede,
      'tipo_teto': tipo_teto,
      'melhoria_habitacional': melhoria_habitacional,
      'triatomineo_intradomicilio': triatomineo_intradomicilio,
      'vestigios_intradomicilio': vestigios_intradomicilio,
      'num_barbeiros_intradomicilio': num_barbeiros_intradomicilio,
      'triatomineo_peridomicilio': triatomineo_peridomicilio,
      'vestigios_peridomicilio': vestigios_peridomicilio,
      'num_barbeiros_peridomicilio': num_barbeiros_peridomicilio,
      'inseticida': inseticida,
      'numero_cargas': numero_cargas,
      'codigo_etiqueta': codigo_etiqueta,
      'pendencia_pesquisa': pendencia_pesquisa,
      'pendencia_borrifacao': pendencia_borrifacao,
    };
  }
}
