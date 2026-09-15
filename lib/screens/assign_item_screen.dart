import 'package:flutter/material.dart';
import '../models/store_item_model.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';

class AssignItemScreen extends StatefulWidget {
  final StoreItemModel? preselectedItem;
  const AssignItemScreen({super.key, this.preselectedItem});

  @override
  State<AssignItemScreen> createState() => _AssignItemScreenState();
}

class _AssignItemScreenState extends State<AssignItemScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _profileIdController = TextEditingController();
  
  List<StoreItemModel> _officialItems = [];
  List<UserStoreItemModel> _userItems = [];
  Map<String, dynamic>? _foundUser;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadOfficialItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _profileIdController.dispose();
    super.dispose();
  }

  Future<void> _loadOfficialItems() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final items = await StoreService.getStoreItemsByCategory(StoreCategory.officialStore);

      if (mounted) {
        setState(() {
          final activeItems = items.where((item) => item.isActive).toList();
          if (widget.preselectedItem != null) {
            _officialItems = activeItems.where((item) => item.id == widget.preselectedItem!.id).toList();
          } else {
            _officialItems = activeItems;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading official items: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load official items');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _searchUser() async {
    final profileId = _profileIdController.text.trim();
    if (profileId.isEmpty) {
      _showErrorSnackBar('Please enter a profile ID');
      return;
    }

    setState(() {
      _isSearching = true;
      _foundUser = null;
    });

    try {
      final user = await StoreService.searchUserByProfileId(profileId);
      
      if (mounted) {
        setState(() {
          _isSearching = false;
          _foundUser = user;
        });

        if (user == null) {
          _showErrorSnackBar('User not found');
        } else {
          _loadUserItems(user['id']);
        }
      }
    } catch (e) {
      debugPrint('Error searching user: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _showErrorSnackBar('Failed to search user');
      }
    }
  }

  Future<void> _loadUserItems(String userId) async {
    try {
      final items = await StoreService.getUserStoreItems(userId);
      
      if (mounted) {
        setState(() {
          _userItems = items;
        });
      }
    } catch (e) {
      debugPrint('Error loading user items: $e');
    }
  }

  Future<void> _assignItem(StoreItemModel item) async {
    if (_foundUser == null) {
      _showErrorSnackBar('Please search for a user first');
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      final success = await StoreService.assignItemToUser(
        storeItemId: item.id,
        userId: _foundUser!['id'],
        userProfileId: _foundUser!['profileId'],
        adminId: AuthService.currentUser?.uid ?? '',
      );

      if (mounted) {
        setState(() {
          _isAssigning = false;
        });

        if (success) {
          _showSuccessSnackBar('Item assigned successfully!');
          _loadUserItems(_foundUser!['id']);
        } else {
          _showErrorSnackBar('Failed to assign item');
        }
      }
    } catch (e) {
      debugPrint('Error assigning item: $e');
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
        _showErrorSnackBar('Failed to assign item');
      }
    }
  }

  Future<void> _removeItem(UserStoreItemModel userItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Remove Item',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove "${userItem.storeItemName}" from this user?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await StoreService.removeItemFromUser(userItem.id);
      
      if (success) {
        _showSuccessSnackBar('Item removed successfully');
        if (_foundUser != null) {
          _loadUserItems(_foundUser!['id']);
        }
      } else {
        _showErrorSnackBar('Failed to remove item');
      }
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
          'Assign Items to Users',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOfficialItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: _foundUser != null
          ? FloatingActionButton.extended(
              onPressed: () {
                // Scroll to available items tab
                DefaultTabController.of(context).animateTo(0);
              },
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Assign Items'),
            )
          : null,
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Step 1: Search User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter a user\'s Profile ID to search and select them',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: _profileIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter User Profile ID',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchUser,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isSearching ? 'Searching...' : 'Search User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Found User Section
          if (_foundUser != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _foundUser!['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Profile ID: ${_foundUser!['profileId'] ?? 'N/A'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Phone: ${_foundUser!['phone'] ?? 'N/A'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          indicatorColor: Colors.blue,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: 'Step 2: Available Items'),
                            Tab(text: 'Step 3: User Items'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildAvailableItemsTab(),
                              _buildUserItemsTab(),
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

  Widget _buildAvailableItemsTab() {
    return _officialItems.isEmpty
        ? const Center(
            child: Text(
              'No official store items available',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : Column(
            children: [
              // Instructions
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _foundUser == null 
                            ? 'Search for a user first, then select items to assign'
                            : 'Select items below to assign to ${_foundUser!['name']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _officialItems.length,
                  itemBuilder: (context, index) {
                    final item = _officialItems[index];
                    return _buildAvailableItemCard(item);
                  },
                ),
              ),
            ],
          );
  }

  Widget _buildUserItemsTab() {
    if (_foundUser == null) {
      return const Center(
        child: Text(
          'Search for a user to view their items',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return _userItems.isEmpty
        ? const Center(
            child: Text(
              'No items assigned to this user',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _userItems.length,
            itemBuilder: (context, index) {
              final userItem = _userItems[index];
              return _buildUserItemCard(userItem);
            },
          );
  }

  Widget _buildAvailableItemCard(StoreItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple, width: 2),
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
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeIcon(item.type),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTypeDisplayName(item.type),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OFFICIAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
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
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Assign Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _foundUser == null || _isAssigning ? null : () => _assignItem(item),
                icon: _isAssigning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add),
                label: Text(_isAssigning 
                    ? 'Assigning...' 
                    : _foundUser == null 
                        ? 'Search User First' 
                        : 'Assign to User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _foundUser == null ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            // Helper text
            if (_foundUser == null) ...[
              const SizedBox(height: 8),
              const Text(
                'Please search for a user first to enable assignment',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserItemCard(UserStoreItemModel userItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: userItem.isExpired ? Colors.red : Colors.green,
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
                    color: (userItem.isExpired ? Colors.red : Colors.green).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeIcon(userItem.itemType),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userItem.storeItemName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTypeDisplayName(userItem.itemType),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: userItem.isExpired ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userItem.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Assignment Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assignment Information',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assigned At',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDate(userItem.assignedAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (userItem.expiresAt != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Expires At',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDate(userItem.expiresAt!),
                              style: TextStyle(
                                color: userItem.isExpired ? Colors.red : Colors.blue,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Remove Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _removeItem(userItem),
                icon: const Icon(Icons.remove_circle),
                label: const Text('Remove from User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
      case StoreItemType.micRefill:
        return 'Mic Refill';
      case StoreItemType.seatDecor:
        return 'Seat Decor';
      case StoreItemType.roomProfileBackground:
        return 'RP Background';
      case StoreItemType.shortProfileTheme:
        return 'Short Profile Theme';
      case StoreItemType.roomEntry:
        return 'Room Entry';
    }
  }
}
