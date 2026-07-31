import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../services/app_theme_admin_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/media_preview_widget.dart';

class AppThemeManagementScreen extends StatefulWidget {
  const AppThemeManagementScreen({super.key});

  @override
  State<AppThemeManagementScreen> createState() => _AppThemeManagementScreenState();
}

class _AppThemeManagementScreenState extends State<AppThemeManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // Configuration State
  Map<String, dynamic> _themeConfig = {};
  
  // Pending Uploads State (Key: config key, Value: file bytes)
  final Map<String, Uint8List> _pendingUploads = {};
  
  // Text Controllers for Colors
  final TextEditingController _splashColorCtrl = TextEditingController();
  final Map<String, TextEditingController> _screenColorCtrls = {
    'home': TextEditingController(),
    'profile': TextEditingController(),
    'room': TextEditingController(),
    'leaderboard': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _splashColorCtrl.dispose();
    for (var ctrl in _screenColorCtrls.values) {
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
        
        final screenThemes = _themeConfig['screenThemes'] as Map<String, dynamic>? ?? {};
        _screenColorCtrls['home']?.text = screenThemes['homeColor'] ?? '';
        _screenColorCtrls['profile']?.text = screenThemes['profileColor'] ?? '';
        _screenColorCtrls['room']?.text = screenThemes['roomColor'] ?? '';
        
        final leaderboardFrames = _themeConfig['leaderboardFrames'] as Map<String, dynamic>? ?? {};
        _screenColorCtrls['leaderboard']?.text = leaderboardFrames['backgroundColor'] ?? '';
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
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _pendingUploads[configKey] = result.files.single.bytes!;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _removeImage(String configKey, {bool isNestedInScreenThemes = false, bool isNestedInLeaderboardFrames = false}) {
    setState(() {
      _pendingUploads.remove(configKey);
      if (isNestedInScreenThemes) {
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
        final folder = key.split('_').first; // e.g., appLogoUrl -> app, sender_rank1_url -> sender
        final url = await AppThemeAdminService.uploadImage(bytes, folder);
        
        // Update local config map before saving to Firestore
        if (key.startsWith('sender_') || key.startsWith('receiver_') || key.startsWith('room_') || key.startsWith('supporter_') || key.startsWith('family_')) {
          _themeConfig['leaderboardFrames'] ??= {};
          _themeConfig['leaderboardFrames'][key] = url;
        } else if (key.endsWith('BgUrl')) {
           _themeConfig['screenThemes'] ??= {};
           _themeConfig['screenThemes'][key] = url;
        } else {
          _themeConfig[key] = url;
        }
      }

      // Update colors from controllers
      _themeConfig['splashColor'] = _splashColorCtrl.text.trim();
      
      _themeConfig['screenThemes'] ??= {};
      _themeConfig['screenThemes']['homeColor'] = _screenColorCtrls['home']!.text.trim();
      _themeConfig['screenThemes']['profileColor'] = _screenColorCtrls['profile']!.text.trim();
      _themeConfig['screenThemes']['roomColor'] = _screenColorCtrls['room']!.text.trim();
      
      _themeConfig['leaderboardFrames'] ??= {};
      _themeConfig['leaderboardFrames']['backgroundColor'] = _screenColorCtrls['leaderboard']!.text.trim();

      // Save to Firestore
      await AppThemeAdminService.updateThemeConfig(_themeConfig);
      
      _pendingUploads.clear(); // Clear pending uploads
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'App Theme & Assets Management',
      actions: [
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAll,
          icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
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
          _buildColorInput('Splash Screen Background Color (Hex)', _splashColorCtrl),
          const SizedBox(height: 32),
          _buildImageUploaderSection('Splash Screen Center Image', 'splashImageUrl'),
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
          const Text('You can define a background color OR upload a background image for specific screens. Background images override colors when uploaded.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildScreenThemeSection('Home Screen', 'home'),
          const Divider(height: 48, color: Colors.grey),
          _buildScreenThemeSection('Profile Screen', 'profile'),
          const Divider(height: 48, color: Colors.grey),
          _buildScreenThemeSection('Audio Room Screen', 'room'),
        ],
      ),
    );
  }

  Widget _buildScreenThemeSection(String title, String keyPrefix) {
    final String configKey = '${keyPrefix}BgUrl';
    String? currentBgUrl = (_themeConfig['screenThemes'] as Map<String, dynamic>?)?[configKey];
    final pendingBytes = _pendingUploads[configKey];
    final bool hasImage = pendingBytes != null || (currentBgUrl != null && currentBgUrl.isNotEmpty);
    final String colorText = _screenColorCtrls[keyPrefix]?.text.trim() ?? '';
    final bool hasColor = colorText.isNotEmpty;

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
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              // Mode Indicator Badge
              if (hasImage)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image, color: Colors.blueAccent, size: 14),
                      SizedBox(width: 6),
                      Text('Image Mode (Overrides Color)', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else if (hasColor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purpleAccent)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.palette, color: Colors.purpleAccent, size: 14),
                      const SizedBox(width: 6),
                      Text('Color Mode Only ($colorText)', style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.style, color: Colors.grey, size: 14),
                      SizedBox(width: 6),
                      Text('Default App Theme Active', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildColorInput('Background Color (Hex)', _screenColorCtrls[keyPrefix]!),
          const SizedBox(height: 20),
          _buildImageUploaderSection('Background Image (Overrides Color)', configKey, isNestedInScreenThemes: true),
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
            _buildColorInput('Global Leaderboard Background Color (Hex)', _screenColorCtrls['leaderboard']!),
            const SizedBox(height: 24),
          ],
          _buildImageUploaderSection('Top 1 Frame ($category)', '${category}_rank1_url', isNestedInLeaderboardFrames: true),
          const SizedBox(height: 24),
          _buildImageUploaderSection('Top 2 Frame ($category)', '${category}_rank2_url', isNestedInLeaderboardFrames: true),
          const SizedBox(height: 24),
          _buildImageUploaderSection('Top 3 Frame ($category)', '${category}_rank3_url', isNestedInLeaderboardFrames: true),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
            const Text('Or choose a preset color:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            if (controller.text.isNotEmpty) ...[
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  controller.clear();
                  setState(() {});
                },
                child: const Text('Clear / Remove Color', style: TextStyle(color: Colors.redAccent, fontSize: 12, decoration: TextDecoration.underline)),
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
                  final hex = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
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

  Widget _buildImageUploaderSection(String label, String configKey, {bool isNestedInScreenThemes = false, bool isNestedInLeaderboardFrames = false}) {
    String? currentUrl;
    if (isNestedInScreenThemes) {
      currentUrl = (_themeConfig['screenThemes'] as Map<String, dynamic>?)?[configKey];
    } else if (isNestedInLeaderboardFrames) {
      currentUrl = (_themeConfig['leaderboardFrames'] as Map<String, dynamic>?)?[configKey];
    } else {
      currentUrl = _themeConfig[configKey];
    }

    final pendingBytes = _pendingUploads[configKey];
    final bool hasImage = pendingBytes != null || (currentUrl != null && currentUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(color: hasImage ? Colors.blue.withValues(alpha: 0.5) : Colors.grey[800]!),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: pendingBytes != null
                  ? Image.memory(pendingBytes, fit: BoxFit.contain)
                  : (currentUrl != null && currentUrl.isNotEmpty)
                      ? MediaPreviewWidget(url: currentUrl, width: 150, height: 150, fit: BoxFit.contain)
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 36),
                              SizedBox(height: 6),
                              Text('No Image', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('(Image Removed)', style: TextStyle(color: Colors.grey, fontSize: 10)),
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
                          isNestedInLeaderboardFrames: isNestedInLeaderboardFrames,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Text('⚡ Pending Upload (Click "Save All Changes")', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ] else if (currentUrl != null && currentUrl.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Text('✅ Current Live Image Active', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Text('⚪ Image Disabled / Removed (Color Only)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

