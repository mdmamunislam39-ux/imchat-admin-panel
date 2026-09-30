import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../services/app_theme_admin_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/media_preview_widget.dart';

class AppThemeManagementScreen extends StatefulWidget {
  const AppThemeManagementScreen({super.key});

  @override
  State<AppThemeManagementScreen> createState() =>
      _AppThemeManagementScreenState();
}

class _AppThemeManagementScreenState extends State<AppThemeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // Configuration State
  Map<String, dynamic> _themeConfig = {};

  // Pending Uploads State (Key: config key, Value: file bytes)
  final Map<String, Uint8List> _pendingUploads = {};
  final Map<String, String> _pendingUploadFileNames = {};

  // Text Controllers for Colors
  final TextEditingController _splashColorCtrl = TextEditingController();
  final TextEditingController _splashTextColorCtrl = TextEditingController();
  final Map<String, TextEditingController> _screenColorCtrls = {
    'home': TextEditingController(),
    'profile': TextEditingController(),
    'room': TextEditingController(),
    'leaderboard': TextEditingController(),
  };
  final Map<String, TextEditingController> _screenTextColorCtrls = {
    'home': TextEditingController(),
    'profile': TextEditingController(),
    'room': TextEditingController(),
    'leaderboard': TextEditingController(),
  };
  final Map<String, TextEditingController> _screenSecondaryTextColorCtrls = {
    'home': TextEditingController(),
    'profile': TextEditingController(),
    'room': TextEditingController(),
    'leaderboard': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _splashColorCtrl.dispose();
    _splashTextColorCtrl.dispose();
    for (var ctrl in _screenColorCtrls.values) {
      ctrl.dispose();
    }
    for (var ctrl in _screenTextColorCtrls.values) {
      ctrl.dispose();
    }
    for (var ctrl in _screenSecondaryTextColorCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final config = await AppThemeAdminService.getThemeConfig();
      if (config != null) {
        _themeConfig = Map.from(config);

        // Initialize color controllers
        _splashColorCtrl.text = _themeConfig['splashColor'] ?? '';
        _splashTextColorCtrl.text = _themeConfig['splashTextColor'] ?? '';

        final screenThemes =
            _themeConfig['screenThemes'] as Map<String, dynamic>? ?? {};
        for (final key in ['home', 'profile', 'room']) {
          _screenColorCtrls[key]?.text = screenThemes['${key}Color'] ?? '';
          _screenTextColorCtrls[key]?.text = screenThemes['${key}TextColor'] ?? '';
          _screenSecondaryTextColorCtrls[key]?.text =
              screenThemes['${key}SecondaryTextColor'] ?? '';
        }

        final leaderboardFrames =
            _themeConfig['leaderboardFrames'] as Map<String, dynamic>? ?? {};
        _screenColorCtrls['leaderboard']?.text =
            leaderboardFrames['backgroundColor'] ??
            screenThemes['leaderboardColor'] ??
            '';
        _screenTextColorCtrls['leaderboard']?.text =
            leaderboardFrames['textColor'] ??
            screenThemes['leaderboardTextColor'] ??
            '';
        _screenSecondaryTextColorCtrls['leaderboard']?.text =
            leaderboardFrames['secondaryTextColor'] ??
            screenThemes['leaderboardSecondaryTextColor'] ??
            '';

        final String lbBgUrl = _themeConfig['leaderboardBgUrl'] ??
            screenThemes['leaderboardBgUrl'] ??
            leaderboardFrames['backgroundUrl'] ??
            '';
        _themeConfig['leaderboardBgUrl'] = lbBgUrl;
        _themeConfig['screenThemes'] ??= {};
        _themeConfig['screenThemes']['leaderboardBgUrl'] = lbBgUrl;
        _themeConfig['leaderboardFrames'] ??= {};
        _themeConfig['leaderboardFrames']['backgroundUrl'] = lbBgUrl;
      }
    } catch (e) {
      _showError('Error loading theme config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(String configKey) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'svga'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && result.files.single.bytes != null) {
        setState(() {
          _pendingUploads[configKey] = result.files.single.bytes!;
          _pendingUploadFileNames[configKey] = result.files.single.name;
        });
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  void _removeImage(
    String configKey, {
    bool isNestedInScreenThemes = false,
    bool isNestedInLeaderboardFrames = false,
  }) {
    setState(() {
      _pendingUploads.remove(configKey);
      _pendingUploadFileNames.remove(configKey);
      if (configKey.startsWith('walletMenuIcon_')) {
        final iconKey = configKey.replaceFirst('walletMenuIcon_', '');
        _themeConfig['walletMenuIcons'] ??= {};
        _themeConfig['walletMenuIcons'][iconKey] = '';
        _themeConfig['profileMenuIcons'] ??= {};
        _themeConfig['profileMenuIcons'][iconKey] = '';
      } else if (configKey == 'leaderboardBgUrl') {
        _themeConfig['leaderboardBgUrl'] = '';
        _themeConfig['screenThemes'] ??= {};
        _themeConfig['screenThemes']['leaderboardBgUrl'] = '';
        _themeConfig['leaderboardFrames'] ??= {};
        _themeConfig['leaderboardFrames']['backgroundUrl'] = '';
      } else if (isNestedInScreenThemes) {
        _themeConfig['screenThemes'] ??= {};
        _themeConfig['screenThemes'][configKey] = '';
      } else if (isNestedInLeaderboardFrames) {
        _themeConfig['leaderboardFrames'] ??= {};
        _themeConfig['leaderboardFrames'][configKey] = '';
      } else {
        _themeConfig[configKey] = '';
      }
    });
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      // Upload pending images
      for (var entry in _pendingUploads.entries) {
        final key = entry.key;
        final bytes = entry.value;
        final fileName = _pendingUploadFileNames[key];

        if (key.startsWith('walletMenuIcon_')) {
          final iconKey = key.replaceFirst('walletMenuIcon_', '');
          final url = await AppThemeAdminService.uploadImage(
            bytes,
            'wallet_icons',
            originalFileName: fileName,
          );
          _themeConfig['walletMenuIcons'] ??= {};
          _themeConfig['walletMenuIcons'][iconKey] = url;
          _themeConfig['profileMenuIcons'] ??= {};
          _themeConfig['profileMenuIcons'][iconKey] = url;
          if (iconKey == 'host_centre') {
            _themeConfig['walletMenuIcons']['host_center'] = url;
            _themeConfig['profileMenuIcons']['host_center'] = url;
          }
        } else if (key.startsWith('roomSettingsIcon_')) {
          final iconKey = key.replaceFirst('roomSettingsIcon_', '');
          final url = await AppThemeAdminService.uploadImage(
            bytes,
            'room_settings',
            originalFileName: fileName,
          );
          _themeConfig['roomSettingsIcons'] ??= {};
          _themeConfig['roomSettingsIcons'][iconKey] = url;
        } else if (key == 'leaderboardBgUrl') {
          final url = await AppThemeAdminService.uploadImage(
            bytes,
            'leaderboard',
            originalFileName: fileName,
          );
          _themeConfig['leaderboardBgUrl'] = url;
          _themeConfig['screenThemes'] ??= {};
          _themeConfig['screenThemes']['leaderboardBgUrl'] = url;
          _themeConfig['leaderboardFrames'] ??= {};
          _themeConfig['leaderboardFrames']['backgroundUrl'] = url;
        } else {
          final folder = key.startsWith('tab') || key == 'searchIconUrl' || key == 'trophyIconUrl'
              ? 'tab_icons'
              : key
                    .split('_')
                    .first; // e.g., appLogoUrl -> app, sender_rank1_url -> sender
          final url = await AppThemeAdminService.uploadImage(
            bytes,
            folder,
            originalFileName: fileName,
          );

          // Update local config map before saving to Firestore
          if (key.startsWith('sender_') ||
              key.startsWith('receiver_') ||
              key.startsWith('room_') ||
              key.startsWith('supporter_') ||
              key.startsWith('family_')) {
            _themeConfig['leaderboardFrames'] ??= {};
            _themeConfig['leaderboardFrames'][key] = url;
          } else if (key.endsWith('BgUrl')) {
            _themeConfig['screenThemes'] ??= {};
            _themeConfig['screenThemes'][key] = url;
          } else {
            _themeConfig[key] = url;
          }
        }
      }

      // Update colors from controllers
      _themeConfig['splashColor'] = _splashColorCtrl.text.trim();
      _themeConfig['splashTextColor'] = _splashTextColorCtrl.text.trim();

      _themeConfig['screenThemes'] ??= {};
      for (final key in ['home', 'profile', 'room', 'leaderboard']) {
        if (_screenColorCtrls.containsKey(key)) {
          _themeConfig['screenThemes']['${key}Color'] =
              _screenColorCtrls[key]!.text.trim();
          _themeConfig['screenThemes']['${key}TextColor'] =
              _screenTextColorCtrls[key]!.text.trim();
          _themeConfig['screenThemes']['${key}SecondaryTextColor'] =
              _screenSecondaryTextColorCtrls[key]!.text.trim();
        }
      }

      _themeConfig['leaderboardFrames'] ??= {};
      _themeConfig['leaderboardFrames']['backgroundColor'] =
          _screenColorCtrls['leaderboard']!.text.trim();
      _themeConfig['leaderboardFrames']['textColor'] =
          _screenTextColorCtrls['leaderboard']!.text.trim();
      _themeConfig['leaderboardFrames']['secondaryTextColor'] =
          _screenSecondaryTextColorCtrls['leaderboard']!.text.trim();
      if (_themeConfig['leaderboardBgUrl'] != null &&
          _themeConfig['leaderboardBgUrl'].toString().isNotEmpty) {
        _themeConfig['leaderboardFrames']['backgroundUrl'] =
            _themeConfig['leaderboardBgUrl'];
      }

      // Save to Firestore
      await AppThemeAdminService.updateThemeConfig(_themeConfig);

      _pendingUploads.clear(); // Clear pending uploads
      _pendingUploadFileNames.clear();
      _showSuccess('Theme configuration updated successfully!');
      await _loadData(); // Reload to refresh UI with network images
    } catch (e) {
      _showError('Failed to save configuration: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'App Theme & Assets Management',
      actions: [
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAll,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Saving...' : 'Save All Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'General Assets'),
                    Tab(text: 'Splash Screen'),
                    Tab(text: 'Screen Backgrounds'),
                    Tab(text: 'Leaderboard Frames'),
                    Tab(text: 'Room & Controls Icons'),
                    Tab(text: 'TabBar Icons'),
                    Tab(text: 'Wallet & Profile Icons'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralTab(),
                      _buildSplashTab(),
                      _buildScreenBackgroundsTab(),
                      _buildLeaderboardTab(),
                      _buildRoomAndControlsIconsTab(),
                      _buildTabBarIconsTab(),
                      _buildWalletAndProfileIconsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // --- UI Builders for Tabs ---

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageUploaderSection('App Logo', 'appLogoUrl'),
          const SizedBox(height: 32),
          _buildImageUploaderSection('Diamond Icon', 'diamondIconUrl'),
          const SizedBox(height: 32),
          _buildImageUploaderSection('Beans Icon', 'beansIconUrl'),
          const SizedBox(height: 32),
          _buildImageUploaderSection('Default User Avatar', 'defaultAvatarUrl'),
        ],
      ),
    );
  }

  Widget _buildSplashTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColorInput(
            'Splash Screen Background Color (Hex)',
            _splashColorCtrl,
          ),
          const SizedBox(height: 20),
          _buildColorInput(
            'Splash Screen Text / Loading Indicator Color (Hex)',
            _splashTextColorCtrl,
          ),
          const SizedBox(height: 32),
          _buildImageUploaderSection(
            'Splash Screen Center Image',
            'splashImageUrl',
          ),
        ],
      ),
    );
  }

  Widget _buildScreenBackgroundsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You can define a background color OR upload a background image for specific screens. Background images override colors when uploaded.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildScreenThemeSection('Home Screen', 'home'),
          const Divider(height: 48, color: Colors.grey),
          _buildScreenThemeSection('Profile Screen', 'profile'),
          const Divider(height: 48, color: Colors.grey),
          _buildScreenThemeSection('Audio Room Screen', 'room'),
          const Divider(height: 48, color: Colors.grey),
          _buildScreenThemeSection('Leaderboard Screen', 'leaderboard'),
        ],
      ),
    );
  }

  Widget _buildScreenThemeSection(String title, String keyPrefix) {
    final String configKey = '${keyPrefix}BgUrl';
    String? currentBgUrl;
    if (keyPrefix == 'leaderboard') {
      currentBgUrl = (_themeConfig['screenThemes'] as Map<String, dynamic>?)?[configKey] ??
          _themeConfig['leaderboardBgUrl'] ??
          (_themeConfig['leaderboardFrames'] as Map<String, dynamic>?)?['backgroundUrl'];
    } else {
      currentBgUrl =
          (_themeConfig['screenThemes'] as Map<String, dynamic>?)?[configKey];
    }
    final pendingBytes = _pendingUploads[configKey];
    final bool hasImage =
        pendingBytes != null ||
        (currentBgUrl != null && currentBgUrl.isNotEmpty);
    final String colorText = _screenColorCtrls[keyPrefix]?.text.trim() ?? '';
    final bool hasColor = colorText.isNotEmpty;
    final String primaryTextColor =
        _screenTextColorCtrls[keyPrefix]?.text.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  // Mode Indicator Badge
                  if (hasImage)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, color: Colors.blueAccent, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Image Mode',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (hasColor)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purpleAccent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.palette,
                            color: Colors.purpleAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Color Mode ($colorText)',
                            style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.style, color: Colors.grey, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Default Theme',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  if (primaryTextColor.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.tealAccent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.format_color_text,
                              color: Colors.tealAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Text: $primaryTextColor',
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildColorInput(
                      'Background Color (Hex)',
                      _screenColorCtrls[keyPrefix]!,
                    ),
                    const SizedBox(height: 20),
                    _buildImageUploaderSection(
                      'Background Image (Overrides Color)',
                      configKey,
                      isNestedInScreenThemes: true,
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'Screen Text Colors (Real-Time)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set custom font colors to ensure high contrast and readability on this background.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    _buildColorInput(
                      'Primary Text Color (Hex) — Headings, Active Tabs, Titles',
                      _screenTextColorCtrls[keyPrefix]!,
                    ),
                    const SizedBox(height: 16),
                    _buildColorInput(
                      'Secondary Text Color (Hex) — Subtitles, Inactive Tabs, Details',
                      _screenSecondaryTextColorCtrls[keyPrefix]!,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Column: Live Interactive Preview Card
              _buildScreenLivePreview(title, keyPrefix, currentBgUrl, pendingBytes),
            ],
          ),
        ],
      ),
    );
  }

  Color? _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    final buffer = StringBuffer();
    final clean = hexString.replaceAll('#', '').trim();
    if (clean.length == 6) {
      buffer.write('ff');
      buffer.write(clean);
    } else if (clean.length == 8) {
      buffer.write(clean);
    } else {
      return null;
    }
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }

  Widget _buildScreenLivePreview(
    String title,
    String keyPrefix,
    String? currentBgUrl,
    Uint8List? pendingBytes,
  ) {
    final bgColor = _parseHexColor(_screenColorCtrls[keyPrefix]?.text) ??
        const Color(0xFF16161E);
    final primaryTextColor =
        _parseHexColor(_screenTextColorCtrls[keyPrefix]?.text) ?? Colors.white;
    final secondaryTextColor =
        _parseHexColor(_screenSecondaryTextColorCtrls[keyPrefix]?.text) ??
            Colors.white.withValues(alpha: 0.65);

    final bool hasImage =
        pendingBytes != null || (currentBgUrl != null && currentBgUrl.isNotEmpty);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview header badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.blue[900]?.withValues(alpha: 0.4),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.remove_red_eye_outlined,
                        size: 14, color: Colors.blueAccent),
                    SizedBox(width: 6),
                    Text(
                      'Live Screen Preview',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Real-Time',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Mock Phone Screen Area
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: bgColor,
              image: hasImage
                  ? (pendingBytes != null
                      ? DecorationImage(
                          image: MemoryImage(pendingBytes),
                          fit: BoxFit.cover,
                        )
                      : DecorationImage(
                          image: NetworkImage(currentBgUrl!),
                          fit: BoxFit.cover,
                        ))
                  : null,
            ),
            child: Container(
              color: Colors.black.withValues(alpha: hasImage ? 0.35 : 0.0),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fake App Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.notifications_none,
                              size: 18, color: primaryTextColor),
                          const SizedBox(width: 8),
                          Icon(Icons.search,
                              size: 18, color: primaryTextColor),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Mock Tab Bar
                  Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            'Active Tab',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: 2,
                            width: 30,
                            color: primaryTextColor,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Inactive Tab',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Sample Content Card
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary Title & Text',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Secondary subtitle description with live contrast preview.',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildLeaderboardTab() {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Sender'),
              Tab(text: 'Receiver'),
              Tab(text: 'Room'),
              Tab(text: 'Supporter'),
              Tab(text: 'Family'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildLeaderboardCategorySection('sender'),
                _buildLeaderboardCategorySection('receiver'),
                _buildLeaderboardCategorySection('room'),
                _buildLeaderboardCategorySection('supporter'),
                _buildLeaderboardCategorySection('family'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCategorySection(String category) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category == 'sender') ...[
            _buildColorInput(
              'Global Leaderboard Background Color (Hex)',
              _screenColorCtrls['leaderboard']!,
            ),
            const SizedBox(height: 20),
            _buildImageUploaderSection(
              'Global Leaderboard Background Theme Picture (Overrides Color)',
              'leaderboardBgUrl',
            ),
            const SizedBox(height: 24),
            _buildColorInput(
              'Global Leaderboard Primary Text Color (Hex)',
              _screenTextColorCtrls['leaderboard']!,
            ),
            const SizedBox(height: 16),
            _buildColorInput(
              'Global Leaderboard Secondary Text Color (Hex)',
              _screenSecondaryTextColorCtrls['leaderboard']!,
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),
          ],
          _buildImageUploaderSection(
            'Top 1 Frame ($category)',
            '${category}_rank1_url',
            isNestedInLeaderboardFrames: true,
          ),
          const SizedBox(height: 24),
          _buildImageUploaderSection(
            'Top 2 Frame ($category)',
            '${category}_rank2_url',
            isNestedInLeaderboardFrames: true,
          ),
          const SizedBox(height: 24),
          _buildImageUploaderSection(
            'Top 3 Frame ($category)',
            '${category}_rank3_url',
            isNestedInLeaderboardFrames: true,
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildColorInput(String label, TextEditingController controller) {
    // List of predefined beautiful colors
    final List<Color> presetColors = [
      const Color(0xFF1A1A2E), // Dark Navy
      const Color(0xFF16213E), // Deep Blue
      const Color(0xFF0F3460), // Royal Blue
      const Color(0xFFE94560), // Vibrant Red
      const Color(0xFF1E1E1E), // Dark Grey
      const Color(0xFF000000), // Black
      const Color(0xFFFFFFFF), // White
      const Color(0xFF2E0249), // Deep Purple
      const Color(0xFF570A57), // Purple
      const Color(0xFFA91079), // Magenta
      const Color(0xFFF806CC), // Pink
      const Color(0xFF005082), // Ocean Blue
      const Color(0xFF00A8CC), // Cyan
      const Color(0xFF11999E), // Teal
      const Color(0xFF40514E), // Slate
      const Color(0xFF2C3E50), // Midnight Blue
      const Color(0xFFE74C3C), // Alizarin
      const Color(0xFF9B59B6), // Amethyst
    ];

    final Color? activeParsedColor = _parseHexColor(controller.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 350,
          child: TextField(
            controller: controller,
            onChanged: (val) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '#000000',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: activeParsedColor != null
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: activeParsedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 1.5),
                        ),
                      ),
                    )
                  : const Icon(Icons.colorize, color: Colors.grey, size: 20),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      tooltip: 'Clear Color',
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Or choose a preset color:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (controller.text.isNotEmpty) ...[
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  controller.clear();
                  setState(() {});
                },
                child: const Text(
                  'Clear / Remove Color',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presetColors.map((color) {
              return InkWell(
                onTap: () {
                  // Convert color to hex string and set to controller
                  final hex =
                      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                  controller.text = hex;
                  setState(() {});
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[600]!, width: 1),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploaderSection(
    String label,
    String configKey, {
    bool isNestedInScreenThemes = false,
    bool isNestedInLeaderboardFrames = false,
  }) {
    String? currentUrl;
    if (configKey == 'leaderboardBgUrl') {
      currentUrl = _themeConfig['leaderboardBgUrl'] ??
          (_themeConfig['screenThemes'] as Map<String, dynamic>?)?['leaderboardBgUrl'] ??
          (_themeConfig['leaderboardFrames'] as Map<String, dynamic>?)?['backgroundUrl'];
    } else if (isNestedInScreenThemes) {
      currentUrl =
          (_themeConfig['screenThemes'] as Map<String, dynamic>?)?[configKey];
    } else if (isNestedInLeaderboardFrames) {
      currentUrl =
          (_themeConfig['leaderboardFrames']
              as Map<String, dynamic>?)?[configKey];
    } else {
      currentUrl = _themeConfig[configKey];
    }

    final pendingBytes = _pendingUploads[configKey];
    final bool hasImage =
        pendingBytes != null || (currentUrl != null && currentUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(
                  color: hasImage
                      ? Colors.blue.withValues(alpha: 0.5)
                      : Colors.grey[800]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: pendingBytes != null
                  ? (_pendingUploadFileNames[configKey]?.toLowerCase().endsWith('.svga') == true
                      ? Container(
                          color: Colors.grey[850],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.animation, color: Colors.amberAccent, size: 40),
                                SizedBox(height: 6),
                                Text(
                                  'SVGA File Selected',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '(Pending Save)',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Image.memory(pendingBytes, fit: BoxFit.contain))
                  : (currentUrl != null && currentUrl.isNotEmpty)
                  ? MediaPreviewWidget(
                      url: currentUrl,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey,
                            size: 36,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'No Image',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            '(Image Removed)',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(configKey),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(hasImage ? 'Change Image' : 'Select Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (hasImage)
                      ElevatedButton.icon(
                        onPressed: () => _removeImage(
                          configKey,
                          isNestedInScreenThemes: isNestedInScreenThemes,
                          isNestedInLeaderboardFrames:
                              isNestedInLeaderboardFrames,
                        ),
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('Remove Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (pendingBytes != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '⚡ Pending Upload (Click "Save All Changes")',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (currentUrl != null && currentUrl.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '✅ Current Live Image Active',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '⚪ Image Disabled / Removed (Color Only)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomAndControlsIconsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bottom Bar Control Icons',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure the bottom bar action icons. Leave empty to use default local assets.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildImageUploaderSection(
                  'Gift Box Bottom Button',
                  'giftBoxIconUrl',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildImageUploaderSection(
                  'Game Wall Bottom Button',
                  'gameWallIconUrl',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),
          const Text(
            'Room Settings Pop-up Icons',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure the icons inside the "Room Settings" panel. Leave empty to use default material icons.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 1.8,
            children: [
              _buildRoomSettingIconUploader('Edit Room Icon', 'edit_room'),
              _buildRoomSettingIconUploader('YouTube Icon', 'youtube'),
              _buildRoomSettingIconUploader('Ludo Game Icon', 'ludo_game'),
              _buildRoomSettingIconUploader('Voting Icon', 'voting'),
              _buildRoomSettingIconUploader('Roulette Icon', 'roulette'),
              _buildRoomSettingIconUploader('Clear Chat Icon', 'clear_chat'),
              _buildRoomSettingIconUploader('Admins Icon', 'admins'),
              _buildRoomSettingIconUploader('Seat Lock Icon', 'seat_lock'),
              _buildRoomSettingIconUploader('PK Battle Icon', 'pk_battle'),
              _buildRoomSettingIconUploader(
                'Music Player Icon',
                'music_player',
              ),
              _buildRoomSettingIconUploader('Live Mode Icon', 'live_mode'),
              _buildRoomSettingIconUploader('Room Decor Icon', 'room_decor'),
              _buildRoomSettingIconUploader('Room Mode Icon', 'room_mode'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSettingIconUploader(String label, String iconKey) {
    String? currentUrl =
        (_themeConfig['roomSettingsIcons'] as Map<String, dynamic>?)?[iconKey];
    final String pendingKey = 'roomSettingsIcon_$iconKey';
    final pendingBytes = _pendingUploads[pendingKey];
    final bool hasImage =
        pendingBytes != null || (currentUrl != null && currentUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(
                  color: hasImage
                      ? Colors.blue.withValues(alpha: 0.5)
                      : Colors.grey[800]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: pendingBytes != null
                  ? (_pendingUploadFileNames[pendingKey]?.toLowerCase().endsWith('.svga') == true
                      ? Container(
                          color: Colors.grey[850],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.animation, color: Colors.amberAccent, size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'SVGA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Image.memory(pendingBytes, fit: BoxFit.contain))
                  : (currentUrl != null && currentUrl.isNotEmpty)
                  ? MediaPreviewWidget(
                      url: currentUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(pendingKey),
                    icon: const Icon(Icons.upload_file, size: 14),
                    label: Text(
                      hasImage ? 'Change' : 'Upload',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  if (hasImage) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _pendingUploads.remove(pendingKey);
                          _pendingUploadFileNames.remove(pendingKey);
                          _themeConfig['roomSettingsIcons'] ??= {};
                          _themeConfig['roomSettingsIcons'][iconKey] = '';
                        });
                      },
                      icon: const Icon(Icons.delete_forever, size: 14),
                      label: const Text(
                        'Remove',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[850],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBarIconsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Main Navigation & Top Bar Header Icons',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure custom icons for top bar actions (Search, Trophy) and bottom tab navigation. Supports SVGA, GIF, WEBP, PNG, JPG.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Text(
            'Top Bar Header Action Icons',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'These icons appear at the top-right of the Home/Party screen next to Mine, All, Party, Live tabs.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildImageUploaderSection(
                  'Search Icon (Top Bar)',
                  'searchIconUrl',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildImageUploaderSection(
                  'Trophy / Top Rankings Icon (Top Bar)',
                  'trophyIconUrl',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          const Text(
            'Bottom Navigation Tab Bar Icons',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'These icons appear on the main bottom navigation tab bar.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildImageUploaderSection('Chat Tab Icon', 'tabChatIconUrl'),
          const SizedBox(height: 24),
          _buildImageUploaderSection(
            'Home / Voice Room Tab Icon',
            'tabHomeIconUrl',
          ),
          const SizedBox(height: 24),
          _buildImageUploaderSection(
            'Explore / News Feed Tab Icon',
            'tabGlobeIconUrl',
          ),
          const SizedBox(height: 24),
          _buildImageUploaderSection('Contacts Tab Icon', 'tabContactsIconUrl'),
        ],
      ),
    );
  }

  // --- TAB 7: WALLET & PROFILE SCREEN ICONS ---

  Widget _buildWalletAndProfileIconsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Information & Instructions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue[900]!.withValues(alpha: 0.5),
                            Colors.purple[900]!.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.amberAccent, size: 32),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'App Wallet & Profile Screen Custom Icons',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'এখানে আপলোড করা সকল লোগো এবং আইকনগুলো মোবাইল অ্যাপের Wallet ও Profile (Me) স্ক্রিনে রিয়েলটাইমে পরিবর্তন হবে। Supports PNG, JPG, WEBP, GIF, and SVGA animation.',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right: Live Phone Mockup Preview
              _buildWalletLivePreviewCard(),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),

          // --- SECTION 1: ALL 15 GRID MENU ICONS ---
          const Row(
            children: [
              Icon(Icons.grid_view_rounded, color: Colors.blueAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'Wallet & Profile Menu Grid Action Icons (15 Items)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'স্ক্রিনশটে প্রদর্শিত ১৫টি অ্যাকশন মেনু আইকনসমূহ:',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 1.75,
            children: [
              _buildWalletIconUploader('1. My Level (লেভেল)', 'my_level', defaultIcon: Icons.military_tech),
              _buildWalletIconUploader('2. Store (স্টোর)', 'store', defaultIcon: Icons.shopping_bag),
              _buildWalletIconUploader('3. Badge (ব্যাজ)', 'badge', defaultIcon: Icons.verified),
              _buildWalletIconUploader('4. My Items (আমার আইটেম)', 'my_items', defaultIcon: Icons.inventory_2),
              _buildWalletIconUploader('5. Family (ফ্যামিলি)', 'family', defaultIcon: Icons.groups),
              _buildWalletIconUploader('6. Agency Manager (এজেন্সি ম্যানেজার)', 'agency_manager', defaultIcon: Icons.assignment_ind),
              _buildWalletIconUploader('7. Host Centre (হোস্ট সেন্টার)', 'host_centre', defaultIcon: Icons.mic_external_on),
              _buildWalletIconUploader('8. Game Wall (গেম ওয়াল)', 'game_wall', defaultIcon: Icons.sports_esports),
              _buildWalletIconUploader('9. Admin Dashboard (এডমিন ড্যাশবোর্ড)', 'admin_dashboard', defaultIcon: Icons.admin_panel_settings),
              _buildWalletIconUploader('10. Diamondseller (ডায়মন্ড সেলার)', 'diamond_seller', defaultIcon: Icons.monetization_on),
              _buildWalletIconUploader('11. Invite (ইনভাইট)', 'invite', defaultIcon: Icons.person_add),
              _buildWalletIconUploader('12. Offline Seller (অফলাইন সেলার)', 'offline_seller', defaultIcon: Icons.wifi_off),
              _buildWalletIconUploader('13. Setting (সেটিংস)', 'setting', defaultIcon: Icons.settings),
              _buildWalletIconUploader('14. Help (হেল্প)', 'help', defaultIcon: Icons.help_outline),
              _buildWalletIconUploader('15. About (অ্যাবাউট)', 'about', defaultIcon: Icons.info_outline),
            ],
          ),

          const SizedBox(height: 36),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),

          // --- SECTION 2: VIP & PRIVILEGES BADGES ---
          const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amberAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'VIP & SVIP Privilege Banner Badges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure the VIP and SVIP badges displayed on the top privileges cards.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 2.1,
            children: [
              _buildWalletIconUploader('imChat VIP Badge / Privilege Icon', 'vip_badge', defaultIcon: Icons.shield),
              _buildWalletIconUploader('imChat SVIP Badge / Privilege Icon', 'svip_badge', defaultIcon: Icons.stars),
            ],
          ),

          const SizedBox(height: 36),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),

          // --- SECTION 3: WALLET BALANCES & HEADER ASSETS ---
          const Row(
            children: [
              Icon(Icons.paid, color: Colors.tealAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'Wallet Balances & Profile Header Icons',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure Diamonds, Beans, User Level Badge, and Navigation icons.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 1.75,
            children: [
              _buildWalletIconUploader('Diamonds Balance Icon', 'wallet_diamonds', defaultIcon: Icons.diamond),
              _buildWalletIconUploader('Beans Balance Icon', 'wallet_beans', defaultIcon: Icons.monetization_on),
              _buildWalletIconUploader('User Level Badge (Lv.11)', 'level_badge_icon', defaultIcon: Icons.shield_outlined),
              _buildWalletIconUploader('Copy ID Icon', 'id_copy_icon', defaultIcon: Icons.copy),
              _buildWalletIconUploader('Navigation Arrow Icon', 'arrow_nav_icon', defaultIcon: Icons.chevron_right),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletIconUploader(
    String label,
    String iconKey, {
    IconData defaultIcon = Icons.image,
  }) {
    String? currentUrl =
        (_themeConfig['walletMenuIcons'] as Map<String, dynamic>?)?[iconKey] ??
        (_themeConfig['profileMenuIcons'] as Map<String, dynamic>?)?[iconKey];

    // Fallback check if diamonds or beans icon is set globally
    if ((currentUrl == null || currentUrl.isEmpty)) {
      if (iconKey == 'wallet_diamonds') {
        currentUrl = _themeConfig['diamondIconUrl'];
      } else if (iconKey == 'wallet_beans') {
        currentUrl = _themeConfig['beansIconUrl'];
      }
    }

    final String pendingKey = 'walletMenuIcon_$iconKey';
    final pendingBytes = _pendingUploads[pendingKey];
    final bool hasImage =
        pendingBytes != null || (currentUrl != null && currentUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(
                  color: hasImage
                      ? Colors.blue.withValues(alpha: 0.6)
                      : Colors.grey[800]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: pendingBytes != null
                  ? (_pendingUploadFileNames[pendingKey]?.toLowerCase().endsWith('.svga') == true
                      ? Container(
                          color: Colors.grey[850],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.animation, color: Colors.amberAccent, size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'SVGA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Image.memory(pendingBytes, fit: BoxFit.contain))
                  : (currentUrl != null && currentUrl.isNotEmpty)
                  ? MediaPreviewWidget(
                      url: currentUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(defaultIcon, color: Colors.grey[600], size: 30),
                          const SizedBox(height: 4),
                          Text(
                            'Default',
                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(pendingKey),
                    icon: const Icon(Icons.upload_file, size: 14),
                    label: Text(
                      hasImage ? 'Change' : 'Upload',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                  if (hasImage) ...[
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _pendingUploads.remove(pendingKey);
                          _pendingUploadFileNames.remove(pendingKey);
                          _themeConfig['walletMenuIcons'] ??= {};
                          _themeConfig['walletMenuIcons'][iconKey] = '';
                          _themeConfig['profileMenuIcons'] ??= {};
                          _themeConfig['profileMenuIcons'][iconKey] = '';
                        });
                      },
                      icon: const Icon(Icons.delete_forever, size: 14),
                      label: const Text(
                        'Remove',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[850],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- LIVE WALLET & PROFILE PHONE PREVIEW ---

  Widget _getLiveIconWidget(
    String iconKey,
    IconData fallbackIcon, {
    Color fallbackColor = Colors.purpleAccent,
    double size = 26,
  }) {
    final String pendingKey = 'walletMenuIcon_$iconKey';
    final pendingBytes = _pendingUploads[pendingKey];
    String? currentUrl =
        (_themeConfig['walletMenuIcons'] as Map<String, dynamic>?)?[iconKey] ??
        (_themeConfig['profileMenuIcons'] as Map<String, dynamic>?)?[iconKey];

    if ((currentUrl == null || currentUrl.isEmpty)) {
      if (iconKey == 'wallet_diamonds') {
        currentUrl = _themeConfig['diamondIconUrl'];
      } else if (iconKey == 'wallet_beans') {
        currentUrl = _themeConfig['beansIconUrl'];
      }
    }

    if (pendingBytes != null) {
      if (_pendingUploadFileNames[pendingKey]?.toLowerCase().endsWith('.svga') == true) {
        return Icon(Icons.animation, color: Colors.amberAccent, size: size);
      }
      return Image.memory(pendingBytes, width: size, height: size, fit: BoxFit.contain);
    }

    if (currentUrl != null && currentUrl.isNotEmpty) {
      return MediaPreviewWidget(
        url: currentUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Icon(fallbackIcon, color: fallbackColor, size: size);
  }

  Widget _buildWalletLivePreviewCard() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.blue[900],
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_android, size: 14, color: Colors.blueAccent),
                    SizedBox(width: 6),
                    Text(
                      'Live Screen Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Real-Time',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Phone Body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top User Header Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.amber[300],
                      child: const Icon(Icons.person, color: Colors.black87),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Boss',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.chevron_right, size: 16, color: Colors.black45),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                'ID : 880',
                                style: TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                              const SizedBox(width: 4),
                              _getLiveIconWidget('id_copy_icon', Icons.copy, fallbackColor: Colors.black45, size: 12),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.teal[400],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Lv.11',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // VIP & SVIP Privilege Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C1810), Color(0xFF1A1020)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'imChat VIP',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  Text(
                                    'Privileges',
                                    style: TextStyle(color: Colors.white70, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                            _getLiveIconWidget('vip_badge', Icons.shield, fallbackColor: Colors.amberAccent, size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E1030), Color(0xFF101B2E)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'imChat SVIP',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  Text(
                                    '15 Privileges',
                                    style: TextStyle(color: Colors.white70, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                            _getLiveIconWidget('svip_badge', Icons.stars, fallbackColor: Colors.cyanAccent, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Diamonds & Beans Balance Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _getLiveIconWidget('wallet_diamonds', Icons.diamond, fallbackColor: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '3,694,527',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Diamonds >',
                              style: TextStyle(color: Colors.pinkAccent, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 28, width: 1, color: Colors.grey[200]),
                      const SizedBox(width: 8),
                      _getLiveIconWidget('wallet_beans', Icons.monetization_on, fallbackColor: Colors.orangeAccent, size: 28),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '49,126',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Beans >',
                              style: TextStyle(color: Colors.orange, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Grid Menu 1 (8 items)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPreviewGridItem('My Level', 'my_level', Icons.military_tech, Colors.pinkAccent),
                          _buildPreviewGridItem('Store', 'store', Icons.shopping_bag, Colors.amber),
                          _buildPreviewGridItem('Badge', 'badge', Icons.verified, Colors.amberAccent),
                          _buildPreviewGridItem('My Items', 'my_items', Icons.inventory_2, Colors.purpleAccent),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPreviewGridItem('Family', 'family', Icons.groups, Colors.cyan),
                          _buildPreviewGridItem('Agency', 'agency_manager', Icons.assignment_ind, Colors.pinkAccent),
                          _buildPreviewGridItem('Host Centre', 'host_centre', Icons.mic_external_on, Colors.tealAccent),
                          _buildPreviewGridItem('Game Wall', 'game_wall', Icons.sports_esports, Colors.purpleAccent),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Grid Menu 2 (7 items)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPreviewGridItem('Admin', 'admin_dashboard', Icons.admin_panel_settings, Colors.purpleAccent),
                          _buildPreviewGridItem('Diamond seller', 'diamond_seller', Icons.monetization_on, Colors.amber),
                          _buildPreviewGridItem('Invite', 'invite', Icons.person_add, Colors.amberAccent),
                          _buildPreviewGridItem('Offline', 'offline_seller', Icons.wifi_off, Colors.cyan),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPreviewGridItem('Setting', 'setting', Icons.settings, Colors.cyan),
                          _buildPreviewGridItem('Help', 'help', Icons.help_outline, Colors.amber),
                          _buildPreviewGridItem('About', 'about', Icons.info_outline, Colors.grey),
                          const SizedBox(width: 54), // spacer
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewGridItem(
    String label,
    String iconKey,
    IconData fallbackIcon,
    Color fallbackColor,
  ) {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          _getLiveIconWidget(iconKey, fallbackIcon, fallbackColor: fallbackColor, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

