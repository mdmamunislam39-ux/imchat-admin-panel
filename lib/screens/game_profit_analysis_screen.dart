import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../widgets/base_screen.dart';

class GameInfo {
  final String key;
  final String name;
  final String icon;
  final Color color;
  final String? thumbnailUrl;
  final bool isHtml5;

  const GameInfo({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
    this.thumbnailUrl,
    this.isHtml5 = true,
  });
}

class GameProfitAnalysisScreen extends StatefulWidget {
  const GameProfitAnalysisScreen({super.key});

  @override
  State<GameProfitAnalysisScreen> createState() =>
      _GameProfitAnalysisScreenState();
}

class _GameProfitAnalysisScreenState extends State<GameProfitAnalysisScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasIndexError = false;
  String? _indexErrorUrl;
  bool _fallbackMode =
      false; // True when fetching without sorting due to index error
  bool _isSwitchingFallback = false;

  // Stream Subscriptions
  StreamSubscription? _historySubscription;
  StreamSubscription? _betHistorySubscription;
  StreamSubscription? _gameHistorySubscription;
  StreamSubscription? _catBetsSubscription;
  StreamSubscription? _catWinsSubscription;
  StreamSubscription? _gamesSubscription;
  StreamSubscription? _roomGamesSubscription;

  // Raw fetched documents per source
  List<Map<String, dynamic>> _greedyLogs = [];
  List<Map<String, dynamic>> _fruitWheelLogs = [];
  List<Map<String, dynamic>> _html5Logs = [];
  List<Map<String, dynamic>> _catBetsLogs = [];
  List<Map<String, dynamic>> _catWinsLogs = [];
  List<Map<String, dynamic>> _allLogs = [];

  // Dynamic Registered Games Registry (Built-in + Real-time from Firestore)
  static final Map<String, GameInfo> _defaultGames = {
    'greedy_market': const GameInfo(
      key: 'greedy_market',
      name: 'Greedy Market',
      icon: '🎡',
      color: Colors.amber,
      isHtml5: true,
    ),
    'greedy_delicious': const GameInfo(
      key: 'greedy_delicious',
      name: 'Greedy Delicious',
      icon: '🍖',
      color: Colors.deepOrangeAccent,
      isHtml5: true,
    ),
    'greedy_cat': const GameInfo(
      key: 'greedy_cat',
      name: 'Greedy Cat',
      icon: '🐱',
      color: Colors.orangeAccent,
      isHtml5: true,
    ),
    'king_queen_slot': const GameInfo(
      key: 'king_queen_slot',
      name: 'King Queen Slot',
      icon: '👑',
      color: Colors.purpleAccent,
      isHtml5: true,
    ),
    'gem_spin_slot': const GameInfo(
      key: 'gem_spin_slot',
      name: 'Arabian Spin Game',
      icon: '💎',
      color: Colors.tealAccent,
      isHtml5: true,
    ),
    'ludo_game': const GameInfo(
      key: 'ludo_game',
      name: 'Ludo Champion',
      icon: '🎲',
      color: Colors.blueAccent,
      isHtml5: true,
    ),
    'greedy_red': const GameInfo(
      key: 'greedy_red',
      name: 'Greedy Red',
      icon: '🌭',
      color: Colors.redAccent,
      isHtml5: false,
    ),
    'greedy_pink': const GameInfo(
      key: 'greedy_pink',
      name: 'Greedy Pink',
      icon: '🧁',
      color: Colors.pinkAccent,
      isHtml5: false,
    ),
    'fruit_wheel': const GameInfo(
      key: 'fruit_wheel',
      name: 'Fruit Wheel',
      icon: '🍒',
      color: Colors.yellowAccent,
      isHtml5: false,
    ),
  };

  late Map<String, GameInfo> _registeredGames;

  // Filter States
  String _selectedTimeFilter =
      'daily'; // 'daily', 'weekly', 'monthly', 'all', 'custom'
  DateTimeRange? _customDateRange;
  String _selectedGameFilter = 'all'; // 'all', or any game key
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination states for the detailed logs table
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  // Cached usernames to avoid querying Firestore repeatedly for same user
  final Map<String, String> _userNamesCache = {};
  bool _isFetchingUsernames = false;

  @override
  void initState() {
    super.initState();
    _registeredGames = Map.from(_defaultGames);
    _setupRealTimeListeners();
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    _betHistorySubscription?.cancel();
    _gameHistorySubscription?.cancel();
    _catBetsSubscription?.cancel();
    _catWinsSubscription?.cancel();
    _gamesSubscription?.cancel();
    _roomGamesSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Helper: Normalize game keys from different naming conventions
  String _normalizeGameKey(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('delicious')) return 'greedy_delicious';
    if (lower.contains('market')) return 'greedy_market';
    if (lower.contains('cat')) return 'greedy_cat';
    if (lower.contains('king') || lower.contains('queen') || lower.contains('slot')) {
      return 'king_queen_slot';
    }
    if (lower.contains('gem') || lower.contains('arabian') || lower.contains('spin')) {
      return 'gem_spin_slot';
    }
    if (lower.contains('ludo') || lower.contains('ludu')) return 'ludo_game';
    if (lower.contains('pink')) return 'greedy_pink';
    if (lower.contains('red') || lower == 'greedy_game') return 'greedy_red';
    if (lower.contains('wheel') || lower.contains('fruit')) return 'fruit_wheel';
    return lower.replaceAll(' ', '_');
  }

  String _formatGameName(String raw) {
    String clean = raw.replaceAll('html5_', '').replaceAll('_', ' ');
    return clean
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _pickEmojiForGame(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('roulette')) return '🎡';
    if (lower.contains('poker') || lower.contains('card')) return '🃏';
    if (lower.contains('dice') || lower.contains('ludo')) return '🎲';
    if (lower.contains('slot') || lower.contains('queen') || lower.contains('king')) return '👑';
    if (lower.contains('cat')) return '🐱';
    if (lower.contains('food') || lower.contains('delicious')) return '🍖';
    if (lower.contains('market')) return '🎡';
    if (lower.contains('gem') || lower.contains('diamond') || lower.contains('spin')) return '💎';
    if (lower.contains('fruit')) return '🍒';
    if (lower.contains('racing') || lower.contains('car')) return '🏎️';
    if (lower.contains('fish')) return '🐠';
    return '🎮';
  }

  Color _pickColorForGame(String key) {
    final palette = [
      Colors.cyanAccent,
      Colors.lightGreenAccent,
      Colors.amberAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.tealAccent,
      Colors.blueAccent,
      Colors.indigoAccent,
      Colors.deepOrangeAccent,
    ];
    final hash = key.codeUnits.fold(0, (prev, elem) => prev + elem);
    return palette[hash % palette.length];
  }

  void _ensureGameRegistered(String rawKey, {String? displayName, String? emoji, bool isHtml5 = true}) {
    final key = _normalizeGameKey(rawKey);
    if (!_registeredGames.containsKey(key)) {
      final formattedName = displayName ?? _formatGameName(rawKey);
      _registeredGames[key] = GameInfo(
        key: key,
        name: formattedName,
        icon: emoji ?? _pickEmojiForGame(formattedName),
        color: _pickColorForGame(key),
        isHtml5: isHtml5,
      );
    }
  }

  // Setup real-time Firestore listeners for game history collections
  Future<void> _setupRealTimeListeners() async {
    final oldHistorySub = _historySubscription;
    final oldBetHistorySub = _betHistorySubscription;
    final oldGameHistorySub = _gameHistorySubscription;
    final oldCatBetsSub = _catBetsSubscription;
    final oldCatWinsSub = _catWinsSubscription;
    final oldGamesSub = _gamesSubscription;
    final oldRoomGamesSub = _roomGamesSubscription;

    _historySubscription = null;
    _betHistorySubscription = null;
    _gameHistorySubscription = null;
    _catBetsSubscription = null;
    _catWinsSubscription = null;
    _gamesSubscription = null;
    _roomGamesSubscription = null;

    await oldHistorySub?.cancel();
    await oldBetHistorySub?.cancel();
    await oldGameHistorySub?.cancel();
    await oldCatBetsSub?.cancel();
    await oldCatWinsSub?.cancel();
    await oldGamesSub?.cancel();
    await oldRoomGamesSub?.cancel();

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Dynamic Listener for games collection (any new game added appears in real-time)
    _gamesSubscription = _firestore.collection('games').snapshots().listen(
      (snapshot) {
        if (mounted) _processGamesSnapshot(snapshot);
      },
      onError: (e) => debugPrint('Games snapshot error: $e'),
      cancelOnError: false,
    );

    // 2. Dynamic Listener for room_games collection
    _roomGamesSubscription = _firestore.collection('room_games').snapshots().listen(
      (snapshot) {
        if (mounted) _processRoomGamesSnapshot(snapshot);
      },
      onError: (e) => debugPrint('Room games snapshot error: $e'),
      cancelOnError: false,
    );

    // 3. Listener for game_history (All HTML5 games: Greedy Market, Greedy Delicious, King Queen Slot, Arabian Spin, etc.)
    final gameHistoryQuery = _fallbackMode
        ? _firestore.collection('game_history').limit(2500)
        : _firestore.collection('game_history').orderBy('createdAt', descending: true).limit(2500);

    _gameHistorySubscription = gameHistoryQuery.snapshots().listen(
      (snapshot) {
        if (mounted) _processGameHistorySnapshot(snapshot);
      },
      onError: (e) {
        debugPrint('Game history subscription error: $e. Using fallback without order.');
        _fallbackGameHistoryListener();
      },
      cancelOnError: false,
    );

    // 4. Listeners for game_bets & game_wins (for greedy_cat or separate collections)
    _catBetsSubscription = _firestore.collection('game_bets').limit(1000).snapshots().listen(
      (snapshot) {
        if (mounted) _processCatBetsSnapshot(snapshot);
      },
      onError: (e) => debugPrint('Cat bets subscription note: $e'),
      cancelOnError: false,
    );

    _catWinsSubscription = _firestore.collection('game_wins').limit(1000).snapshots().listen(
      (snapshot) {
        if (mounted) _processCatWinsSnapshot(snapshot);
      },
      onError: (e) => debugPrint('Cat wins subscription note: $e'),
      cancelOnError: false,
    );

    // 5. Query: history (Greedy Red & Pink)
    final historyQuery = _fallbackMode
        ? _firestore.collectionGroup('history').limit(2000)
        : _firestore
              .collectionGroup('history')
              .orderBy('timestamp', descending: true)
              .limit(2000);

    _historySubscription = historyQuery.snapshots().listen(
      (snapshot) {
        if (mounted) _processHistorySnapshot(snapshot);
      },
      onError: (e) {
        _handleError(e);
      },
      cancelOnError: false,
    );

    // 6. Query: bet_history (Fruit Wheel)
    final betHistoryQuery = _fallbackMode
        ? _firestore.collectionGroup('bet_history').limit(2000)
        : _firestore
              .collectionGroup('bet_history')
              .orderBy('timestamp', descending: true)
              .limit(2000);

    _betHistorySubscription = betHistoryQuery.snapshots().listen(
      (snapshot) {
        if (mounted) _processBetHistorySnapshot(snapshot);
      },
      onError: (e) {
        _handleError(e);
      },
      cancelOnError: false,
    );
  }

  void _fallbackGameHistoryListener() {
    _gameHistorySubscription?.cancel();
    _gameHistorySubscription = _firestore
        .collection('game_history')
        .limit(2500)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) _processGameHistorySnapshot(snapshot);
          },
          onError: (e) => debugPrint('Fallback game_history error: $e'),
          cancelOnError: false,
        );
  }

  // Process live games list from 'games' collection
  void _processGamesSnapshot(QuerySnapshot snapshot) {
    bool updated = false;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final String rawId = (data['gameCode'] ?? data['gameId'] ?? doc.id).toString();
      final String key = _normalizeGameKey(rawId);
      final String name = (data['name'] ?? data['title'] ?? _formatGameName(rawId)).toString();
      final String thumb = (data['thumbnailUrl'] ?? data['icon'] ?? data['image'] ?? '').toString();
      final bool isHtml5 = data['isHtml5'] == true || data['type'] == 'html5' || data['gameType'] == 'html5';

      if (!_registeredGames.containsKey(key)) {
        _registeredGames[key] = GameInfo(
          key: key,
          name: name,
          icon: _pickEmojiForGame(name),
          color: _pickColorForGame(key),
          thumbnailUrl: thumb.isNotEmpty ? thumb : null,
          isHtml5: isHtml5,
        );
        updated = true;
      } else {
        final existing = _registeredGames[key]!;
        if (existing.name != name || (thumb.isNotEmpty && existing.thumbnailUrl != thumb)) {
          _registeredGames[key] = GameInfo(
            key: key,
            name: name,
            icon: existing.icon,
            color: existing.color,
            thumbnailUrl: thumb.isNotEmpty ? thumb : existing.thumbnailUrl,
            isHtml5: existing.isHtml5 || isHtml5,
          );
          updated = true;
        }
      }
    }
    if (updated && mounted) {
      setState(() {});
    }
  }

  // Process live games list from 'room_games' collection
  void _processRoomGamesSnapshot(QuerySnapshot snapshot) {
    bool updated = false;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final String rawId = (data['gameCode'] ?? data['gameId'] ?? doc.id).toString();
      final String key = _normalizeGameKey(rawId);
      final String name = (data['name'] ?? data['title'] ?? _formatGameName(rawId)).toString();
      final String thumb = (data['thumbnailUrl'] ?? data['icon'] ?? '').toString();

      if (!_registeredGames.containsKey(key)) {
        _registeredGames[key] = GameInfo(
          key: key,
          name: name,
          icon: _pickEmojiForGame(name),
          color: _pickColorForGame(key),
          thumbnailUrl: thumb.isNotEmpty ? thumb : null,
          isHtml5: true,
        );
        updated = true;
      }
    }
    if (updated && mounted) {
      setState(() {});
    }
  }

  // Process live events from HTML5 games stored in 'game_history'
  void _processGameHistorySnapshot(QuerySnapshot snapshot) {
    final List<Map<String, dynamic>> processed = [];
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final String rawGame = (data['gameId'] ?? data['gameCode'] ?? data['gameName'] ?? 'html5_game').toString();
      final String gameKey = _normalizeGameKey(rawGame);
      final String rawName = (data['gameName'] ?? data['name'] ?? rawGame).toString();

      _ensureGameRegistered(gameKey, displayName: _registeredGames[gameKey]?.name ?? _formatGameName(rawName));

      final gameInfo = _registeredGames[gameKey];
      final String gameName = gameInfo?.name ?? _formatGameName(rawName);

      // Parse timestamp
      DateTime timestamp = DateTime.now();
      if (data['createdAt'] is Timestamp) {
        timestamp = (data['createdAt'] as Timestamp).toDate();
      } else if (data['timestamp'] is Timestamp) {
        timestamp = (data['timestamp'] as Timestamp).toDate();
      } else if (data['date'] is Timestamp) {
        timestamp = (data['date'] as Timestamp).toDate();
      }

      final String type = (data['type'] ?? '').toString().toUpperCase();
      double totalBet = 0.0;
      double winAmount = 0.0;

      if (type == 'BET') {
        totalBet = (data['betAmount'] ?? data['bet'] ?? data['totalBet'] ?? 0).toDouble();
        winAmount = 0.0;
      } else if (type == 'WIN') {
        winAmount = (data['winAmount'] ?? data['earnings'] ?? data['payout'] ?? data['won'] ?? 0).toDouble();
        totalBet = (data['betAmount'] ?? data['bet'] ?? 0).toDouble();
      } else {
        totalBet = (data['betAmount'] ?? data['bet'] ?? data['totalBet'] ?? 0).toDouble();
        winAmount = (data['winAmount'] ?? data['earnings'] ?? data['payout'] ?? data['won'] ?? 0).toDouble();
      }

      final String userId = (data['userId'] ?? '').toString();
      if (data['userName'] != null && data['userName'].toString().isNotEmpty && userId.isNotEmpty) {
        _userNamesCache[userId] = data['userName'].toString();
      }

      final String roundNumber = (data['roundNumber'] ?? data['roundId'] ?? data['round'] ?? 'N/A').toString();
      final String emoji = (data['winningEmoji'] ?? data['winningItem'] ?? data['itemName'] ?? (type == 'WIN' ? '🏆' : (type == 'BET' ? '🎲' : (gameInfo?.icon ?? '🎮')))).toString();

      processed.add({
        'id': doc.id,
        'gameName': gameName,
        'gameKey': gameKey,
        'gameIcon': gameInfo?.icon ?? '🎮',
        'userId': userId,
        'roundNumber': roundNumber,
        'totalBet': totalBet,
        'winAmount': winAmount,
        'profit': totalBet - winAmount,
        'timestamp': timestamp,
        'winningEmoji': emoji,
        'type': type.isNotEmpty ? type : (winAmount > 0 ? 'WIN' : 'BET'),
      });
    }

    setState(() {
      _html5Logs = processed;
      _combineAndSortLogs();
      _isLoading = false;
    });

    _fetchUsernamesForLogs();
  }

  // Process live events from Greedy Cat bets collection
  void _processCatBetsSnapshot(QuerySnapshot snapshot) {
    final List<Map<String, dynamic>> processed = [];
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime timestamp = DateTime.now();
      if (data['createdAt'] is Timestamp) {
        timestamp = (data['createdAt'] as Timestamp).toDate();
      }
      final double bet = (data['betAmount'] ?? data['bet'] ?? 0).toDouble();
      final String userId = (data['userId'] ?? '').toString();
      if (data['userName'] != null && data['userName'].toString().isNotEmpty && userId.isNotEmpty) {
        _userNamesCache[userId] = data['userName'].toString();
      }
      processed.add({
        'id': 'cat_bet_${doc.id}',
        'gameName': 'Greedy Cat',
        'gameKey': 'greedy_cat',
        'gameIcon': '🐱',
        'userId': userId,
        'roundNumber': (data['roundId'] ?? 'N/A').toString(),
        'totalBet': bet,
        'winAmount': 0.0,
        'profit': bet,
        'timestamp': timestamp,
        'winningEmoji': '🐟',
        'type': 'BET',
      });
    }
    setState(() {
      _catBetsLogs = processed;
      _combineAndSortLogs();
      _isLoading = false;
    });
    _fetchUsernamesForLogs();
  }

  // Process live events from Greedy Cat wins collection
  void _processCatWinsSnapshot(QuerySnapshot snapshot) {
    final List<Map<String, dynamic>> processed = [];
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime timestamp = DateTime.now();
      if (data['createdAt'] is Timestamp) {
        timestamp = (data['createdAt'] as Timestamp).toDate();
      }
      final double win = (data['winAmount'] ?? data['won'] ?? 0).toDouble();
      final String userId = (data['userId'] ?? '').toString();
      if (data['userName'] != null && data['userName'].toString().isNotEmpty && userId.isNotEmpty) {
        _userNamesCache[userId] = data['userName'].toString();
      }
      processed.add({
        'id': 'cat_win_${doc.id}',
        'gameName': 'Greedy Cat',
        'gameKey': 'greedy_cat',
        'gameIcon': '🐱',
        'userId': userId,
        'roundNumber': (data['roundId'] ?? 'N/A').toString(),
        'totalBet': 0.0,
        'winAmount': win,
        'profit': -win,
        'timestamp': timestamp,
        'winningEmoji': '🏆',
        'type': 'WIN',
      });
    }
    setState(() {
      _catWinsLogs = processed;
      _combineAndSortLogs();
      _isLoading = false;
    });
    _fetchUsernamesForLogs();
  }

  // Process live events from Greedy Red & Pink
  void _processHistorySnapshot(QuerySnapshot snapshot) {
    final List<Map<String, dynamic>> processedGreedy = [];
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final path = doc.reference.path;

      final String gameName = path.contains('pink_greedy_game')
          ? 'Greedy Pink'
          : 'Greedy Red';
      final String gameKey = path.contains('pink_greedy_game')
          ? 'greedy_pink'
          : 'greedy_red';

      // Extract userId from path: gready_game_bet_history/{userId}/history/{docId}
      final pathSegments = doc.reference.path.split('/');
      String userId = '';
      if (pathSegments.length >= 2) {
        userId = pathSegments[pathSegments.length - 3];
      }

      DateTime timestamp = DateTime.now();
      if (data['timestamp'] != null) {
        timestamp = (data['timestamp'] as Timestamp).toDate();
      }

      final double totalBet = (data['totalBet'] ?? 0).toDouble();
      final double winAmount = (data['winAmount'] ?? 0).toDouble();

      processedGreedy.add({
        'id': doc.id,
        'gameName': gameName,
        'gameKey': gameKey,
        'gameIcon': gameKey == 'greedy_pink' ? '🧁' : '🌭',
        'userId': userId,
        'roundNumber': data['roundNumber']?.toString() ?? 'N/A',
        'totalBet': totalBet,
        'winAmount': winAmount,
        'profit': totalBet - winAmount, // App profit
        'timestamp': timestamp,
        'winningEmoji': data['winningEmoji'] ?? '🎲',
        'type': winAmount > 0 ? 'WIN' : 'BET',
      });
    }

    setState(() {
      _greedyLogs = processedGreedy;
      _combineAndSortLogs();
      _isLoading = false;
    });

    _fetchUsernamesForLogs();
  }

  // Process live events from Fruit Wheel
  void _processBetHistorySnapshot(QuerySnapshot snapshot) {
    final List<Map<String, dynamic>> processedWheel = [];
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Extract userId from path: Users/{userId}/bet_history/{docId}
      final pathSegments = doc.reference.path.split('/');
      String userId = '';
      if (pathSegments.length >= 2) {
        userId = pathSegments[pathSegments.length - 3];
      }

      DateTime timestamp = DateTime.now();
      if (data['timestamp'] != null) {
        timestamp = (data['timestamp'] as Timestamp).toDate();
      }

      // Calculate total bet from bets map
      double totalBet = 0;
      if (data['bets'] != null && data['bets'] is Map) {
        final betsMap = data['bets'] as Map;
        for (final val in betsMap.values) {
          totalBet += (val ?? 0).toDouble();
        }
      } else if (data['totalBet'] != null) {
        totalBet = (data['totalBet'] ?? 0).toDouble();
      }

      double winAmount = 0;
      if (data['netResult'] != null) {
        final double netResult = (data['netResult'] ?? 0).toDouble();
        winAmount = netResult + totalBet;
      } else if (data['payout'] != null) {
        winAmount = (data['payout'] ?? 0).toDouble();
      }

      processedWheel.add({
        'id': doc.id,
        'gameName': 'Fruit Wheel',
        'gameKey': 'fruit_wheel',
        'gameIcon': '🍒',
        'userId': userId,
        'roundNumber': data['roundNumber']?.toString() ?? 'N/A',
        'totalBet': totalBet,
        'winAmount': winAmount,
        'profit': totalBet - winAmount, // App profit
        'timestamp': timestamp,
        'winningEmoji': data['result'] ?? '🍒',
        'type': winAmount > 0 ? 'WIN' : 'BET',
      });
    }

    setState(() {
      _fruitWheelLogs = processedWheel;
      _combineAndSortLogs();
      _isLoading = false;
    });

    _fetchUsernamesForLogs();
  }

  // Combine and sort combined logs by timestamp with deduplication
  void _combineAndSortLogs() {
    final List<Map<String, dynamic>> raw = [
      ..._greedyLogs,
      ..._fruitWheelLogs,
      ..._html5Logs,
      ..._catBetsLogs,
      ..._catWinsLogs,
    ];

    final Set<String> seenIds = {};
    final List<Map<String, dynamic>> deduped = [];
    for (final item in raw) {
      final id = item['id'].toString();
      if (seenIds.add(id)) {
        deduped.add(item);
      }
    }

    deduped.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );
    _allLogs = deduped;
  }

  // Live Error handling for Index failures
  void _handleError(dynamic error) async {
    if (!mounted) return;
    debugPrint('GameProfitAnalysis error: $error');

    if (error is FirebaseException &&
        (error.code == 'failed-precondition' ||
            (error.message?.contains('index') ?? false))) {
      if (!_fallbackMode && !_isSwitchingFallback) {
        _isSwitchingFallback = true;
        if (mounted) {
          setState(() {
            _hasIndexError = true;
            _indexErrorUrl = _extractIndexUrl(error.message ?? '');
            _fallbackMode = true;
          });
        }
        // Restart listeners in fallback mode
        await _setupRealTimeListeners();
        _isSwitchingFallback = false;
      }
    } else {
      if (mounted && !_fallbackMode && !_isSwitchingFallback) {
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Helper: check if a date is within selected time range
  bool _isWithinDateRange(DateTime date) {
    final now = DateTime.now();

    switch (_selectedTimeFilter) {
      case 'daily':
        final todayStart = DateTime(now.year, now.month, now.day);
        return date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart);
      case 'weekly':
        final sevenDaysAgo = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 7));
        return date.isAfter(sevenDaysAgo);
      case 'monthly':
        final thirtyDaysAgo = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 30));
        return date.isAfter(thirtyDaysAgo);
      case 'custom':
        if (_customDateRange == null) return true;
        // Make end date inclusive of the entire day
        final endInclusive = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
          999,
        );
        return (date.isAfter(_customDateRange!.start) ||
                date.isAtSameMomentAs(_customDateRange!.start)) &&
            (date.isBefore(endInclusive) ||
                date.isAtSameMomentAs(endInclusive));
      case 'all':
      default:
        return true;
    }
  }

  String? _extractIndexUrl(String errorMessage) {
    final regExp = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
    final match = regExp.firstMatch(errorMessage);
    return match?.group(0);
  }

  // Fetch usernames asynchronously in batches to build user name cache
  Future<void> _fetchUsernamesForLogs() async {
    if (_isFetchingUsernames || !mounted) return;
    _isFetchingUsernames = true;

    try {
      final Set<String> userIdsToFetch = {};
      for (final log in _allLogs) {
        final String uid = log['userId'];
        if (uid.isNotEmpty && !_userNamesCache.containsKey(uid)) {
          userIdsToFetch.add(uid);
        }
      }

      if (userIdsToFetch.isEmpty) return;

      // Process in small batches of 10 to prevent rate-limiting or heavy queries
      final listUids = userIdsToFetch.toList();
      for (int i = 0; i < listUids.length; i += 10) {
        if (!mounted) break;
        final end = (i + 10 < listUids.length) ? i + 10 : listUids.length;
        final batchUids = listUids.sublist(i, end);

        await Future.wait(
          batchUids.map((uid) async {
            try {
              final doc = await _firestore.collection('Users').doc(uid).get();
              if (doc.exists) {
                final data = doc.data();
                final String name =
                    data?['fullname'] ?? data?['username'] ?? 'User';
                _userNamesCache[uid] = name;
              } else {
                _userNamesCache[uid] = 'User ($uid)';
              }
            } catch (e) {
              _userNamesCache[uid] = 'User';
            }
          }),
        );

        // Update UI progressively
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error fetching usernames for logs: $e');
    } finally {
      _isFetchingUsernames = false;
    }
  }

  // Retrieve filtered list of logs
  List<Map<String, dynamic>> _getFilteredLogs() {
    return _allLogs.where((log) {
      // 1. Time Filter
      final DateTime timestamp = log['timestamp'] as DateTime;
      if (!_isWithinDateRange(timestamp)) return false;

      // 2. Game Filter
      if (_selectedGameFilter != 'all' &&
          log['gameKey'] != _selectedGameFilter) {
        return false;
      }

      // 3. Search Query (UserId, Username, or Round)
      if (_searchQuery.isNotEmpty) {
        final uid = log['userId'].toString().toLowerCase();
        final username = (_userNamesCache[log['userId']] ?? '').toLowerCase();
        final round = log['roundNumber'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();

        if (!uid.contains(query) &&
            !username.contains(query) &&
            !round.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Calculate statistics based on current active filters
  Map<String, double> _calculateStats({String? gameFilter}) {
    double totalBets = 0;
    double totalWins = 0;

    final targetLogs = gameFilter == null
        ? _getFilteredLogs()
        : _allLogs.where((log) {
            // Apply current time filters
            final DateTime timestamp = log['timestamp'] as DateTime;
            if (!_isWithinDateRange(timestamp)) return false;

            // Check game filter override
            return log['gameKey'] == gameFilter;
          }).toList();

    for (final log in targetLogs) {
      totalBets += log['totalBet'];
      totalWins += log['winAmount'];
    }

    return {
      'bets': totalBets,
      'wins': totalWins,
      'profit': totalBets - totalWins,
      'margin': totalBets > 0
          ? ((totalBets - totalWins) / totalBets) * 100
          : 0.0,
    };
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.grey[900]),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTimeFilter = 'custom';
        _customDateRange = picked;
        _currentPage = 0; // Reset page
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final filteredLogs = _getFilteredLogs();

    // Paginate logs
    final int totalLogs = filteredLogs.length;
    final int totalPages = (totalLogs / _rowsPerPage).ceil();
    final int startIndex = _currentPage * _rowsPerPage;
    final int endIndex = (startIndex + _rowsPerPage > totalLogs)
        ? totalLogs
        : startIndex + _rowsPerPage;
    final List<Map<String, dynamic>> paginatedLogs = totalLogs > 0
        ? filteredLogs.sublist(startIndex, endIndex)
        : [];

    return BaseScreen(
      title: 'Game Profit & Analysis',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _setupRealTimeListeners,
          tooltip: 'Refresh Data',
        ),
      ],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : RefreshIndicator(
              color: Colors.deepPurple,
              onRefresh: () async {
                _setupRealTimeListeners();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message
                    if (_errorMessage != null) _buildErrorCard(_errorMessage!),

                    // Firestore Index Warning card (Non-blocking)
                    if (_hasIndexError) _buildIndexErrorWarningCard(),

                    // Preset Time Filters & Custom Date Range
                    _buildTimeFiltersRow(),
                    const SizedBox(height: 16),

                    // Top Analytics Metrics Cards (Aggregated stats)
                    _buildMetricsGrid(stats),
                    const SizedBox(height: 24),

                    // Game-wise breakdown grid
                    _buildGameBreakdownSection(),
                    const SizedBox(height: 24),

                    // Logs and History Section
                    _buildHistoryLogsSection(
                      paginatedLogs,
                      totalLogs,
                      totalPages,
                      startIndex,
                      endIndex,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- UI WIDGET BUILDERS ---

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        border: Border.all(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.redAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Error loading data: $error',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexErrorWarningCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(color: Colors.orangeAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.orangeAccent, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Firestore Index Required',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'For optimal performance and real-time sorting, please click the link below to configure Firestore Collection Group indexes. The app is currently running in a slower fallback memory-computation mode.',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          if (_indexErrorUrl != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
              icon: const Icon(
                Icons.open_in_new,
                color: Colors.black,
                size: 18,
              ),
              label: const Text(
                'Create Firestore Indexes',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                // Since this runs in Dart code, let the user open the URL.
                // We'll print the link in debug console as well for convenience.
                debugPrint('Create Index URL: $_indexErrorUrl');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Console link printed in logger. Visit: $_indexErrorUrl',
                    ),
                    duration: const Duration(seconds: 8),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeFiltersRow() {
    final Map<String, String> timePresets = {
      'daily': 'Daily (Today)',
      'weekly': 'Weekly (7 Days)',
      'monthly': 'Monthly (30 Days)',
      'all': 'All Time',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...timePresets.entries.map((preset) {
            final isSelected = _selectedTimeFilter == preset.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(preset.value),
                selected: isSelected,
                selectedColor: Colors.deepPurple,
                backgroundColor: Colors.grey[900],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedTimeFilter = preset.key;
                      _currentPage = 0;
                    });
                  }
                },
              ),
            );
          }),
          ChoiceChip(
            label: Text(
              _selectedTimeFilter == 'custom' && _customDateRange != null
                  ? '${DateFormat('MM/dd').format(_customDateRange!.start)} - ${DateFormat('MM/dd').format(_customDateRange!.end)}'
                  : 'Custom Range',
            ),
            selected: _selectedTimeFilter == 'custom',
            selectedColor: Colors.deepPurple,
            backgroundColor: Colors.grey[900],
            labelStyle: TextStyle(
              color: _selectedTimeFilter == 'custom'
                  ? Colors.white
                  : Colors.grey[400],
              fontWeight: _selectedTimeFilter == 'custom'
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (val) {
              _selectCustomDateRange();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, double> stats) {
    final double profit = stats['profit'] ?? 0;
    final double margin = stats['margin'] ?? 0;
    final isProfit = profit >= 0;

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Total Bets',
          value: '${NumberFormat.compact().format(stats['bets'])} 💎',
          subtitle: 'All User Investments',
          icon: Icons.monetization_on,
          gradient: LinearGradient(
            colors: [Colors.amber[700]!, Colors.orange[900]!],
          ),
        ),
        _buildStatCard(
          title: 'Total Wins',
          value: '${NumberFormat.compact().format(stats['wins'])} 💎',
          subtitle: 'All User Payouts',
          icon: Icons.emoji_events,
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.indigo[900]!],
          ),
        ),
        _buildStatCard(
          title: 'App Profit',
          value: '${NumberFormat.compact().format(profit)} 💎',
          subtitle: isProfit ? 'App In Net Gain' : 'App In Net Loss',
          icon: isProfit ? Icons.trending_up : Icons.trending_down,
          gradient: LinearGradient(
            colors: isProfit
                ? [Colors.teal[700]!, Colors.green[900]!]
                : [Colors.red[700]!, Colors.orange[900]!],
          ),
        ),
        _buildStatCard(
          title: 'Profit Margin',
          value: '${margin.toStringAsFixed(1)}%',
          subtitle: 'App Return Ratio',
          icon: Icons.pie_chart_outline,
          gradient: LinearGradient(
            colors: [Colors.purple[700]!, Colors.deepPurple[900]!],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBreakdownSection() {
    final gamesList = _registeredGames.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text(
                  'Game Breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '• Live Real-Time',
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (_selectedGameFilter != 'all')
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedGameFilter = 'all';
                    _currentPage = 0;
                  });
                },
                icon: const Icon(Icons.clear, size: 14, color: Colors.amber),
                label: const Text(
                  'Reset Filter',
                  style: TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 1200
                ? 3
                : (MediaQuery.of(context).size.width > 700 ? 2 : 1),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 110,
          ),
          itemCount: gamesList.length,
          itemBuilder: (context, index) {
            final game = gamesList[index];
            final gameStats = _calculateStats(gameFilter: game.key);
            final double profit = gameStats['profit'] ?? 0;
            final double margin = gameStats['margin'] ?? 0;
            final isProfit = profit >= 0;
            final isSelected = _selectedGameFilter == game.key;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedGameFilter = isSelected ? 'all' : game.key;
                  _currentPage = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? game.color.withValues(alpha: 0.18)
                      : Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? game.color : Colors.grey[800]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: game.color.withValues(alpha: 0.25),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Icon / Thumbnail
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: game.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: game.color.withValues(alpha: 0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: game.thumbnailUrl != null &&
                              game.thumbnailUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                game.thumbnailUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  game.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            )
                          : Text(
                              game.icon,
                              style: const TextStyle(fontSize: 22),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Title, HTML5 badge, Bet / Win
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  game.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? game.color : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (game.isHtml5) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.amber.withValues(alpha: 0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    'HTML5',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Bet: ${NumberFormat.compact().format(gameStats['bets'])}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Win: ${NumberFormat.compact().format(gameStats['wins'])}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Profit and Margin
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${profit >= 0 ? '+' : ''}${NumberFormat.compact().format(profit)} 💎',
                          style: TextStyle(
                            color: isProfit
                                ? Colors.tealAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${margin.toStringAsFixed(1)}% margin',
                          style: TextStyle(
                            color: isProfit
                                ? Colors.tealAccent.withValues(alpha: 0.8)
                                : Colors.redAccent.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryLogsSection(
    List<Map<String, dynamic>> paginatedLogs,
    int totalLogs,
    int totalPages,
    int startIndex,
    int endIndex,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Filters row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Game History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Game Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: DropdownButton<String>(
                  value: _registeredGames.containsKey(_selectedGameFilter) ||
                          _selectedGameFilter == 'all'
                      ? _selectedGameFilter
                      : 'all',
                  dropdownColor: Colors.black,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('🎮 All Games'),
                    ),
                    ..._registeredGames.values.map((game) {
                      return DropdownMenuItem(
                        value: game.key,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${game.icon} '),
                            Text(game.name),
                            if (game.isHtml5) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'HTML5',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedGameFilter = val;
                        _currentPage = 0;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by User ID, Username, or Round...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[500]),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _currentPage = 0;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.black,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.deepPurple),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
                _currentPage = 0;
              });
            },
          ),
          const SizedBox(height: 16),

          // Logs table
          if (totalLogs == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text(
                  'No matching game history found.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.grey[800]),
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Time',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Game',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'User',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Round',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Action / Item',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Bet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Payout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'App Profit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  rows: paginatedLogs.map((log) {
                    final double profit = log['profit'];
                    final bool isProfit = profit >= 0;
                    final String userId = log['userId'];
                    final String displayUsername =
                        _userNamesCache[userId] ?? 'User ($userId)';
                    final gameKey = log['gameKey'];
                    final gameInfo = _registeredGames[gameKey];

                    final Color gameColor = gameInfo?.color ?? Colors.deepPurpleAccent;
                    final String displayGameName = gameInfo?.name ?? log['gameName'] ?? 'Game';
                    final String gameIcon = gameInfo?.icon ?? log['gameIcon'] ?? '🎮';
                    final String logType = (log['type'] ?? '').toString();

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            DateFormat(
                              'MMM dd, hh:mm a',
                            ).format(log['timestamp']),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Chip(
                            avatar: Text(gameIcon, style: const TextStyle(fontSize: 12)),
                            label: Text(
                              displayGameName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: gameColor.withValues(alpha: 0.15),
                            side: BorderSide(
                              color: gameColor.withValues(alpha: 0.5),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayUsername,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                userId,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            '#${log['roundNumber']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                log['winningEmoji'] ?? '🎲',
                                style: const TextStyle(fontSize: 15),
                              ),
                              if (logType.isNotEmpty) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: logType == 'WIN'
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.blueGrey.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: logType == 'WIN'
                                          ? Colors.greenAccent
                                          : Colors.grey,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    logType,
                                    style: TextStyle(
                                      color: logType == 'WIN'
                                          ? Colors.greenAccent
                                          : Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            '${(log['totalBet'] as num).toStringAsFixed(0)} 💎',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${(log['winAmount'] as num).toStringAsFixed(0)} 💎',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${profit >= 0 ? '+' : ''}${profit.toStringAsFixed(0)} 💎',
                            style: TextStyle(
                              color: isProfit
                                  ? Colors.tealAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pagination controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${startIndex + 1}-$endIndex of $totalLogs records',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    Text(
                      'Page ${_currentPage + 1} of $totalPages',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
