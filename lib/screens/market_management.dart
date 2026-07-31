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
    _tabController = TabController(length: 8, vsync: this);

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
        return 'Profile Skins';
      case StoreItemType.roomTheme:
        return 'Room Themes';
      case StoreItemType.seatDecor:
        return 'Seat Decor';
      case StoreItemType.micRefill:
        return 'Mic Refills';
      case StoreItemType.roomProfileBackground:
        return 'RP Backgrounds';
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
                  title: 'Profile Skins',
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
                  title: 'Room Themes',
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
                  title: 'Add Profile Skin',
                  subtitle: 'Create new profile skin',
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
                  title: 'Add Room Theme',
                  subtitle: 'Create new room theme',
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
            if (item.fileUrl.isNotEmpty || (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty))
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
              ),

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
                        '${item.diamondPrice.toStringAsFixed(0)}💎',
                        style: const TextStyle(
                          color: Colors.white,
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Edit Market Item',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StoreItemType>(
                  initialValue: selectedType,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Item Type',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                  items: StoreItemType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Active: ',
                      style: TextStyle(color: Colors.white),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updatedItem = item.copyWith(
                    name: nameController.text,
                    description: descriptionController.text,
                    diamondPrice:
                        double.tryParse(priceController.text) ??
                        item.diamondPrice,
                    type: selectedType,
                    isActive: isActive,
                    updatedAt: DateTime.now(),
                  );

                  await UserProfileService.updateStoreItem(updatedItem);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadData();
                  _showSuccessSnackBar('Market item updated successfully');
                } catch (e) {
                  if (!context.mounted) return;
                  _showErrorSnackBar('Error updating item: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleItemStatus(StoreItemModel item) async {
    try {
      final updatedItem = item.copyWith(
        isActive: !item.isActive,
        updatedAt: DateTime.now(),
      );

      await UserProfileService.updateStoreItem(updatedItem);
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
                if (item.category == StoreCategory.officialStore) {
                  await OfficialItemsService.deleteOfficialItem(item.id);
                } else {
                  await UserProfileService.deleteStoreItem(item.id);
                }
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

                      // Thumbnail Upload
                      if (_selectedType != StoreItemType.roomTheme) ...[
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
        return 'Profile skin';
      case StoreItemType.roomTheme:
        return 'Room theme';
      case StoreItemType.seatDecor:
        return 'Seat decor';
      case StoreItemType.micRefill:
        return 'Mic Refill';
      case StoreItemType.roomProfileBackground:
        return 'Room Profile Background';
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
      final isRoomTheme = _selectedType == StoreItemType.roomTheme;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: isRoomTheme ? ['svga', 'gif', 'png', 'jpg', 'jpeg'] : ['svga'],
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
        allowedExtensions: ['png'],
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

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAssetBytes == null) {
      _showErrorSnackBar('Please select an asset file');
      return;
    }

    if (_selectedThumbnailBytes == null && _selectedType != StoreItemType.roomTheme) {
      _showErrorSnackBar('Please select a thumbnail');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final itemId = FirebaseFirestore.instance
          .collection('market_items')
          .doc()
          .id;

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

      bool success = false;
      
      if (_selectedType == StoreItemType.seatDecor) {
        // Create as an Official Item
        final officialId = await OfficialItemsService.createOfficialItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: OfficialItemCategory.seatDecor,
          fileUrl: assetUrl,
          fileName: _selectedAssetName!,
          fileType: _selectedAssetType ?? 'png',
          thumbnailUrl: thumbnailUrl,
          starRating: 1,
        );
        success = officialId != null;
      } else {
        // Create as a normal Market Item
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

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
