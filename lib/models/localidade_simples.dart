class LocalidadeSimples {
  final String id;
  final String nome;
  final String codigo;
  final String categoria;

  LocalidadeSimples({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.categoria,
  });

  factory LocalidadeSimples.fromMap(Map<String, dynamic> map) {
    return LocalidadeSimples(
      id: map['id'] as String,
      nome: map['nome'] as String,
      codigo: map['codigo'] as String? ?? '',
      categoria: map['categoria'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'codigo': codigo,
      'categoria': categoria,
    };
  }
}
