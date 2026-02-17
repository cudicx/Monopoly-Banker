import 'player.dart';

class Game {
  int id;
  String name;
  List<Player> players;
  DateTime createdAt;

  Game({
    required this.id,
    required this.name,
    required this.players,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
