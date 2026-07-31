import 'package:flutter/material.dart';
import '../models/store_item_model.dart';
import '../services/store_service.dart';

class BulkOperationsScreen extends StatefulWidget {
  const BulkOperationsScreen({super.key});

  @override
  State<BulkOperationsScreen> createState() => _BulkOperationsScreenState();
}

class _BulkOperationsScreenState extends State<BulkOperationsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<StoreItemModel> _storeItems = [];
  List<StoreItemModel> _officialItems = [];
  Set<String> _selectedItems = {};
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final storeItems = await StoreService.getStoreItemsByCategory(StoreCategory.store);
      final officialItems = await StoreService.getStoreItemsByCategory(StoreCategory.officialStore);

      setState(() {
        _storeItems = storeItems;
        _officialItems = officialItems;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _selectAllItems(List<StoreItemModel> items) {
    setState(() {
      _selectedItems = items.map((item) => item.id).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
    });
  }

  Future<void> _bulkActivate() async {
    if (_selectedItems.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      for (String itemId in _selectedItems) {
        await StoreService.updateStoreItem(itemId: itemId, isActive: true);
      }
      
      _showSuccessSnackBar('${_selectedItems.length} items activated successfully');
      _clearSelection();
      _loadData();
    } catch (e) {
      _showErrorSnackBar('Error activating items: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _bulkDeactivate() async {
    if (_selectedItems.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      for (String itemId in _selectedItems) {
        await StoreService.updateStoreItem(itemId: itemId, isActive: false);
      }
      
      _showSuccessSnackBar('${_selectedItems.length} items deactivated successfully');
      _clearSelection();
      _loadData();
    } catch (e) {
      _showErrorSnackBar('Error deactivating items: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedItems.isEmpty) return;

    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      for (String itemId in _selectedItems) {
        await StoreService.deleteStoreItem(itemId);
      }
      
      _showSuccessSnackBar('${_selectedItems.length} items deleted successfully');
      _clearSelection();
      _loadData();
    } catch (e) {
      _showErrorSnackBar('Error deleting items: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Confirm Delete',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedItems.length} items? This action cannot be undone.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessSnackBar(String message) {
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          '⚡ Bulk Operations',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.orange[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearSelection,
              tooltip: 'Clear Selection',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Store Items'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Official Items'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            )
          : AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      // Selection Info and Actions
                      if (_selectedItems.isNotEmpty) _buildSelectionBar(),
                      
                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildItemsList(_storeItems),
                            _buildItemsList(_officialItems),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[900],
        border: Border(
          bottom: BorderSide(color: Colors.orange, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedItems.length} items selected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (!_isProcessing) ...[
            _buildActionButton(
              icon: Icons.play_arrow,
              label: 'Activate',
              color: Colors.green,
              onPressed: _bulkActivate,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.pause,
              label: 'Deactivate',
              color: Colors.orange,
              onPressed: _bulkDeactivate,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.delete,
              label: 'Delete',
              color: Colors.red,
              onPressed: _bulkDelete,
            ),
          ] else
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
    );
  }

  Widget _buildItemsList(List<StoreItemModel> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items available',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1, // +1 for select all header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSelectAllHeader(items);
        }
        
        final item = items[index - 1];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildSelectAllHeader(List<StoreItemModel> items) {
    final allSelected = items.every((item) => _selectedItems.contains(item.id));
    final someSelected = items.any((item) => _selectedItems.contains(item.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            tristate: true,
            onChanged: (value) {
              if (value == true) {
                _selectAllItems(items);
              } else {
                _clearSelection();
              }
            },
            activeColor: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allSelected 
                  ? 'All ${items.length} items selected'
                  : someSelected 
                      ? '${_selectedItems.length} of ${items.length} items selected'
                      : 'Select all ${items.length} items',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (someSelected)
            TextButton(
              onPressed: _clearSelection,
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(StoreItemModel item) {
    final isSelected = _selectedItems.contains(item.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.withValues(alpha: 0.1) : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.grey[800]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => _toggleItemSelection(item.id),
        activeColor: Colors.orange,
        title: Text(
          item.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTypeDisplayName(item.type),
              style: const TextStyle(color: Colors.grey),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.category == StoreCategory.officialStore 
                        ? Colors.purple 
                        : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.category == StoreCategory.officialStore 
                        ? 'Official' 
                        : 'Store',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        secondary: Text(
          _getTypeIcon(item.type),
          style: const TextStyle(fontSize: 24),
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
        return 'Profile Skin';
      case StoreItemType.roomTheme:
        return 'Room Theme';
      case StoreItemType.seatDecor:
        return 'Seat Decor';
      case StoreItemType.micRefill:
        return 'Mic Refill';
      case StoreItemType.roomProfileBackground:
        return 'RP Background';
    }
  }
}
