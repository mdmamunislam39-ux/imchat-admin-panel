import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:imchat_adminpanel/widgets/web_iframe_view.dart';

class KingQueenSlotManagementView extends StatefulWidget {
  final VoidCallback? onBackToCatalog;

  const KingQueenSlotManagementView({super.key, this.onBackToCatalog});

  @override
  State<KingQueenSlotManagementView> createState() =>
      _KingQueenSlotManagementViewState();
}

class _KingQueenSlotManagementViewState
    extends State<KingQueenSlotManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _iframeKey = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncingToWall = false;
  bool _isActive = true;

  // Game Hosting & URLs
  final String _hostedUrl = 'https://king-queen-slot-game.web.app';
  final String _localUrl = 'http://localhost:3001';
  bool _useLocalDevUrl = false;

  // RTP & Pool Configuration
  double _targetRtp = 72.0; // 72% Target Return to Player
  double _houseMargin = 28.0; // 28% App Owner Guaranteed Profit
  double _maxRtpCap = 80.0; // 80% Hard Cap
  final TextEditingController _jackpotBaseCtrl = TextEditingController(
    text: '52480',
  );
  final List<TextEditingController> _betLevelCtrls = [
    TextEditingController(text: '100'),
    TextEditingController(text: '1000'),
    TextEditingController(text: '5000'),
    TextEditingController(text: '10000'),
    TextEditingController(text: '50000'),
    TextEditingController(text: '100000'),
  ];

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

  // Background Wallpaper Controller
  final TextEditingController _bgImageUrlCtrl = TextEditingController(
    text: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=1920&auto=format&fit=crop',
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
    _loadSlotConfig();
    _loadCodeFile(_selectedFile);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jackpotBaseCtrl.dispose();
    for (var c in _betLevelCtrls) {
      c.dispose();
    }
    _testUserIdCtrl.dispose();
    _testUserNameCtrl.dispose();
    _testDiamondsCtrl.dispose();
    _bgImageUrlCtrl.dispose();
    _codeEditorCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlotConfig() async {
    setState(() => _isLoading = true);
    try {
      final doc =
          await _firestore.collection('config').doc('html5_slot_game').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _targetRtp = (data['targetRtp'] as num?)?.toDouble() ?? 72.0;
        _houseMargin = (data['houseMargin'] as num?)?.toDouble() ?? 28.0;
        _maxRtpCap = (data['maxRtpCap'] as num?)?.toDouble() ?? 80.0;
        _isActive = data['isActive'] ?? true;
        if (data['jackpotBase'] != null) {
          _jackpotBaseCtrl.text = data['jackpotBase'].toString();
        }
        if (data['backgroundImageUrl'] != null && data['backgroundImageUrl'].toString().isNotEmpty) {
          _bgImageUrlCtrl.text = data['backgroundImageUrl'].toString();
        }
        final List<dynamic>? bets = data['betLevels'];
        if (bets != null && bets.length == 6) {
          for (int i = 0; i < 6; i++) {
            _betLevelCtrls[i].text = bets[i].toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading slot config: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSlotConfig() async {
    setState(() => _isSaving = true);
    try {
      final betLevels =
          _betLevelCtrls.map((c) => int.tryParse(c.text) ?? 100).toList();

      final payload = {
        'gameCode': 'html5_king_queen_slot',
        'gameName': 'King Queen Slot Game',
        'targetRtp': _targetRtp,
        'houseMargin': _houseMargin,
        'maxRtpCap': _maxRtpCap,
        'jackpotBase': int.tryParse(_jackpotBaseCtrl.text) ?? 52480,
        'betLevels': betLevels,
        'backgroundImageUrl': _bgImageUrlCtrl.text.trim(),
        'isActive': _isActive,
        'hostedUrl': _hostedUrl,
        'localUrl': _localUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('config')
          .doc('html5_slot_game')
          .set(payload, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  '✅ কিং কুইন স্লট গেমের RTP, প্রফিট মার্জিন ও সেটিংস সফলভাবে সেভ হয়েছে!',
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
      final gameData = {
        'id': 'html5_king_queen_slot',
        'gameCode': 'html5_king_queen_slot',
        'gameId': 'html5_king_queen_slot',
        'name': 'King Queen Slot Game',
        'title': 'King Queen Slot Game',
        'description':
            'King of the Castle 5-Reel HTML5 Medieval Royal Slot Machine with 20 Paylines and Progressive Jackpot',
        'thumbnailUrl': 'https://cdn-icons-png.flaticon.com/512/263/263068.png',
        'icon': 'https://cdn-icons-png.flaticon.com/512/263/263068.png',
        'image': 'https://cdn-icons-png.flaticon.com/512/263/263068.png',
        'picture':
            'https://cdn-icons-png.flaticon.com/512/263/263068.png', // checked by game_wall_bottom_sheet
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
        'order': 2,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('games')
          .doc('html5_king_queen_slot')
          .set(gameData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '👑 King Queen Slot Game সফলভাবে মোবাইল অ্যাপের Game Wall-এ অ্যাড ও সিঙ্ক করা হয়েছে!',
              style: TextStyle(fontWeight: FontWeight.bold),
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
            content: Text('Error syncing to app: $e'),
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
      // 1. Try fetching from Firestore code doc
      final doc = await _firestore
          .collection('config')
          .doc('html5_slot_code_${fileName.replaceAll('.', '_')}')
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
              '// File: $fileName\n// Loaded from King Queen Slot Game engine.\n';
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

      // Save to Firestore config so web admin updates stay persisted
      await _firestore
          .collection('config')
          .doc('html5_slot_code_${_selectedFile.replaceAll('.', '_')}')
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

    final userId = _testUserIdCtrl.text.trim();
    final name = Uri.encodeComponent(_testUserNameCtrl.text.trim());
    final diamonds = _testDiamondsCtrl.text.trim();

    return '$base/?userId=$userId&name=$name&diamonds=$diamonds&coins=$diamonds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
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
              icon: const Icon(Icons.arrow_back, color: Colors.amber),
              tooltip: 'Back to Games Catalog',
              onPressed: widget.onBackToCatalog,
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.casino, color: Colors.amber, size: 26),
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
                      'King Queen Slot Game',
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
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purpleAccent),
                      ),
                      child: const Text(
                        'slot-game-tow',
                        style: TextStyle(
                          color: Colors.purpleAccent,
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
              backgroundColor: Colors.amber,
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
        indicatorColor: Colors.amber,
        labelColor: Colors.amber,
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
                  'Test user diamond detection and spin deductions',
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
                        activeColor: Colors.amber,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        value: true,
                        groupValue: _useLocalDevUrl,
                        onChanged: (val) =>
                            setState(() => _useLocalDevUrl = val ?? true),
                        title: const Text(
                          'Local Dev Server (port 3001)',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        subtitle: Text(
                          _localUrl,
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 11,
                          ),
                        ),
                        activeColor: Colors.amber,
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
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh, color: Colors.black),
                    label: const Text(
                      'Apply & Reload Preview',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
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
                        backgroundColor: Colors.amber,
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
                    border: Border.all(color: Colors.amber, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: buildWebIframe(
                    viewId: 'king_queen_slot_live_frame_$_iframeKey',
                    url: _buildLiveUrl(withUser: true),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '💡 Real-time Interactive Slot Engine running live with direct Users/{userId} diamond sync.',
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
                'Set the exact player payout return and app owner guaranteed profit percentage',
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSlotConfig,
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
                  backgroundColor: Colors.amber,
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
                        max: 80.0,
                        divisions: 30,
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
                        '💡 Recommended: 70% - 75% return. For every 1,000 diamonds bet, players receive approximately 700 - 750 diamonds back over time.',
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
                            '💰 App Owner Net Profit Margin (%):',
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
                      Slider(
                        value: _houseMargin,
                        min: 20.0,
                        max: 50.0,
                        divisions: 30,
                        activeColor: Colors.amber,
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          setState(() {
                            _houseMargin = val;
                            _targetRtp = 100.0 - val;
                          });
                        },
                      ),
                      const Text(
                        '💡 Guaranteed profit reserved directly for app owner. Never distributed to players.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bet Levels & Progressive Jackpot
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
                const Text(
                  '💎 6 Configurable Bet Levels & Progressive Jackpot Base',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        label: 'Progressive Jackpot Starting Base',
                        controller: _jackpotBaseCtrl,
                        icon: Icons.emoji_events,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: List.generate(6, (idx) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildTextField(
                                label: 'Level ${idx + 1}',
                                controller: _betLevelCtrls[idx],
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Fullscreen Game Background Wallpaper Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.wallpaper, color: Colors.amber, size: 22),
                        SizedBox(width: 8),
                        Text(
                          '🖼️ Fullscreen Game Background Wallpaper (গেমের পেছনের ব্যাকগ্রাউন্ড পিকচার)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveSlotConfig,
                      icon: const Icon(Icons.save, size: 16, color: Colors.black),
                      label: const Text(
                        'Save Wallpaper',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'মোবাইলে এবং পপ-আপে স্লট ক্যাবিনেটের পেছনে (উপরে ও নিচে) এই ছবি প্রদর্শিত হবে। রিয়েল-টাইমে গেমে সিঙ্ক হবে।',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallpaper Preview Thumbnail
                    Container(
                      width: 140,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(_bgImageUrlCtrl.text),
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
                            label: 'Background Picture URL',
                            controller: _bgImageUrlCtrl,
                            icon: Icons.link,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Click to Choose from Premium Medieval & Casino Presets:',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildBgPresetChip('🏰 Royal Castle Vault', 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=1920&auto=format&fit=crop'),
                              _buildBgPresetChip('👑 Medieval Kingdom', 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?q=80&w=1920&auto=format&fit=crop'),
                              _buildBgPresetChip('🎰 Golden Casino', 'https://images.unsplash.com/photo-1596838132731-3301c3fd4317?q=80&w=1920&auto=format&fit=crop'),
                              _buildBgPresetChip('🌌 Dark Fantasy Sky', 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?q=80&w=1920&auto=format&fit=crop'),
                              _buildBgPresetChip('💎 Velvet Palace', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1920&auto=format&fit=crop'),
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

          const SizedBox(height: 24),

          // Paytable Reference Summary Card
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
                const Text(
                  '📜 20 Paylines Payout Table Multipliers',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildPaytableCard(
                      'WILD',
                      '5x: 2500 | 4x: 500 | 3x: 50',
                      Colors.amber,
                    ),
                    _buildPaytableCard(
                      'THE KING',
                      '5x: 1000 | 4x: 300 | 3x: 80',
                      Colors.orange,
                    ),
                    _buildPaytableCard(
                      'THE QUEEN',
                      '5x: 600 | 4x: 200 | 3x: 50',
                      Colors.pinkAccent,
                    ),
                    _buildPaytableCard(
                      'KNIGHT',
                      '5x: 400 | 4x: 150 | 3x: 40',
                      Colors.blueAccent,
                    ),
                    _buildPaytableCard(
                      'CASTLE SCATTER',
                      '3+ Triggers 10 Free Spins (3x Win)',
                      Colors.redAccent,
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

  Widget _buildPaytableCard(String title, String desc, Color color) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- TAB 3: IN-WINDOW CODE EDITOR ---
  // =========================================================================
  Widget _buildCodeEditorTab() {
    final files = ['game.js', 'index.html', 'style.css', 'assets.js', 'audio.js'];

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
                    selectedColor: Colors.amber,
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
                  backgroundColor: Colors.amber,
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
                      child: CircularProgressIndicator(color: Colors.amber),
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
                  'When user opens the game from Game Wall or Room, app passes ?userId={ID}&name={Name}&diamonds={Bal}. Game immediately connects to Users/{userId}.',
                  Icons.person_search,
                  Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWalletStepCard(
                  '2. Atomic Spin Deduction',
                  'Before spinning, game verifies diamonds >= totalBet. Calls FieldValue.increment(-bet) in Firestore. Blocks spin if diamonds insufficient.',
                  Icons.remove_circle,
                  Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWalletStepCard(
                  '3. Atomic Win Payout',
                  'When user wins, payout is credited directly back with FieldValue.increment(winAmount). Win record saved to game_history in real time.',
                  Icons.add_circle,
                  Colors.greenAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Live Stream of Spins from game_history
          const Text(
            '📊 Live Slot Spins & Win History (Real-Time Firestore Stream)',
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
                .where('gameName', isEqualTo: 'King Queen Slot Game')
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
                        'No slot spins recorded yet. Spins by players in the app or preview will stream here in real time!',
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
                          isWin ? Icons.emoji_events : Icons.casino,
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

  Widget _buildBgPresetChip(String title, String url) {
    final isSelected = _bgImageUrlCtrl.text == url;
    return ActionChip(
      avatar: Icon(
        Icons.image,
        size: 14,
        color: isSelected ? Colors.black : Colors.amber,
      ),
      label: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : Colors.white,
        ),
      ),
      backgroundColor: isSelected ? Colors.amber : const Color(0xFF334155),
      side: BorderSide(
        color: isSelected ? Colors.amber : Colors.transparent,
      ),
      onPressed: () {
        setState(() {
          _bgImageUrlCtrl.text = url;
        });
      },
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
                  ? Icon(icon, color: Colors.amber, size: 18)
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
