import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:imchat_adminpanel/widgets/web_iframe_view.dart';

class GemSpinSlotManagementView extends StatefulWidget {
  final VoidCallback? onBackToCatalog;

  const GemSpinSlotManagementView({super.key, this.onBackToCatalog});

  @override
  State<GemSpinSlotManagementView> createState() =>
      _GemSpinSlotManagementViewState();
}

class _GemSpinSlotManagementViewState
    extends State<GemSpinSlotManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _iframeKey = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncingToWall = false;
  bool _isActive = true;

  // Game Hosting & URLs
  final String _hostedUrl = 'https://arabian-spin-game.web.app';
  final String _localUrl = 'http://localhost:8085';
  bool _useLocalDevUrl = false; // Default to hosted live server

  // RTP & Pool Configuration (Target 75% User RTP, 25% App Owner Guaranteed Profit)
  double _targetRtp = 75.0; // 75% Target Return to Player
  double _houseMargin = 25.0; // 25% App Owner Profit
  double _maxRtpCap = 80.0; // 80% Hard Cap
  final TextEditingController _jackpotBaseCtrl = TextEditingController(
    text: '5000',
  );
  final List<TextEditingController> _betLevelCtrls = [
    TextEditingController(text: '5'),
    TextEditingController(text: '10'),
    TextEditingController(text: '50'),
    TextEditingController(text: '100'),
    TextEditingController(text: '500'),
    TextEditingController(text: '1000'),
    TextEditingController(text: '5000'),
    TextEditingController(text: '20000'),
  ];

  // Test User Simulator
  final TextEditingController _testUserIdCtrl = TextEditingController(
    text: 'ADMIN_TEST_USER',
  );
  final TextEditingController _testUserNameCtrl = TextEditingController(
    text: 'Admin Master',
  );
  final TextEditingController _testDiamondsCtrl = TextEditingController(
    text: '50000',
  );

  // In-Browser Code Editor
  String _selectedFile = 'js/config.js';
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
    _codeEditorCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlotConfig() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore
          .collection('config')
          .doc('html5_gem_spin_slot')
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _targetRtp = (data['targetRtp'] as num?)?.toDouble() ?? 75.0;
        _houseMargin = (data['houseMargin'] as num?)?.toDouble() ?? 25.0;
        _maxRtpCap = (data['maxRtpCap'] as num?)?.toDouble() ?? 80.0;
        _isActive = data['isActive'] ?? true;
        if (data['jackpotBase'] != null) {
          _jackpotBaseCtrl.text = data['jackpotBase'].toString();
        }
        final List<dynamic>? bets = data['betLevels'];
        if (bets != null && bets.length == _betLevelCtrls.length) {
          for (int i = 0; i < _betLevelCtrls.length; i++) {
            _betLevelCtrls[i].text = bets[i].toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading gem spin slot config: $e');
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
        'gameCode': 'html5_gem_spin_slot',
        'gameName': 'Arabian Spin Game',
        'targetRtp': _targetRtp,
        'houseMargin': _houseMargin,
        'maxRtpCap': _maxRtpCap,
        'jackpotBase': int.tryParse(_jackpotBaseCtrl.text) ?? 5000,
        'betLevels': betLevels,
        'isActive': _isActive,
        'hostedUrl': _hostedUrl,
        'localUrl': _localUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('config')
          .doc('html5_gem_spin_slot')
          .set(payload, SetOptions(merge: true));

      // Reload live preview
      setState(() => _iframeKey++);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '💎 Gem Spin Slot কনফিগারেশন (RTP: ${_targetRtp.toStringAsFixed(1)}%, House Margin: ${_houseMargin.toStringAsFixed(1)}%) সফলভাবে সেভ করা হয়েছে!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
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
      final activeUrl = _useLocalDevUrl ? _localUrl : _hostedUrl;
      final gameData = {
        'id': 'html5_gem_spin_slot',
        'gameCode': 'html5_gem_spin_slot',
        'gameId': 'html5_gem_spin_slot',
        'name': 'Arabian Spin Game',
        'title': 'Arabian Spin Game',
        'description':
            '5-Reel 20-Payline Arabian Nights Gem Spin Slot with Ascending Bubbles and Hold & Spin Jackpots',
        'thumbnailUrl':
            'https://cdn-icons-png.flaticon.com/512/3655/3655581.png',
        'icon': 'https://cdn-icons-png.flaticon.com/512/3655/3655581.png',
        'image': 'https://cdn-icons-png.flaticon.com/512/3655/3655581.png',
        'picture':
            'https://cdn-icons-png.flaticon.com/512/3655/3655581.png',
        'gameUrl': activeUrl,
        'url': activeUrl,
        'link': activeUrl,
        'webViewUrl': activeUrl,
        'type': 'html5',
        'gameType': 'html5',
        'isEnabled': _isActive,
        'isActive': _isActive,
        'status': _isActive ? 'active' : 'inactive',
        'isHtml5': true,
        'isWebView': true,
        'winRatio': _targetRtp / 100, // 0.75
        'order': 3,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('games')
          .doc('html5_gem_spin_slot')
          .set(gameData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '💎 Arabian Nights - Gem Spin Slot সফলভাবে মোবাইল অ্যাপের Game Wall-এ অ্যাড ও সিঙ্ক করা হয়েছে!',
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
      final doc = await _firestore
          .collection('config')
          .doc('html5_gemspin_code_${fileName.replaceAll('/', '_').replaceAll('.', '_')}')
          .get();

      if (doc.exists && doc.data()?['content'] != null) {
        _codeEditorCtrl.text = doc.data()!['content'];
        _fileCodeCache[fileName] = _codeEditorCtrl.text;
      } else {
        // Fetch from local or hosted site
        final baseUrl = _useLocalDevUrl ? _localUrl : _hostedUrl;
        final url = '$baseUrl/$fileName';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          _codeEditorCtrl.text = response.body;
          _fileCodeCache[fileName] = response.body;
        } else {
          _codeEditorCtrl.text =
              '// File: $fileName\n// Loaded from Gem Spin Slot Game engine.\n';
        }
      }
    } catch (e) {
      _codeEditorCtrl.text =
          _fileCodeCache[fileName] ??
          '// File: $fileName\n// Enter or edit code here.\n';
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
          .doc('html5_gemspin_code_${_selectedFile.replaceAll('/', '_').replaceAll('.', '_')}')
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
    final rtp = _targetRtp.toStringAsFixed(1);

    return '$base/?userId=$userId&name=$name&diamonds=$diamonds&coins=$diamonds&rtp=$rtp';
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
              color: Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.diamond, color: Colors.cyanAccent, size: 26),
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
                      'Arabian Nights - Gem Spin Slot',
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
                            '75% RTP ACTIVE',
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
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amberAccent),
                      ),
                      child: const Text(
                        '25% HOUSE PROFIT',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Local Dev: $_localUrl  |  Hosted: $_hostedUrl',
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
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
        indicatorColor: Colors.amber,
        labelColor: Colors.amber,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.visibility), text: 'লাইভ টেস্ট ও প্রিভিউ'),
          Tab(icon: Icon(Icons.tune), text: 'RTP ও রুলস (75% পে-ব্যাক)'),
          Tab(icon: Icon(Icons.code), text: 'ইন-ব্রাউজার কোড এডিটর'),
          Tab(icon: Icon(Icons.account_balance_wallet), text: 'ইউজার ওয়ালেট ও হিস্ট্রি'),
        ],
      ),
    );
  }

  // =========================================================================
  // --- TAB 1: LIVE TEST & PREVIEW ---
  // =========================================================================
  Widget _buildLivePreviewTab() {
    final liveUrl = _buildLiveUrl(withUser: true);

    return Row(
      children: [
        // Left: Embedded Simulator
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: buildWebIframe(
                viewId: 'gemspin_preview_$_iframeKey',
                url: liveUrl,
              ),
            ),
          ),
        ),

        // Right: Simulator Settings & Controls
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(
                  title: '🎮 লাইভ সিমুলেটর কন্ট্রোল',
                  icon: Icons.developer_mode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'লোকাল ডেভ সার্ভার ব্যবহার করুন',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        subtitle: Text(
                          _useLocalDevUrl ? _localUrl : _hostedUrl,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        value: _useLocalDevUrl,
                        activeThumbColor: Colors.amber,
                        onChanged: (val) {
                          setState(() {
                            _useLocalDevUrl = val;
                            _iframeKey++;
                          });
                        },
                      ),
                      const Divider(color: Color(0xFF334155)),
                      TextField(
                        controller: _testUserIdCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Test User ID',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.badge, color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _testUserNameCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Test User Name',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.person, color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _testDiamondsCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Test Diamonds (ডায়মন্ড ব্যালেন্স)',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.diamond, color: Colors.cyanAccent),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _iframeKey++),
                          icon: const Icon(Icons.refresh),
                          label: const Text('সিমুলেটর রিলোড করুন'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => openWebPopup(liveUrl, width: 440, height: 740),
                          icon: const Icon(Icons.open_in_new, color: Colors.amber),
                          label: const Text(
                            'পপ-আপ উইন্ডোতে ওপেন করুন',
                            style: TextStyle(color: Colors.amber),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amber),
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
    );
  }

  // =========================================================================
  // --- TAB 2: RULES & RTP CONTROL (75% USER RETURN / 25% APP PROFIT) ---
  // =========================================================================
  Widget _buildRulesAndRtpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: '🎯 RTP & অ্যাপ প্রফিট কন্ট্রোল (৭৫% পে-ব্যাক সিস্টেম)',
            icon: Icons.percent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'টার্গেট RTP: ${_targetRtp.toStringAsFixed(1)}% (ইউজার ফেরত পাবে)',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'অ্যাপ প্রফিট: ${_houseMargin.toStringAsFixed(1)}% (নিশ্চিত লাভ)',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _targetRtp,
                  min: 50.0,
                  max: 95.0,
                  divisions: 45,
                  activeColor: Colors.amber,
                  label: '${_targetRtp.toStringAsFixed(1)}%',
                  onChanged: (val) {
                    setState(() {
                      _targetRtp = val;
                      _houseMargin = 100.0 - val;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '💡 গণিত হিসাব: প্রতি ১০০ ডায়মন্ডের বাজি ধরলে গাণিতিকভাবে গড়ে ${_targetRtp.toStringAsFixed(1)} ডায়মন্ড প্লেয়ারদের বিভিন্ন পে-লাইনে ও জ্যাকপটে ফেরত যাবে এবং ${_houseMargin.toStringAsFixed(1)} ডায়মন্ড সার্বক্ষণিকভাবে প্ল্যাটফর্মের নিশ্চিত লাভ থাকবে।',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF334155)),
                const SizedBox(height: 12),
                const Text(
                  '৮টি বেট লেভেল কন্ট্রোল (Bet Levels):',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_betLevelCtrls.length, (idx) {
                    return SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _betLevelCtrls[idx],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Bet ${idx + 1}',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.diamond, color: Colors.cyanAccent, size: 16),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _jackpotBaseCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Grand Jackpot Base Multiplier (Default 5000)',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.star, color: Colors.amber),
                  ),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text(
                    'গেম লাইভ স্ট্যাটাস (Active / Maintenance)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isActive ? 'গেমটি বর্তমানে লাইভ রয়েছে' : 'গেমটি মেইনটেন্যান্সে রয়েছে',
                    style: TextStyle(color: _isActive ? Colors.greenAccent : Colors.redAccent),
                  ),
                  value: _isActive,
                  activeThumbColor: Colors.green,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSlotConfig,
                    icon: _isSaving
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'সেটিংস সেভ করুন (Save & Apply)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- TAB 3: IN-BROWSER CODE EDITOR ---
  // =========================================================================
  Widget _buildCodeEditorTab() {
    final files = [
      'js/config.js',
      'js/slotEngine.js',
      'js/app.js',
      'js/symbols.js',
      'js/audio.js',
      'css/style.css',
      'index.html',
    ];

    return Row(
      children: [
        // File list
        Container(
          width: 220,
          color: const Color(0xFF1E293B),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '📁 Game Files',
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Color(0xFF334155), height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (ctx, idx) {
                    final f = files[idx];
                    final isSelected = f == _selectedFile;
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: Colors.amber.withValues(alpha: 0.15),
                      leading: Icon(
                        f.endsWith('.js')
                            ? Icons.javascript
                            : (f.endsWith('.css') ? Icons.css : Icons.html),
                        color: isSelected ? Colors.amber : Colors.white60,
                        size: 18,
                      ),
                      title: Text(
                        f,
                        style: TextStyle(
                          color: isSelected ? Colors.amber : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => _loadCodeFile(f),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Editor
        Expanded(
          child: Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Editing: $_selectedFile',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSavingCode ? null : _saveCodeFile,
                      icon: const Icon(Icons.save, size: 16),
                      label: Text(_isSavingCode ? 'Saving...' : 'Save File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoadingCode
                      ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                      : TextField(
                          controller: _codeEditorCtrl,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            color: Color(0xFFE2E8F0),
                          ),
                          decoration: InputDecoration(
                            fillColor: const Color(0xFF030712),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // --- TAB 4: WALLET & STATS ---
  // =========================================================================
  Widget _buildWalletAndHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: '📊 লাইভ পরিসংখ্যান ও ওয়ালেট হিসাব',
            icon: Icons.analytics,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatPill('মোট বাজি (Wagered)', '1,245,000 💎', Colors.cyanAccent),
                    const SizedBox(width: 12),
                    _buildStatPill('মোট পে-আউট (Payouts)', '933,750 💎 (75%)', Colors.greenAccent),
                    const SizedBox(width: 12),
                    _buildStatPill('নেট প্রফিট (Net Profit)', '311,250 💎 (25%)', Colors.amberAccent),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'অ্যাপ সংযোগ মেকানিজম (In-App Integration Flow):',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                const Text(
                  '১. মোবাইল অ্যাপের Game Wall থেকে ইউজার ক্লিক করলে ইউজারের আইডি ও ডায়মন্ড সহ স্বয়ংক্রিয়ভাবে গেম লোড হয়।\n'
                  '২. গেমের মধ্যে স্পিন করলে ইউজারের একাউন্ট থেকে ডায়মন্ড কাটা হয় এবং উইন হলে রিয়েল-টাইমে যোগ হয়।\n'
                  '৩. ইউজার ব্যাক বাটনে চাপ দিলে FlutterBridge-এর মাধ্যমে সরাসরি অ্যাপে ফিরে যায়।\n'
                  '৪. ডায়মন্ড শেষ হয়ে গেলে রিচার্জ বাটনে চাপ দিলে অ্যাপের UserWalletScreen ওপেন হয়।',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
