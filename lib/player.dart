class Player {
  int id;
  String name;
  int? balance;
  bool bankrupt;

  Player({
    required this.id,
    required this.name,
    this.balance,
    this.bankrupt = false,
  });
}