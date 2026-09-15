import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imchat_adminpanel/widgets/web_iframe_view.dart';
import 'package:imchat_adminpanel/models/room_game_model.dart';
import 'package:imchat_adminpanel/services/room_game_service.dart';

class LudoGameManagementView extends StatefulWidget {
  final VoidCallback? onBackToCatalog;

  const LudoGameManagementView({super.key, this.onBackToCatalog});

  @override
  State<LudoGameManagementView> createState() => _LudoGameManagementViewState();
}

class _LudoGameManagementViewState extends State<LudoGameManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _iframeKey = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncingToRoom = false;
  bool _isActive = true;

  // URLs & Hosting
  final String _hostedUrl = 'https://ludu-room-game.web.app';
  final String _localUrl = 'http://localhost:8080';
  bool _useLocalDevUrl = true; // Default to local 8080 where user is running ludugame-1

  // Game Info Controllers
  final TextEditingController _gameNameCtrl = TextEditingController(text: 'Ludo Champion (লুডু গেম)');
  final TextEditingController _gameCodeCtrl = TextEditingController(text: 'ludo');
  final TextEditingController _gameUrlCtrl = TextEditingController(text: 'https://ludu-room-game.web.app');
  final TextEditingController _thumbnailUrlCtrl = TextEditingController(
    text: 'https://cdn-icons-png.flaticon.com/512/3595/3595455.png',
  );

  // Gameplay Rules & Settings
  bool _enableTwoPlayer = true;
  bool _enableFourPlayer = true;
  bool _enableMagicDice = true;
  bool _enableBotMatch = true;
  int _turnTimeSeconds = 15;
  final TextEditingController _entryDiamondsCtrl = TextEditingController(text: '100');
  final TextEditingController _winnerRewardPercentCtrl = TextEditingController(text: '90');
  final TextEditingController _platformFeePercentCtrl = TextEditingController(text: '10');

  // Room Game Category
  String _roomCategory = 'mode'; // 'mode' (Room Mode) or 'game' (Room Game)

  // Test User Simulator
  final TextEditingController _testUserIdCtrl = TextEditingController(text: 'ADMIN_LUDO_USER');
  final TextEditingController _testUserNameCtrl = TextEditingController(text: 'Alone Boy');
  final TextEditingController _testDiamondsCtrl = TextEditingController(text: '50000');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLudoConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gameNameCtrl.dispose();
    _gameCodeCtrl.dispose();
    _gameUrlCtrl.dispose();
    _thumbnailUrlCtrl.dispose();
    _entryDiamondsCtrl.dispose();
    _winnerRewardPercentCtrl.dispose();
    _platformFeePercentCtrl.dispose();
    _testUserIdCtrl.dispose();
    _testUserNameCtrl.dispose();
    _testDiamondsCtrl.dispose();
    super.dispose();
  }

  String get _currentPreviewUrl {
    final base = _useLocalDevUrl
        ? _localUrl
        : (_gameUrlCtrl.text.trim().isNotEmpty
            ? _gameUrlCtrl.text.trim()
            : _hostedUrl);
    final uid = _testUserIdCtrl.text.trim();
    final name = Uri.encodeComponent(_testUserNameCtrl.text.trim());
    final diamonds = _testDiamondsCtrl.text.trim();
    final separator = base.contains('?') ? '&' : '?';
    return '$base${separator}userId=$uid&name=$name&diamonds=$diamonds&magic=$_enableMagicDice';
  }

  Future<void> _loadLudoConfig() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('config').doc('html5_ludo_game').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _isActive = data['isActive'] ?? true;
        _gameNameCtrl.text = data['name'] ?? 'Ludo Champion (লুডু গেম)';
        _gameCodeCtrl.text = data['gameCode'] ?? 'ludo';
        _gameUrlCtrl.text = data['gameUrl'] ?? 'http://localhost:8080';
        _thumbnailUrlCtrl.text = data['thumbnailUrl'] ??
            'https://cdn-icons-png.flaticon.com/512/3595/3595455.png';
        _enableTwoPlayer = data['enableTwoPlayer'] ?? true;
        _enableFourPlayer = data['enableFourPlayer'] ?? true;
        _enableMagicDice = data['enableMagicDice'] ?? true;
        _enableBotMatch = data['enableBotMatch'] ?? true;
        _turnTimeSeconds = data['turnTimeSeconds'] ?? 15;
        _entryDiamondsCtrl.text = (data['entryDiamonds'] ?? 100).toString();
        _winnerRewardPercentCtrl.text = (data['winnerRewardPercent'] ?? 90).toString();
        _platformFeePercentCtrl.text = (data['platformFeePercent'] ?? 10).toString();
        _roomCategory = data['category'] ?? 'mode';
        _useLocalDevUrl = data['useLocalDevUrl'] ?? true;
      }
    } catch (e) {
      debugPrint('Error loading Ludo config: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLudoConfig({bool showSnackBar = true}) async {
    setState(() => _isSaving = true);
    try {
      final configData = {
        'name': _gameNameCtrl.text.trim(),
        'gameCode': _gameCodeCtrl.text.trim(),
        'gameUrl': _gameUrlCtrl.text.trim(),
        'thumbnailUrl': _thumbnailUrlCtrl.text.trim(),
        'isActive': _isActive,
        'enableTwoPlayer': _enableTwoPlayer,
        'enableFourPlayer': _enableFourPlayer,
        'enableMagicDice': _enableMagicDice,
        'enableBotMatch': _enableBotMatch,
        'turnTimeSeconds': _turnTimeSeconds,
        'entryDiamonds': int.tryParse(_entryDiamondsCtrl.text) ?? 100,
        'winnerRewardPercent': int.tryParse(_winnerRewardPercentCtrl.text) ?? 90,
        'platformFeePercent': int.tryParse(_platformFeePercentCtrl.text) ?? 10,
        'category': _roomCategory,
        'useLocalDevUrl': _useLocalDevUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('config').doc('html5_ludo_game').set(
            configData,
            SetOptions(merge: true),
          );

      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ludo Game settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving config: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _syncToRoomGame() async {
    setState(() => _isSyncingToRoom = true);
    try {
      await _saveLudoConfig(showSnackBar: false);

      final gameCode = _gameCodeCtrl.text.trim().isEmpty ? 'ludo' : _gameCodeCtrl.text.trim();
      final gameName = _gameNameCtrl.text.trim().isEmpty ? 'Ludo (লুডু গেম)' : _gameNameCtrl.text.trim();
      final gameUrl = _gameUrlCtrl.text.trim().isEmpty ? 'https://ludu-room-game.web.app' : _gameUrlCtrl.text.trim();
      final thumb = _thumbnailUrlCtrl.text.trim();

      // 1. Sync to room_games collection using set with merge: true (creates or updates without error)
      await _firestore.collection('room_games').doc('room_ludo_champion').set({
        'id': 'room_ludo_champion',
        'gameCode': gameCode,
        'name': gameName,
        'thumbnailUrl': thumb,
        'gameUrl': gameUrl,
        'category': _roomCategory,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Also ensure builtIn config in config/room_games has ludo enabled
      await RoomGameService.toggleBuiltInGameStatus('ludo', _isActive);

      // 3. Strictly remove any Ludo doc from 'games' collection so it NEVER appears on Game Wall
      try {
        await _firestore.collection('games').doc('ludugame-1').delete();
        await _firestore.collection('games').doc('ludo').delete();
        await _firestore.collection('games').doc('ludo_game').delete();
        await _firestore.collection('games').doc('room_ludo_champion').delete();
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🎉 Ludo game synced to Room Game & Room Mode! (Category: $_roomCategory, Code: $gameCode)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync to Room Game: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingToRoom = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Top Action Control Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
            ),
            child: Row(
              children: [
                // Live / Maintenance Badge
                InkWell(
                  onTap: () {
                    setState(() => _isActive = !_isActive);
                    _saveLudoConfig();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isActive
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isActive ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isActive ? Icons.check_circle : Icons.warning_amber,
                          color: _isActive ? Colors.greenAccent : Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isActive ? 'LIVE ACTIVE' : 'MAINTENANCE',
                          style: TextStyle(
                            color: _isActive ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                // Sync to Room Game Button
                ElevatedButton.icon(
                  onPressed: _isSyncingToRoom ? null : _syncToRoomGame,
                  icon: _isSyncingToRoom
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.meeting_room, color: Colors.white, size: 16),
                  label: Text(
                    _isSyncingToRoom ? 'Syncing...' : 'রুম গেমে এড করুন (Sync Room Game)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(width: 10),

                // Copy Link Button
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _currentPreviewUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📋 Game Link copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy, color: Colors.cyanAccent, size: 16),
                  label: const Text('Copy Link', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.cyanAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(width: 10),

                // Save & Publish Button
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveLudoConfig(),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.cloud_upload, color: Colors.black, size: 18),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save & Publish (লাইভ আপডেট)',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // TabBar
          Container(
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(icon: Icon(Icons.play_circle_fill), text: '🎮 Live Game Preview (লাইভ প্রিভিউ)'),
                Tab(icon: Icon(Icons.rule_folder), text: '⚙️ Game Modes & Room Rules (মোড ও নিয়ম)'),
                Tab(icon: Icon(Icons.palette), text: '🎨 UI, Themes & Assets (থিম ও ছবি)'),
                Tab(icon: Icon(Icons.meeting_room), text: '🚪 Room Game Integration (রুম মোড স্ট্যাটাস)'),
              ],
            ),
          ),

          // TabBarView Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLivePreviewTab(),
                _buildRulesTab(),
                _buildThemeAndAssetsTab(),
                _buildRoomIntegrationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: LIVE GAME PREVIEW
  Widget _buildLivePreviewTab() {
    return Row(
      children: [
        // Left: Embedded Game Iframe
        Expanded(
          flex: 6,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  buildWebIframe(
                    viewId: 'ludo-iframe-$_iframeKey',
                    url: _currentPreviewUrl,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        IconButton.filled(
                          onPressed: () => setState(() => _iframeKey++),
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                          tooltip: 'Reload Game',
                          style: IconButton.styleFrom(backgroundColor: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right: Dev Controls & Simulator Settings
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Server Switcher
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌐 Game Server Environment',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Local Port 8080')),
                              selected: _useLocalDevUrl,
                              selectedColor: Colors.amber.withValues(alpha: 0.3),
                              labelStyle: TextStyle(
                                color: _useLocalDevUrl ? Colors.amber : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) {
                                setState(() {
                                  _useLocalDevUrl = true;
                                  _iframeKey++;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Hosted Web.app')),
                              selected: !_useLocalDevUrl,
                              selectedColor: Colors.cyanAccent.withValues(alpha: 0.3),
                              labelStyle: TextStyle(
                                color: !_useLocalDevUrl ? Colors.cyanAccent : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) {
                                setState(() {
                                  _useLocalDevUrl = false;
                                  _iframeKey++;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Current URL: $_currentPreviewUrl',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Test Player Simulation
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👤 Test Player Simulator',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _testUserNameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Player Name',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.person, color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.amber),
                          ),
                        ),
                        onChanged: (_) => setState(() => _iframeKey++),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _testDiamondsCtrl,
                        style: const TextStyle(color: Colors.cyanAccent),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Diamond Coins',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.diamond, color: Colors.cyanAccent),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyanAccent),
                          ),
                        ),
                        onChanged: (_) => setState(() => _iframeKey++),
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

  // TAB 2: GAME MODES & ROOM RULES
  Widget _buildRulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🕹️ Multiplayer Modes & Logic (মোড ও খেলার নিয়ম)',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'ভয়েস রুমে প্লেয়াররা যেভাবে লুডু গেম ওপেন করবে এবং খেলবে তার নিয়মাবলী কনফিগার করুন',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Player Modes (2 Players / 4 Players)
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Supported Room Player Formats',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('2 Players Mode (১ বনাম ১ মোড)', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Red vs Yellow classic head-to-head match', style: TextStyle(color: Colors.grey[400])),
                    value: _enableTwoPlayer,
                    activeThumbColor: Colors.amber,
                    onChanged: (val) => setState(() => _enableTwoPlayer = val),
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    title: const Text('4 Players Mode (৪ জন প্লেয়ার মোড)', style: TextStyle(color: Colors.white)),
                    subtitle: Text('4 players (Red, Green, Yellow, Blue) all-out battle', style: TextStyle(color: Colors.grey[400])),
                    value: _enableFourPlayer,
                    activeThumbColor: Colors.amber,
                    onChanged: (val) => setState(() => _enableFourPlayer = val),
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    title: const Text('Magic Dice Mode (ম্যাজিক ডাইস)', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Special rolls, power-ups and animated rolling dice', style: TextStyle(color: Colors.grey[400])),
                    value: _enableMagicDice,
                    activeThumbColor: Colors.deepPurpleAccent,
                    onChanged: (val) => setState(() => _enableMagicDice = val),
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    title: const Text('Auto-Matchmaking & AI Fill (অটো ম্যাচ ও বট)', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Auto fill empty seats with friendly bot players if waiting times out', style: TextStyle(color: Colors.grey[400])),
                    value: _enableBotMatch,
                    activeThumbColor: Colors.greenAccent,
                    onChanged: (val) => setState(() => _enableBotMatch = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Timer & Turn Limits
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⏱️ Turn Timer & Diamond Fees (সময় ও কয়েন)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Turn Time per Player (সেকেন্ড)', style: TextStyle(color: Colors.grey[300])),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              initialValue: _turnTimeSeconds,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 10, child: Text('10 Seconds (Fast)')),
                                DropdownMenuItem(value: 15, child: Text('15 Seconds (Normal)')),
                                DropdownMenuItem(value: 20, child: Text('20 Seconds (Relaxed)')),
                                DropdownMenuItem(value: 30, child: Text('30 Seconds (Extended)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _turnTimeSeconds = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Entry Fee (Diamonds)', style: TextStyle(color: Colors.grey[300])),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _entryDiamondsCtrl,
                              style: const TextStyle(color: Colors.cyanAccent),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.diamond, color: Colors.cyanAccent),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Winner Reward Share (%)', style: TextStyle(color: Colors.grey[300])),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _winnerRewardPercentCtrl,
                              style: const TextStyle(color: Colors.greenAccent),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                suffixText: '%',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Platform / Room Owner Fee (%)', style: TextStyle(color: Colors.grey[300])),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _platformFeePercentCtrl,
                              style: const TextStyle(color: Colors.amber),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                suffixText: '%',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: THEME & ASSETS
  Widget _buildThemeAndAssetsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎨 Game Identity & Launch URLs',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Name & Code
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _gameNameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Game Title (গেমের নাম)',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.title, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _gameCodeCtrl,
                    style: const TextStyle(color: Colors.amber),
                    decoration: InputDecoration(
                      labelText: 'Game Identifier Code (e.g. ludo / ludugame-1)',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.tag, color: Colors.amber),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _gameUrlCtrl,
                    style: const TextStyle(color: Colors.cyanAccent),
                    decoration: InputDecoration(
                      labelText: 'HTML5 Web Launch URL',
                      hintText: 'https://ludo-game.web.app or http://localhost:8080',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.link, color: Colors.cyanAccent),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _thumbnailUrlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Thumbnail Image URL (থাম্বনেইল লিংক)',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.image, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
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

  // TAB 4: ROOM GAME INTEGRATION
  Widget _buildRoomIntegrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚪 Room Game & Room Mode Integration',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'অ্যাপের অডিও রুমে "Room Mode" এবং "Room Game" মেনুতে এই লুডু গেমটি সংযুক্ত রাখুন',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 20),

          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room Display Category',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Room Mode (রুম মোড - হেড টু হেড)')),
                          selected: _roomCategory == 'mode',
                          selectedColor: Colors.deepOrange.withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: _roomCategory == 'mode' ? Colors.deepOrangeAccent : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) => setState(() => _roomCategory = 'mode'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Room Game (রুম গেম - ইন-রুম গেম)')),
                          selected: _roomCategory == 'game',
                          selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: _roomCategory == 'game' ? Colors.blueAccent : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) => setState(() => _roomCategory = 'game'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Synchronization Action',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'নিচের বাটনে ক্লিক করলে লুডু গেমটি সাথে সাথে রুম গেম ডাটাবেসে সেভ এবং সক্রিয় হয়ে যাবে।',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSyncingToRoom ? null : _syncToRoomGame,
                    icon: _isSyncingToRoom
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync, color: Colors.white),
                    label: Text(
                      _isSyncingToRoom ? 'Syncing...' : 'Sync & Enable in Voice Rooms Now',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
