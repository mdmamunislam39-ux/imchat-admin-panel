import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:imchat_adminpanel/widgets/web_iframe_view.dart';

class GreedyCatManagementView extends StatefulWidget {
  final VoidCallback? onBackToCatalog;

  const GreedyCatManagementView({super.key, this.onBackToCatalog});

  @override
  State<GreedyCatManagementView> createState() =>
      _GreedyCatManagementViewState();
}

class _GreedyCatManagementViewState
    extends State<GreedyCatManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _iframeKey = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncingToWall = false;
  bool _isActive = true;

  // Game Hosting & URLs
  final String _hostedUrl = 'https://greedy-cat-game.web.app';
  final String _localUrl = 'http://localhost:8090';
  bool _useLocalDevUrl = false;

  // RTP & Mechanics Configuration
  double _targetRtp = 75.0; // 75% Target Return to Player
  double _houseMargin = 25.0; // 25% App Owner Guaranteed Profit
  double _maxRtpCap = 85.0; // 85% Hard Cap
  final TextEditingController _jackpotBaseCtrl = TextEditingController(
    text: '2000000',
  );
  int _forceWinnerIndex = -1; // -1: Random PRNG, 0..7: Items, 8: Salad, 9: Pizza

  // 8 Food Items Controllers (Greedy Cat specific items)
  final List<TextEditingController> _itemNames = [
    TextEditingController(text: 'BBQ Chicken'),
    TextEditingController(text: 'Tomato'),
    TextEditingController(text: 'BBQ Leg Piece'),
    TextEditingController(text: 'Pepper'),
    TextEditingController(text: 'BBQ Fish'),
    TextEditingController(text: 'Carrot'),
    TextEditingController(text: 'BBQ Shrimp'),
    TextEditingController(text: 'Grilled Corn'),
  ];
  final List<TextEditingController> _itemMultipliers = [
    TextEditingController(text: '45'),
    TextEditingController(text: '5'),
    TextEditingController(text: '15'),
    TextEditingController(text: '5'),
    TextEditingController(text: '25'),
    TextEditingController(text: '5'),
    TextEditingController(text: '10'),
    TextEditingController(text: '5'),
  ];

  // Chips Configuration Controllers (Regular & Advanced)
  final List<TextEditingController> _regularChipCtrls = [
    TextEditingController(text: '10'),
    TextEditingController(text: '100'),
    TextEditingController(text: '1000'),
    TextEditingController(text: '10000'),
    TextEditingController(text: '100000'),
  ];
  final List<TextEditingController> _advancedChipCtrls = [
    TextEditingController(text: '1000'),
    TextEditingController(text: '10000'),
    TextEditingController(text: '50000'),
    TextEditingController(text: '100000'),
    TextEditingController(text: '500000'),
  ];

  // Background Wallpaper Controller
  final TextEditingController _bgImageUrlCtrl = TextEditingController(
    text: '',
  );

  // Real-Time Diamond Icon Controller
  final TextEditingController _diamondIconUrlCtrl = TextEditingController(
    text: 'https://cdn-icons-png.flaticon.com/512/9496/9496739.png',
  );

  // Test User Simulator
  final TextEditingController _testUserIdCtrl = TextEditingController(
    text: 'ADMIN_TEST_USER',
  );
  final TextEditingController _testUserNameCtrl = TextEditingController(
    text: 'Cat Master',
  );
  final TextEditingController _testDiamondsCtrl = TextEditingController(
    text: '500000',
  );

  // In-Browser Code Editor
  String _selectedFile = 'game.js';
  final TextEditingController _codeEditorCtrl = TextEditingController();
  bool _isLoadingCode = false;
  bool _isSavingCode = false;

  // Code Cache
  final Map<String, String> _fileCodeCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadConfig();
    _loadCodeFile(_selectedFile);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jackpotBaseCtrl.dispose();
    for (var c in _itemNames) {
      c.dispose();
    }
    for (var c in _itemMultipliers) {
      c.dispose();
    }
    for (var c in _regularChipCtrls) {
      c.dispose();
    }
    for (var c in _advancedChipCtrls) {
      c.dispose();
    }
    _bgImageUrlCtrl.dispose();
    _diamondIconUrlCtrl.dispose();
    _testUserIdCtrl.dispose();
    _testUserNameCtrl.dispose();
    _testDiamondsCtrl.dispose();
    _codeEditorCtrl.dispose();
    super.dispose();
  }

  String get _currentPreviewUrl {
    final base = _useLocalDevUrl ? _localUrl : _hostedUrl;
    final uid = _testUserIdCtrl.text.trim();
    final name = Uri.encodeComponent(_testUserNameCtrl.text.trim());
    final diamonds = _testDiamondsCtrl.text.trim();
    return '$base?userId=$uid&name=$name&diamonds=$diamonds&gameCode=html5_greedy_cat';
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore
          .collection('config')
          .doc('html5_greedy_cat')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _isActive = data['isActive'] ?? true;
        _targetRtp = (data['winRatio'] as num?)?.toDouble() ?? 75.0;
        _houseMargin = 100.0 - _targetRtp;
        _maxRtpCap = (data['maxRtpCap'] as num?)?.toDouble() ?? 85.0;
        if (data['jackpotBase'] != null) {
          _jackpotBaseCtrl.text = data['jackpotBase'].toString();
        }
        _forceWinnerIndex = data['forceWinnerIndex'] ?? -1;

        if (data['gameBackgroundUrl'] != null &&
            data['gameBackgroundUrl'].toString().isNotEmpty) {
          _bgImageUrlCtrl.text = data['gameBackgroundUrl'].toString();
        }
        if (data['diamondIcon'] != null &&
            data['diamondIcon'].toString().isNotEmpty) {
          _diamondIconUrlCtrl.text = data['diamondIcon'].toString();
        }

        final List<dynamic>? items = data['items'];
        if (items != null && items.length == 8) {
          for (int i = 0; i < 8; i++) {
            _itemNames[i].text = items[i]['name'] ?? _itemNames[i].text;
            _itemMultipliers[i].text =
                (items[i]['multiplier'] ?? _itemMultipliers[i].text).toString();
          }
        }

        final List<dynamic>? regChips = data['regularChips'];
        if (regChips != null && regChips.length == 5) {
          for (int i = 0; i < 5; i++) {
            _regularChipCtrls[i].text = regChips[i].toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading greedy cat config: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final List<Map<String, dynamic>> itemsList = [];
      for (int i = 0; i < 8; i++) {
        itemsList.add({
          'id': i,
          'name': _itemNames[i].text.trim(),
          'multiplier': int.tryParse(_itemMultipliers[i].text.trim()) ?? 5,
          'category': (i % 2 == 0) ? 'meat' : 'veg',
        });
      }

      final regChips = _regularChipCtrls
          .map((c) => int.tryParse(c.text.trim()) ?? 10)
          .toList();
      final advChips = _advancedChipCtrls
          .map((c) => int.tryParse(c.text.trim()) ?? 1000)
          .toList();

      final payload = {
        'gameCode': 'html5_greedy_cat',
        'gameName': 'Greedy Cat',
        'isActive': _isActive,
        'winRatio': _targetRtp,
        'houseMargin': _houseMargin,
        'maxRtpCap': _maxRtpCap,
        'jackpotBase': int.tryParse(_jackpotBaseCtrl.text.trim()) ?? 2000000,
        'forceWinnerIndex': _forceWinnerIndex,
        'items': itemsList,
        'regularChips': regChips,
        'advancedChips': advChips,
        'gameBackgroundUrl': _bgImageUrlCtrl.text.trim(),
        'diamondIcon': _diamondIconUrlCtrl.text.trim(),
        'currencyRatio': '1:1',
        'hostedUrl': _hostedUrl,
        'localUrl': _localUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('config')
          .doc('html5_greedy_cat')
          .set(payload, SetOptions(merge: true));

      if (_diamondIconUrlCtrl.text.trim().isNotEmpty) {
        await _firestore
            .collection('global_settings')
            .doc('app_theme')
            .set({
              'diamondIconUrl': _diamondIconUrlCtrl.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  '✅ Greedy Cat সেটিংস, RTP, আইটেম ও ডায়মন্ড আইকন সফলভাবে সেভ হয়েছে!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving config: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _syncToMobileAppGameWall() async {
    setState(() => _isSyncingToWall = true);
    try {
      const thumbnailUrl =
          'https://cdn-icons-png.flaticon.com/512/616/616430.png';

      final gameData = {
        'id': 'html5_greedy_cat',
        'gameCode': 'html5_greedy_cat',
        'gameId': 'html5_greedy_cat',
        'name': 'Greedy Cat',
        'title': 'Greedy Cat',
        'description':
            'Cute Cat Ferris Wheel Spin Game with 8 BBQ Delicacies, Pizza Grand Special & Salad Prize',
        'thumbnailUrl': thumbnailUrl,
        'icon': thumbnailUrl,
        'image': thumbnailUrl,
        'picture': thumbnailUrl,
        'gameUrl': _hostedUrl,
        'url': _hostedUrl,
        'link': _hostedUrl,
        'webViewUrl': _hostedUrl,
        'type': 'html5',
        'gameType': 'html5',
        'isEnabled': _isActive,
        'isActive': _isActive,
        'status': _isActive ? 'active' : 'inactive',
        'isHtml5': true,
        'isWebView': true,
        'winRatio': _targetRtp / 100,
        'currency': 'diamonds',
        'conversionRate': 1.0,
        'order': 4,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('games')
          .doc('html5_greedy_cat')
          .set(gameData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.pets, color: Colors.pinkAccent),
                SizedBox(width: 10),
                Text(
                  '🐱 Greedy Cat সফলভাবে মোবাইল অ্যাপের Game Wall-এ অ্যাড ও সিঙ্ক করা হয়েছে!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.purple,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing to Game Wall: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingToWall = false);
    }
  }

  Future<void> _rechargeTestUserDiamonds(int amount) async {
    final uid = _testUserIdCtrl.text.trim();
    if (uid.isEmpty) return;

    try {
      await _firestore.collection('Users').doc(uid).set({
        'userId': uid,
        'name': _testUserNameCtrl.text.trim(),
        'diamonds': FieldValue.increment(amount),
        'coins': FieldValue.increment(amount),
        'totalDiamonds': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final cur = int.tryParse(_testDiamondsCtrl.text.trim()) ?? 0;
      _testDiamondsCtrl.text = (cur + amount).toString();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '💎 +$amount Diamonds সফলভাবে $uid একাউন্টে রিচার্জ হয়েছে!',
            ),
            backgroundColor: Colors.teal,
          ),
        );
        setState(() => _iframeKey++);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recharge error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCodeFile(String fileName) async {
    setState(() => _isLoadingCode = true);
    try {
      final doc = await _firestore
          .collection('config')
          .doc('html5_greedy_cat_code_${fileName.replaceAll('.', '_')}')
          .get();

      if (doc.exists && doc.data()?['content'] != null) {
        final code = doc.data()!['content'] as String;
        _fileCodeCache[fileName] = code;
        _codeEditorCtrl.text = code;
      } else {
        final res = await http.get(Uri.parse('$_hostedUrl/$fileName'));
        if (res.statusCode == 200) {
          _fileCodeCache[fileName] = res.body;
          _codeEditorCtrl.text = res.body;
        } else {
          _codeEditorCtrl.text =
              '// Local file public_games/greedy_cat/$fileName loaded';
        }
      }
    } catch (_) {
      _codeEditorCtrl.text =
          '// File public_games/greedy_cat/$fileName is active.';
    } finally {
      if (mounted) setState(() => _isLoadingCode = false);
    }
  }

  Future<void> _saveCodeFile() async {
    setState(() => _isSavingCode = true);
    try {
      final code = _codeEditorCtrl.text;
      _fileCodeCache[_selectedFile] = code;

      await _firestore
          .collection('config')
          .doc('html5_greedy_cat_code_${_selectedFile.replaceAll('.', '_')}')
          .set({
            'fileName': _selectedFile,
            'content': code,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $_selectedFile সেভ হয়েছে!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      );
    }

    return Column(
      children: [
        _buildTopHeaderBar(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLivePreviewTab(),
              _buildRtpAndPaytableTab(),
              _buildCodeEditorTab(),
              _buildWalletAndWinsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          if (widget.onBackToCatalog != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              tooltip: 'Back to Games',
              onPressed: widget.onBackToCatalog,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.pets, color: Colors.pinkAccent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Greedy Cat (কিউট গ্রিডি ক্যাট গেম)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: Colors.greenAccent,
                            size: 8,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'LIVE HOSTED',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pinkAccent),
                      ),
                      child: const Text(
                        'greedy-cat',
                        style: TextStyle(
                          color: Colors.pinkAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Cute Cat Ferris Wheel • 8 BBQ Delicacies • 1:1 Diamond Wallet Sync • Real-Time Firestore',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveConfig,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.black, size: 18),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Config (সেভ সেটিংস)',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _isSyncingToWall ? null : _syncToMobileAppGameWall,
            icon: _isSyncingToWall
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.app_shortcut, color: Colors.white, size: 18),
            label: Text(
              _isSyncingToWall
                  ? 'Syncing...'
                  : '🚀 Publish to App Game Wall (এপে সিঙ্ক)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _hostedUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied Game URL: $_hostedUrl'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
            icon: const Icon(Icons.copy, color: Colors.cyanAccent, size: 18),
            label: const Text(
              'Copy URL',
              style: TextStyle(color: Colors.cyanAccent),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF1E293B),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.pinkAccent,
        labelColor: Colors.pinkAccent,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(
            icon: Icon(Icons.phone_android),
            text: '🎮 Live Preview & User Test (লাইভ গেম)',
          ),
          Tab(
            icon: Icon(Icons.tune),
            text: '⚙️ RTP, Paytable & Pool Rules (প্রফিট ও রুলস)',
          ),
          Tab(
            icon: Icon(Icons.code),
            text: '💻 In-Window Code Editor (গেম এডিটর)',
          ),
          Tab(
            icon: Icon(Icons.account_balance_wallet),
            text: '💎 Real-Time Wallet & Wins (ডায়মন্ড হিস্ট্রি)',
          ),
        ],
      ),
    );
  }

  // --- TAB 1: LIVE INTERACTIVE PREVIEW & TEST PLAY ---
  Widget _buildLivePreviewTab() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Phone View Mockup
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                width: 440,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: const Color(0xFF334155), width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Phone Top Speaker / Camera Notch
                    Container(
                      height: 28,
                      color: Colors.black,
                      child: Center(
                        child: Container(
                          width: 90,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    // WebView
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                        child: buildWebIframe(
                          viewId: 'greedy_cat_live_frame_$_iframeKey',
                          url: _currentPreviewUrl,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Right: Testing & Simulator Controls
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    '⚡ Live Simulation & Test Controls',
                    Icons.science,
                    Colors.amber,
                  ),
                  const SizedBox(height: 12),
                  // Environment Switch
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PREVIEW SOURCE ENVIRONMENT',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                value: false,
                                groupValue: _useLocalDevUrl,
                                activeColor: Colors.pinkAccent,
                                title: const Text(
                                  'Cloud Hosted',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  _hostedUrl,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    _useLocalDevUrl = v!;
                                    _iframeKey++;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                value: true,
                                groupValue: _useLocalDevUrl,
                                activeColor: Colors.pinkAccent,
                                title: const Text(
                                  'Local Dev Server',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  _localUrl,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    _useLocalDevUrl = v!;
                                    _iframeKey++;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Test User Diamond Simulator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.account_circle,
                              color: Colors.pinkAccent,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'TEST USER IDENTITY & LIVE WALLET',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _testUserIdCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'User ID (UID)',
                            labelStyle: const TextStyle(color: Colors.white60),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _testUserNameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Display Name',
                            labelStyle: const TextStyle(color: Colors.white60),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _testDiamondsCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.amber),
                          decoration: InputDecoration(
                            labelText: 'Initial Diamonds Balance',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(
                              Icons.diamond,
                              color: Colors.amber,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Quick Instant Recharge to User ID:',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildRechargeChip(10000, '+10K 💎'),
                            _buildRechargeChip(50000, '+50K 💎'),
                            _buildRechargeChip(200000, '+200K 💎'),
                            _buildRechargeChip(1000000, '+1M 💎'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _iframeKey++),
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text(
                              'Reload Game in Phone (রিলোড গেম)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeChip(int amount, String label) {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 14, color: Colors.tealAccent),
      label: Text(label, style: const TextStyle(color: Colors.tealAccent)),
      backgroundColor: Colors.teal.withValues(alpha: 0.15),
      side: const BorderSide(color: Colors.tealAccent),
      onPressed: () => _rechargeTestUserDiamonds(amount),
    );
  }

  // --- TAB 2: RTP, PAYTABLE & RULES ---
  Widget _buildRtpAndPaytableTab() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: RTP Controls
            _buildSectionHeader(
              '🎰 House Edge, RTP & Profit Calibration',
              Icons.trending_up,
              Colors.greenAccent,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Player RTP: ${_targetRtp.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Average percentage of total bets returned to players',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            Slider(
                              value: _targetRtp,
                              min: 50.0,
                              max: 95.0,
                              divisions: 45,
                              activeColor: Colors.pinkAccent,
                              onChanged: (val) {
                                setState(() {
                                  _targetRtp = val;
                                  _houseMargin = 100.0 - val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'GUARANTEED PROFIT',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_houseMargin.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'App Owner Cut',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 28),
                  // Force Winner Control
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Force Round Winner Override (লাইভ নিয়ন্ত্রণ):',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Select a specific slot to win next round, or leave Random RTP',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          value: _forceWinnerIndex,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: -1,
                              child: Text('🎲 Random RTP Engine (স্বাভাবিক মোড)'),
                            ),
                            ...List.generate(8, (i) {
                              return DropdownMenuItem(
                                value: i,
                                child: Text(
                                  'Slot $i: ${_itemNames[i].text} (${_itemMultipliers[i].text}x)',
                                ),
                              );
                            }),
                            const DropdownMenuItem(
                              value: 8,
                              child: Text('🥗 Salad Prize (All 4 Veg Win 5x)'),
                            ),
                            const DropdownMenuItem(
                              value: 9,
                              child: Text('🍕 Pizza Prize (All 4 Meats Win)'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _forceWinnerIndex = v ?? -1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Row 2: 8 Food Items Paytable
            _buildSectionHeader(
              '🍗 8 BBQ Delicacies Paytable (৮টি খাবার ও গুণিতক)',
              Icons.fastfood,
              Colors.orangeAccent,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (ctx, i) {
                  final isMeat = i % 2 == 0;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMeat
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMeat
                            ? Colors.orangeAccent.withValues(alpha: 0.4)
                            : Colors.greenAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Slot $i (${isMeat ? "Meat" : "Veg"})',
                              style: TextStyle(
                                color: isMeat
                                    ? Colors.orangeAccent
                                    : Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _itemNames[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'Name',
                                    labelStyle: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _itemMultipliers[i],
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'Mult',
                                    suffixText: 'x',
                                    labelStyle: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Row 3: Chips Setup
            _buildSectionHeader(
              '🪙 Regular Gummy Chips Setup (চিপস ভ্যালু)',
              Icons.monetization_on,
              Colors.pinkAccent,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: List.generate(5, (i) {
                  final labels = [
                    'Blue Cat',
                    'Green Cat',
                    'Orange Cat',
                    'Purple Cat',
                    'Red Cat',
                  ];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: TextField(
                        controller: _regularChipCtrls[i],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: labels[i],
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            // Row 4: UI & Themes (Wallpaper & Diamond Icon)
            _buildSectionHeader(
              '🎨 UI Background & Diamond Icon URLs',
              Icons.image,
              Colors.cyanAccent,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _bgImageUrlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Custom Game Background Wallpaper Image URL',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.wallpaper, color: Colors.cyanAccent),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _diamondIconUrlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'App Diamond Icon URL (Real-time sync to game & theme)',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.diamond, color: Colors.cyanAccent),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: IN-WINDOW CODE EDITOR ---
  Widget _buildCodeEditorTab() {
    return Container(
      color: const Color(0xFF0B1120),
      child: Column(
        children: [
          // Editor Sub-header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                const Icon(Icons.code, color: Colors.pinkAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Code Editor: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                ...['game.js', 'index.html', 'style.css'].map((f) {
                  final isSel = _selectedFile == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSel,
                      selectedColor: Colors.pinkAccent,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: const Color(0xFF0F172A),
                      onSelected: (sel) {
                        if (sel) {
                          setState(() => _selectedFile = f);
                          _loadCodeFile(f);
                        }
                      },
                    ),
                  );
                }),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isSavingCode ? null : _saveCodeFile,
                  icon: _isSavingCode
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.black, size: 16),
                  label: const Text(
                    'Save Code',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingCode
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  )
                : TextField(
                    controller: _codeEditorCtrl,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Color(0xFF090D16),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: REAL-TIME WALLET & WINS STREAM ---
  Widget _buildWalletAndWinsTab() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '💎 Live Bets & Real-Time Diamond Transactions',
            Icons.receipt_long,
            Colors.tealAccent,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('game_bets')
                  .where('gameId', isEqualTo: 'html5_greedy_cat')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No live bets recorded yet today.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Color(0xFF334155), height: 1),
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final user = data['userName'] ?? data['userId'] ?? 'User';
                    final food = data['foodId'] ?? 'item';
                    final amount = data['betAmount'] ?? 0;
                    final time = data['createdAt'] != null
                        ? (data['createdAt'] as Timestamp).toDate().toString()
                        : 'Just now';

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.pinkAccent,
                        child: Icon(Icons.pets, color: Colors.black, size: 18),
                      ),
                      title: Text(
                        '$user bet on $food',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Text(
                        '-$amount 💎',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
