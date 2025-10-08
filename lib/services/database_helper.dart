import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const _dbName = 'vector_tracker.db';
  static const _dbVersion = 2; // <<< VERSÃO DO BANCO DE DADOS ATUALIZADA

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // <<< ROTINA DE ATUALIZAÇÃO ADICIONADA
    );
  }

  // Cria o banco de dados para novas instalações
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE pending_visits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        unique_id TEXT NOT NULL UNIQUE -- Garante que cada visita seja única
    )
    ''');
  }

  // Atualiza o banco de dados para usuários existentes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // A maneira mais simples de atualizar é recriar a tabela.
      // Isso apagará os dados pendentes existentes, mas corrigirá a estrutura.
      await db.execute('DROP TABLE IF EXISTS pending_visits');
      await _onCreate(db, newVersion);
    }
  }

  // Insere ou ATUALIZA uma visita pendente no banco de dados local
  Future<int> insertPendingVisit(String data, String uniqueId) async {
    final db = await database;
    return await db.insert(
      'pending_visits',
      {'data': data, 'unique_id': uniqueId},
      // Se uma visita com o mesmo unique_id já existir, ela será substituída.
      // Isso evita duplicatas e erros.
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Busca todas as visitas pendentes
  Future<List<Map<String, dynamic>>> getPendingVisits() async {
    final db = await database;
    return await db.query('pending_visits');
  }

  // Deleta uma visita pendente pelo seu ID único
  Future<int> deletePendingVisit(String uniqueId) async {
    final db = await database;
    return await db.delete('pending_visits', where: 'unique_id = ?', whereArgs: [uniqueId]);
  }
}
