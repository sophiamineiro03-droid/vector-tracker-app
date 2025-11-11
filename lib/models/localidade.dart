class Localidade {
  final String id;
  final String nome;

  Localidade({required this.id, required this.nome});

  factory Localidade.fromMap(Map<String, dynamic> map) {
    return Localidade(
      id: map['id'] as String,
      nome: map['nome'] as String,
    );
  }
}
