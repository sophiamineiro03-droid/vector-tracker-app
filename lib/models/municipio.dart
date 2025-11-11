class Municipio {
  final String id;
  final String nome;

  Municipio({required this.id, required this.nome});

  factory Municipio.fromMap(Map<String, dynamic> map) {
    return Municipio(
      id: map['id'] as String,
      nome: map['nome'] as String,
    );
  }
}
