import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/room_decoration_admin_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/media_preview_widget.dart';
import '../widgets/golden_seat_widget.dart';

class RoomCreateDecorationScreen extends StatefulWidget {
  const RoomCreateDecorationScreen({super.key});

  @override
  State<RoomCreateDecorationScreen> createState() =>
      _RoomCreateDecorationScreenState();
}

class _RoomCreateDecorationScreenState
    extends State<RoomCreateDecorationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSaving = false;

  // Toggles
  bool _enableBackground = true;
  bool _enableSeatDecor = true;
  bool _enableRoomProfilePic = true;
  bool _enableSeatAnimation = true;

  // Controllers for direct URL / names
  final TextEditingController _bgUrlCtrl = TextEditingController();
  final TextEditingController _bgNameCtrl = TextEditingController();

  final TextEditingController _seatDecorUrlCtrl = TextEditingController();
  final TextEditingController _lockedSeatDecorUrlCtrl = TextEditingController();
  final TextEditingController _seatNameCtrl = TextEditingController();
  String _seatColorMode = 'original';
  String _seatAnimationType = 'rotatingRing';
  double _seatAnimationSpeed = 1.0;
  String _seatAnimationColor = 'cyan';

  final TextEditingController _profilePicUrlCtrl = TextEditingController();
  final TextEditingController _profilePicNameCtrl = TextEditingController();

  // Pending upload files (bytes)
  Uint8List? _bgBytes;
  String? _bgFileName;

  Uint8List? _seatDecorBytes;
  String? _seatDecorFileName;

  Uint8List? _lockedSeatDecorBytes;
  String? _lockedSeatDecorFileName;

  Uint8List? _profilePicBytes;
  String? _profilePicFileName;

  // Store items
  List<Map<String, dynamic>> _storeBackgrounds = [];
  List<Map<String, dynamic>> _storeSeatDecors = [];
  bool _isLoadingStore = false;

  final List<String> _seatColorModes = [
    'original',
    'golden',
    'purple',
    'cyberEmerald',
    'dashedPink',
    'dashedOrange',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bgUrlCtrl.dispose();
    _bgNameCtrl.dispose();
    _seatDecorUrlCtrl.dispose();
    _lockedSeatDecorUrlCtrl.dispose();
    _seatNameCtrl.dispose();
    _profilePicUrlCtrl.dispose();
    _profilePicNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final config = await RoomDecorationAdminService.getDecorationConfig();
      if (config != null) {
        _applyConfigToState(config);
      } else {
        // Defaults
        _bgNameCtrl.text = 'Default Room Theme';
        _seatNameCtrl.text = 'Standard Seat Decor';
        _profilePicNameCtrl.text = 'Default Voice Avatar';
      }

      // Load store items in background
      _loadStoreItems();
    } catch (e) {
      debugPrint('Error loading initial decoration data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyConfigToState(Map<String, dynamic> config) {
    _enableBackground = config['enableDefaultBackground'] ?? config['enableBackground'] ?? true;
    _enableSeatDecor = config['enableDefaultSeatDecor'] ?? config['enableSeatDecor'] ?? true;
    _enableRoomProfilePic = config['enableDefaultRoomProfilePic'] ?? config['enableRoomProfilePic'] ?? true;
    _enableSeatAnimation = config['enableSeatAnimation'] ?? config['seatDecor']?['isAnimated'] ?? true;

    // Background
    _bgUrlCtrl.text = config['defaultBackgroundImageUrl'] ?? config['backgroundTheme']?['imageUrl'] ?? '';
    _bgNameCtrl.text = config['defaultBackgroundName'] ?? config['backgroundTheme']?['name'] ?? 'Default Room Theme';

    // Seat Decor
    _seatDecorUrlCtrl.text = config['defaultSeatDecorUrl'] ?? config['seatDecor']?['seatDecorUrl'] ?? '';
    _lockedSeatDecorUrlCtrl.text = config['defaultLockedSeatDecorUrl'] ?? config['seatDecor']?['lockedSeatDecorUrl'] ?? '';
    _seatNameCtrl.text = config['defaultSeatName'] ?? config['seatDecor']?['name'] ?? 'Standard Seat Decor';
    _seatColorMode = config['defaultSeatColorMode'] ?? config['seatDecor']?['seatColorMode'] ?? 'original';
    _seatAnimationType = config['seatAnimationType'] ?? config['seatDecor']?['animationType'] ?? 'rotatingRing';
    _seatAnimationSpeed = (config['seatAnimationSpeed'] ?? config['seatDecor']?['animationSpeed'] ?? 1.0).toDouble();
    _seatAnimationColor = config['seatAnimationColor'] ?? config['seatDecor']?['animationColor'] ?? 'cyan';

    // Profile Pic
    _profilePicUrlCtrl.text = config['defaultRoomProfilePicUrl'] ?? config['roomProfilePic']?['imageUrl'] ?? '';
    _profilePicNameCtrl.text = config['defaultRoomProfileName'] ?? config['roomProfilePic']?['name'] ?? 'Default Voice Avatar';
  }

  Future<void> _loadStoreItems() async {
    setState(() => _isLoadingStore = true);
    try {
      final bgs = await RoomDecorationAdminService.getStoreBackgrounds();
      final seats = await RoomDecorationAdminService.getStoreSeatDecors();
      if (mounted) {
        setState(() {
          _storeBackgrounds = bgs;
          _storeSeatDecors = seats;
          _isLoadingStore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStore = false);
    }
  }

  Future<void> _pickFile(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final name = result.files.single.name;

        setState(() {
          if (type == 'background') {
            _bgBytes = bytes;
            _bgFileName = name;
          } else if (type == 'seatDecor') {
            _seatDecorBytes = bytes;
            _seatDecorFileName = name;
          } else if (type == 'lockedSeatDecor') {
            _lockedSeatDecorBytes = bytes;
            _lockedSeatDecorFileName = name;
          } else if (type == 'profilePic') {
            _profilePicBytes = bytes;
            _profilePicFileName = name;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File selection failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      String finalBgUrl = _bgUrlCtrl.text.trim();
      String finalSeatDecorUrl = _seatDecorUrlCtrl.text.trim();
      String finalLockedSeatDecorUrl = _lockedSeatDecorUrlCtrl.text.trim();
      String finalProfilePicUrl = _profilePicUrlCtrl.text.trim();

      // 1. Upload background if selected
      if (_bgBytes != null) {
        finalBgUrl = await RoomDecorationAdminService.uploadAsset(
          _bgBytes!,
          'backgrounds',
          fileName: _bgFileName,
        );
        _bgUrlCtrl.text = finalBgUrl;
        _bgBytes = null;
      }

      // 2. Upload seat decor if selected
      if (_seatDecorBytes != null) {
        finalSeatDecorUrl = await RoomDecorationAdminService.uploadAsset(
          _seatDecorBytes!,
          'seat_decors',
          fileName: _seatDecorFileName,
        );
        _seatDecorUrlCtrl.text = finalSeatDecorUrl;
        _seatDecorBytes = null;
      }

      // 3. Upload locked seat decor if selected
      if (_lockedSeatDecorBytes != null) {
        finalLockedSeatDecorUrl = await RoomDecorationAdminService.uploadAsset(
          _lockedSeatDecorBytes!,
          'seat_decors',
          fileName: _lockedSeatDecorFileName,
        );
        _lockedSeatDecorUrlCtrl.text = finalLockedSeatDecorUrl;
        _lockedSeatDecorBytes = null;
      }

      // 4. Upload room profile pic if selected
      if (_profilePicBytes != null) {
        finalProfilePicUrl = await RoomDecorationAdminService.uploadAsset(
          _profilePicBytes!,
          'room_profile_pics',
          fileName: _profilePicFileName,
        );
        _profilePicUrlCtrl.text = finalProfilePicUrl;
        _profilePicBytes = null;
      }

      final Map<String, dynamic> data = {
        'isEnabled': true,
        'enableDefaultBackground': _enableBackground,
        'enableDefaultSeatDecor': _enableSeatDecor,
        'enableDefaultRoomProfilePic': _enableRoomProfilePic,
        'enableSeatAnimation': _enableSeatAnimation,
        'seatAnimationType': _seatAnimationType,
        'seatAnimationSpeed': _seatAnimationSpeed,
        'seatAnimationColor': _seatAnimationColor,

        // Flat fields for easy query
        'defaultBackgroundImageUrl': finalBgUrl.isNotEmpty ? finalBgUrl : null,
        'defaultBackgroundName': _bgNameCtrl.text.trim(),

        'defaultSeatDecorUrl': finalSeatDecorUrl.isNotEmpty ? finalSeatDecorUrl : null,
        'defaultLockedSeatDecorUrl': finalLockedSeatDecorUrl.isNotEmpty ? finalLockedSeatDecorUrl : null,
        'defaultSeatName': _seatNameCtrl.text.trim(),
        'defaultSeatColorMode': _seatColorMode,

        'defaultRoomProfilePicUrl': finalProfilePicUrl.isNotEmpty ? finalProfilePicUrl : null,
        'defaultRoomProfileName': _profilePicNameCtrl.text.trim(),

        // Structured objects
        'backgroundTheme': {
          'enabled': _enableBackground,
          'imageUrl': finalBgUrl,
          'name': _bgNameCtrl.text.trim(),
        },
        'seatDecor': {
          'enabled': _enableSeatDecor,
          'seatDecorUrl': finalSeatDecorUrl,
          'lockedSeatDecorUrl': finalLockedSeatDecorUrl,
          'name': _seatNameCtrl.text.trim(),
          'seatColorMode': _seatColorMode,
          'isAnimated': _enableSeatAnimation,
          'animationType': _seatAnimationType,
          'animationSpeed': _seatAnimationSpeed,
          'animationColor': _seatAnimationColor,
        },
        'roomProfilePic': {
          'enabled': _enableRoomProfilePic,
          'imageUrl': finalProfilePicUrl,
          'name': _profilePicNameCtrl.text.trim(),
        },
      };

      await RoomDecorationAdminService.saveDecorationConfig(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room creation decoration settings saved successfully in real-time!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showStorePickerModal(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final items = type == 'background' ? _storeBackgrounds : _storeSeatDecors;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type == 'background'
                            ? 'Select Store Background Theme'
                            : 'Select Store Mic Seat Decor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  if (items.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No items found in Store for $type',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: GridView.builder(
                        itemCount: items.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          final name = item['name'] ?? 'Unnamed';
                          final fileUrl = item['fileUrl'] ?? '';
                          final lockedUrl = item['lockedFileUrl'];
                          final thumb = item['thumbnailUrl'] ?? fileUrl;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (type == 'background') {
                                  _bgUrlCtrl.text = fileUrl;
                                  _bgNameCtrl.text = name;
                                  _bgBytes = null;
                                } else {
                                  _seatDecorUrlCtrl.text = fileUrl;
                                  _seatNameCtrl.text = name;
                                  _seatDecorBytes = null;
                                  if (lockedUrl != null && lockedUrl.toString().isNotEmpty) {
                                    _lockedSeatDecorUrlCtrl.text = lockedUrl.toString();
                                    _lockedSeatDecorBytes = null;
                                  }
                                }
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Selected "$name"'),
                                  backgroundColor: Colors.blueAccent,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: thumb != null && thumb.toString().isNotEmpty
                                          ? MediaPreviewWidget(
                                              url: thumb.toString(),
                                              fit: BoxFit.contain,
                                            )
                                          : const Icon(Icons.image, color: Colors.grey, size: 40),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'New Room Create Decoration',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: RoomDecorationAdminService.getDecorationStream(),
              builder: (context, snapshot) {
                return Column(
                  children: [
                    _buildHeaderBanner(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewAndLivePreviewTab(),
                          _buildMicSeatTab(),
                          _buildBackgroundTab(),
                          _buildProfilePicTab(),
                        ],
                      ),
                    ),
                    _buildBottomSaveBar(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade900, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Default Room Creation Setup (রুম ক্রিয়েট ডেকোরেশন)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'রিয়েল-টাইমে নতুন রুম তৈরির ডিফল্ট মাইক সেট, ব্যাকগ্রাউন্ড থিম ও রুম প্রোফাইল পিকচার সেট করুন। নতুন যেকোনো রুম ক্রিয়েট করলে স্বয়ংক্রিয়ভাবে এই ডেকোরেশন যুক্ত হবে।',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                SizedBox(width: 6),
                Text(
                  'REAL-TIME SYNC',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[900],
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blueAccent,
        labelColor: Colors.blueAccent,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.preview), text: 'Live Mockup Preview'),
          Tab(icon: Icon(Icons.mic), text: 'Mic Seat Set'),
          Tab(icon: Icon(Icons.wallpaper), text: 'Background Theme'),
          Tab(icon: Icon(Icons.account_circle), text: 'Room Profile Pic'),
        ],
      ),
    );
  }

  // TAB 1: Live Mockup Preview & Quick Summary
  Widget _buildOverviewAndLivePreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Interactive Preview Phone Frame
          Expanded(
            flex: 5,
            child: _buildPhoneMockupPreview(),
          ),
          const SizedBox(width: 20),
          // Right column: Current Status & Quick Controls
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  title: '🎙️ Default Mic Seat Decoration',
                  subtitle: _seatNameCtrl.text.isNotEmpty ? _seatNameCtrl.text : 'None',
                  isEnabled: _enableSeatDecor,
                  onToggle: (val) => setState(() => _enableSeatDecor = val),
                  assetUrl: _seatDecorUrlCtrl.text,
                  localBytes: _seatDecorBytes,
                  onEditTap: () => _tabController.animateTo(1),
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  title: '🖼️ Default Room Background Theme',
                  subtitle: _bgNameCtrl.text.isNotEmpty ? _bgNameCtrl.text : 'None',
                  isEnabled: _enableBackground,
                  onToggle: (val) => setState(() => _enableBackground = val),
                  assetUrl: _bgUrlCtrl.text,
                  localBytes: _bgBytes,
                  onEditTap: () => _tabController.animateTo(2),
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  title: '👤 Default Room Profile Picture',
                  subtitle: _profilePicNameCtrl.text.isNotEmpty ? _profilePicNameCtrl.text : 'None',
                  isEnabled: _enableRoomProfilePic,
                  onToggle: (val) => setState(() => _enableRoomProfilePic = val),
                  assetUrl: _profilePicUrlCtrl.text,
                  localBytes: _profilePicBytes,
                  isCircle: true,
                  onEditTap: () => _tabController.animateTo(3),
                ),
                const SizedBox(height: 20),
                _buildQuickPresetsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Interactive Live Phone Frame Mockup
  Widget _buildPhoneMockupPreview() {
    final hasBgImage = _enableBackground && (_bgBytes != null || _bgUrlCtrl.text.isNotEmpty);
    final hasProfilePic = _enableRoomProfilePic && (_profilePicBytes != null || _profilePicUrlCtrl.text.isNotEmpty);
    final hasSeatSkin = _enableSeatDecor && (_seatDecorBytes != null || _seatDecorUrlCtrl.text.isNotEmpty);

    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade700, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Wallpaper
            Positioned.fill(
              child: hasBgImage
                  ? (_bgBytes != null
                      ? Image.memory(_bgBytes!, fit: BoxFit.cover)
                      : MediaPreviewWidget(url: _bgUrlCtrl.text, width: double.infinity, height: double.infinity, fit: BoxFit.cover))
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF0F3B36),
                            Color(0xFF0B2538),
                            Color(0xFF061421),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
            ),

            // Top Status Bar & Room Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    // Room Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: ClipOval(
                        child: hasProfilePic
                            ? (_profilePicBytes != null
                                ? Image.memory(_profilePicBytes!, fit: BoxFit.cover)
                                : MediaPreviewWidget(url: _profilePicUrlCtrl.text, width: 44, height: 44, fit: BoxFit.cover))
                            : const Icon(Icons.room, color: Colors.white70, size: 26),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'New Created Room',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'ID: 7892104 • Live Audio',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            // Center: 9 Mic Seats Grid (Owner top, No.1-4 row 1, No.5-8 row 2)
            Positioned(
              top: 120,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Row 0: Owner Seat (Top Centered)
                  _buildMockSeat(number: 1, isHost: true, hasSeatSkin: hasSeatSkin),
                  const SizedBox(height: 14),
                  // Row 1: Seats 2 to 5 (No.1 to No.4)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMockSeat(number: 2, isHost: false, hasSeatSkin: hasSeatSkin),
                      _buildMockSeat(number: 3, isHost: false, hasSeatSkin: hasSeatSkin),
                      _buildMockSeat(number: 4, isHost: false, hasSeatSkin: hasSeatSkin),
                      _buildMockSeat(number: 5, isHost: false, hasSeatSkin: hasSeatSkin),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Row 2: Seats 6 to 9 (No.5 to No.8)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMockSeat(number: 6, isHost: false, hasSeatSkin: hasSeatSkin),
                      _buildMockSeat(number: 7, isHost: false, isLocked: true, hasSeatSkin: hasSeatSkin),
                      _buildMockSeat(number: 8, isHost: false, hasSeatSkin: hasSeatSkin),
                      _buildMockSeat(number: 9, isHost: false, hasSeatSkin: hasSeatSkin),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Overlay Notice
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.touch_app, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Live Real-Time Mockup: User will see this decoration setup when opening a newly created room.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAnimationGlowColor(String colorKey) {
    switch (colorKey) {
      case 'purple':
        return const Color(0xFFFF00D4);
      case 'golden':
        return const Color(0xFFFFD700);
      case 'emerald':
        return const Color(0xFF00E676);
      case 'amber':
        return const Color(0xFFFF9100);
      case 'cyan':
      default:
        return const Color(0xFF00FFE0);
    }
  }

  Widget _buildMockSeat({
    required int number,
    required bool isHost,
    bool isLocked = false,
    required bool hasSeatSkin,
  }) {
    final hasLockedSkin = isLocked &&
        _enableSeatDecor &&
        (_lockedSeatDecorBytes != null || _lockedSeatDecorUrlCtrl.text.isNotEmpty);

    final glowColor = _getAnimationGlowColor(_seatAnimationColor);

    Widget seatBase;
    if (hasSeatSkin || hasLockedSkin) {
      seatBase = SizedBox(
        width: 52,
        height: 52,
        child: hasLockedSkin
            ? (_lockedSeatDecorBytes != null
                ? Image.memory(_lockedSeatDecorBytes!, fit: BoxFit.contain)
                : MediaPreviewWidget(url: _lockedSeatDecorUrlCtrl.text, width: 52, height: 52, fit: BoxFit.contain))
            : (_seatDecorBytes != null
                ? Image.memory(_seatDecorBytes!, fit: BoxFit.contain)
                : MediaPreviewWidget(url: _seatDecorUrlCtrl.text, width: 52, height: 52, fit: BoxFit.contain)),
      );
    } else if (_seatColorMode == 'cyberEmerald') {
      seatBase = CyberEmeraldDiamondOrbWidget(
        size: 48,
        isLocked: isLocked,
        child: isHost
            ? const GoldenHomeIcon(width: 25, height: 25, isNeonPurple: false)
            : (isLocked
                ? const GoldenLockIcon(width: 23, height: 26, isNeonPurple: false)
                : const GoldenSofaIcon(width: 27, height: 24, isNeonPurple: false)),
      );
    } else if (_seatColorMode == 'purple') {
      seatBase = NeonPurpleGlassOrbWidget(
        size: 48,
        isLocked: isLocked,
        child: isHost
            ? const GoldenHomeIcon(width: 25, height: 25, isNeonPurple: true)
            : (isLocked
                ? const GoldenLockIcon(width: 23, height: 26, isNeonPurple: true)
                : const GoldenSofaIcon(width: 27, height: 24, isNeonPurple: true)),
      );
    } else if (_seatColorMode == 'golden') {
      seatBase = GoldenGlassOrbWidget(
        size: 48,
        isLocked: isLocked,
        child: isHost
            ? const GoldenHomeIcon(width: 25, height: 25)
            : (isLocked
                ? const GoldenLockIcon(width: 23, height: 26)
                : const GoldenSofaIcon(width: 27, height: 24)),
      );
    } else {
      seatBase = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(
            color: isLocked
                ? Colors.white.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      );
    }

    return Column(
      children: [
        AnimatedSeatDecorWidget(
          isAnimated: _enableSeatAnimation,
          animationType: _seatAnimationType,
          animationSpeed: _seatAnimationSpeed,
          glowColor: glowColor,
          size: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              seatBase,

              // Center Icon / Avatar (for non-golden / non-purple / non-cyber modes)
              if (_seatColorMode != 'golden' && _seatColorMode != 'purple' && _seatColorMode != 'cyberEmerald') ...[
                if (isHost)
                  const Icon(Icons.home_rounded, color: Colors.white, size: 24)
                else if (isLocked)
                  Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.85), size: 20)
                else
                  Icon(Icons.mic_rounded, color: Colors.white.withValues(alpha: 0.75), size: 22),
              ],
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          (_seatColorMode == 'golden' || _seatColorMode == 'purple' || _seatColorMode == 'cyberEmerald')
              ? (isHost ? 'Host' : 'No.$number')
              : (isHost ? 'Owner' : 'No.${number - 1}'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String subtitle,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required String assetUrl,
    Uint8List? localBytes,
    bool isCircle = false,
    required VoidCallback onEditTap,
  }) {
    final hasAsset = localBytes != null || assetUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEnabled ? Colors.blueAccent.withValues(alpha: 0.4) : Colors.grey.shade800),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(8),
              color: Colors.black38,
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
              borderRadius: isCircle ? BorderRadius.circular(28) : BorderRadius.circular(8),
              child: hasAsset
                  ? (localBytes != null
                      ? Image.memory(localBytes, fit: BoxFit.cover)
                      : MediaPreviewWidget(url: assetUrl, width: 56, height: 56, fit: BoxFit.cover))
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: isEnabled ? Colors.greenAccent : Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          // Action button
          TextButton.icon(
            onPressed: onEditTap,
            icon: const Icon(Icons.edit, size: 16, color: Colors.blueAccent),
            label: const Text('Configure', style: TextStyle(color: Colors.blueAccent)),
          ),
          const SizedBox(width: 8),

          // Switch
          Switch(
            value: isEnabled,
            onChanged: onToggle,
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPresetsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.palette, color: Colors.purpleAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Style Presets (১-ক্লিক প্রিসেট)',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPresetChip('Cyber Emerald Aura (Animated)', 'cyberEmerald', 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800', seatName: 'Cyber Emerald Aura (Animated)'),
              _buildPresetChip('Aurora Classic Mic & Owner (Free)', 'original', 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800', seatName: 'Classic Mic & Owner (Free)'),
              _buildPresetChip('Golden Sofa & Host (Free)', 'golden', 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800', seatName: 'Golden Sofa & Host (Free)'),
              _buildPresetChip('Cyber Neon Blue', 'golden', 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800'),
              _buildPresetChip('Royal Dark Studio', 'original', 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800'),
              _buildPresetChip('Neon Purple & Gold (Free)', 'purple', 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800', seatName: 'Neon Purple & Gold (Free)'),
              _buildPresetChip('Clear to Default', 'original', '', seatName: 'Classic Mic & Owner (Free)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String name, String colorMode, String bgUrl, {String? seatName}) {
    return ActionChip(
      backgroundColor: Colors.white12,
      label: Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      onPressed: () {
        setState(() {
          _seatColorMode = colorMode;
          if (colorMode == 'cyberEmerald' || colorMode == 'purple') {
            _enableSeatAnimation = true;
            _seatAnimationType = 'rotatingRing';
            _seatAnimationColor = colorMode == 'cyberEmerald' ? 'cyan' : 'purple';
          }
          if (seatName != null) {
            _seatNameCtrl.text = seatName;
            _seatDecorUrlCtrl.clear();
            _lockedSeatDecorUrlCtrl.clear();
            _seatDecorBytes = null;
            _lockedSeatDecorBytes = null;
            _seatDecorFileName = null;
            _lockedSeatDecorFileName = null;
          }
          if (bgUrl.isNotEmpty) {
            _bgUrlCtrl.text = bgUrl;
            _bgNameCtrl.text = name;
            _bgBytes = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preset "$name" applied to editor'), backgroundColor: Colors.purpleAccent),
        );
      },
    );
  }

  // TAB 2: Mic Seat Skin
  Widget _buildMicSeatTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSwitchTile(
            title: 'Enable Default Mic Seat Decoration for New Rooms',
            subtitle: 'When enabled, every newly created audio room automatically gets this mic seat set.',
            value: _enableSeatDecor,
            onChanged: (val) => setState(() => _enableSeatDecor = val),
          ),
          const SizedBox(height: 20),

          // Highlight Card: Free Default Classic Seat Set
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F3B36).withValues(alpha: 0.8),
                  const Color(0xFF0B2538).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.stars, color: Colors.tealAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Default Free Seat Icon Set (ফ্রী সিট আইকন সেট)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'রুম যখন প্রথমবার তৈরি হবে তখন ইউজার এই সুন্দর ফ্রী সিট আইকন সেটটি দেখতে পাবে:\n'
                  '• Owner Seat: হোস্টিং হোম আইকন (Owner)\n'
                  '• Guest Seats: প্রিমিয়াম মাইক আইকন (No.1 - No.8)\n'
                  '• Locked Seat: হোয়াইট লক আইকন',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _enableSeatDecor = true;
                      _seatNameCtrl.text = 'Classic Mic & Owner (Free)';
                      _seatDecorUrlCtrl.clear();
                      _lockedSeatDecorUrlCtrl.clear();
                      _seatDecorBytes = null;
                      _lockedSeatDecorBytes = null;
                      _seatDecorFileName = null;
                      _lockedSeatDecorFileName = null;
                      _seatColorMode = 'original';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Free Classic Mic & Owner seat icon set selected! Save to apply.'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.black, size: 18),
                  label: const Text(
                    'Use Default Free Classic Seat Icons (ফ্রী সেট নির্বাচন করুন)',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Publishing free seat decor to live app store...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      await RoomDecorationAdminService.syncFreeSeatDecorToStore(
                        name: _seatNameCtrl.text.isNotEmpty
                            ? _seatNameCtrl.text
                            : 'Classic Mic & Owner (Free)',
                        seatColorMode: _seatColorMode,
                        seatDecorUrl: _seatDecorUrlCtrl.text.trim(),
                        lockedSeatDecorUrl: _lockedSeatDecorUrlCtrl.text.trim(),
                        isAnimated: _enableSeatAnimation,
                        animationType: _seatAnimationType,
                        animationSpeed: _seatAnimationSpeed,
                        animationColor: _seatAnimationColor,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '⚡ Successfully published to app in real-time! All users will see it without restart.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to publish: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.bolt, color: Colors.tealAccent, size: 18),
                  label: const Text(
                    'Instant Live Sync to App (অ্যাপে রিয়েল-টাইমে পাবলিশ করুন - কোনো রিফ্রেশ ছাড়া)',
                    style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.tealAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Real-time Seat Animation Controls Section ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _enableSeatAnimation ? Colors.cyanAccent.withValues(alpha: 0.6) : Colors.white12,
                width: _enableSeatAnimation ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _enableSeatAnimation ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: _enableSeatAnimation ? Colors.cyanAccent : Colors.grey,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Real-Time Seat Animation (সিট অ্যানিমেশন অন/অফ)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'সুইচ অন রাখলে সব সিটে রিয়েল-টাইমে ঘুরন্ত নিয়ন অরা, স্পার্কল ও পালসিং এনিমেশন চলবে।',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enableSeatAnimation,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => setState(() => _enableSeatAnimation = val),
                    ),
                  ],
                ),

                if (_enableSeatAnimation) ...[
                  const Divider(color: Colors.white24, height: 24),

                  const Text(
                    'Animation Effect Style (অ্যানিমেশন ইফেক্ট):',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _seatAnimationType,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.black26,
                    ),
                    items: const [
                                    DropdownMenuItem(
                                      value: 'beamSweep',
                                      child: Text('⚡ Laser Light Beam Sweep (বাম থেকে ডানে আলো যাওয়া)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'rotatingRing',
                        child: Text('💫 360° Rotating Neon Aura Ring (ঘুরন্ত নিয়ন রিং)'),
                      ),
                      DropdownMenuItem(
                        value: 'neonPulse',
                        child: Text('💓 Breathing Neon Glow Pulse (পালসিং গ্লো)'),
                      ),
                      DropdownMenuItem(
                        value: 'starSparkle',
                        child: Text('✨ Orbiting Star Sparkles (স্পার্কলিং স্টার)'),
                      ),
                      DropdownMenuItem(
                        value: 'rippleWave',
                        child: Text('🌊 Cyber Sonar Ripple Wave (রিপল ওয়েভ)'),
                      ),
                      DropdownMenuItem(
                        value: 'goldenShimmer',
                        child: Text('🌟 Holographic Shimmer Sweep (শিমার ইফেক্ট)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _seatAnimationType = val);
                    },
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Aura Glow Color (অরা নিয়ন কালার):',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRoomColorChip('Cyan Neon', 'cyan', const Color(0xFF00FFE0)),
                      _buildRoomColorChip('Electric Purple', 'purple', const Color(0xFFFF00D4)),
                      _buildRoomColorChip('Champagne Gold', 'golden', const Color(0xFFFFD700)),
                      _buildRoomColorChip('Cosmic Emerald', 'emerald', const Color(0xFF00E676)),
                      _buildRoomColorChip('Fire Amber', 'amber', const Color(0xFFFF9100)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Animation Speed (গতি):',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_seatAnimationSpeed.toStringAsFixed(2)}x',
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _seatAnimationSpeed,
                    min: 0.5,
                    max: 2.5,
                    divisions: 8,
                    label: '${_seatAnimationSpeed.toStringAsFixed(2)}x',
                    activeColor: Colors.cyanAccent,
                    inactiveColor: Colors.grey[800],
                    onChanged: (val) => setState(() => _seatAnimationSpeed = val),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Name
          TextFormField(
            controller: _seatNameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Mic Seat Set Name (e.g., Royal Golden Sofa, Cyber Mic)',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Seat Decor Normal Image
          _buildAssetUploadSection(
            title: '1. Normal Mic Seat Skin (নরমাল সিট স্কিন)',
            hint: 'Square PNG/WEBP image with transparent background. Appears on all open/occupied seats.',
            urlCtrl: _seatDecorUrlCtrl,
            localBytes: _seatDecorBytes,
            localFileName: _seatDecorFileName,
            onPickFile: () => _pickFile('seatDecor'),
            onChooseStore: () => _showStorePickerModal('seatDecor'),
            onClear: () => setState(() {
              _seatDecorBytes = null;
              _seatDecorFileName = null;
              _seatDecorUrlCtrl.clear();
            }),
          ),
          const SizedBox(height: 24),

          // Locked Seat Decor Image
          _buildAssetUploadSection(
            title: '2. Locked Mic Seat Skin (লকড সিট স্কিন - Optional)',
            hint: 'Appears when host locks a seat in the voice room.',
            urlCtrl: _lockedSeatDecorUrlCtrl,
            localBytes: _lockedSeatDecorBytes,
            localFileName: _lockedSeatDecorFileName,
            onPickFile: () => _pickFile('lockedSeatDecor'),
            onChooseStore: () => _showStorePickerModal('seatDecor'),
            onClear: () => setState(() {
              _lockedSeatDecorBytes = null;
              _lockedSeatDecorFileName = null;
              _lockedSeatDecorUrlCtrl.clear();
            }),
          ),
          const SizedBox(height: 24),

          // Color Mode Dropdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seat Color Mode (সিটের কালার মুড)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Used as the base theme if custom asset skin is transparent or loading.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _seatColorMode,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.black26,
                  ),
                  items: _seatColorModes.map((mode) {
                    return DropdownMenuItem<String>(
                      value: mode,
                      child: Text(mode.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _seatColorMode = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomColorChip(String label, String colorKey, Color color) {
    final isSelected = _seatAnimationColor == colorKey;
    return ChoiceChip(
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.black45,
      onSelected: (selected) {
        if (selected) setState(() => _seatAnimationColor = colorKey);
      },
    );
  }

  // TAB 3: Background Theme
  Widget _buildBackgroundTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSwitchTile(
            title: 'Enable Default Background Theme for New Rooms',
            subtitle: 'When enabled, newly created rooms will use this wallpaper image as their room theme.',
            value: _enableBackground,
            onChanged: (val) => setState(() => _enableBackground = val),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _bgNameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Background Theme Name (e.g., Cyber Neon, Starry Night)',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          _buildAssetUploadSection(
            title: 'Room Background Wallpaper Image (ব্যাকগ্রাউন্ড ওয়ালপেপার)',
            hint: 'Recommended aspect ratio 9:16 (vertical mobile screen) in JPG, PNG or WEBP format.',
            urlCtrl: _bgUrlCtrl,
            localBytes: _bgBytes,
            localFileName: _bgFileName,
            isFullWidth: true,
            onPickFile: () => _pickFile('background'),
            onChooseStore: () => _showStorePickerModal('background'),
            onClear: () => setState(() {
              _bgBytes = null;
              _bgFileName = null;
              _bgUrlCtrl.clear();
            }),
          ),
        ],
      ),
    );
  }

  // TAB 4: Room Profile Picture
  Widget _buildProfilePicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSwitchTile(
            title: 'Enable Default Room Profile Picture (ডিফল্ট রুম প্রোফাইল পিকচার)',
            subtitle: 'When enabled, if creator doesn\'t upload a custom room avatar, this image will be applied automatically.',
            value: _enableRoomProfilePic,
            onChanged: (val) => setState(() => _enableRoomProfilePic = val),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _profilePicNameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Profile Picture Label (e.g., Official Voice Room Icon)',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          _buildAssetUploadSection(
            title: 'Default Room Avatar / Icon (রুমের ডিফল্ট আইকন)',
            hint: 'Square 1:1 ratio image in PNG/JPG/WEBP. Appears in room cards, explore tab, and room header.',
            urlCtrl: _profilePicUrlCtrl,
            localBytes: _profilePicBytes,
            localFileName: _profilePicFileName,
            isCircularPreview: true,
            onPickFile: () => _pickFile('profilePic'),
            onClear: () => setState(() {
              _profilePicBytes = null;
              _profilePicFileName = null;
              _profilePicUrlCtrl.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildAssetUploadSection({
    required String title,
    required String hint,
    required TextEditingController urlCtrl,
    Uint8List? localBytes,
    String? localFileName,
    bool isFullWidth = false,
    bool isCircularPreview = false,
    required VoidCallback onPickFile,
    VoidCallback? onChooseStore,
    required VoidCallback onClear,
  }) {
    final hasAsset = localBytes != null || urlCtrl.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Box
              Container(
                width: isFullWidth ? 110 : (isCircularPreview ? 90 : 90),
                height: isFullWidth ? 160 : 90,
                decoration: BoxDecoration(
                  shape: isCircularPreview ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isCircularPreview ? null : BorderRadius.circular(8),
                  color: Colors.black45,
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: isCircularPreview ? BorderRadius.circular(50) : BorderRadius.circular(8),
                  child: hasAsset
                      ? (localBytes != null
                          ? Image.memory(localBytes, fit: isFullWidth ? BoxFit.cover : BoxFit.contain)
                          : MediaPreviewWidget(
                              url: urlCtrl.text,
                              width: isFullWidth ? 110 : (isCircularPreview ? 90 : 90),
                              height: isFullWidth ? 160 : 90,
                              fit: isFullWidth ? BoxFit.cover : BoxFit.contain,
                            ))
                      : const Center(child: Icon(Icons.image, color: Colors.grey, size: 36)),
                ),
              ),
              const SizedBox(width: 16),

              // Inputs and Buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: urlCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Asset URL (সরাসরি ইমেজ লিংক দিন)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black26,
                        border: const OutlineInputBorder(),
                        suffixIcon: urlCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: onClear,
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: onPickFile,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: Text(localFileName != null ? 'Picked: $localFileName' : 'Upload from PC'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (onChooseStore != null)
                          OutlinedButton.icon(
                            onPressed: onChooseStore,
                            icon: const Icon(Icons.storefront, size: 18, color: Colors.amberAccent),
                            label: const Text('Pick from Store', style: TextStyle(color: Colors.amberAccent)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.amberAccent),
                            ),
                          ),
                        if (hasAsset)
                          TextButton.icon(
                            onPressed: onClear,
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            label: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSaveBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(top: BorderSide(color: Colors.white24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'Changes apply instantly to all newly created rooms in real-time.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAll,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save, size: 20),
            label: Text(
              _isSaving ? 'Saving Changes...' : 'Save All Decoration Changes',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
