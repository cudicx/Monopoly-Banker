import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'player.dart';
import 'game.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'monopoly_banker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            startingBalance INTEGER,
            passingMoney INTEGER,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE players (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            balance INTEGER,
            bankrupt INTEGER,
            gameId INTEGER,
            FOREIGN KEY (gameId) REFERENCES games(id)
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Eski tabloları sil
          await db.execute('DROP TABLE IF EXISTS players');
          await db.execute('DROP TABLE IF EXISTS games');
          
          // Yeni tabloları oluştur
          await db.execute('''
            CREATE TABLE games (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              startingBalance INTEGER,
              passingMoney INTEGER,
              createdAt TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE players (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              balance INTEGER,
              bankrupt INTEGER,
              gameId INTEGER,
              FOREIGN KEY (gameId) REFERENCES games(id)
            )
          ''');
        }
      },
    );
  }

  // Game CRUD
  Future<int> insertGame(Game game, {int startingBalance = 0, int passingMoney = 0}) async {
    final dbClient = await db;
    return await dbClient.insert('games', {
      'name': game.name,
      'startingBalance': startingBalance,
      'passingMoney': passingMoney,
      'createdAt': game.createdAt.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getGames() async {
    final dbClient = await db;
    final result = await dbClient.query('games');
    // NULL değerleri 0 ile değiştir
    return result.map((game) {
      return {
        ...game,
        'startingBalance': game['startingBalance'] ?? 0,
        'passingMoney': game['passingMoney'] ?? 0,
      };
    }).toList();
  }

  Future<int> deleteGame(int id) async {
    final dbClient = await db;
    await dbClient.delete('players', where: 'gameId = ?', whereArgs: [id]);
    return await dbClient.delete('games', where: 'id = ?', whereArgs: [id]);
  }

  // Player CRUD
  Future<int> insertPlayer(Player player, int gameId) async {
    final dbClient = await db;
    return await dbClient.insert('players', {
      'name': player.name,
      'balance': player.balance,
      'bankrupt': player.bankrupt ? 1 : 0,
      'gameId': gameId,
    });
  }

  Future<List<Map<String, dynamic>>> getPlayers(int gameId) async {
    final dbClient = await db;
    return await dbClient.query('players', where: 'gameId = ?', whereArgs: [gameId]);
  }

  Future<int> updatePlayer(Player player, int gameId) async {
    final dbClient = await db;
    return await dbClient.update(
      'players',
      {
        'name': player.name,
        'balance': player.balance,
        'bankrupt': player.bankrupt ? 1 : 0,
        'gameId': gameId,
      },
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<int> deletePlayer(int id) async {
    final dbClient = await db;
    return await dbClient.delete('players', where: 'id = ?', whereArgs: [id]);
  }
}
