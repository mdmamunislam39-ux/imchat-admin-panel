import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:imchat_adminpanel/widgets/web_iframe_view.dart';

class GreedyDeliciousManagementView extends StatefulWidget {
  final VoidCallback? onBackToCatalog;

  const GreedyDeliciousManagementView({super.key, this.onBackToCatalog});

  @override
  State<GreedyDeliciousManagementView> createState() =>
      _GreedyDeliciousManagementViewState();
}

class _GreedyDeliciousManagementViewState
    extends State<GreedyDeliciousManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _iframeKey = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncingToWall = false;
  bool _isActive = true;

  // Game Hosting & URLs
  final String _hostedUrl = 'https://greedy-delicious-game.web.app';
  final String _localUrl = 'http://localhost:8085';
  bool _useLocalDevUrl = false;

  // RTP & Mechanics Configuration
  double _targetRtp = 75.0; // 75% Target Return to Player
  double _houseMargin = 25.0; // 25% App Owner Guaranteed Profit
  double _maxRtpCap = 85.0; // 85% Hard Cap
  final TextEditingController _jackpotBaseCtrl = TextEditingController(
    text: '2500000',
  );
  int _forceWinnerIndex = -1; // -1: Random PRNG, 0..7: Items, 8: Salad, 9: Pizza

  // 8 Food Items Controllers
  final List<TextEditingController> _itemNames = [
    TextEditingController(text: 'Hot Dog'),
    TextEditingController(text: 'BBQ Skewer'),
    TextEditingController(text: 'Ham Leg'),
    TextEditingController(text: 'Steak'),
    TextEditingController(text: 'Carrot'),
    TextEditingController(text: 'Corn'),
    TextEditingController(text: 'Cabbage'),
    TextEditingController(text: 'Tomato'),
  ];
  final List<TextEditingController> _itemMultipliers = [
    TextEditingController(text: '10'),
    TextEditingController(text: '15'),
    TextEditingController(text: '25'),
    TextEditingController(text: '45'),
    TextEditingController(text: '5'),
    TextEditingController(text: '5'),
    TextEditingController(text: '5'),
    TextEditingController(text: '5'),
  ];

  // Chips Configuration Controllers (Regular & Advanced)
  final List<TextEditingController> _regularChipCtrls = [
    TextEditingController(text: '100'),
    TextEditingController(text: '1000'),
    TextEditingController(text: '10000'),
    TextEditingController(text: '50000'),
  ];
  final List<TextEditingController> _advancedChipCtrls = [
    TextEditingController(text: '1000'),
    TextEditingController(text: '10000'),
    TextEditingController(text: '50000'),
    TextEditingController(text: '100000'),
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
    text: 'Admin Master',
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

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore
          .collection('config')
          .doc('html5_greedy_delicious')
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
        if (regChips != null && regChips.length == 4) {
          for (int i = 0; i < 4; i++) {
            _regularChipCtrls[i].text = regChips[i].toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading greedy delicious config: $e');
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
          'category': i < 4 ? 'meat' : 'vegetable',
        });
      }

      final regChips =
          _regularChipCtrls.map((c) => int.tryParse(c.text.trim()) ?? 100).toList();
      final advChips =
          _advancedChipCtrls.map((c) => int.tryParse(c.text.trim()) ?? 1000).toList();

      final payload = {
        'gameCode': 'html5_greedy_delicious',
        'gameName': 'Greedy Delicious',
        'isActive': _isActive,
        'winRatio': _targetRtp,
        'houseMargin': _houseMargin,
        'maxRtpCap': _maxRtpCap,
        'jackpotBase': int.tryParse(_jackpotBaseCtrl.text.trim()) ?? 2500000,
        'forceWinnerIndex': _forceWinnerIndex,
        'items': itemsList,
        'regularChips': regChips,
        'advancedChips': advChips,
        'gameBackgroundUrl': _bgImageUrlCtrl.text.trim(),
        'diamondIcon': _diamondIconUrlCtrl.text.trim(),
        'currencyRatio': '1:1', // 1 Diamond = 1 Coin
        'hostedUrl': _hostedUrl,
        'localUrl': _localUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('config')
          .doc('html5_greedy_delicious')
          .set(payload, SetOptions(merge: true));

      // Also sync diamond icon to global theme if provided
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
                  '✅ Greedy Delicious সেটিংস, RTP, আইটেম ও ডায়মন্ড আইকন সফলভাবে সেভ হয়েছে!',
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
          'https://cdn-icons-png.flaticon.com/512/3081/3081840.png';

      final gameData = {
        'id': 'html5_greedy_delicious',
        'gameCode': 'html5_greedy_delicious',
        'gameId': 'html5_greedy_delicious',
        'name': 'Greedy Delicious',
        'title': 'Greedy Delicious',
        'description':
            'Hot Food Ferris Wheel Spin Game with 8 Delicious Foods, Pizza Mega Win & Salad Special',
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
        'order': 3,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('games')
          .doc('html5_greedy_delicious')
          .set(gameData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.flash_on, color: Colors.amber),
                SizedBox(width: 10),
                Text(
                  '🍖 Greedy Delicious সফলভাবে মোবাইল অ্যাপের Game Wall-এ অ্যাড ও সিঙ্ক করা হয়েছে!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green,
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

  Future<void> _loadCodeFile(String fileName) async {
    setState(() {
      _selectedFile = fileName;
      _isLoadingCode = true;
    });

    try {
      // 1. Try Firestore doc
      final doc = await _firestore
          .collection('config')
          .doc('html5_greedy_delicious_code_${fileName.replaceAll('.', '_')}')
          .get();

      if (doc.exists && doc.data()?['content'] != null) {
        _codeEditorCtrl.text = doc.data()!['content'];
        _fileCodeCache[fileName] = _codeEditorCtrl.text;
      } else {
        // 2. Fetch from hosted site
        final url = '$_hostedUrl/$fileName';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          _codeEditorCtrl.text = response.body;
          _fileCodeCache[fileName] = response.body;
        } else {
          _codeEditorCtrl.text =
              '// File: $fileName\n// Loaded from Greedy Delicious game engine.\n';
        }
      }
    } catch (e) {
      _codeEditorCtrl.text =
          _fileCodeCache[fileName] ??
          '// Error loading $fileName: $e\n// Enter your custom code and press Save.';
    } finally {
      if (mounted) setState(() => _isLoadingCode = false);
    }
  }

  Future<void> _saveCodeFile() async {
    setState(() => _isSavingCode = true);
    try {
      final content = _codeEditorCtrl.text;
      _fileCodeCache[_selectedFile] = content;

      await _firestore
          .collection('config')
          .doc('html5_greedy_delicious_code_${_selectedFile.replaceAll('.', '_')}')
          .set({
            'fileName': _selectedFile,
            'content': content,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '💾 $_selectedFile কোড সফলভাবে সেভ করা হয়েছে!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 3),
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

  String _buildLiveUrl({bool withUser = true}) {
    final base = _useLocalDevUrl ? _localUrl : _hostedUrl;
    if (!withUser) return base;

    final userId = Uri.encodeComponent(_testUserIdCtrl.text.trim());
    final name = Uri.encodeComponent(_testUserNameCtrl.text.trim());
    final diamonds = _testDiamondsCtrl.text.trim();

    return '$base/?userId=$userId&name=$name&diamonds=$diamonds&coins=$diamonds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          _buildHeaderBanner(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLivePreviewTab(),
                _buildRulesAndRtpTab(),
                _buildCodeEditorTab(),
                _buildWalletAndHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- 1. TOP HEADER BANNER ---
  // =========================================================================
  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          if (widget.onBackToCatalog != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.orangeAccent),
              tooltip: 'Back to Games Catalog',
              onPressed: widget.onBackToCatalog,
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(Icons.restaurant, color: Colors.orangeAccent, size: 26),
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
                      'Greedy Delicious (লুভনীয় ডেলিশিয়াস গেম)',
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
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orangeAccent),
                      ),
                      child: const Text(
                        'greedy-delicious',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'URL: $_hostedUrl  |  Local Dev: $_localUrl',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSyncingToWall ? null : _syncToMobileAppGameWall,
            icon: _isSyncingToWall
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.app_shortcut, color: Colors.black, size: 18),
            label: Text(
              _isSyncingToWall
                  ? 'Syncing...'
                  : '🚀 Publish to App Game Wall (এপে সিঙ্ক)',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
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

  // =========================================================================
  // --- 2. TAB BAR ---
  // =========================================================================
  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF1E293B),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.orangeAccent,
        labelColor: Colors.orangeAccent,
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

  // =========================================================================
  // --- TAB 1: LIVE INTERACTIVE PREVIEW & TEST PLAY ---
  // =========================================================================
  Widget _buildLivePreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Test User Simulation Controls
          SizedBox(
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(
                  '👤 Test User Simulation',
                  'Test user diamond detection and real-time bets deduction',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'User ID (Firestore Users/{userId})',
                  controller: _testUserIdCtrl,
                  icon: Icons.badge,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Player Display Name',
                  controller: _testUserNameCtrl,
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Starting Diamonds 💎',
                  controller: _testDiamondsCtrl,
                  icon: Icons.diamond,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // URL Source Switcher (Hosted vs Local)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌐 Preview Target Source:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<bool>(
                        value: false,
                        groupValue: _useLocalDevUrl,
                        onChanged: (val) =>
                            setState(() => _useLocalDevUrl = val ?? false),
                        title: const Text(
                          'Firebase Hosting (Live Production)',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        subtitle: Text(
                          _hostedUrl,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 11,
                          ),
                        ),
                        activeColor: Colors.orangeAccent,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        value: true,
                        groupValue: _useLocalDevUrl,
                        onChanged: (val) =>
                            setState(() => _useLocalDevUrl = val ?? true),
                        title: const Text(
                          'Local Dev Server (port 8085)',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        subtitle: Text(
                          _localUrl,
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 11,
                          ),
                        ),
                        activeColor: Colors.orangeAccent,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _iframeKey++),
                    icon: const Icon(Icons.refresh, color: Colors.black),
                    label: const Text(
                      'Apply & Reload Preview',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Direct URL Copy
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔗 Full App Launch URL with Query Params:',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _buildLiveUrl(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _buildLiveUrl()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied Full App Launch URL!'),
                                backgroundColor: Colors.teal,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy,
                            size: 14,
                            color: Colors.cyanAccent,
                          ),
                          label: const Text(
                            'Copy Link',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.cyanAccent,
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

          const SizedBox(width: 32),

          // Right: Real Interactive Phone Preview Frame
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Quick Launch Controls Bar above phone
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        openWebPopup(_buildLiveUrl(withUser: true), width: 440, height: 740);
                      },
                      icon: const Icon(Icons.open_in_new, color: Colors.black, size: 18),
                      label: const Text(
                        '📱 Open Perfect Mobile Pop-up (নিখুঁত মোবাইল সাইজ)',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
                      tooltip: 'Reload Phone Iframe',
                      onPressed: () {
                        setState(() => _iframeKey++);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Real Phone Mockup Frame running the Live Game Engine
                Container(
                  width: 440,
                  height: 720,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0C0B),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.orangeAccent, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: buildWebIframe(
                    viewId: 'greedy_delicious_live_frame_$_iframeKey',
                    url: _buildLiveUrl(withUser: true),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '💡 Real-time Interactive Greedy Delicious Engine running live with direct Users/{userId} diamond sync.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- TAB 2: RTP, RULES & SMART POOL CONFIGURATION ---
  // =========================================================================
  Widget _buildRulesAndRtpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardHeader(
                '⚙️ Smart Revenue & RTP Controller',
                'Set the player payout return, guaranteed profit percentage and food multipliers',
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
                  _isSaving ? 'Saving...' : 'Save & Sync Settings',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // RTP Sliders Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🎯 Target Return to Player (RTP %):',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.greenAccent),
                            ),
                            child: Text(
                              '${_targetRtp.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _targetRtp,
                        min: 50.0,
                        max: 85.0,
                        divisions: 35,
                        activeColor: Colors.greenAccent,
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          setState(() {
                            _targetRtp = val;
                            _houseMargin = 100.0 - val;
                          });
                        },
                      ),
                      const Text(
                        '💡 Recommended: 70% - 75% return. For every 1,000 diamonds bet, players receive approximately 700 - 750 diamonds back.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🛡️ App Owner Profit Margin (%):',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Text(
                              '${_houseMargin.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _houseMargin / 100.0,
                        backgroundColor: Colors.white12,
                        color: Colors.amber,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '💰 Guaranteed Profit Retention: The math engine dynamically guarantees this house margin across rounds.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Force Next Round Winner (Admin Controller)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sports_esports, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '🎯 Force Next Round Winner (এডমিন কন্ট্রোল)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'যেকোনো রাউন্ডের ফলাফল আপনি নিজে সিলেক্ট করতে পারেন। -1 থাকলে স্বয়ংক্রিয় PRNG অ্যালগরিদম অনুযায়ী চলবে।',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildForceWinnerChip(-1, '🎲 Random (Fair PRNG)'),
                    _buildForceWinnerChip(0, '🌭 Hot Dog (10x)'),
                    _buildForceWinnerChip(1, '🍢 BBQ Skewer (15x)'),
                    _buildForceWinnerChip(2, '🍖 Ham Leg (25x)'),
                    _buildForceWinnerChip(3, '🥩 Steak (45x)'),
                    _buildForceWinnerChip(4, '🥕 Carrot (5x)'),
                    _buildForceWinnerChip(5, '🌽 Corn (5x)'),
                    _buildForceWinnerChip(6, '🥬 Cabbage (5x)'),
                    _buildForceWinnerChip(7, '🍅 Tomato (5x)'),
                    _buildForceWinnerChip(8, '🥗 Salad Combo (All Veg)'),
                    _buildForceWinnerChip(9, '🍕 Pizza Combo (All Meat)'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 8 Food Items Multiplier Grid
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fastfood, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '🍔 8 Food Items & Multipliers Configuration',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'এখানে প্রতিটি খাবারের নাম ও গুণিতক (Multiplier) পরিবর্তন করতে পারেন। রিয়েল-টাইমে গেমে সিঙ্ক হবে।',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: 8,
                  itemBuilder: (ctx, i) {
                    final isMeat = i < 4;
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMeat
                              ? Colors.redAccent.withValues(alpha: 0.4)
                              : Colors.greenAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isMeat
                                ? Colors.redAccent.withValues(alpha: 0.2)
                                : Colors.greenAccent.withValues(alpha: 0.2),
                            radius: 16,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: isMeat ? Colors.redAccent : Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _itemNames[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'Multiplier: ',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: TextField(
                                        controller: _itemMultipliers[i],
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                          color: isMeat
                                              ? Colors.amberAccent
                                              : Colors.greenAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                          suffixText: 'x',
                                          suffixStyle: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Real-Time Diamond Icon Controller
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.diamond, color: Colors.cyanAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '💎 Real-Time App Diamond Icon (পিএনজি আইকন)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'গেমের ব্যালেন্স, চিপস ও উইনিং ডায়ালগে প্রদর্শিত ডায়মন্ডের আইকন লিংক। এটি সরাসরি গেমে লাইভ পরিবর্তিত হবে।',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.cyanAccent),
                      ),
                      child: Image.network(
                        _diamondIconUrlCtrl.text,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.diamond, color: Colors.cyanAccent),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Diamond PNG Icon URL',
                        controller: _diamondIconUrlCtrl,
                        icon: Icons.link,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDiamondPresetChip(
                      'Official 3D Diamond',
                      'https://cdn-icons-png.flaticon.com/512/9496/9496739.png',
                    ),
                    _buildDiamondPresetChip(
                      'Purple Royal Gem',
                      'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                    ),
                    _buildDiamondPresetChip(
                      'Sparkling Jewel',
                      'https://cdn-icons-png.flaticon.com/512/2618/2618245.png',
                    ),
                    _buildDiamondPresetChip(
                      'Golden Diamond',
                      'https://cdn-icons-png.flaticon.com/512/1828/1828884.png',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Dynamic Background Wallpaper Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wallpaper, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '🖼️ Game Background Wallpaper (ওয়ালপেপার সেটিংস)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'মোবাইলে এবং পপ-আপে গেমের পেছনে এই ব্যাকগ্রাউন্ড প্রদর্শিত হবে। রিয়েল-টাইমে গেমে সিঙ্ক হবে।',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orangeAccent, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(
                            _bgImageUrlCtrl.text.isEmpty
                                ? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=1920&auto=format&fit=crop'
                                : _bgImageUrlCtrl.text,
                          ),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Background Image URL',
                            controller: _bgImageUrlCtrl,
                            icon: Icons.link,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildBgPresetChip('🎪 Carnival Feast', 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=1920&auto=format&fit=crop'),
                              _buildBgPresetChip('🍕 Delicious Kitchen', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1920&auto=format&fit=crop'),
                              _buildBgPresetChip('🏮 Night Market', 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?q=80&w=1920&auto=format&fit=crop'),
                              _buildBgPresetChip('🌌 Golden Neon Party', 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=1920&auto=format&fit=crop'),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildForceWinnerChip(int index, String label) {
    final isSelected = _forceWinnerIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.orangeAccent,
      backgroundColor: const Color(0xFF0F172A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (val) {
        setState(() => _forceWinnerIndex = val ? index : -1);
      },
    );
  }

  Widget _buildDiamondPresetChip(String title, String url) {
    final isSelected = _diamondIconUrlCtrl.text == url;
    return ActionChip(
      avatar: const Icon(Icons.diamond, size: 14, color: Colors.cyanAccent),
      label: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected ? Colors.cyanAccent : const Color(0xFF334155),
      onPressed: () {
        setState(() => _diamondIconUrlCtrl.text = url);
      },
    );
  }

  Widget _buildBgPresetChip(String title, String url) {
    final isSelected = _bgImageUrlCtrl.text == url;
    return ActionChip(
      avatar: Icon(
        Icons.image,
        size: 14,
        color: isSelected ? Colors.black : Colors.orangeAccent,
      ),
      label: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected ? Colors.orangeAccent : const Color(0xFF334155),
      onPressed: () {
        setState(() => _bgImageUrlCtrl.text = url);
      },
    );
  }

  // =========================================================================
  // --- TAB 3: IN-WINDOW CODE EDITOR ---
  // =========================================================================
  Widget _buildCodeEditorTab() {
    final files = ['game.js', 'index.html', 'style.css'];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // File Picker & Action Bar
          Row(
            children: [
              const Text(
                'Select File to Edit:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 14),
              ...files.map((file) {
                final isSel = _selectedFile == file;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(file),
                    selected: isSel,
                    selectedColor: Colors.orangeAccent,
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.black : Colors.white,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => _loadCodeFile(file),
                  ),
                );
              }),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isSavingCode ? null : _saveCodeFile,
                icon: _isSavingCode
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
                  _isSavingCode ? 'Saving...' : '💾 Save & Apply Code',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Code Editor Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: _isLoadingCode
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orangeAccent),
                    )
                  : TextField(
                      controller: _codeEditorCtrl,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFF7EE787),
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- TAB 4: REAL-TIME WALLET & PROFIT HISTORY ---
  // =========================================================================
  Widget _buildWalletAndHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            '💎 Real-Time User Diamond Wallet Architecture',
            'How user detection and live diamond deduction/win credit work inside IMChat App',
          ),
          const SizedBox(height: 16),

          // Architecture Explainer Cards
          Row(
            children: [
              Expanded(
                child: _buildWalletStepCard(
                  '1. Live User Detection',
                  'When user opens the game from Game Wall or Voice Room, app passes ?userId={ID}&name={Name}&diamonds={Bal}. Game connects to Users/{userId}.',
                  Icons.person_search,
                  Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWalletStepCard(
                  '2. Atomic Bet Deduction',
                  'Before wheel spins, game verifies diamonds >= betAmount. Deducts with FieldValue.increment(-bet). Blocks bet if diamonds are insufficient.',
                  Icons.remove_circle,
                  Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWalletStepCard(
                  '3. Atomic Win Payout',
                  'When wheel stops on winning delicacy, payout is credited back with FieldValue.increment(earnings). Round record saved in real time.',
                  Icons.add_circle,
                  Colors.greenAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Test User Diamond Simulator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '⚡ Quick Test User Recharge Simulator',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'টেস্ট ইউজারের ব্যালেন্সে সরাসরি ফায়ারস্টোর থেকে ডায়মন্ড যোগ করুন:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildQuickAddDiamondsBtn(1000),
                    _buildQuickAddDiamondsBtn(5000),
                    _buildQuickAddDiamondsBtn(10000),
                    _buildQuickAddDiamondsBtn(50000),
                    _buildQuickAddDiamondsBtn(100000),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Live Stream of Bets from game_history
          const Text(
            '📊 Live Greedy Delicious Bets & Win History (Real-Time Firestore Stream)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('game_history')
                .where('gameName', isEqualTo: 'Greedy Delicious')
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Error loading history: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.history, color: Colors.white38, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'No rounds recorded yet. Rounds played by users in the app or preview will stream here in real time!',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Color(0xFF334155), height: 1),
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data() as Map<String, dynamic>;
                    final name = data['userName'] ?? 'Player';
                    final bet = data['betAmount'] ?? 0;
                    final win = data['winAmount'] ?? 0;
                    final isWin = win > 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isWin
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        child: Icon(
                          isWin ? Icons.emoji_events : Icons.restaurant,
                          color: isWin ? Colors.greenAccent : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Bet: $bet 💎 | Win: $win 💎',
                        style: TextStyle(
                          color: isWin ? Colors.greenAccent : Colors.white60,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isWin
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isWin ? Colors.green : Colors.grey,
                          ),
                        ),
                        child: Text(
                          isWin ? 'WIN +$win 💎' : 'SPIN',
                          style: TextStyle(
                            color: isWin ? Colors.greenAccent : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddDiamondsBtn(int amount) {
    return ElevatedButton.icon(
      onPressed: () async {
        final uid = _testUserIdCtrl.text.trim();
        if (uid.isEmpty) return;
        try {
          await _firestore.collection('Users').doc(uid).set({
            'diamonds': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          final current = int.tryParse(_testDiamondsCtrl.text.trim()) ?? 0;
          setState(() {
            _testDiamondsCtrl.text = (current + amount).toString();
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('+$amount 💎 added to user $uid'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding diamonds: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.add, size: 16, color: Colors.black),
      label: Text(
        '+${amount >= 1000 ? '${amount ~/ 1000}k' : amount} 💎',
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _buildWalletStepCard(
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.orangeAccent, size: 18)
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
