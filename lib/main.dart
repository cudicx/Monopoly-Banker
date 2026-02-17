import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'player.dart';
import 'game.dart';
import 'package:audioplayers/audioplayers.dart';

// Global Ayarlar
class AppSettings {
  static bool isMuted = false;
  static String language = 'tr'; // 'tr' veya 'en'
}

// Çeviri sistemi
Map<String, Map<String, String>> translations = {
  'tr': {
    'newGameName': 'Yeni Oyun Adı',
    'start': 'Başlangıç',
    'players': 'Oyuncular',
    'playerName': 'Oyuncu Adı',
    'add': 'Ekle',
    'startingMoney': 'Başlangıç Parası',
    'passingMoney': 'Başlangıçtan Geçiş Parası',
    'startGame': 'Oyuna Başla',
    'enterAmount': 'Tutar Giriniz',
    'subtract': 'Çıkar',
    'distributeToAll': 'Herkese Dağıt',
    'transfer': 'Aktar',
    'selectPlayer': 'Aktarılacak Oyuncu',
    'passStart': 'Başlangıçtan Geç',
    'bankrupt': 'İflas',
    'undoBankrupt': 'İflası Geri Al',
    'bankruptLabel': 'İFLAS',
    'settings': 'Ayarlar',
    'muteMode': 'Sessiz Mod',
    'language': 'Dil',
    'turkish': 'Türkçe',
    'english': 'İngilizce',
    'enterGameName': 'Lütfen oyun adını girin',
    'enterValidAmount': 'Lütfen geçerli bir tutar girin',
    'noUndoAction': 'Geri alınacak işlem yok',
    'undoSuccess': 'Son işlem geri alındı',
    'fillAllFields': 'Lütfen tüm alanları doldurun',
    'created': 'Başlangıç',
  },
  'en': {
    'newGameName': 'New Game Name',
    'start': 'Start',
    'players': 'Players',
    'playerName': 'Player Name',
    'add': 'Add',
    'startingMoney': 'Starting Money',
    'passingMoney': 'Passing Money',
    'startGame': 'Start Game',
    'enterAmount': 'Enter Amount',
    'subtract': 'Subtract',
    'distributeToAll': 'Distribute',
    'transfer': 'Transfer',
    'selectPlayer': 'Select Player',
    'passStart': 'Pass Start',
    'bankrupt': 'Bankrupt',
    'undoBankrupt': 'Undo Bankrupt',
    'bankruptLabel': 'BANKRUPT',
    'settings': 'Settings',
    'muteMode': 'Mute Mode',
    'language': 'Language',
    'turkish': 'Turkish',
    'english': 'English',
    'enterGameName': 'Please enter game name',
    'enterValidAmount': 'Please enter a valid amount',
    'noUndoAction': 'No action to undo',
    'undoSuccess': 'Last action undone',
    'fillAllFields': 'Please fill all fields',
    'created': 'Created',
  },
};

String tr(String key) {
  return translations[AppSettings.language]?[key] ?? key;
}

Future<void> playMoneySound() async {
  if (AppSettings.isMuted) return;
  try {
    final player = AudioPlayer();
    await player.setSource(AssetSource('audio/para.m4a'));
    await player.resume();
    player.onPlayerComplete.listen((_) {
      player.dispose();
    });
  } catch (e) {
    print('Ses çalınırken hata: $e');
  }
}

Future<void> playBankruptSound() async {
  if (AppSettings.isMuted) return;
  try {
    final player = AudioPlayer();
    await player.setSource(AssetSource('audio/iflas.m4a'));
    await player.resume();
    player.onPlayerComplete.listen((_) {
      player.dispose();
    });
  } catch (e) {
    print('Ses çalınırken hata: $e');
  }
}

const Color primaryGreen = Color(0xFF00897B);
const Color blackText = Color(0xFF000000);

String formatDateTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  try {
    final dateTime = DateTime.parse(isoString);
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return isoString;
  }
}

BoxDecoration getGradientBackground() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF5F5F5),  // Açık beyaz
        Color(0xFFD0D0D0),  // Açık gri
      ],
    ),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MonopolyBankerApp());
  });
}

class CustomSlideRoute extends PageRouteBuilder {
  final Widget child;
  final bool isExit;

  CustomSlideRoute({required this.child, this.isExit = false})
      : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          Offset begin = isExit ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
          Offset end = Offset.zero;
          
          return SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: end,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 500),
      );
}

class MonopolyBankerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monopara',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: GameListScreen(),
    );
  }
}

class GameListScreen extends StatefulWidget {
  @override
  _GameListScreenState createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  List<Map<String, dynamic>> games = [];
  final dbHelper = DatabaseHelper();
  final TextEditingController _gameNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final data = await dbHelper.getGames();
    setState(() {
      games = data;
    });
  }

  void _createGame() async {
    if (_gameNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('enterGameName')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await dbHelper.insertGame(Game(
      id: 0,
      name: _gameNameController.text,
      players: [],
    ));
    _gameNameController.clear();
    _loadGames();
  }

  void _deleteGame(int id) async {
    await dbHelper.deleteGame(id);
    _loadGames();
  }

  void _onGameTap(Map<String, dynamic> game) async {
    // Oyuncuları kontrol et
    final players = await dbHelper.getPlayers(game['id']);
    
    if (players.isNotEmpty) {
      // Oyuncular varsa direkt oyun sayfasına git
      // Güncel başlangıç değerlerini database'den çek
      int passingMoney = game['passingMoney'] ?? 0;
      int startingBalance = game['startingBalance'] ?? 0;
      
      Navigator.push(
        context,
        CustomSlideRoute(
          child: GamePlayScreen(
            gameId: game['id'],
            gameName: game['name'],
            passingMoney: passingMoney,
            startingBalance: startingBalance,
          ),
        ),
      );
    } else {
      // Oyuncular yoksa setup sayfasına git
      Navigator.push(
        context,
        CustomSlideRoute(
          child: GameSetupScreen(
            gameId: game['id'],
            gameName: game['name'],
            savedStartingBalance: game['startingBalance'] ?? 0,
            savedPassingMoney: game['passingMoney'] ?? 0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: getGradientBackground(),
        child: Stack(
          children: [
            // Logo - dikey ortada
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'lib/media/unnamed.png',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _gameNameController,
                          style: TextStyle(color: blackText),
                          decoration: InputDecoration(
                            labelText: tr('newGameName'),
                            labelStyle: TextStyle(color: blackText),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: blackText),
                        onPressed: _createGame,
                      ),
                    ],
                  ),
                ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return ListTile(
                          title: Text(game['name'] ?? '', style: TextStyle(color: blackText, fontWeight: FontWeight.bold)),
                          subtitle: Text('${tr('created')}: ${formatDateTime(game['createdAt'])}', style: TextStyle(color: blackText)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: blackText),
                            onPressed: () => _deleteGame(game['id']),
                          ),
                          onTap: () => _onGameTap(game),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Ayarlar butonu
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => SettingsPanel(onSettingsChanged: () {
                      setState(() {});
                    }),
                  );
                },
                backgroundColor: primaryGreen,
                child: Icon(Icons.settings, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ayarlar Paneli
class SettingsPanel extends StatefulWidget {
  final VoidCallback onSettingsChanged;
  
  SettingsPanel({required this.onSettingsChanged});
  
  @override
  _SettingsPanelState createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            tr('settings'),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          // Sessiz Mod
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(AppSettings.isMuted ? Icons.volume_off : Icons.volume_up),
                  SizedBox(width: 10),
                  Text(tr('muteMode'), style: TextStyle(fontSize: 16)),
                ],
              ),
              Switch(
                value: AppSettings.isMuted,
                onChanged: (value) {
                  setState(() {
                    AppSettings.isMuted = value;
                  });
                  widget.onSettingsChanged();
                },
                activeColor: primaryGreen,
              ),
            ],
          ),
          Divider(),
          // Dil Seçimi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.language),
                  SizedBox(width: 10),
                  Text(tr('language'), style: TextStyle(fontSize: 16)),
                ],
              ),
              DropdownButton<String>(
                value: AppSettings.language,
                items: [
                  DropdownMenuItem(
                    value: 'tr',
                    child: Text(tr('turkish')),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(tr('english')),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    AppSettings.language = value ?? 'tr';
                  });
                  widget.onSettingsChanged();
                },
              ),
            ],
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

class GameSetupScreen extends StatefulWidget {
  final int gameId;
  final String gameName;
  final int savedStartingBalance;
  final int savedPassingMoney;
  
  GameSetupScreen({
    required this.gameId,
    required this.gameName,
    this.savedStartingBalance = 0,
    this.savedPassingMoney = 0,
  });

  @override
  _GameSetupScreenState createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final dbHelper = DatabaseHelper();
  List<String> playerNames = [];
  final TextEditingController _playerNameController = TextEditingController();
  late TextEditingController _startingBalanceController;
  late TextEditingController _passingMoneyController;

  @override
  void initState() {
    super.initState();
    _startingBalanceController = TextEditingController(text: widget.savedStartingBalance.toString());
    _passingMoneyController = TextEditingController(text: widget.savedPassingMoney.toString());
  }

  void _addPlayerName() {
    if (_playerNameController.text.isEmpty) return;
    setState(() {
      playerNames.add(_playerNameController.text);
      _playerNameController.clear();
    });
  }

  void _removePlayerName(int index) {
    setState(() {
      playerNames.removeAt(index);
    });
  }

  void _startGame() async {
    if (playerNames.isEmpty || _startingBalanceController.text.isEmpty || _passingMoneyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('fillAllFields'))));
      return;
    }

    int startingBalance = int.tryParse(_startingBalanceController.text) ?? 0;
    int passingMoney = int.tryParse(_passingMoneyController.text) ?? 0;

    // Oyunun başlangıç bilgilerini veritabanına kaydet
    final dbClient = await dbHelper.db;
    await dbClient.update(
      'games',
      {
        'startingBalance': startingBalance,
        'passingMoney': passingMoney,
      },
      where: 'id = ?',
      whereArgs: [widget.gameId],
    );

    // Oyuncuları veritabanına ekle (sıralamaya göre)
    List<Player> players = [];
    for (int i = 0; i < playerNames.length; i++) {
      Player player = Player(
        id: i + 1,
        name: playerNames[i],
        balance: startingBalance,
        bankrupt: false,
      );
      await dbHelper.insertPlayer(player, widget.gameId);
      players.add(player);
    }

    Navigator.pushReplacement(
      context,
      CustomSlideRoute(
        child: GamePlayScreen(
          gameId: widget.gameId,
          gameName: widget.gameName,
          passingMoney: passingMoney,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: getGradientBackground(),
        child: Stack(
          children: [
            // Logo
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'lib/media/unnamed.png',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            // Content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(tr('players'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: blackText)),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _playerNameController,
                              style: TextStyle(color: blackText),
                              decoration: InputDecoration(
                                labelText: tr('playerName'),
                                labelStyle: TextStyle(color: blackText),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _addPlayerName,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                            ),
                            child: Text(tr('add'), style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: playerNames.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(playerNames[index], style: TextStyle(color: blackText)),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: blackText),
                              onPressed: () => _removePlayerName(index),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _startingBalanceController,
                        style: TextStyle(color: blackText),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: tr('startingMoney'),
                          labelStyle: TextStyle(color: blackText),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: _passingMoneyController,
                        style: TextStyle(color: blackText),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: tr('passingMoney'),
                          labelStyle: TextStyle(color: blackText),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
            // Geri butonu
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                backgroundColor: primaryGreen,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            // Oyuna Başla butonu - ortada
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(tr('startGame'), style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GamePlayScreen extends StatefulWidget {
  final int gameId;
  final String gameName;
  final int passingMoney;
  final int startingBalance;
  GamePlayScreen({
    required this.gameId,
    required this.gameName,
    required this.passingMoney,
    this.startingBalance = 0,
  });

  @override
  _GamePlayScreenState createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  List<Map<String, dynamic>> players = [];
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>>? _lastPlayersState;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final data = await dbHelper.getPlayers(widget.gameId);
    setState(() {
      players = data;
    });
  }

  Future<void> _undoLastAction() async {
    if (_lastPlayersState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('noUndoAction')),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: MediaQuery.of(context).size.height - 150),
        ),
      );
      return;
    }

    // Eski durumu geri yükle
    for (var oldPlayer in _lastPlayersState!) {
      await dbHelper.updatePlayer(
        Player(
          id: oldPlayer['id'],
          name: oldPlayer['name'],
          balance: oldPlayer['balance'],
          bankrupt: oldPlayer['bankrupt'] == 1,
        ),
        widget.gameId,
      );
    }
    
    _lastPlayersState = null;
    await _loadPlayers();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('undoSuccess')),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: MediaQuery.of(context).size.height - 150),
      ),
    );
  }

  void _openPlayerActions(Map<String, dynamic> player) {
    // İşlem öncesi durumu kaydet
    _lastPlayersState = players.map((p) => Map<String, dynamic>.from(p)).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PlayerActionsSheet(
          player: player,
          gameId: widget.gameId,
          allPlayers: players,
          dbHelper: dbHelper,
          passingMoney: widget.passingMoney,
          onActionComplete: _loadPlayers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: getGradientBackground(),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'lib/media/unnamed.png',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            GridView.builder(
              padding: EdgeInsets.fromLTRB(10, 150, 10, 70),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return GestureDetector(
                  onTap: () => _openPlayerActions(player),
                  child: Card(
                    elevation: 5,
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: player['bankrupt'] == 1 ? Color(0xFFBDBDBD) : Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF5C5C5C),
                          width: 2.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            player['name'],
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: blackText),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            '${player['balance'] ?? 0}\$',
                            style: TextStyle(fontSize: 24, color: primaryGreen, fontWeight: FontWeight.bold),
                          ),
                          if (player['bankrupt'] == 1)
                            Text(
                              tr('bankruptLabel'),
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    CustomSlideRoute(child: GameListScreen(), isExit: true),
                    (route) => false,
                  );
                },
                backgroundColor: primaryGreen,
                child: Icon(Icons.home, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _undoLastAction,
                backgroundColor: Colors.orange,
                child: Icon(Icons.undo, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerActionsSheet extends StatefulWidget {
  final Map<String, dynamic> player;
  final int gameId;
  final List<Map<String, dynamic>> allPlayers;
  final DatabaseHelper dbHelper;
  final int passingMoney;
  final VoidCallback onActionComplete;

  PlayerActionsSheet({
    required this.player,
    required this.gameId,
    required this.allPlayers,
    required this.dbHelper,
    required this.passingMoney,
    required this.onActionComplete,
  });

  @override
  _PlayerActionsSheetState createState() => _PlayerActionsSheetState();
}

class _PlayerActionsSheetState extends State<PlayerActionsSheet> {
  final TextEditingController _amountController = TextEditingController();
  int? _selectedTransferPlayer;

  void _addMoney() async {
    int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('enterValidAmount')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: MediaQuery.of(context).size.height - 150),
        ),
      );
      return;
    }

    int newBalance = (widget.player['balance'] ?? 0) + amount;
    await widget.dbHelper.updatePlayer(
      Player(
        id: widget.player['id'],
        name: widget.player['name'],
        balance: newBalance,
        bankrupt: widget.player['bankrupt'] == 1,
      ),
      widget.gameId,
    );
    playMoneySound();
    widget.onActionComplete();
    Navigator.pop(context);
  }

  void _subtractMoney() async {
    int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('enterValidAmount')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: MediaQuery.of(context).size.height - 150),
        ),
      );
      return;
    }

    int newBalance = (widget.player['balance'] ?? 0) - amount;
    await widget.dbHelper.updatePlayer(
      Player(
        id: widget.player['id'],
        name: widget.player['name'],
        balance: newBalance,
        bankrupt: widget.player['bankrupt'] == 1,
      ),
      widget.gameId,
    );
    playMoneySound();
    widget.onActionComplete();
    Navigator.pop(context);
  }

  void _transferMoney() async {
    if (_selectedTransferPlayer == null) return;
    int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('enterValidAmount')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: MediaQuery.of(context).size.height - 150),
        ),
      );
      return;
    }

    var toPlayer = widget.allPlayers.firstWhere((p) => p['id'] == _selectedTransferPlayer);
    int fromBalance = (widget.player['balance'] ?? 0) - amount;
    int toBalance = (toPlayer['balance'] ?? 0) + amount;

    await widget.dbHelper.updatePlayer(
      Player(
        id: widget.player['id'],
        name: widget.player['name'],
        balance: fromBalance,
        bankrupt: widget.player['bankrupt'] == 1,
      ),
      widget.gameId,
    );

    await widget.dbHelper.updatePlayer(
      Player(
        id: toPlayer['id'],
        name: toPlayer['name'],
        balance: toBalance,
        bankrupt: toPlayer['bankrupt'] == 1,
      ),
      widget.gameId,
    );

    playMoneySound();
    widget.onActionComplete();
    Navigator.pop(context);
  }

  void _distributeToAll() async {
    int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('enterValidAmount')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: MediaQuery.of(context).size.height - 150),
        ),
      );
      return;
    }

    int activePlayers = widget.allPlayers.where((p) => p['bankrupt'] == 0).length - 1;
    if (activePlayers <= 0) return;

    int totalDeduction = amount * activePlayers;
    int fromBalance = (widget.player['balance'] ?? 0) - totalDeduction;

    await widget.dbHelper.updatePlayer(
      Player(
        id: widget.player['id'],
        name: widget.player['name'],
        balance: fromBalance,
        bankrupt: widget.player['bankrupt'] == 1,
      ),
      widget.gameId,
    );

    for (var player in widget.allPlayers) {
      if (player['bankrupt'] == 0 && player['id'] != widget.player['id']) {
        int newBalance = (player['balance'] ?? 0) + amount;
        await widget.dbHelper.updatePlayer(
          Player(
            id: player['id'],
            name: player['name'],
            balance: newBalance,
            bankrupt: false,
          ),
          widget.gameId,
        );
      }
    }

    playMoneySound();
    widget.onActionComplete();
    Navigator.pop(context);
  }

  void _passingStart() async {
    int newBalance = (widget.player['balance'] ?? 0) + widget.passingMoney;
    await widget.dbHelper.updatePlayer(
      Player(
        id: widget.player['id'],
        name: widget.player['name'],
        balance: newBalance,
        bankrupt: widget.player['bankrupt'] == 1,
      ),
      widget.gameId,
    );
    playMoneySound();
    widget.onActionComplete();
    Navigator.pop(context);
  }

  void _goBankrupt() async {
    await widget.dbHelper.updatePlayer(
      Player(
        id: widget.player['id'],
        name: widget.player['name'],
        balance: 0,
        bankrupt: true,
      ),
      widget.gameId,
    );
    playBankruptSound();
    widget.onActionComplete();
    Navigator.pop(context);
  }

  void _undoBankrupt() async {
    await widget.dbHelper.updatePlayer(
      Player(
        id: widget.player['id'],
        name: widget.player['name'],
        balance: widget.player['balance'] ?? 0,
        bankrupt: false,
      ),
      widget.gameId,
    );
    widget.onActionComplete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.player['name'],
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: tr('enterAmount')),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _addMoney,
                child: Text(tr('add')),
              ),
              ElevatedButton(
                onPressed: _subtractMoney,
                child: Text(tr('subtract')),
              ),
              ElevatedButton(
                onPressed: _distributeToAll,
                child: Text(tr('distributeToAll')),
              ),
            ],
          ),
          SizedBox(height: 15),
          DropdownButton<int>(
            value: _selectedTransferPlayer,
            hint: Text(tr('selectPlayer')),
            items: widget.allPlayers
                .where((p) => p['id'] != widget.player['id'])
                .map<DropdownMenuItem<int>>((player) {
              bool isBankrupt = player['bankrupt'] == 1;
              return DropdownMenuItem<int>(
                value: player['id'],
                enabled: !isBankrupt,
                child: Text(
                  player['name'],
                  style: TextStyle(
                    color: isBankrupt ? Colors.grey : Colors.black,
                    fontWeight: isBankrupt ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTransferPlayer = value;
              });
            },
          ),
          SizedBox(height: 15),
          ElevatedButton(
            onPressed: _selectedTransferPlayer != null ? _transferMoney : null,
            child: Text(tr('transfer')),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _passingStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                ),
                child: Text('${tr('passStart')} (${widget.passingMoney}\$)', style: TextStyle(color: Colors.white)),
              ),
              widget.player['bankrupt'] == 1
                ? ElevatedButton(
                    onPressed: _undoBankrupt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(tr('undoBankrupt'), style: TextStyle(color: Colors.white)),
                  )
                : ElevatedButton(
                    onPressed: _goBankrupt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(tr('bankrupt'), style: TextStyle(color: Colors.white)),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final int gameId;
  final String gameName;
  PlayerScreen({required this.gameId, required this.gameName});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  List<Map<String, dynamic>> players = [];
  final dbHelper = DatabaseHelper();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _transferAmountController = TextEditingController();
  int? _fromPlayerId;
  int? _toPlayerId;
  final TextEditingController _payAllController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final data = await dbHelper.getPlayers(widget.gameId);
    setState(() {
      players = data;
    });
  }

  void _addPlayer() async {
    if (_playerNameController.text.isEmpty) return;
    await dbHelper.insertPlayer(
      Player(
        id: 0,
        name: _playerNameController.text,
        balance: null,
        bankrupt: false,
      ),
      widget.gameId,
    );
    _playerNameController.clear();
    _loadPlayers();
  }

  void _setBalances() async {
    if (_balanceController.text.isEmpty) return;
    int balance = int.tryParse(_balanceController.text) ?? 0;
    for (var player in players) {
      await dbHelper.updatePlayer(
        Player(
          id: player['id'],
          name: player['name'],
          balance: balance,
          bankrupt: false,
        ),
        widget.gameId,
      );
    }
    _balanceController.clear();
    _loadPlayers();
  }

  void _transferFunds() async {
    if (_fromPlayerId == null || _toPlayerId == null || _transferAmountController.text.isEmpty) return;
    int amount = int.tryParse(_transferAmountController.text) ?? 0;
    var from = players.firstWhere((p) => p['id'] == _fromPlayerId);
    var to = players.firstWhere((p) => p['id'] == _toPlayerId);
    if (from['balance'] != null && to['balance'] != null && from['balance'] >= amount) {
      await dbHelper.updatePlayer(
        Player(
          id: from['id'],
          name: from['name'],
          balance: from['balance'] - amount,
          bankrupt: from['bankrupt'] == 1,
        ),
        widget.gameId,
      );
      await dbHelper.updatePlayer(
        Player(
          id: to['id'],
          name: to['name'],
          balance: to['balance'] + amount,
          bankrupt: to['bankrupt'] == 1,
        ),
        widget.gameId,
      );
      _loadPlayers();
    }
    _transferAmountController.clear();
  }

  void _payToAll() async {
    if (_payAllController.text.isEmpty) return;
    int amount = int.tryParse(_payAllController.text) ?? 0;
    for (var player in players) {
      if (player['bankrupt'] == 0 && player['balance'] != null) {
        await dbHelper.updatePlayer(
          Player(
            id: player['id'],
            name: player['name'],
            balance: player['balance'] + amount,
            bankrupt: false,
          ),
          widget.gameId,
        );
      }
    }
    _payAllController.clear();
    _loadPlayers();
  }

  void _deletePlayer(int id) async {
    await dbHelper.deletePlayer(id);
    _loadPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.gameName)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _playerNameController,
                      decoration: InputDecoration(labelText: 'Oyuncu Adı'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.person_add),
                    onPressed: _addPlayer,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _balanceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Başlangıç Bakiyesi'),
                    ),
                  ),
                  ElevatedButton(
                    child: Text('Bakiyeleri Ayarla'),
                    onPressed: _setBalances,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: _fromPlayerId,
                      hint: Text('Gönderen'),
                      items: players.map<DropdownMenuItem<int>>((player) {
                        return DropdownMenuItem<int>(
                          value: player['id'],
                          child: Text(player['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _fromPlayerId = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: DropdownButton<int>(
                      value: _toPlayerId,
                      hint: Text('Alıcı'),
                      items: players.map<DropdownMenuItem<int>>((player) {
                        return DropdownMenuItem<int>(
                          value: player['id'],
                          child: Text(player['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _toPlayerId = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _transferAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Tutar'),
                    ),
                  ),
                  ElevatedButton(
                    child: Text('Transfer'),
                    onPressed: _transferFunds,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _payAllController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Herkese Ekle'),
                    ),
                  ),
                  ElevatedButton(
                    child: Text('Herkese Ekle'),
                    onPressed: _payToAll,
                  ),
                ],
              ),
            ),
            Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return ListTile(
                  title: Text(player['name'] ?? ''),
                  subtitle: Text('Bakiye: ${player['balance'] ?? 0}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deletePlayer(player['id']),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
