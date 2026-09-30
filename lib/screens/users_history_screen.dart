import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/base_screen.dart';
import '../widgets/media_preview_widget.dart';

class UserHistorySummary {
  final String docId;
  final String userId;
  final String username;
  final String? profileImageUrl;
  final String? phone;
  final String? searchId;
  final String userType;
  final double currentDiamonds;
  final double currentBeans;

  // Period-filtered Metrics
  double rechargeDiamonds;
  double adminGivenDiamonds;
  double giftSentDiamonds;
  double giftReceivedDiamonds;
  int voiceRoomMinutes;
  int gameActiveMinutes;
  double gameTotalBets;
  double gameTotalWins;

  UserHistorySummary({
    required this.docId,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    this.phone,
    this.searchId,
    required this.userType,
    required this.currentDiamonds,
    required this.currentBeans,
    this.rechargeDiamonds = 0.0,
    this.adminGivenDiamonds = 0.0,
    this.giftSentDiamonds = 0.0,
    this.giftReceivedDiamonds = 0.0,
    this.voiceRoomMinutes = 0,
    this.gameActiveMinutes = 0,
    this.gameTotalBets = 0.0,
    this.gameTotalWins = 0.0,
  });

  double get gameNetProfitLoss => gameTotalWins - gameTotalBets;
}

class UserGameRoundLog {
  final String roundId;
  final String gameName;
  final String gameIcon;
  final double betAmount;
  final double winAmount;
  final double profitLoss;
  final String result;
  final DateTime timestamp;

  UserGameRoundLog({
    required this.roundId,
    required this.gameName,
    required this.gameIcon,
    required this.betAmount,
    required this.winAmount,
    required this.profitLoss,
    required this.result,
    required this.timestamp,
  });
}

class UserTransactionRecord {
  final String id;
  final String type; // 'Diamond Recharge', 'Admin Diamond Grant', 'Gift Sent 🎁', 'Gift Received 📥'
  final double amount;
  final String description;
  final DateTime timestamp;
  final Color color;
  final IconData icon;

  UserTransactionRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.color,
    required this.icon,
  });
}

class UsersHistoryScreen extends StatefulWidget {
  final String? initialUserId;

  const UsersHistoryScreen({super.key, this.initialUserId});

  @override
  State<UsersHistoryScreen> createState() => _UsersHistoryScreenState();
}

class _UsersHistoryScreenState extends State<UsersHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Selected period: 'daily', 'weekly', 'monthly', 'last_3_months', 'all', 'custom'
  String _selectedPeriod = 'daily';
  DateTimeRange? _customDateRange;

  bool _isLoading = true;

  // Raw fetched data
  List<DocumentSnapshot> _rawUserDocs = [];
  List<Map<String, dynamic>> _rechargeLogs = [];
  List<Map<String, dynamic>> _rechargeOrderLogs = [];
  List<Map<String, dynamic>> _adminDiamondLogs = [];
  List<Map<String, dynamic>> _superAdminLogs = [];
  List<Map<String, dynamic>> _giftTxnLogs = [];
  List<Map<String, dynamic>> _gameHistoryLogs = [];
  List<Map<String, dynamic>> _historyLogs = [];
  List<Map<String, dynamic>> _betHistoryLogs = [];
  List<Map<String, dynamic>> _catBetLogs = [];
  List<Map<String, dynamic>> _catWinLogs = [];

  // Computed User summaries
  List<UserHistorySummary> _allUserSummaries = [];
  List<UserHistorySummary> _filteredSummaries = [];

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedUserTypeFilter = 'all';

  // Sorting
  String _sortBy = 'recharge'; // 'recharge', 'admin', 'gift_sent', 'gift_rec', 'voice', 'game_time', 'game_pl'
  bool _sortAscending = false;

  // Pagination
  int _currentPage = 0;
  final int _rowsPerPage = 12;

  // Subscriptions
  StreamSubscription? _usersSub;
  StreamSubscription? _rechargeSub;
  StreamSubscription? _rechargeOrdersSub;
  StreamSubscription? _giftSub;
  StreamSubscription? _gameSub;

  @override
  void initState() {
    super.initState();
    _startListeners();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _currentPage = 0;
        _applyFilters();
      });
    });
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _rechargeSub?.cancel();
    _rechargeOrdersSub?.cancel();
    _giftSub?.cancel();
    _gameSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  DateTime _getPeriodStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        return now.subtract(const Duration(days: 7));
      case 'monthly':
        return now.subtract(const Duration(days: 30));
      case 'last_3_months':
        return now.subtract(const Duration(days: 90));
      case 'custom':
        return _customDateRange?.start ?? now.subtract(const Duration(days: 30));
      case 'all':
      default:
        return DateTime(2020, 1, 1);
    }
  }

  DateTime _getPeriodEndDate() {
    final now = DateTime.now();
    if (_selectedPeriod == 'custom' && _customDateRange != null) {
      return DateTime(
        _customDateRange!.end.year,
        _customDateRange!.end.month,
        _customDateRange!.end.day,
        23, 59, 59,
      );
    }
    return now;
  }

  void _startListeners() {
    setState(() => _isLoading = true);

    // 1. Users Stream
    _usersSub?.cancel();
    _usersSub = _firestore.collection('Users').snapshots().listen((snapshot) {
      if (!mounted) return;
      _rawUserDocs = snapshot.docs;
      _recomputeData();
    }, onError: (e) {
      debugPrint('Users listen error: $e');
    });

    // 2. Recharge stream from recharge_history
    _rechargeSub?.cancel();
    _rechargeSub = _firestore.collection('recharge_history').limit(3000).snapshots().listen((snapshot) {
      if (!mounted) return;
      _rechargeLogs = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _recomputeData();
    }, onError: (e) => debugPrint('Recharge listen error: $e'));

    // 3. Recharge Orders from rechargeOrders (wallet recharge)
    _rechargeOrdersSub?.cancel();
    _rechargeOrdersSub = _firestore.collection('rechargeOrders').limit(3000).snapshots().listen((snapshot) {
      if (!mounted) return;
      _rechargeOrderLogs = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _recomputeData();
    }, onError: (e) => debugPrint('Recharge orders listen error: $e'));

    // 4. Gift Transactions
    _giftSub?.cancel();
    _giftSub = _firestore.collection('gift_transactions').limit(3500).snapshots().listen((snapshot) {
      if (!mounted) return;
      _giftTxnLogs = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _recomputeData();
    }, onError: (e) => debugPrint('Gift listen error: $e'));

    // 5. Game History
    _gameSub?.cancel();
    _gameSub = _firestore.collection('game_history').limit(3500).snapshots().listen((snapshot) {
      if (!mounted) return;
      _gameHistoryLogs = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _recomputeData();
    }, onError: (e) => debugPrint('Game history listen error: $e'));

    // Secondary logs
    _fetchSecondaryCollections();
  }

  Future<void> _fetchSecondaryCollections() async {
    try {
      final futures = await Future.wait([
        _firestore.collection('diamond_transactions').limit(1500).get().catchError((_) => _emptyQuerySnap()),
        _firestore.collection('super_admin_assign_history').limit(500).get().catchError((_) => _emptyQuerySnap()),
        _firestore.collectionGroup('history').limit(2000).get().catchError((_) => _emptyQuerySnap()),
        _firestore.collectionGroup('bet_history').limit(2000).get().catchError((_) => _emptyQuerySnap()),
        _firestore.collection('game_bets').limit(1500).get().catchError((_) => _emptyQuerySnap()),
        _firestore.collection('game_wins').limit(1500).get().catchError((_) => _emptyQuerySnap()),
      ]);

      if (!mounted) return;
      _adminDiamondLogs = futures[0].docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
      _superAdminLogs = futures[1].docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
      _historyLogs = futures[2].docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
      _betHistoryLogs = futures[3].docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
      _catBetLogs = futures[4].docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
      _catWinLogs = futures[5].docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();

      _recomputeData();
    } catch (e) {
      debugPrint('Secondary logs fetch note: $e');
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _emptyQuerySnap() async {
    return await _firestore.collection('_empty_stub_').limit(1).get();
  }

  DateTime? _parseTimestamp(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) {
      // If unix seconds (10 digits), convert to ms
      if (val < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(val * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  double _parseNumber(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
    }
    return 0.0;
  }

  void _recomputeData() {
    final startDate = _getPeriodStartDate();
    final endDate = _getPeriodEndDate();

    final List<UserHistorySummary> userList = [];
    final Map<String, UserHistorySummary> idLookup = {};

    // 1. Initialize user summaries from Users collection
    for (final doc in _rawUserDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final docId = doc.id;
      final userId = (data['userId'] ?? docId).toString();
      final username = (data['fullname'] ?? data['username'] ?? data['name'] ?? 'User $userId').toString();
      final photoUrl = (data['photoUrl'] ?? data['profileImageUrl'] ?? data['avatar'] ?? data['image'])?.toString();
      final phone = (data['number'] ?? data['phone'] ?? data['phoneNumber'])?.toString();
      final searchId = (data['searchId'] ?? data['uniqueId'] ?? data['id'])?.toString();
      final userType = (data['userType'] ?? 'regular').toString();
      final diamonds = _parseNumber(data['diamonds'] ?? data['totalDiamonds']);
      final beans = _parseNumber(data['beans'] ?? data['totalBeans']);

      // Base user profile stats as fallback if period is all-time or stats are recorded in doc
      final activityStats = data['activityStats'] as Map<String, dynamic>? ?? {};
      int voiceMins = 0;
      double userSent = 0.0;
      double userRec = 0.0;
      double userRecharge = 0.0;

      if (_selectedPeriod == 'daily') {
        voiceMins = (activityStats['dailyVoiceRoomMinutes'] as num?)?.toInt() ?? 0;
        userSent = _parseNumber(activityStats['dailyDiamondsSent']);
        userRec = _parseNumber(activityStats['dailyDiamondsReceived']);
      } else if (_selectedPeriod == 'weekly') {
        voiceMins = (activityStats['weeklyVoiceRoomMinutes'] as num?)?.toInt() ?? 0;
        userSent = _parseNumber(activityStats['weeklyDiamondsSent']);
        userRec = _parseNumber(activityStats['weeklyDiamondsReceived']);
      } else if (_selectedPeriod == 'monthly') {
        voiceMins = (activityStats['monthlyVoiceRoomMinutes'] as num?)?.toInt() ?? 0;
        userSent = _parseNumber(activityStats['monthlyDiamondsSent']);
        userRec = _parseNumber(activityStats['monthlyDiamondsReceived']);
        userRecharge = _parseNumber(data['monthlyRechargeAmount']);
      } else {
        voiceMins = (data['voiceRoomMinutes'] ?? data['voiceMinutes'] ?? (activityStats['monthlyVoiceRoomMinutes'] as num?)?.toInt() ?? 0) as int;
        userSent = _parseNumber(data['diamondsSent'] ?? activityStats['monthlyDiamondsSent']);
        userRec = _parseNumber(data['diamondsReceived'] ?? activityStats['monthlyDiamondsReceived']);
        userRecharge = _parseNumber(data['totalRecharged'] ?? data['monthlyRechargeAmount']);
      }

      final summary = UserHistorySummary(
        docId: docId,
        userId: userId,
        username: username,
        profileImageUrl: photoUrl,
        phone: phone,
        searchId: searchId,
        userType: userType,
        currentDiamonds: diamonds,
        currentBeans: beans,
        voiceRoomMinutes: voiceMins,
        giftSentDiamonds: userSent,
        giftReceivedDiamonds: userRec,
        rechargeDiamonds: userRecharge,
      );

      userList.add(summary);

      // Register all identifier variants in lookup
      idLookup[docId] = summary;
      idLookup[userId] = summary;
      if (searchId != null && searchId.isNotEmpty) {
        idLookup[searchId] = summary;
      }
      if (phone != null && phone.isNotEmpty) {
        idLookup[phone] = summary;
      }
    }

    UserHistorySummary? findUser(dynamic rawId, [dynamic rawProfileId, dynamic rawPhone]) {
      if (rawId != null) {
        final key = rawId.toString().trim();
        if (idLookup.containsKey(key)) return idLookup[key];
      }
      if (rawProfileId != null) {
        final key = rawProfileId.toString().trim();
        if (idLookup.containsKey(key)) return idLookup[key];
      }
      if (rawPhone != null) {
        final key = rawPhone.toString().trim();
        if (idLookup.containsKey(key)) return idLookup[key];
      }
      return null;
    }

    // 2. Aggregate Recharges from recharge_history
    for (final r in _rechargeLogs) {
      final date = _parseTimestamp(r['createdAt'] ?? r['timestamp'] ?? r['date']);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) continue;

      final u = findUser(r['userId'], r['userProfileId'], r['userPhoneNumber']);
      final amt = _parseNumber(r['amount'] ?? r['diamonds'] ?? r['diamondAmount']);

      if (u != null) {
        u.rechargeDiamonds += amt;
      }
    }

    // 3. Aggregate Recharge Orders from rechargeOrders
    for (final ro in _rechargeOrderLogs) {
      final status = (ro['status'] ?? '').toString().toLowerCase();
      if (status != 'approved' && status != 'completed' && status != 'success') continue;

      final date = _parseTimestamp(ro['createdAt'] ?? ro['timestamp'] ?? ro['updatedAt']);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) continue;

      final u = findUser(ro['userId'], ro['userNumericId'], ro['userPhone']);
      final amt = _parseNumber(ro['diamondAmount'] ?? ro['amount']);

      if (u != null) {
        u.rechargeDiamonds += amt;
      }
    }

    // 4. Aggregate Admin Diamond Grants & Deductions
    for (final a in _adminDiamondLogs) {
      final date = _parseTimestamp(a['createdAt'] ?? a['timestamp']);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) continue;

      final u = findUser(a['userId'], a['targetUserId']);
      final amt = _parseNumber(a['diamonds'] ?? a['amount']);
      final type = (a['type'] ?? a['action'] ?? '').toString().toLowerCase();

      if (u != null) {
        if (type.contains('deduct') || type.contains('remove')) {
          u.adminGivenDiamonds -= amt;
        } else {
          u.adminGivenDiamonds += amt;
        }
      }
    }

    for (final sa in _superAdminLogs) {
      final date = _parseTimestamp(sa['createdAt'] ?? sa['timestamp']);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) continue;

      final u = findUser(sa['userId'] ?? sa['targetUserId']);
      final amt = _parseNumber(sa['diamonds'] ?? sa['amount']);
      if (u != null) {
        u.adminGivenDiamonds += amt;
      }
    }

    // 5. Aggregate Gift Transactions
    for (final g in _giftTxnLogs) {
      final date = _parseTimestamp(g['createdAt'] ?? g['timestamp']);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) continue;

      final sender = findUser(g['senderId']);
      final receiver = findUser(g['receiverId']);
      final diamondAmt = _parseNumber(g['diamondAmount'] ?? g['amount'] ?? g['diamonds']);

      if (sender != null) {
        sender.giftSentDiamonds += diamondAmt;
      }
      if (receiver != null) {
        receiver.giftReceivedDiamonds += diamondAmt;
      }
    }

    // 6. Aggregate Game History (HTML5, Greedy, Slot, Wheel)
    for (final gh in _gameHistoryLogs) {
      final date = _parseTimestamp(gh['createdAt'] ?? gh['timestamp'] ?? gh['time']);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) continue;

      final u = findUser(gh['userId'] ?? gh['player'] ?? gh['user_id']);
      final bet = _parseNumber(gh['totalBet'] ?? gh['bet'] ?? gh['betAmount'] ?? gh['amount']);
      final win = _parseNumber(gh['totalWin'] ?? gh['win'] ?? gh['winAmount'] ?? gh['payout']);

      if (u != null) {
        u.gameTotalBets += bet;
        u.gameTotalWins += win;
        u.gameActiveMinutes += (gh['playTimeMinutes'] as num?)?.toInt() ?? 2;
      }
    }

    // 7. Aggregate CollectionGroup history & bet_history
    for (final h in _historyLogs) {
      final date = _parseTimestamp(h['timestamp'] ?? h['createdAt']);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) continue;

      final u = findUser(h['userId'] ?? h['playerId']);
      final bet = _parseNumber(h['bet'] ?? h['totalBet']);
      final win = _parseNumber(h['win'] ?? h['totalWin']);

      if (u != null) {
        u.gameTotalBets += bet;
        u.gameTotalWins += win;
        u.gameActiveMinutes += 1;
      }
    }

    for (final bh in _betHistoryLogs) {
      final date = _parseTimestamp(bh['timestamp'] ?? bh['createdAt']);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) continue;

      final u = findUser(bh['userId'] ?? bh['playerId']);
      final bet = _parseNumber(bh['bet'] ?? bh['amount']);
      final win = _parseNumber(bh['win'] ?? bh['payout']);

      if (u != null) {
        u.gameTotalBets += bet;
        u.gameTotalWins += win;
        u.gameActiveMinutes += 1;
      }
    }

    setState(() {
      _allUserSummaries = userList;
      _isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    var list = List<UserHistorySummary>.from(_allUserSummaries);

    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      list = list.where((u) {
        final matchesName = u.username.toLowerCase().contains(_searchQuery);
        final matchesId = u.userId.toLowerCase().contains(_searchQuery);
        final matchesDocId = u.docId.toLowerCase().contains(_searchQuery);
        final matchesSearchId = (u.searchId ?? '').toLowerCase().contains(_searchQuery);
        final matchesPhone = (u.phone ?? '').toLowerCase().contains(_searchQuery);
        return matchesName || matchesId || matchesDocId || matchesSearchId || matchesPhone;
      }).toList();
    }

    // 2. User Type Filter
    if (_selectedUserTypeFilter != 'all') {
      list = list.where((u) => u.userType.toLowerCase() == _selectedUserTypeFilter.toLowerCase()).toList();
    }

    // 3. Sorting
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'recharge':
          cmp = a.rechargeDiamonds.compareTo(b.rechargeDiamonds);
          break;
        case 'admin':
          cmp = a.adminGivenDiamonds.compareTo(b.adminGivenDiamonds);
          break;
        case 'gift_sent':
          cmp = a.giftSentDiamonds.compareTo(b.giftSentDiamonds);
          break;
        case 'gift_rec':
          cmp = a.giftReceivedDiamonds.compareTo(b.giftReceivedDiamonds);
          break;
        case 'voice':
          cmp = a.voiceRoomMinutes.compareTo(b.voiceRoomMinutes);
          break;
        case 'game_time':
          cmp = a.gameActiveMinutes.compareTo(b.gameActiveMinutes);
          break;
        case 'game_pl':
          cmp = a.gameNetProfitLoss.compareTo(b.gameNetProfitLoss);
          break;
        default:
          cmp = a.rechargeDiamonds.compareTo(b.rechargeDiamonds);
      }
      return _sortAscending ? cmp : -cmp;
    });

    setState(() {
      _filteredSummaries = list;
    });
  }

  void _setPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _isLoading = true;
    });
    _recomputeData();
  }

  Future<void> _pickCustomDateRange() async {
    final initialRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 14)),
      end: DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _customDateRange ?? initialRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'custom';
        _isLoading = true;
      });
      _recomputeData();
    }
  }

  String _formatNumber(double val) {
    if (val.abs() >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val.abs() >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}K';
    }
    return val.toStringAsFixed(0);
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Users History',
      body: Container(
        color: const Color(0xFF0F172A),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 16),
                    Text(
                      'হিস্টরি ডেটা সঠিকতা যাচাই ও লোড হচ্ছে...',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  _startListeners();
                },
                color: Colors.blueAccent,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 16),
                      _buildPeriodFilterTabs(),
                      const SizedBox(height: 20),
                      _buildKPICardsGrid(),
                      const SizedBox(height: 24),
                      _buildSearchAndFilters(),
                      const SizedBox(height: 16),
                      _buildUsersHistoryTable(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── Header Section ───
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.manage_history, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Users History & Activity Intelligence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ইউজারদের রিচার্জ, এডমিন ট্রান্সফার, গিফট লেনদেন, ভয়েসরুম ও গেম রাউন্ড ভিত্তিক ১০০% নিখুঁত হিস্টরি',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _exportToCsv,
            icon: const Icon(Icons.file_download, size: 18),
            label: const Text('Export CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Period Filter Tabs ───
  Widget _buildPeriodFilterTabs() {
    final periods = [
      {'id': 'daily', 'label': '📅 Daily (আজ)', 'icon': Icons.today},
      {'id': 'weekly', 'label': '📅 Weekly (৭ দিন)', 'icon': Icons.date_range},
      {'id': 'monthly', 'label': '📅 Monthly (৩০ দিন)', 'icon': Icons.calendar_month},
      {'id': 'last_3_months', 'label': '📅 Last 3 Months (৩ মাস)', 'icon': Icons.history},
      {'id': 'all', 'label': '♾️ All Time', 'icon': Icons.all_inclusive},
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...periods.map((p) {
              final isSelected = _selectedPeriod == p['id'];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => _setPeriod(p['id'] as String),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: _pickCustomDateRange,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedPeriod == 'custom' ? const Color(0xFF8B5CF6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedPeriod == 'custom' ? Colors.purpleAccent : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_calendar, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _selectedPeriod == 'custom' && _customDateRange != null
                            ? '${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}'
                            : '📆 Custom Date Range',
                        style: TextStyle(
                          color: _selectedPeriod == 'custom' ? Colors.white : Colors.grey[300],
                          fontWeight: _selectedPeriod == 'custom' ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── KPI Cards Grid ───
  Widget _buildKPICardsGrid() {
    double totalRecharge = 0.0;
    double totalAdmin = 0.0;
    double totalGiftSent = 0.0;
    double totalGiftRec = 0.0;
    int totalVoiceMins = 0;
    int totalGameMins = 0;
    double totalGameBet = 0.0;
    double totalGameWin = 0.0;

    for (final u in _filteredSummaries) {
      totalRecharge += u.rechargeDiamonds;
      totalAdmin += u.adminGivenDiamonds;
      totalGiftSent += u.giftSentDiamonds;
      totalGiftRec += u.giftReceivedDiamonds;
      totalVoiceMins += u.voiceRoomMinutes;
      totalGameMins += u.gameActiveMinutes;
      totalGameBet += u.gameTotalBets;
      totalGameWin += u.gameTotalWins;
    }

    final netGamePL = totalGameWin - totalGameBet;

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 900;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildKPICard(
            title: 'কত ডায়মন্ড রিচার্জ',
            subtitle: 'Recharged Diamonds',
            value: '${_formatNumber(totalRecharge)} 💎',
            icon: Icons.account_balance_wallet,
            color: const Color(0xFF10B981),
            width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2,
          ),
          _buildKPICard(
            title: 'এডমিন ডায়মন্ড দিয়েছে',
            subtitle: 'Admin Given Diamonds',
            value: '${_formatNumber(totalAdmin)} 💎',
            icon: Icons.admin_panel_settings,
            color: const Color(0xFFF59E0B),
            width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2,
          ),
          _buildKPICard(
            title: 'কত ডায়মন্ড গিফট করেছে',
            subtitle: 'Diamonds Gifted',
            value: '${_formatNumber(totalGiftSent)} 💎',
            icon: Icons.card_giftcard,
            color: const Color(0xFFEC4899),
            width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2,
          ),
          _buildKPICard(
            title: 'কত ডায়মন্ড রিসিভ করেছে',
            subtitle: 'Diamonds Received',
            value: '${_formatNumber(totalGiftRec)} 💎',
            icon: Icons.move_to_inbox,
            color: const Color(0xFF8B5CF6),
            width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2,
          ),
          _buildKPICard(
            title: 'ভয়েসরুমে একটিভ সময়',
            subtitle: 'Voice Room Active',
            value: _formatMinutes(totalVoiceMins),
            icon: Icons.mic,
            color: const Color(0xFF06B6D4),
            width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2,
          ),
          _buildKPICard(
            title: 'গেমে একটিভ সময়',
            subtitle: 'Game Active Time',
            value: _formatMinutes(totalGameMins),
            icon: Icons.sports_esports,
            color: const Color(0xFF6366F1),
            width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2,
          ),
          _buildKPICard(
            title: 'গেম মোট উইন / লস',
            subtitle: 'Total Bets vs Wins',
            value: 'Win: ${_formatNumber(totalGameWin)} / Bet: ${_formatNumber(totalGameBet)}',
            icon: Icons.casino,
            color: const Color(0xFFE11D48),
            width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2,
          ),
          _buildKPICard(
            title: 'গেম নেট লাভ / ক্ষতি',
            subtitle: 'Net Profit/Loss (P/L)',
            value: '${netGamePL >= 0 ? '+' : ''}${_formatNumber(netGamePL)} 💎',
            icon: netGamePL >= 0 ? Icons.trending_up : Icons.trending_down,
            color: netGamePL >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2,
          ),
        ],
      );
    });
  }

  Widget _buildKPICard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search & Filters Bar ───
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ইউজারনেম, ইউজার আইডি, প্রোফাইল আইডি বা ফোন নম্বর দিয়ে খুঁজুন...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0F172A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Type filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedUserTypeFilter,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All User Types')),
                  DropdownMenuItem(value: 'regular', child: Text('Regular')),
                  DropdownMenuItem(value: 'host', child: Text('Host')),
                  DropdownMenuItem(value: 'seller', child: Text('Seller')),
                  DropdownMenuItem(value: 'agency', child: Text('Agency')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedUserTypeFilter = val;
                      _currentPage = 0;
                      _applyFilters();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Users History Overview Table ───
  Widget _buildUsersHistoryTable() {
    if (_filteredSummaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off, color: Colors.grey, size: 50),
            const SizedBox(height: 12),
            const Text(
              'কোন ইউজার হিস্টরি পাওয়া যায়নি',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'অনুগ্রহ করে অন্য সময়কাল বা সার্চ কিওয়ার্ড দিয়ে চেষ্টা করুন।',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }

    final totalPages = (_filteredSummaries.length / _rowsPerPage).ceil();
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredSummaries.length);
    final pageItems = _filteredSummaries.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 68,
              horizontalMargin: 16,
              columnSpacing: 20,
              columns: [
                const DataColumn(label: Text('User Profile', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(
                  label: const Text('Recharged 💎', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  onSort: (idx, asc) => _toggleSort('recharge'),
                ),
                DataColumn(
                  label: const Text('Admin Given 💎', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                  onSort: (idx, asc) => _toggleSort('admin'),
                ),
                DataColumn(
                  label: const Text('Gift Sent 💎', style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold)),
                  onSort: (idx, asc) => _toggleSort('gift_sent'),
                ),
                DataColumn(
                  label: const Text('Gift Received 💎', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                  onSort: (idx, asc) => _toggleSort('gift_rec'),
                ),
                DataColumn(
                  label: const Text('Voice Active 🎙️', style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold)),
                  onSort: (idx, asc) => _toggleSort('voice'),
                ),
                DataColumn(
                  label: const Text('Game Active 🎮', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                  onSort: (idx, asc) => _toggleSort('game_time'),
                ),
                DataColumn(
                  label: const Text('Game Win/Loss 🎰', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                  onSort: (idx, asc) => _toggleSort('game_pl'),
                ),
                const DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              ],
              rows: pageItems.map((u) {
                final netPL = u.gameNetProfitLoss;
                return DataRow(
                  cells: [
                    // User cell
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                            child: u.profileImageUrl != null && u.profileImageUrl!.isNotEmpty
                                ? MediaPreviewWidget(
                                    url: u.profileImageUrl!,
                                    width: 36,
                                    height: 36,
                                    borderRadius: BorderRadius.circular(18),
                                  )
                                : Text(
                                    u.username.isNotEmpty ? u.username[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                u.username,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'ID: ${u.searchId ?? (u.userId.length > 8 ? u.userId.substring(0, 8) : u.userId)}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _getUserTypeColor(u.userType).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      u.userType.toUpperCase(),
                                      style: TextStyle(
                                        color: _getUserTypeColor(u.userType),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Recharged
                    DataCell(
                      Text(
                        '${_formatNumber(u.rechargeDiamonds)} 💎',
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Admin given
                    DataCell(
                      Text(
                        '${_formatNumber(u.adminGivenDiamonds)} 💎',
                        style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Gift sent
                    DataCell(
                      Text(
                        '${_formatNumber(u.giftSentDiamonds)} 💎',
                        style: const TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Gift received
                    DataCell(
                      Text(
                        '${_formatNumber(u.giftReceivedDiamonds)} 💎',
                        style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Voice Room Time
                    DataCell(
                      Text(
                        _formatMinutes(u.voiceRoomMinutes),
                        style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Game Active Time
                    DataCell(
                      Text(
                        _formatMinutes(u.gameActiveMinutes),
                        style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Game Win / Loss
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'W: ${_formatNumber(u.gameTotalWins)} / B: ${_formatNumber(u.gameTotalBets)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          Text(
                            '${netPL >= 0 ? '+' : ''}${_formatNumber(netPL)} 💎',
                            style: TextStyle(
                              color: netPL >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    DataCell(
                      ElevatedButton.icon(
                        onPressed: () => _openUserDetailsDialog(u),
                        icon: const Icon(Icons.analytics_outlined, size: 14),
                        label: const Text('হিস্টরি দেখুন'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          // Pagination controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${startIndex + 1} - $endIndex of ${_filteredSummaries.length} Users',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
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
                      'Page ${_currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSort(String field) {
    setState(() {
      if (_sortBy == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = field;
        _sortAscending = false;
      }
      _applyFilters();
    });
  }

  Color _getUserTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'host':
        return Colors.purpleAccent;
      case 'seller':
        return Colors.greenAccent;
      case 'agency':
        return Colors.amberAccent;
      case 'admin':
        return Colors.redAccent;
      default:
        return Colors.blueAccent;
    }
  }

  // ─── User In-Depth History Drill-Down Dialog ───
  void _openUserDetailsDialog(UserHistorySummary user) {
    showDialog(
      context: context,
      builder: (ctx) => _UserDetailsDialog(
        user: user,
        selectedPeriod: _selectedPeriod,
        startDate: _getPeriodStartDate(),
        endDate: _getPeriodEndDate(),
        firestore: _firestore,
      ),
    );
  }

  // ─── Export to CSV ───
  void _exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln('User ID,Username,Phone,User Type,Recharged Diamonds,Admin Diamonds,Gift Sent,Gift Received,Voice Room Mins,Game Active Mins,Game Bets,Game Wins,Game Net PL');

    for (final u in _filteredSummaries) {
      buffer.writeln(
        '"${u.userId}","${u.username}","${u.phone ?? ''}","${u.userType}",${u.rechargeDiamonds},${u.adminGivenDiamonds},${u.giftSentDiamonds},${u.giftReceivedDiamonds},${u.voiceRoomMinutes},${u.gameActiveMinutes},${u.gameTotalBets},${u.gameTotalWins},${u.gameNetProfitLoss}',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${_filteredSummaries.length} user records to CSV!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// In-Depth User Details Modal (Game Rounds, Recharges, Gifts, Voice Room)
// ─────────────────────────────────────────────────────────────────────────────

class _UserDetailsDialog extends StatefulWidget {
  final UserHistorySummary user;
  final String selectedPeriod;
  final DateTime startDate;
  final DateTime endDate;
  final FirebaseFirestore firestore;

  const _UserDetailsDialog({
    required this.user,
    required this.selectedPeriod,
    required this.startDate,
    required this.endDate,
    required this.firestore,
  });

  @override
  State<_UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<_UserDetailsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingLogs = true;

  List<UserGameRoundLog> _gameRounds = [];
  List<UserTransactionRecord> _rechargeAndAdminLogs = [];
  List<UserTransactionRecord> _giftLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserDetailedLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetailedLogs() async {
    try {
      final uId = widget.user.userId;
      final docId = widget.user.docId;
      final searchId = widget.user.searchId ?? '';
      final phone = widget.user.phone ?? '';

      final candidateIds = {uId, docId, searchId, phone}..removeWhere((e) => e.isEmpty);

      // 1. Fetch Game Rounds from game_history & history
      final List<Future<QuerySnapshot<Map<String, dynamic>>>> gameQueries = [];
      for (final cid in candidateIds) {
        gameQueries.add(
          widget.firestore
              .collection('game_history')
              .where('userId', isEqualTo: cid)
              .limit(150)
              .get()
              .catchError((_) => widget.firestore.collection('_empty_stub_').limit(1).get()),
        );
      }

      final gameSnaps = await Future.wait(gameQueries);

      final List<UserGameRoundLog> rounds = [];
      final Set<String> seenRounds = {};

      for (final snap in gameSnaps) {
        for (final doc in snap.docs) {
          final data = doc.data();
          final roundId = (data['roundId'] ?? data['roundNumber'] ?? doc.id).toString();
          if (seenRounds.contains(roundId)) continue;
          seenRounds.add(roundId);

          final rawGame = data['gameKey'] ?? data['gameName'] ?? data['game'] ?? 'HTML5 Game';
          final gameName = _pickGameName(rawGame);
          final gameIcon = _pickGameIcon(gameName);
          final bet = _parseNumber(data['totalBet'] ?? data['bet'] ?? data['betAmount']);
          final win = _parseNumber(data['totalWin'] ?? data['win'] ?? data['winAmount']);
          final pl = win - bet;
          final result = (data['result'] ?? data['outcome'] ?? data['winningItem'] ?? (pl >= 0 ? 'Win' : 'Loss')).toString();
          final time = _parseTimestamp(data['createdAt'] ?? data['timestamp']) ?? DateTime.now();

          rounds.add(UserGameRoundLog(
            roundId: roundId,
            gameName: gameName,
            gameIcon: gameIcon,
            betAmount: bet,
            winAmount: win,
            profitLoss: pl,
            result: result,
            timestamp: time,
          ));
        }
      }

      // Also query collectionGroup history & bet_history for this user
      try {
        final historyGroupSnaps = await Future.wait([
          widget.firestore.collectionGroup('history').where('userId', isEqualTo: uId).limit(100).get().catchError((_) => widget.firestore.collection('_empty_stub_').limit(1).get()),
          widget.firestore.collectionGroup('bet_history').where('userId', isEqualTo: uId).limit(100).get().catchError((_) => widget.firestore.collection('_empty_stub_').limit(1).get()),
        ]);

        for (final snap in historyGroupSnaps) {
          for (final doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final roundId = (data['roundId'] ?? data['roundNumber'] ?? doc.id).toString();
            if (seenRounds.contains(roundId)) continue;
            seenRounds.add(roundId);

            final rawGame = data['gameName'] ?? data['game'] ?? 'Greedy / Wheel';
            final gameName = _pickGameName(rawGame);
            final gameIcon = _pickGameIcon(gameName);
            final bet = _parseNumber(data['bet'] ?? data['totalBet'] ?? data['amount']);
            final win = _parseNumber(data['win'] ?? data['totalWin'] ?? data['payout']);
            final pl = win - bet;
            final result = (data['result'] ?? (pl >= 0 ? 'Win' : 'Loss')).toString();
            final time = _parseTimestamp(data['timestamp'] ?? data['createdAt']) ?? DateTime.now();

            rounds.add(UserGameRoundLog(
              roundId: roundId,
              gameName: gameName,
              gameIcon: gameIcon,
              betAmount: bet,
              winAmount: win,
              profitLoss: pl,
              result: result,
              timestamp: time,
            ));
          }
        }
      } catch (e) {
        debugPrint('Group history query note: $e');
      }

      rounds.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // 2. Fetch Recharges & Admin Grants
      final List<UserTransactionRecord> rechargeLogs = [];

      final rechargeQueries = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
      for (final cid in candidateIds) {
        rechargeQueries.add(
          widget.firestore
              .collection('recharge_history')
              .where('userId', isEqualTo: cid)
              .limit(100)
              .get()
              .catchError((_) => widget.firestore.collection('_empty_stub_').limit(1).get()),
        );
        rechargeQueries.add(
          widget.firestore
              .collection('rechargeOrders')
              .where('userId', isEqualTo: cid)
              .limit(100)
              .get()
              .catchError((_) => widget.firestore.collection('_empty_stub_').limit(1).get()),
        );
        rechargeQueries.add(
          widget.firestore
              .collection('diamond_transactions')
              .where('userId', isEqualTo: cid)
              .limit(100)
              .get()
              .catchError((_) => widget.firestore.collection('_empty_stub_').limit(1).get()),
        );
      }

      final rechargeResults = await Future.wait(rechargeQueries);
      final Set<String> seenTxnIds = {};

      for (final snap in rechargeResults) {
        for (final doc in snap.docs) {
          if (seenTxnIds.contains(doc.id)) continue;
          seenTxnIds.add(doc.id);

          final data = doc.data();
          final amt = _parseNumber(data['diamonds'] ?? data['amount'] ?? data['diamondAmount']);
          final time = _parseTimestamp(data['createdAt'] ?? data['timestamp'] ?? data['updatedAt']) ?? DateTime.now();

          if (data.containsKey('paymentMethod') || data.containsKey('orderId') || data.containsKey('sellerId')) {
            rechargeLogs.add(UserTransactionRecord(
              id: doc.id,
              type: 'Diamond Recharge',
              amount: amt,
              description: 'Payment: ${data['paymentMethod'] ?? 'Wallet/Online'} | Seller: ${data['sellerName'] ?? 'Official'} | ID: ${data['transactionId'] ?? doc.id}',
              timestamp: time,
              color: const Color(0xFF10B981),
              icon: Icons.account_balance_wallet,
            ));
          } else {
            final reason = (data['reason'] ?? data['notes'] ?? 'Admin Adjustment').toString();
            final isDeduct = reason.toLowerCase().contains('deduct') || reason.toLowerCase().contains('remove');
            rechargeLogs.add(UserTransactionRecord(
              id: doc.id,
              type: isDeduct ? 'Admin Diamond Deduct' : 'Admin Diamond Grant',
              amount: amt,
              description: 'Admin Credit: $reason',
              timestamp: time,
              color: isDeduct ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
              icon: Icons.admin_panel_settings,
            ));
          }
        }
      }

      rechargeLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // 3. Fetch Gift Logs (Sent & Received)
      final List<UserTransactionRecord> gifts = [];
      final Set<String> seenGiftIds = {};

      final giftQueries = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
      for (final cid in candidateIds) {
        giftQueries.add(
          widget.firestore
              .collection('gift_transactions')
              .where('senderId', isEqualTo: cid)
              .limit(100)
              .get()
              .catchError((_) => widget.firestore.collection('_empty_stub_').limit(1).get()),
        );
        giftQueries.add(
          widget.firestore
              .collection('gift_transactions')
              .where('receiverId', isEqualTo: cid)
              .limit(100)
              .get()
              .catchError((_) => widget.firestore.collection('_empty_stub_').limit(1).get()),
        );
      }

      final giftSnaps = await Future.wait(giftQueries);
      for (final snap in giftSnaps) {
        for (final doc in snap.docs) {
          if (seenGiftIds.contains(doc.id)) continue;
          seenGiftIds.add(doc.id);

          final data = doc.data();
          final senderId = (data['senderId'] ?? '').toString();
          final isSender = candidateIds.contains(senderId);
          final amt = _parseNumber(data['diamondAmount'] ?? data['amount'] ?? data['beansToReceiver']);
          final time = _parseTimestamp(data['createdAt'] ?? data['timestamp']) ?? DateTime.now();

          if (isSender) {
            gifts.add(UserTransactionRecord(
              id: doc.id,
              type: 'Gift Sent 🎁',
              amount: amt,
              description: 'Sent "${data['giftName'] ?? 'Gift'}" to ${data['receiverName'] ?? data['receiverId']}',
              timestamp: time,
              color: const Color(0xFFEC4899),
              icon: Icons.send_rounded,
            ));
          } else {
            gifts.add(UserTransactionRecord(
              id: doc.id,
              type: 'Gift Received 📥',
              amount: amt,
              description: 'Received "${data['giftName'] ?? 'Gift'}" from ${data['senderName'] ?? data['senderId']}',
              timestamp: time,
              color: const Color(0xFF8B5CF6),
              icon: Icons.move_to_inbox,
            ));
          }
        }
      }

      gifts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          _gameRounds = rounds;
          _rechargeAndAdminLogs = rechargeLogs;
          _giftLogs = gifts;
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user logs: $e');
      if (mounted) {
        setState(() => _isLoadingLogs = false);
      }
    }
  }

  String _pickGameName(dynamic raw) {
    final str = (raw ?? '').toString().toLowerCase();
    if (str.contains('delicious')) return 'Greedy Delicious';
    if (str.contains('market')) return 'Greedy Market';
    if (str.contains('cat')) return 'Greedy Cat';
    if (str.contains('queen') || str.contains('king') || str.contains('slot')) return 'King Queen Slot';
    if (str.contains('spin') || str.contains('gem') || str.contains('arabian')) return 'Arabian Spin';
    if (str.contains('ludo')) return 'Ludo Champion';
    if (str.contains('wheel') || str.contains('fruit')) return 'Fruit Wheel';
    if (str.contains('pink')) return 'Greedy Pink';
    if (str.contains('red')) return 'Greedy Red';
    return raw?.toString() ?? 'HTML5 Game';
  }

  String _pickGameIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('delicious')) return '🍖';
    if (lower.contains('market')) return '🎡';
    if (lower.contains('cat')) return '🐱';
    if (lower.contains('queen') || lower.contains('king') || lower.contains('slot')) return '👑';
    if (lower.contains('spin') || lower.contains('gem') || lower.contains('arabian')) return '💎';
    if (lower.contains('ludo')) return '🎲';
    if (lower.contains('fruit') || lower.contains('wheel')) return '🍒';
    if (lower.contains('pink')) return '🧁';
    if (lower.contains('red')) return '🌭';
    return '🎮';
  }

  double _parseNumber(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
    return 0.0;
  }

  DateTime? _parseTimestamp(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) {
      if (val < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(val * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 1000,
        height: 750,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildDialogHeader(),
            const SizedBox(height: 16),
            _buildDialogTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoadingLogs
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGameRoundsTab(),
                        _buildRechargeAndAdminTab(),
                        _buildGiftsTab(),
                        _buildVoiceRoomActivityTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
          child: widget.user.profileImageUrl != null && widget.user.profileImageUrl!.isNotEmpty
              ? MediaPreviewWidget(
                  url: widget.user.profileImageUrl!,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(26),
                )
              : Text(
                  widget.user.username.isNotEmpty ? widget.user.username[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.user.username,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.user.userType.toUpperCase(),
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'User ID: ${widget.user.userId}  |  Current Diamonds: ${widget.user.currentDiamonds.toStringAsFixed(0)} 💎  |  Beans: ${widget.user.currentBeans.toStringAsFixed(0)} 🫘',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildDialogTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blueAccent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.casino, size: 18), text: 'গেম হিস্টরি ও রাউন্ড (Games)'),
          Tab(icon: Icon(Icons.account_balance_wallet, size: 18), text: 'রিচার্জ ও এডমিন ডায়মন্ড'),
          Tab(icon: Icon(Icons.card_giftcard, size: 18), text: 'গিফট লেনদেন (Gifts)'),
          Tab(icon: Icon(Icons.mic, size: 18), text: 'ভয়েসরুম ও অ্যাক্টিভিটি'),
        ],
      ),
    );
  }

  // ─── Tab 1: Game Rounds Tab ───
  Widget _buildGameRoundsTab() {
    if (_gameRounds.isEmpty) {
      return const Center(
        child: Text(
          'কোন গেম রাউন্ড হিস্টরি পাওয়া যায়নি',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: _gameRounds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = _gameRounds[index];
        final isWin = r.profitLoss >= 0;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isWin ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isWin ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(r.gameIcon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r.gameName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'রাউন্ড নং: ${r.roundId}',
                            style: TextStyle(color: Colors.grey[300], fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ফলাফল: ${r.result}  |  সময়: ${DateFormat('dd MMM yyyy, hh:mm a').format(r.timestamp)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'বেট: ${r.betAmount.toStringAsFixed(0)} 💎  |  উইন: ${r.winAmount.toStringAsFixed(0)} 💎',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isWin ? '+' : ''}${r.profitLoss.toStringAsFixed(0)} 💎',
                    style: TextStyle(
                      color: isWin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Tab 2: Recharge & Admin Logs ───
  Widget _buildRechargeAndAdminTab() {
    if (_rechargeAndAdminLogs.isEmpty) {
      return const Center(
        child: Text(
          'কোন রিচার্জ বা এডমিন ডায়মন্ড হিস্টরি পাওয়া যায়নি',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: _rechargeAndAdminLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _rechargeAndAdminLogs[index];
        final isNegative = log.type.contains('Deduct');
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: log.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: log.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(log.icon, color: log.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.type,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      log.description,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(log.timestamp),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '${isNegative ? '-' : '+'}${log.amount.toStringAsFixed(0)} 💎',
                style: TextStyle(color: log.color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Tab 3: Gifts Tab ───
  Widget _buildGiftsTab() {
    if (_giftLogs.isEmpty) {
      return const Center(
        child: Text(
          'কোন গিফট লেনদেন হিস্টরি পাওয়া যায়নি',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: _giftLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final g = _giftLogs[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: g.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: g.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(g.icon, color: g.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.type,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      g.description,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(g.timestamp),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '${g.type.contains('Sent') ? '-' : '+'}${g.amount.toStringAsFixed(0)} 💎',
                style: TextStyle(color: g.color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Tab 4: Voice Room Activity Tab ───
  Widget _buildVoiceRoomActivityTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ভয়েসরুম ও একটিভ টাইম সামারি',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActivityMiniCard(
                  'মোট ভয়েসরুম সময়',
                  '${widget.user.voiceRoomMinutes} মিনিট (${(widget.user.voiceRoomMinutes / 60).toStringAsFixed(1)} ঘণ্টা)',
                  Icons.mic,
                  const Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityMiniCard(
                  'মোট গেমিং একটিভ সময়',
                  '${widget.user.gameActiveMinutes} মিনিট (${(widget.user.gameActiveMinutes / 60).toStringAsFixed(1)} ঘণ্টা)',
                  Icons.sports_esports,
                  const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'অ্যাক্টিভিটি লেভেল ও স্ট্যাটাস',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildStatRow('ইউজার আইডি', widget.user.userId),
                const Divider(color: Colors.white10),
                _buildStatRow('ফোন নম্বর', widget.user.phone ?? 'N/A'),
                const Divider(color: Colors.white10),
                _buildStatRow('ডায়মন্ড ব্যালেন্স', '${widget.user.currentDiamonds.toStringAsFixed(0)} 💎'),
                const Divider(color: Colors.white10),
                _buildStatRow('বিন্স ব্যালেন্স', '${widget.user.currentBeans.toStringAsFixed(0)} 🫘'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityMiniCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(height: 4),
                Text(val, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
