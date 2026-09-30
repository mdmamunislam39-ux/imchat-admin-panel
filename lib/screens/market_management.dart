import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_item_model.dart';
import '../services/user_profile_service.dart';
import '../services/official_items_service.dart';
import '../models/official_item_model.dart';
import '../widgets/media_preview_widget.dart';
import '../services/room_decoration_admin_service.dart';
import '../widgets/golden_seat_widget.dart';

class MarketManagement extends StatefulWidget {
  const MarketManagement({super.key});

  @override
  State<MarketManagement> createState() => _MarketManagementState();
}

class _MarketManagementState extends State<MarketManagement>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  List<StoreItemModel> _marketItems = [];
  bool _isLoading = true;
  StoreItemType? _selectedType;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _loadData();
    _animationController.forward();
  }

  StreamSubscription<List<StoreItemModel>>? _marketItemsSubscription;

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _marketItemsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Ensure all items have a displayId assigned
      await OfficialItemsService.ensureAllItemsHaveIds();
      // Ensure all free and built-in seat decors are synced in real-time
      await RoomDecorationAdminService.syncFreeSeatDecorToStore();

      _marketItemsSubscription = UserProfileService.streamAllMarketItems().listen(
        (items) {
          if (mounted) {
            setState(() {
              _marketItems = items;
              _isLoading = false;
            });
          }
        },
        onError: (e) {
          debugPrint('Error streaming market data: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showErrorSnackBar('Failed to load market data');
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing market data stream: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to initialize market data');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  Color _getAnimationColorValue(String colorKey) {
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

  String _getAnimationTypeName(String? type) {
    switch (type) {
      case 'beamSweep':
      case 'lightBeam':
      case 'lightBeamSweep':
        return 'Laser Light Beam Sweep';
      case 'neonPulse':
        return 'Breathing Neon Pulse';
      case 'starSparkle':
        return 'Orbiting Star Sparkles';
      case 'rippleWave':
        return 'Cyber Sonar Ripple';
      case 'goldenShimmer':
        return 'Holographic Shimmer';
      case 'rotatingRing':
      default:
        return '360° Rotating Neon Ring';
    }
  }

  Future<void> _quickToggleSeatAnimation(StoreItemModel item, bool isAnimated) async {
    try {
      final updatedItem = item.copyWith(
        isAnimated: isAnimated,
        updatedAt: DateTime.now(),
      );
      await UserProfileService.updateStoreItem(updatedItem);
      try {
        await FirebaseFirestore.instance
            .collection('official_items')
            .doc(item.id)
            .update({
          'isAnimated': isAnimated,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
      _loadData();
      _showSuccessSnackBar(
        isAnimated
            ? '⚡ Seat Animation ACTIVATED for "${item.name}"'
            : '⚪ Seat Animation DEACTIVATED for "${item.name}"',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update animation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          '🛍️ Market Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildBadgesTab(),
                      _buildFramesTab(),
                      _buildEffectsTab(),
                      _buildSkinsTab(),
                      _buildRoomsTab(),
                      _buildSeatDecorTab(),
                      _buildRoomProfileBackgroundsTab(),
                      _buildShortProfileThemesTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.blue,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
          Tab(icon: Icon(Icons.photo), text: 'Frames'),
          Tab(icon: Icon(Icons.auto_awesome), text: 'Effects'),
          Tab(icon: Icon(Icons.portrait), text: 'Skins'),
          Tab(icon: Icon(Icons.palette), text: 'Rooms'),
          Tab(icon: Icon(Icons.chair), text: 'Seat Decor'),
          Tab(icon: Icon(Icons.wallpaper), text: 'RP Background'),
          Tab(icon: Icon(Icons.portrait_sharp), text: 'Short Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '🔍 Search items...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: _showFilters ? Colors.blue : Colors.grey,
                ),
                onPressed: _toggleFilters,
                tooltip: 'Filters',
              ),
            ],
          ),

          // Filter Chips
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? 50 : 0,
            child: _showFilters
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', null),
                          const SizedBox(width: 8),
                          ...StoreItemType.values.map(
                            (type) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildFilterChip(
                                _getTypeDisplayName(type),
                                type,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, StoreItemType? type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
      selectedColor: Colors.blue.withValues(alpha: 0.3),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  String _getTypeDisplayName(StoreItemType type) {
    switch (type) {
      case StoreItemType.avatarFrame:
        return 'Frames';
      case StoreItemType.entryEffect:
        return 'Effects';
      case StoreItemType.badge:
        return 'Badges';
      case StoreItemType.backgroundTheme:
        return 'Room Background Themes';
      case StoreItemType.roomTheme:
        return 'Profile Skins';
      case StoreItemType.seatDecor:
        return 'Seat Decor';
      case StoreItemType.micRefill:
        return 'Mic Refills';
      case StoreItemType.roomProfileBackground:
        return 'RP Backgrounds';
      case StoreItemType.shortProfileTheme:
        return 'Short Profiles';
      case StoreItemType.roomEntry:
        return 'Room Entries';
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          const Text(
            'Market Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Items',
                  value: _marketItems.length.toString(),
                  icon: Icons.inventory,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Items',
                  value: _marketItems
                      .where((item) => item.isActive)
                      .length
                      .toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Badges',
                  value: _marketItems
                      .where((item) => item.type == StoreItemType.badge)
                      .length
                      .toString(),
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Frames',
                  value: _marketItems
                      .where((item) => item.type == StoreItemType.avatarFrame)
                      .length
                      .toString(),
                  icon: Icons.photo,
                  color: Colors.cyan,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Entry Effects',
                  value: _marketItems
                      .where((item) => item.type == StoreItemType.entryEffect)
                      .length
                      .toString(),
                  icon: Icons.auto_awesome,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Room Background Themes',
                  value: _marketItems
                      .where(
                        (item) => item.type == StoreItemType.backgroundTheme,
                      )
                      .length
                      .toString(),
                  icon: Icons.portrait,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Profile Skins',
                  value: _marketItems
                      .where((item) => item.type == StoreItemType.roomTheme)
                      .length
                      .toString(),
                  icon: Icons.palette,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Seat Decor',
                  value: _marketItems
                      .where((item) => item.type == StoreItemType.seatDecor)
                      .length
                      .toString(),
                  icon: Icons.chair,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Add Badge',
                  subtitle: 'Create new badge',
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                  onTap: () => _showAddItemDialog(StoreItemType.badge),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Add Frame',
                  subtitle: 'Create new frame',
                  icon: Icons.photo,
                  color: Colors.cyan,
                  onTap: () => _showAddItemDialog(StoreItemType.avatarFrame),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Add Entry Effect',
                  subtitle: 'Create new effect',
                  icon: Icons.auto_awesome,
                  color: Colors.pink,
                  onTap: () => _showAddItemDialog(StoreItemType.entryEffect),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Add Room Background Theme',
                  subtitle: 'Create new room background theme',
                  icon: Icons.portrait,
                  color: Colors.purple,
                  onTap: () =>
                      _showAddItemDialog(StoreItemType.backgroundTheme),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Add Profile Skin',
                  subtitle: 'Create new profile skin',
                  icon: Icons.palette,
                  color: Colors.teal,
                  onTap: () =>
                      _showAddItemDialog(StoreItemType.roomTheme),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Add Seat Decor',
                  subtitle: 'Create new seat decor',
                  icon: Icons.chair,
                  color: Colors.orange,
                  onTap: () =>
                      _showAddItemDialog(StoreItemType.seatDecor),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Add RP Background',
                  subtitle: 'Create room profile bg',
                  icon: Icons.wallpaper,
                  color: Colors.indigo,
                  onTap: () =>
                      _showAddItemDialog(StoreItemType.roomProfileBackground),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    final badges = _marketItems
        .where((item) => item.type == StoreItemType.badge)
        .toList();
    return _buildItemsList(badges);
  }

  Widget _buildFramesTab() {
    final frames = _marketItems
        .where((item) => item.type == StoreItemType.avatarFrame)
        .toList();
    return _buildItemsList(frames);
  }

  Widget _buildEffectsTab() {
    final effects = _marketItems
        .where((item) => item.type == StoreItemType.entryEffect)
        .toList();
    return _buildItemsList(effects);
  }

  Widget _buildSkinsTab() {
    final skins = _marketItems
        .where((item) => item.type == StoreItemType.backgroundTheme)
        .toList();
    return _buildItemsList(skins);
  }

  Widget _buildRoomsTab() {
    final rooms = _marketItems
        .where((item) => item.type == StoreItemType.roomTheme)
        .toList();
    return _buildItemsList(rooms);
  }

  Widget _buildSeatDecorTab() {
    final seatDecors = _marketItems
        .where((item) => item.type == StoreItemType.seatDecor)
        .toList();
    return _buildItemsList(seatDecors);
  }

  Widget _buildRoomProfileBackgroundsTab() {
    final bg = _marketItems
        .where((item) => item.type == StoreItemType.roomProfileBackground)
        .toList();
    return _buildItemsList(bg);
  }

  Widget _buildShortProfileThemesTab() {
    final bg = _marketItems
        .where((item) => item.type == StoreItemType.shortProfileTheme)
        .toList();
    return _buildItemsList(bg);
  }

  Widget _buildItemsList(List<StoreItemModel> items) {
    return items.isEmpty
        ? const Center(
            child: Text(
              'No items found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemCard(item);
            },
          );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.grey[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(StoreItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isActive ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(item.type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.typeIcon,
                    style: const TextStyle(fontSize: 24),
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
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.displayId != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: item.displayId.toString()),
                                );
                                _showSuccessSnackBar(
                                  'Copied ID ${item.displayId} to clipboard',
                                );
                              },
                              child: Tooltip(
                                message: 'Tap to copy ID',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ID: ${item.displayId}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.copy,
                                        color: Colors.blue,
                                        size: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.typeDisplayName,
                        style: TextStyle(
                          color: _getTypeColor(item.type),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: item.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // File Preview
            if (item.type == StoreItemType.seatDecor && (item.fileUrl.isNotEmpty || (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty) || (item.hostSeatDecorUrl != null && item.hostSeatDecorUrl!.isNotEmpty)))
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isAnimated
                        ? Colors.cyanAccent.withValues(alpha: 0.4)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    // 1. Host Seat
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                            ),
                            child: const Text('HOST SEAT', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Center(
                              child: AnimatedSeatDecorWidget(
                                isAnimated: item.isAnimated,
                                animationType: item.animationType,
                                animationSpeed: item.animationSpeed,
                                glowColor: _getAnimationColorValue(item.animationColor ?? 'cyan'),
                                size: 54,
                                child: MediaPreviewWidget(
                                  url: (item.hostSeatDecorUrl != null && item.hostSeatDecorUrl!.isNotEmpty)
                                      ? item.hostSeatDecorUrl!
                                      : (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty ? item.thumbnailUrl! : item.fileUrl),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 80, color: Colors.grey[700]),
                    // 2. Unlock Seat
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                            ),
                            child: const Text('UNLOCK SEAT', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Center(
                              child: AnimatedSeatDecorWidget(
                                isAnimated: item.isAnimated,
                                animationType: item.animationType,
                                animationSpeed: item.animationSpeed,
                                glowColor: _getAnimationColorValue(item.animationColor ?? 'cyan'),
                                size: 54,
                                child: MediaPreviewWidget(
                                  url: item.fileUrl.isNotEmpty
                                      ? item.fileUrl
                                      : (item.thumbnailUrl ?? ''),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 80, color: Colors.grey[700]),
                    // 3. Lock Seat
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                            ),
                            child: const Text('LOCK SEAT', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Center(
                              child: (item.lockedFileUrl != null && item.lockedFileUrl!.isNotEmpty)
                                  ? AnimatedSeatDecorWidget(
                                      isAnimated: item.isAnimated,
                                      animationType: item.animationType,
                                      animationSpeed: item.animationSpeed,
                                      glowColor: _getAnimationColorValue(item.animationColor ?? 'cyan'),
                                      size: 54,
                                      child: MediaPreviewWidget(
                                        url: item.lockedFileUrl!,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : const Icon(Icons.lock, color: Colors.white38, size: 28),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (item.fileUrl.isNotEmpty || (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty))
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      // PNG/Thumbnail Side
                      if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MediaPreviewWidget(
                                url: item.thumbnailUrl!,
                                fit: BoxFit.contain,
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('PNG', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (item.fileUrl.isNotEmpty && (item.fileType.toLowerCase().contains('png') || item.fileType.toLowerCase().contains('image')))
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MediaPreviewWidget(
                                url: item.fileUrl,
                                fit: BoxFit.contain,
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('PNG', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      // Divider if both exist
                      if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty && item.fileUrl.isNotEmpty && !item.fileType.toLowerCase().contains('png') && !item.fileType.toLowerCase().contains('image'))
                        Container(width: 1, color: Colors.grey[700]),
                        
                      // SVGA/File Side
                      if (item.fileUrl.isNotEmpty && (!item.fileType.toLowerCase().contains('png') && !item.fileType.toLowerCase().contains('image')))
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildFilePreview(item),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.fileType.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10)
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else if (item.type == StoreItemType.seatDecor)
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isAnimated
                        ? Colors.cyanAccent.withValues(alpha: 0.4)
                        : Colors.white12,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: AnimatedSeatDecorWidget(
                          isAnimated: item.isAnimated,
                          animationType: item.animationType,
                          animationSpeed: item.animationSpeed,
                          glowColor: _getAnimationColorValue(item.animationColor ?? 'cyan'),
                          size: 60,
                          child: _buildSeatDecorModePreview(item),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BUILT-IN / LIVE',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Seat Animation Status & Quick Toggle Bar ──
            if (item.type == StoreItemType.seatDecor) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: item.isAnimated
                      ? Colors.cyan.withValues(alpha: 0.12)
                      : Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: item.isAnimated
                        ? Colors.cyanAccent.withValues(alpha: 0.5)
                        : Colors.white12,
                    width: item.isAnimated ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: item.isAnimated ? Colors.cyanAccent : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.isAnimated
                                    ? '⚡ ANIMATION: ACTIVE'
                                    : '⚪ ANIMATION: DEACTIVATED',
                                style: TextStyle(
                                  color: item.isAnimated ? Colors.cyanAccent : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (item.isAnimated)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getAnimationColorValue(item.animationColor ?? 'cyan').withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getAnimationColorValue(item.animationColor ?? 'cyan'),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getAnimationTypeName(item.animationType),
                                    style: TextStyle(
                                      color: _getAnimationColorValue(item.animationColor ?? 'cyan'),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.isAnimated
                                ? 'সিটে লাইভ নিয়ন অরা ও স্পার্কল এনিমেশন চালু রয়েছে।'
                                : 'সিটে এনিমেশন বন্ধ আছে। চালু করতে টগল করুন।',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: item.isAnimated,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => _quickToggleSeatAnimation(item, val),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Price and Duration
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        item.diamondPrice <= 0
                            ? 'Free (0💎)'
                            : '${item.diamondPrice.toStringAsFixed(0)}💎',
                        style: TextStyle(
                          color: item.diamondPrice <= 0 ? Colors.greenAccent : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        item.expirationText,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'File Type',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        item.fileType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editItem(item),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleItemStatus(item),
                    icon: Icon(
                      item.isActive ? Icons.visibility_off : Icons.visibility,
                    ),
                    label: Text(item.isActive ? 'Deactivate' : 'Activate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isActive
                          ? Colors.red
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteItem(item),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(StoreItemModel item) {
    final type = item.fileType.toLowerCase();
    if (type.contains('image') ||
        type.contains('png') ||
        type.contains('jpg') ||
        type.contains('jpeg')) {
      return MediaPreviewWidget(
        url: item.fileUrl,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (item.fileType.toLowerCase() == 'svg') {
      return const Center(
        child: Icon(Icons.auto_awesome, color: Colors.blue, size: 50),
      );
    } else if (item.fileType.toLowerCase() == 'gif') {
      return const Center(
        child: Icon(Icons.animation, color: Colors.pink, size: 50),
      );
    } else if (item.fileType.toLowerCase() == 'mp4') {
      return const Center(
        child: Icon(Icons.videocam, color: Colors.red, size: 50),
      );
    } else {
      return const Center(
        child: Icon(Icons.insert_drive_file, color: Colors.grey, size: 50),
      );
    }
  }

  Widget _buildSeatDecorModePreview(StoreItemModel item) {
    final name = item.name.toLowerCase();
    final id = item.id.toLowerCase();
    
    if (id.contains('golden') || name.contains('golden') || name.contains('sofa')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFEA7A), Color(0xFFB8860B), Color(0xFF4A3500)],
                ),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.chair_rounded, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 14),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seat 1: HOST (Golden Sofa)',
                  style: TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Seats 2-N: Guest No.2, No.3...',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (id.contains('purple') || name.contains('purple')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFE085FF), Color(0xFF8A00E6), Color(0xFF380062)],
                ),
                border: Border.all(color: const Color(0xFFD466FF), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB026FF).withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.chair_rounded, color: Color(0xFFFFD700), size: 24),
            ),
            const SizedBox(width: 14),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seat 1: HOST (Neon Purple Sofa)',
                  style: TextStyle(color: Color(0xFFD466FF), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Seats 2-N: Guest No.2, No.3...',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (id.contains('pink') || name.contains('pink')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, color: Colors.pinkAccent, size: 36),
            SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashed Pink Musical Seats',
                  style: TextStyle(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Music Note Ring Animation',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (id.contains('orange') || name.contains('orange')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.weekend_rounded, color: Colors.orangeAccent, size: 36),
            SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashed Orange Sofa Seats',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Orange Sofa Seat Decor',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_rounded, color: Colors.blueAccent, size: 36),
            SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seat 1: OWNER (Classic Mic)',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Seats 2-N: Default Frosted Mic',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Color _getTypeColor(StoreItemType type) {
    switch (type) {
      case StoreItemType.avatarFrame:
        return Colors.cyan;
      case StoreItemType.entryEffect:
        return Colors.pink;
      case StoreItemType.badge:
        return Colors.amber;
      case StoreItemType.backgroundTheme:
        return Colors.purple;
      case StoreItemType.roomTheme:
        return Colors.teal;
      case StoreItemType.seatDecor:
        return Colors.brown;
      case StoreItemType.micRefill:
        return Colors.indigo;
      case StoreItemType.roomProfileBackground:
        return Colors.blueGrey;
      case StoreItemType.shortProfileTheme:
        return Colors.pinkAccent;
      case StoreItemType.roomEntry:
        return Colors.greenAccent;
    }
  }

  void _showAddItemDialog([StoreItemType? type]) {
    showDialog(
      context: context,
      builder: (context) => AddMarketItemDialog(
        initialType: type,
        onItemAdded: (item) {
          setState(() {
            _marketItems.add(item);
          });
          _showSuccessSnackBar('Item added successfully');
        },
      ),
    );
  }

  void _editItem(StoreItemModel item) {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description);
    final priceController = TextEditingController(
      text: item.diamondPrice.toString(),
    );

    StoreItemType selectedType = item.type;
    bool isActive = item.isActive;
    bool isAnimated = item.isAnimated;
    String animationType = item.animationType ?? 'rotatingRing';
    String animationColor = item.animationColor ?? 'cyan';
    double animationSpeed = item.animationSpeed;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final glowColor = _getAnimationColorValue(animationColor);

          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Text(
                  'Edit Market Item',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (Diamonds)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.black26,
                        suffixText: '💎',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<StoreItemType>(
                      initialValue: selectedType,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Item Type',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      items: StoreItemType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Active Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isActive ? Icons.check_circle : Icons.cancel,
                                color: isActive ? Colors.greenAccent : Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Item Status (Active/Inactive):',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Switch(
                            value: isActive,
                            activeColor: Colors.greenAccent,
                            onChanged: (value) => setState(() => isActive = value),
                          ),
                        ],
                      ),
                    ),

                    // ── Seat Animation & Live Effects Controls ──
                    if (selectedType == StoreItemType.seatDecor) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAnimated
                                ? Colors.cyanAccent.withValues(alpha: 0.6)
                                : Colors.white12,
                            width: isAnimated ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row with Switch
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isAnimated
                                        ? Colors.cyanAccent.withValues(alpha: 0.2)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: isAnimated ? Colors.cyanAccent : Colors.grey,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Seat Animation & Effects (সিট অ্যানিমেশন)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'অন রাখলে সিটে রিয়েল-টাইম ঘুরন্ত নিয়ন অরা, স্পার্কল বা পালসিং এনিমেশন হবে।',
                                        style: TextStyle(color: Colors.white60, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isAnimated,
                                  activeColor: Colors.cyanAccent,
                                  onChanged: (val) => setState(() => isAnimated = val),
                                ),
                              ],
                            ),

                            if (isAnimated) ...[
                              const Divider(color: Colors.white24, height: 24),

                              // Live Animated Preview
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedSeatDecorWidget(
                                      isAnimated: true,
                                      animationType: animationType,
                                      animationSpeed: animationSpeed,
                                      glowColor: glowColor,
                                      size: 58,
                                      child: (item.fileUrl.isNotEmpty || (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty))
                                          ? MediaPreviewWidget(
                                              url: item.fileUrl.isNotEmpty ? item.fileUrl : item.thumbnailUrl!,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.contain,
                                            )
                                          : const CyberEmeraldDiamondOrbWidget(
                                              size: 48,
                                              child: Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 15),
                                              SizedBox(width: 6),
                                              Text(
                                                'Live Animation Preview',
                                                style: TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Style: ${_getAnimationTypeName(animationType)}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                          Text(
                                            'Speed: ${animationSpeed.toStringAsFixed(1)}x • Color: ${animationColor.toUpperCase()}',
                                            style: TextStyle(color: glowColor, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Animation Effect Dropdown
                              const Text(
                                'Animation Effect Style (অ্যানিমেশন ইফেক্ট):',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: animationType,
                                dropdownColor: Colors.grey[900],
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.black38,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  if (val != null) setState(() => animationType = val);
                                },
                              ),

                              const SizedBox(height: 14),

                              // Aura Glow Color
                              const Text(
                                'Aura Glow Color (অরা নিয়ন কালার):',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildColorChoiceChip('Cyan', 'cyan', const Color(0xFF00FFE0), animationColor, (c) => setState(() => animationColor = c)),
                                  _buildColorChoiceChip('Purple', 'purple', const Color(0xFFFF00D4), animationColor, (c) => setState(() => animationColor = c)),
                                  _buildColorChoiceChip('Gold', 'golden', const Color(0xFFFFD700), animationColor, (c) => setState(() => animationColor = c)),
                                  _buildColorChoiceChip('Emerald', 'emerald', const Color(0xFF00E676), animationColor, (c) => setState(() => animationColor = c)),
                                  _buildColorChoiceChip('Amber', 'amber', const Color(0xFFFF9100), animationColor, (c) => setState(() => animationColor = c)),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Animation Speed Slider
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Animation Speed (গতি):',
                                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${animationSpeed.toStringAsFixed(1)}x',
                                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              Slider(
                                value: animationSpeed,
                                min: 0.5,
                                max: 2.5,
                                divisions: 8,
                                activeColor: Colors.cyanAccent,
                                inactiveColor: Colors.white24,
                                onChanged: (val) => setState(() => animationSpeed = val),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 18),
                onPressed: () async {
                  try {
                    final updatedItem = item.copyWith(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      diamondPrice: double.tryParse(priceController.text) ?? item.diamondPrice,
                      type: selectedType,
                      isActive: isActive,
                      isAnimated: isAnimated,
                      animationType: isAnimated ? animationType : null,
                      animationColor: isAnimated ? animationColor : null,
                      animationSpeed: animationSpeed,
                      updatedAt: DateTime.now(),
                    );

                    await UserProfileService.updateStoreItem(updatedItem);
                    try {
                      await FirebaseFirestore.instance
                          .collection('official_items')
                          .doc(item.id)
                          .update({
                        'name': updatedItem.name,
                        'description': updatedItem.description,
                        'diamondPrice': updatedItem.diamondPrice,
                        'isActive': updatedItem.isActive,
                        'isAnimated': isAnimated,
                        'animationType': isAnimated ? animationType : null,
                        'animationColor': isAnimated ? animationColor : null,
                        'animationSpeed': animationSpeed,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    } catch (_) {}

                    try {
                      await FirebaseFirestore.instance
                          .collection('store_items')
                          .doc(item.id)
                          .update({
                        'name': updatedItem.name,
                        'description': updatedItem.description,
                        'diamondPrice': updatedItem.diamondPrice,
                        'isActive': updatedItem.isActive,
                        'isAnimated': isAnimated,
                        'animationType': isAnimated ? animationType : null,
                        'animationColor': isAnimated ? animationColor : null,
                        'animationSpeed': animationSpeed,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    } catch (_) {}

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadData();
                    _showSuccessSnackBar('Market item updated successfully!');
                  } catch (e) {
                    if (!context.mounted) return;
                    _showErrorSnackBar('Error updating item: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                label: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorChoiceChip(
    String label,
    String key,
    Color color,
    String currentKey,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = currentKey == key;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.grey[800],
      onSelected: (_) => onSelected(key),
    );
  }

  void _toggleItemStatus(StoreItemModel item) async {
    try {
      final updatedItem = item.copyWith(
        isActive: !item.isActive,
        updatedAt: DateTime.now(),
      );

      await UserProfileService.updateStoreItem(updatedItem);
      try {
        await FirebaseFirestore.instance
            .collection('official_items')
            .doc(item.id)
            .update({
          'isActive': updatedItem.isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
      _loadData();
      _showSuccessSnackBar('Item status updated successfully');
    } catch (e) {
      _showErrorSnackBar('Error updating item status: $e');
    }
  }

  void _deleteItem(StoreItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Item', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${item.name}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await OfficialItemsService.deleteOfficialItem(item.id);
                await UserProfileService.deleteStoreItem(item.id);
                _loadData();
                _showSuccessSnackBar('Item deleted successfully');
              } catch (e) {
                _showErrorSnackBar('Error deleting item: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddMarketItemDialog extends StatefulWidget {
  final StoreItemType? initialType;
  final Function(StoreItemModel) onItemAdded;

  const AddMarketItemDialog({
    super.key,
    this.initialType,
    required this.onItemAdded,
  });

  @override
  State<AddMarketItemDialog> createState() => _AddMarketItemDialogState();
}

class _AddMarketItemDialogState extends State<AddMarketItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  StoreItemType _selectedType = StoreItemType.badge;
  Uint8List? _selectedAssetBytes;
  String? _selectedAssetName;
  String? _selectedAssetType;
  Uint8List? _selectedThumbnailBytes;
  String? _selectedThumbnailName;
  bool _isPermanent = false;
  bool _isFree = false;
  bool _isUploading = false;

  // Seat Decor: Host Seat, Unlock Seat, Lock Seat
  Uint8List? _hostSeatBytes;
  String? _hostSeatName;
  Uint8List? _unlockSeatBytes;
  String? _unlockSeatName;
  Uint8List? _lockedSeatBytes;
  String? _lockedSeatName;

  // Seat Animation Settings
  bool _isAnimated = false;
  String _animationType = 'rotatingRing';
  String _animationColor = 'cyan';
  double _animationSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Add Market Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Type Selection
                      const Text(
                        'Item Type',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<StoreItemType>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        dropdownColor: Colors.grey[800],
                        style: const TextStyle(color: Colors.white),
                        items: StoreItemType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Text(_getTypeIcon(type)),
                                const SizedBox(width: 8),
                                Text(_getTypeDisplayName(type)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // File Upload Section
                      const Text(
                        'File Upload',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Thumbnail Upload (hidden for roomTheme & badge)
                      if (_selectedType != StoreItemType.roomTheme && _selectedType != StoreItemType.badge) ...[
                        _buildUploadSection(
                          title: 'Thumbnail (PNG only)',
                          selected: _selectedThumbnailBytes != null,
                          fileName: _selectedThumbnailName,
                          onPickFile: _pickThumbnail,
                          icon: Icons.image,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_selectedType == StoreItemType.seatDecor) ...[
                        _buildUploadSection(
                          title: '👑 1. Host Seat Decor (Seat 1 / Host PNG)',
                          selected: _hostSeatBytes != null,
                          fileName: _hostSeatName,
                          onPickFile: _pickHostSeat,
                          icon: Icons.chair_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildUploadSection(
                          title: '🪑 2. Unlock Seat Decor (Guest Unlocked Seats PNG)',
                          selected: _unlockSeatBytes != null,
                          fileName: _unlockSeatName,
                          onPickFile: _pickUnlockSeat,
                          icon: Icons.event_seat_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildUploadSection(
                          title: '🔒 3. Lock Seat Decor (Locked Seats PNG)',
                          selected: _lockedSeatBytes != null,
                          fileName: _lockedSeatName,
                          onPickFile: _pickLockedSeat,
                          icon: Icons.lock,
                        ),
                        const SizedBox(height: 16),
                        _buildUploadSection(
                          title: '🖼️ Thumbnail (Optional - auto uses Host/Unlock if empty)',
                          selected: _selectedThumbnailBytes != null,
                          fileName: _selectedThumbnailName,
                          onPickFile: _pickThumbnail,
                          icon: Icons.image,
                        ),
                      ] else ...[
                        // Thumbnail Upload (hidden for roomTheme & badge)
                        if (_selectedType != StoreItemType.roomTheme && _selectedType != StoreItemType.badge) ...[
                          _buildUploadSection(
                            title: 'Thumbnail (PNG only)',
                            selected: _selectedThumbnailBytes != null,
                            fileName: _selectedThumbnailName,
                            onPickFile: _pickThumbnail,
                            icon: Icons.image,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Asset Upload
                        _buildUploadSection(
                          title: _selectedType == StoreItemType.roomTheme 
                              ? 'Asset (SVGA, GIF, Image)'
                              : 'Asset (SVGA only)',
                          selected: _selectedAssetBytes != null,
                          fileName: _selectedAssetName,
                          fileType: _selectedAssetType,
                          onPickFile: _pickAsset,
                          icon: Icons.auto_awesome,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Item Details
                      const Text(
                        'Item Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!_isFree) ...[
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Diamond Price',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixText: '💎',
                            suffixStyle: const TextStyle(color: Colors.cyan),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter valid price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Checkbox(
                            value: _isFree,
                            onChanged: (value) {
                              setState(() {
                                _isFree = value ?? false;
                                if (_isFree) {
                                  _priceController.clear();
                                }
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                          const Text(
                            'Free Item',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Duration Settings
                      Row(
                        children: [
                          Checkbox(
                            value: _isPermanent,
                            onChanged: (value) {
                              setState(() {
                                _isPermanent = value ?? false;
                                if (_isPermanent) {
                                  _durationController.clear();
                                }
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                          const Text(
                            'Permanent Item',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      if (!_isPermanent) ...[
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Duration (days)',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixText: 'days',
                            suffixStyle: const TextStyle(color: Colors.blue),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (!_isPermanent &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter duration';
                            }
                            if (value != null &&
                                value.isNotEmpty &&
                                int.tryParse(value) == null) {
                              return 'Please enter valid duration';
                            }
                            return null;
                          },
                        ),
                      ],

                      // ── Seat Animation Section (For Seat Decor) ──
                      if (_selectedType == StoreItemType.seatDecor) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isAnimated
                                  ? Colors.cyanAccent.withValues(alpha: 0.6)
                                  : Colors.white12,
                              width: _isAnimated ? 1.5 : 1.0,
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
                                      color: _isAnimated
                                          ? Colors.cyanAccent.withValues(alpha: 0.2)
                                          : Colors.white10,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: _isAnimated ? Colors.cyanAccent : Colors.grey,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Seat Animation & Effects (সিট অ্যানিমেশন)',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'অন রাখলে নতুন সিটটিতে রিয়েল-টাইমে ৩৬০° ঘুরন্ত নিয়ন অরা বা পালসিং এনিমেশন হবে।',
                                          style: TextStyle(color: Colors.white60, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isAnimated,
                                    activeColor: Colors.cyanAccent,
                                    onChanged: (val) => setState(() => _isAnimated = val),
                                  ),
                                ],
                              ),

                              if (_isAnimated) ...[
                                const Divider(color: Colors.white24, height: 24),

                                // Animation Effect Dropdown
                                const Text(
                                  'Animation Effect Style (অ্যানিমেশন ইফেক্ট):',
                                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _animationType,
                                  dropdownColor: Colors.grey[900],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.black38,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                    if (val != null) setState(() => _animationType = val);
                                  },
                                ),

                                const SizedBox(height: 14),

                                // Aura Glow Color
                                const Text(
                                  'Aura Glow Color (অরা নিয়ন কালার):',
                                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildAddDialogColorChip('Cyan', 'cyan', const Color(0xFF00FFE0)),
                                    _buildAddDialogColorChip('Purple', 'purple', const Color(0xFFFF00D4)),
                                    _buildAddDialogColorChip('Gold', 'golden', const Color(0xFFFFD700)),
                                    _buildAddDialogColorChip('Emerald', 'emerald', const Color(0xFF00E676)),
                                    _buildAddDialogColorChip('Amber', 'amber', const Color(0xFFFF9100)),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Animation Speed Slider
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Animation Speed (গতি):',
                                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${_animationSpeed.toStringAsFixed(1)}x',
                                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _animationSpeed,
                                  min: 0.5,
                                  max: 2.5,
                                  divisions: 8,
                                  activeColor: Colors.cyanAccent,
                                  inactiveColor: Colors.white24,
                                  onChanged: (val) => setState(() => _animationSpeed = val),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Save Item'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeIcon(StoreItemType type) {
    switch (type) {
      case StoreItemType.avatarFrame:
        return '🖼️';
      case StoreItemType.entryEffect:
        return '✨';
      case StoreItemType.badge:
        return '🏆';
      case StoreItemType.backgroundTheme:
        return '🎭';
      case StoreItemType.roomTheme:
        return '🎨';
      case StoreItemType.seatDecor:
        return '🪑';
      case StoreItemType.micRefill:
        return '🎙️';
      case StoreItemType.roomProfileBackground:
        return '🖼️';
      case StoreItemType.shortProfileTheme:
        return '🖼️';
      case StoreItemType.roomEntry:
        return '🚪';
    }
  }

  String _getTypeDisplayName(StoreItemType type) {
    switch (type) {
      case StoreItemType.avatarFrame:
        return 'Avatar Frame';
      case StoreItemType.entryEffect:
        return 'Entry Effect';
      case StoreItemType.badge:
        return 'Badge';
      case StoreItemType.backgroundTheme:
        return 'Room Background Theme';
      case StoreItemType.roomTheme:
        return 'Profile Skin';
      case StoreItemType.seatDecor:
        return 'Seat decor';
      case StoreItemType.micRefill:
        return 'Mic Refill';
      case StoreItemType.roomProfileBackground:
        return 'Room Profile Background';
      case StoreItemType.shortProfileTheme:
        return 'Short Profile Theme';
      case StoreItemType.roomEntry:
        return 'Room Entry';
    }
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.toLowerCase().contains('image') ||
        fileType.toLowerCase() == 'png' ||
        fileType.toLowerCase() == 'jpg' ||
        fileType.toLowerCase() == 'jpeg') {
      return Icons.image;
    } else if (fileType.toLowerCase() == 'svg') {
      return Icons.auto_awesome;
    } else if (fileType.toLowerCase() == 'gif') {
      return Icons.animation;
    } else if (fileType.toLowerCase() == 'mp4') {
      return Icons.videocam;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Widget _buildUploadSection({
    required String title,
    required bool selected,
    String? fileName,
    String? fileType,
    required VoidCallback onPickFile,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? Colors.green : Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: selected
              ? Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      fileType != null ? _getFileIcon(fileType) : Icons.image,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName ?? 'Selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (fileType != null)
                            Text(
                              fileType.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          if (title.contains('Thumbnail')) {
                            _selectedThumbnailBytes = null;
                            _selectedThumbnailName = null;
                          } else {
                            _selectedAssetBytes = null;
                            _selectedAssetName = null;
                            _selectedAssetType = null;
                          }
                        });
                      },
                    ),
                  ],
                )
              : Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.grey, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'No file selected',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.attach_file, size: 18),
            label: const Text('Pick File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAsset() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svga', 'gif', 'png', 'jpg', 'jpeg', 'webp', 'mp4', 'vap'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedAssetBytes = result.files.single.bytes;
          _selectedAssetName = result.files.single.name;
          _selectedAssetType = result.files.single.extension?.toLowerCase() ?? 'svga';
        });
      }
    } catch (e) {
      debugPrint('Error picking asset: $e');
      _showErrorSnackBar('Failed to pick asset');
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedThumbnailBytes = result.files.single.bytes;
          _selectedThumbnailName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking thumbnail: $e');
      _showErrorSnackBar('Failed to pick thumbnail (Only .png allowed)');
    }
  }

  Future<void> _pickHostSeat() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _hostSeatBytes = result.files.single.bytes;
          _hostSeatName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking host seat decor: $e');
      _showErrorSnackBar('Failed to pick Host Seat Decor');
    }
  }

  Future<void> _pickUnlockSeat() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _unlockSeatBytes = result.files.single.bytes;
          _unlockSeatName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking unlock seat decor: $e');
      _showErrorSnackBar('Failed to pick Unlock Seat Decor');
    }
  }

  Future<void> _pickLockedSeat() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _lockedSeatBytes = result.files.single.bytes;
          _lockedSeatName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking lock seat decor: $e');
      _showErrorSnackBar('Failed to pick Lock Seat Decor');
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType == StoreItemType.seatDecor) {
      if (_unlockSeatBytes == null && _hostSeatBytes == null) {
        _showErrorSnackBar('Please upload at least Host Seat or Unlock Seat Decor');
        return;
      }
    } else {
      if (_selectedAssetBytes == null) {
        _showErrorSnackBar('Please select an asset file');
        return;
      }

      if (_selectedThumbnailBytes == null && _selectedType != StoreItemType.roomTheme) {
        _showErrorSnackBar('Please select a thumbnail');
        return;
      }
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final itemId = FirebaseFirestore.instance
          .collection('market_items')
          .doc()
          .id;

      bool success = false;
      
      if (_selectedType == StoreItemType.seatDecor) {
        // Upload Unlock Seat Decor (primary fileUrl)
        final Uint8List primaryUnlockBytes = _unlockSeatBytes ?? _hostSeatBytes!;
        final String primaryUnlockName = _unlockSeatName ?? _hostSeatName!;
        final unlockUrl = await UserProfileService.uploadMarketItemFile(
          primaryUnlockBytes,
          'unlock_$primaryUnlockName',
          itemId,
        );
        if (unlockUrl == null) throw Exception('Failed to upload unlock seat decor');

        // Upload Host Seat Decor
        String? hostUrl;
        if (_hostSeatBytes != null) {
          hostUrl = await UserProfileService.uploadMarketItemFile(
            _hostSeatBytes!,
            'host_${_hostSeatName!}',
            itemId,
          );
        } else {
          hostUrl = unlockUrl;
        }

        // Upload Lock Seat Decor
        String? lockedUrl;
        if (_lockedSeatBytes != null) {
          lockedUrl = await UserProfileService.uploadMarketItemFile(
            _lockedSeatBytes!,
            'locked_${_lockedSeatName!}',
            itemId,
          );
        } else {
          lockedUrl = unlockUrl;
        }

        // Upload Thumbnail if provided, otherwise default to Host or Unlock
        String? thumbnailUrl;
        if (_selectedThumbnailBytes != null) {
          thumbnailUrl = await UserProfileService.uploadMarketItemFile(
            _selectedThumbnailBytes!,
            'thumbnail_${_selectedThumbnailName!}',
            itemId,
          );
        }
        thumbnailUrl ??= hostUrl ?? unlockUrl;

        final double price = _isFree ? 0.0 : (double.tryParse(_priceController.text) ?? 0.0);
        final int duration = _isPermanent ? 0 : (int.tryParse(_durationController.text) ?? 0);

        final officialId = await OfficialItemsService.createOfficialItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: OfficialItemCategory.seatDecor,
          fileUrl: unlockUrl,
          fileName: primaryUnlockName,
          fileType: 'png',
          thumbnailUrl: thumbnailUrl,
          lockedFileUrl: lockedUrl,
          hostSeatDecorUrl: hostUrl,
          starRating: 1,
          diamondPrice: price,
          expirationDuration: duration,
          isAnimated: _isAnimated,
          animationType: _isAnimated ? _animationType : null,
          animationSpeed: _animationSpeed,
          animationColor: _isAnimated ? _animationColor : null,
        );
        success = officialId != null;
      } else {
        String? thumbnailUrl;
        if (_selectedThumbnailBytes != null) {
          thumbnailUrl = await UserProfileService.uploadMarketItemFile(
            _selectedThumbnailBytes!,
            'thumbnail_${_selectedThumbnailName!}',
            itemId,
          );
          if (thumbnailUrl == null) throw Exception('Failed to upload thumbnail');
        }

        // Upload Asset
        final assetUrl = await UserProfileService.uploadMarketItemFile(
          _selectedAssetBytes!,
          _selectedAssetName!,
          itemId,
        );

        if (assetUrl == null) throw Exception('Failed to upload asset');

        final item = StoreItemModel(
          id: itemId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          category: StoreCategory.store,
          fileUrl: assetUrl,
          fileName: _selectedAssetName!,
          fileType: _selectedAssetType ?? 'png',
          diamondPrice: _isFree ? 0.0 : double.parse(_priceController.text),
          expirationDuration: _isPermanent
              ? 0
              : int.parse(_durationController.text),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          thumbnailUrl: thumbnailUrl,
        );

        success = await UserProfileService.createMarketItem(item);
        if (success) {
          widget.onItemAdded(item);
        }
      }

      if (success) {
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        throw Exception('Failed to save item');
      }
    } catch (e) {
      debugPrint('Error saving item: $e');
      _showErrorSnackBar('Failed to save item: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildAddDialogColorChip(String label, String key, Color color) {
    final isSelected = _animationColor == key;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.grey[800],
      onSelected: (_) => setState(() => _animationColor = key),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
