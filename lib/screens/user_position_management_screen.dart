import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import '../services/user_position_service.dart';

class UserPositionManagementScreen extends StatefulWidget {
  const UserPositionManagementScreen({super.key});

  @override
  State<UserPositionManagementScreen> createState() => _UserPositionManagementScreenState();
}

class _UserPositionManagementScreenState extends State<UserPositionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Position Config Controllers
  final Map<String, TextEditingController> _frameControllers = {};
  final Map<String, TextEditingController> _badgeControllers = {};
  final Map<String, TextEditingController> _nameplateControllers = {};
  final Map<String, bool> _savingStatus = {};

  // Live item preview cache
  final Map<String, Map<String, dynamic>?> _itemPreviewCache = {};

  // User Assignment State
  final TextEditingController _userSearchController = TextEditingController();
  bool _isSearchingUser = false;
  Map<String, dynamic>? _selectedUser;
  String _selectedPositionToApply = 'host';
  int _selectedDurationDays = 365;
  bool _isApplyingPosition = false;

  // Position Users Filter State
  String _activePositionFilter = 'all';
  final TextEditingController _listSearchController = TextEditingController();
  String _listSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    for (final pos in UserPositionService.supportedPositions) {
      _frameControllers[pos] = TextEditingController();
      _badgeControllers[pos] = TextEditingController();
      _nameplateControllers[pos] = TextEditingController();
      _savingStatus[pos] = false;
    }

    _loadConfigs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchController.dispose();
    _listSearchController.dispose();
    for (final c in _frameControllers.values) {
      c.dispose();
    }
    for (final c in _badgeControllers.values) {
      c.dispose();
    }
    for (final c in _nameplateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    final configs = await UserPositionService.getPositionConfigs();
    if (mounted) {
      setState(() {
        for (final pos in UserPositionService.supportedPositions) {
          final item = configs[pos] ?? PositionConfigItem();
          _frameControllers[pos]?.text = item.frameItemId;
          _badgeControllers[pos]?.text = item.badgeItemId;
          _nameplateControllers[pos]?.text = item.nameplateItemId;

          if (item.frameItemId.isNotEmpty) {
            _itemPreviewCache[item.frameItemId] = {
              'id': item.frameItemId,
              'name': item.frameName.isNotEmpty ? item.frameName : 'Frame #${item.frameItemId}',
              'imageUrl': item.frameUrl,
              'category': 'avatarFrame',
              'starRating': item.frameStarRating,
            };
            _fetchItemPreview(item.frameItemId);
          }
          if (item.badgeItemId.isNotEmpty) {
            _itemPreviewCache[item.badgeItemId] = {
              'id': item.badgeItemId,
              'name': item.badgeName.isNotEmpty ? item.badgeName : 'Badge #${item.badgeItemId}',
              'imageUrl': item.badgeUrl,
              'category': 'badge',
              'starRating': item.badgeStarRating,
            };
            _fetchItemPreview(item.badgeItemId);
          }
          if (item.nameplateItemId.isNotEmpty) {
            _itemPreviewCache[item.nameplateItemId] = {
              'id': item.nameplateItemId,
              'name': item.nameplateName.isNotEmpty ? item.nameplateName : 'Nameplate #${item.nameplateItemId}',
              'imageUrl': item.nameplateUrl,
              'category': 'nameplate',
              'starRating': item.nameplateStarRating,
            };
            _fetchItemPreview(item.nameplateItemId);
          }
        }
      });
    }
  }

  Future<void> _fetchItemPreview(String itemId) async {
    final clean = itemId.trim();
    if (clean.isEmpty) return;

    final details = await UserPositionService.getItemDetails(clean);
    if (mounted && details != null) {
      setState(() {
        _itemPreviewCache[clean] = details;
      });
    }
  }

  Future<void> _saveConfig(String posKey) async {
    final frameId = _frameControllers[posKey]?.text.trim() ?? '';
    final badgeId = _badgeControllers[posKey]?.text.trim() ?? '';
    final nameplateId = _nameplateControllers[posKey]?.text.trim() ?? '';

    setState(() {
      _savingStatus[posKey] = true;
    });

    final success = await UserPositionService.savePositionConfig(
      positionKey: posKey,
      frameItemId: frameId,
      badgeItemId: badgeId,
      nameplateItemId: nameplateId,
      adminId: AdminAuthService.currentUserId ?? 'admin',
    );

    if (mounted) {
      setState(() {
        _savingStatus[posKey] = false;
      });
      if (success) {
        _showSnackBar(
          '✅ ${UserPositionService.getPositionDisplayName(posKey)} configuration saved successfully!',
          Colors.green,
        );
        if (frameId.isNotEmpty) await _fetchItemPreview(frameId);
        if (badgeId.isNotEmpty) await _fetchItemPreview(badgeId);
        if (nameplateId.isNotEmpty) await _fetchItemPreview(nameplateId);
        await _loadConfigs();
      } else {
        _showSnackBar('❌ Failed to save configuration', Colors.red);
      }
    }
  }

  Future<void> _searchUser() async {
    final query = _userSearchController.text.trim();
    if (query.isEmpty) {
      _showSnackBar('Please enter a Profile ID, User ID, or Phone', Colors.orange);
      return;
    }

    setState(() {
      _isSearchingUser = true;
      _selectedUser = null;
    });

    final user = await UserPositionService.searchUser(query);

    if (mounted) {
      setState(() {
        _isSearchingUser = false;
        _selectedUser = user;
      });

      if (user == null) {
        _showSnackBar('No user found matching "$query"', Colors.red);
      }
    }
  }

  Future<void> _applyPositionToSelectedUser() async {
    if (_selectedUser == null) {
      _showSnackBar('Please search and select a user first', Colors.orange);
      return;
    }

    final userId = _selectedUser!['id'];
    setState(() {
      _isApplyingPosition = true;
    });

    final success = await UserPositionService.applyPositionToUser(
      userId: userId,
      positionKey: _selectedPositionToApply,
      durationDays: _selectedDurationDays,
      adminId: AdminAuthService.currentUserId ?? 'admin',
    );

    if (mounted) {
      setState(() {
        _isApplyingPosition = false;
      });

      if (success) {
        _showSnackBar(
          '🎉 ${_selectedPositionToApply.toUpperCase()} position & items applied to ${_selectedUser!['fullname'] ?? 'User'}!',
          Colors.green,
        );
        // Refresh selected user
        final updatedUser = await UserPositionService.searchUser(userId);
        if (mounted && updatedUser != null) {
          setState(() {
            _selectedUser = updatedUser;
          });
        }
      } else {
        _showSnackBar('❌ Failed to apply position', Colors.red);
      }
    }
  }

  Future<void> _removePositionFromUser(String userId, String posKey, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2130),
        title: Text(
          'Revoke ${UserPositionService.getPositionDisplayName(posKey)}?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove the "$posKey" position from $userName?\n\n'
          'All exclusive Frame, Badge, and Nameplate items for this position will be automatically removed from the user in real time.',
          style: const TextStyle(color: Color(0xFFD1D5DB)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke & Clean Items', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await UserPositionService.removePositionFromUser(
        userId: userId,
        positionKey: posKey,
        adminId: AdminAuthService.currentUserId ?? 'admin',
      );

      if (mounted) {
        if (success) {
          _showSnackBar('✅ Removed $posKey position & unassigned items for $userName', Colors.green);
          if (_selectedUser != null && _selectedUser!['id'] == userId) {
            final updated = await UserPositionService.searchUser(userId);
            if (mounted) setState(() => _selectedUser = updated);
          }
        } else {
          _showSnackBar('❌ Failed to remove position', Colors.red);
        }
      }
    }
  }

  bool _isSyncingAll = false;

  Future<void> _syncAllExistingPositionUsers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sync, color: Color(0xFF38BDF8), size: 24),
            SizedBox(width: 10),
            Text('Sync Existing Users (অটো-সিঙ্ক)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SizedBox(
          width: 440,
          child: Text(
            'আপনি কি ডাটাবেজের সকল বিদ্যমান Host, Agency, Seller, Official ও Assistant ইউজারদের প্যাকেজ আইটেম সিঙ্ক করতে চান?\n\n'
            'এতে করে যাদের আইডিতে পূর্বে নির্ধারিত Frame, Badge বা Nameplate যুক্ত ছিল না, তাদের আইডিতে কনফিগার করা আইটেমগুলো স্বয়ংক্রিয়ভাবে রিয়েল-টাইমে যুক্ত হয়ে যাবে।',
            style: TextStyle(color: Color(0xFFD1D5DB), height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.sync, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            label: const Text('Start Auto-Sync'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSyncingAll = true);
      _showSnackBar('🔄 ডাটাবেজের সকল বিদ্যমান এক্টিভ ইউজারদের আইটেম সিঙ্ক হচ্ছে...', Colors.blue);
      final res = await UserPositionService.syncAllExistingPositionUsers();
      if (mounted) {
        setState(() => _isSyncingAll = false);
        final total = res['totalUsers'] ?? 0;
        _showSnackBar(
          '🎉 সফলভাবে $total জন ইউজারের আইডিতে প্যাকেজ আইটেম সিঙ্ক হয়েছে! (হোস্ট: ${res['hosts'] ?? 0}, এজেন্সি: ${res['agencies'] ?? 0}, সেলার: ${res['sellers'] ?? 0})',
          Colors.green,
        );
      }
    }
  }

  void _showSnackBar(String message, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openItemPickerModal(String posKey, String itemType, TextEditingController controller) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2130),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        itemType == 'frame'
                            ? Icons.filter_frames
                            : (itemType == 'badge' ? Icons.military_tech : Icons.badge),
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Select $itemType Item for ${posKey.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF374151)),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('market_items').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.blue));
                      }

                      final items = snapshot.data!.docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return {'id': d.id, ...data};
                      }).toList();

                      if (items.isEmpty) {
                        return const Center(
                          child: Text('No store items found', style: TextStyle(color: Colors.grey)),
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(color: Color(0xFF2D3748)),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final docId = item['id'] as String;
                          final displayId = item['displayId']?.toString() ?? '';
                          final chosenId = displayId.isNotEmpty ? displayId : docId;
                          final name = item['name'] ?? item['title'] ?? 'Item $chosenId';
                          final img = item['fileUrl'] ??
                              item['thumbnailUrl'] ??
                              item['imageUrl'] ??
                              item['image'] ??
                              '';
                          final category = item['category'] ?? item['itemType'] ?? '';

                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: img.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        img,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.inventory_2, color: Colors.blueAccent),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '⭐ ${item['starRating'] ?? item['stars'] ?? item['star'] ?? 1} Stars | ID: $chosenId ${displayId.isNotEmpty ? "($docId)" : ""} | $category',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                controller.text = chosenId;
                                final stars = int.tryParse((item['starRating'] ?? item['stars'] ?? item['star'] ?? 1).toString()) ?? 1;
                                _itemPreviewCache[chosenId] = {
                                  'id': chosenId,
                                  'name': name,
                                  'imageUrl': img,
                                  'category': category,
                                  'starRating': stars,
                                };
                                _fetchItemPreview(chosenId);
                                setState(() {});
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('Select', style: TextStyle(color: Colors.white)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFF38BDF8), size: 26),
            SizedBox(width: 10),
            Text(
              'User Position Management (ইউজার পজিশন)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _isSyncingAll ? null : _syncAllExistingPositionUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSyncingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync, size: 18),
              label: Text(
                _isSyncingAll ? 'Syncing...' : '🔄 Auto-Sync All Users',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: '1. ⚙️ Configuration (কনফিগারেশন)'),
            Tab(icon: Icon(Icons.person_add), text: '2. 👤 Apply to User (ইউজার এসাইন)'),
            Tab(icon: Icon(Icons.people), text: '3. 📋 Position Users (তালিকা)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConfigurationTab(),
          _buildApplyPositionTab(),
          _buildPositionUsersTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 1: Position Configuration
  // ─────────────────────────────────────────────────────────────
  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFF0284C7),
                  child: Icon(Icons.military_tech, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Position Items Binding',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Configure Frame, Badge, and Nameplate Item IDs for Host, Agency, Seller, Official, and Official Assistant positions. When a position is assigned or active, the configured items are automatically granted to the user in real time.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isSyncingAll ? null : _syncAllExistingPositionUsers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isSyncingAll
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync, size: 18),
                  label: Text(
                    _isSyncingAll ? 'Syncing...' : '🔄 Auto-Sync All Users',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4 Position Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final crossAxisCount = isWide ? 2 : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 660,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: UserPositionService.supportedPositions.length,
                itemBuilder: (context, index) {
                  final pos = UserPositionService.supportedPositions[index];
                  return _buildPositionConfigCard(pos);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPositionConfigCard(String posKey) {
    Color cardColor;
    IconData icon;
    String posTitle = UserPositionService.getPositionDisplayName(posKey);

    switch (posKey) {
      case 'host':
        cardColor = const Color(0xFF10B981); // Emerald
        icon = Icons.mic;
        break;
      case 'agency':
        cardColor = const Color(0xFF3B82F6); // Blue
        icon = Icons.apartment;
        break;
      case 'seller':
        cardColor = const Color(0xFFF59E0B); // Amber
        icon = Icons.diamond;
        break;
      case 'official':
        cardColor = const Color(0xFFA855F7); // Purple
        icon = Icons.verified;
        break;
      case 'official_assistant':
        cardColor = const Color(0xFF06B6D4); // Cyan / Teal
        icon = Icons.support_agent;
        break;
      default:
        cardColor = Colors.cyan;
        icon = Icons.star;
    }

    final isSaving = _savingStatus[posKey] == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cardColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  posTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  posKey.toUpperCase(),
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155)),
          const SizedBox(height: 12),

          // 1. Frame Input (Left: Input, Right: Preview)
          _buildItemInputField(
            posKey: posKey,
            itemType: 'frame',
            label: 'Frame Item ID (ফ্রেম আইডি)',
            icon: Icons.filter_frames,
            controller: _frameControllers[posKey]!,
            accentColor: cardColor,
          ),
          const SizedBox(height: 14),

          // 2. Badge Input (Left: Input, Right: Preview)
          _buildItemInputField(
            posKey: posKey,
            itemType: 'badge',
            label: 'Badge Item ID (ব্যাজ আইডি)',
            icon: Icons.military_tech,
            controller: _badgeControllers[posKey]!,
            accentColor: cardColor,
          ),
          const SizedBox(height: 14),

          // 3. Nameplate Input (Left: Input, Right: Preview)
          _buildItemInputField(
            posKey: posKey,
            itemType: 'nameplate',
            label: 'Nameplate Item ID (নেমপ্লেট আইডি)',
            icon: Icons.badge,
            controller: _nameplateControllers[posKey]!,
            accentColor: cardColor,
          ),
          const Spacer(),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : () => _saveConfig(posKey),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save, size: 20),
              label: Text(
                isSaving ? 'Saving Configuration...' : 'Save ${posKey.toUpperCase()} Config',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInputField({
    required String posKey,
    required String itemType,
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color accentColor,
  }) {
    final cleanId = controller.text.trim();
    final preview = cleanId.isNotEmpty ? _itemPreviewCache[cleanId] : null;
    final hasImage = preview != null && (preview['imageUrl'] as String? ?? '').isNotEmpty;
    final itemName = preview?['name'] ?? (cleanId.isNotEmpty ? '$itemType #$cleanId' : 'No Item');
    final imageUrl = preview?['imageUrl'] as String? ?? '';
    final category = preview?['category'] ?? itemType;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasImage ? accentColor.withValues(alpha: 0.5) : const Color(0xFF334155),
          width: hasImage ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── LEFT SIDE: Input & Label & Browse Button ───
          Expanded(
            flex: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF475569)),
                        ),
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (val) {
                            if (val.trim().isNotEmpty) {
                              _fetchItemPreview(val.trim());
                            }
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter $itemType ID...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                      tooltip: 'Browse store items',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF475569)),
                        ),
                        padding: const EdgeInsets.all(10),
                      ),
                      onPressed: () => _openItemPickerModal(posKey, itemType, controller),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  cleanId.isEmpty
                      ? 'No ID configured'
                      : (preview != null
                          ? '✓ ID: $cleanId • $itemName'
                          : 'ID: $cleanId (Looking up item...)'),
                  style: TextStyle(
                    color: cleanId.isEmpty
                        ? const Color(0xFF64748B)
                        : (preview != null ? const Color(0xFF10B981) : Colors.amberAccent),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
          Container(
            height: 75,
            width: 1,
            color: const Color(0xFF334155),
          ),
          const SizedBox(width: 12),

          // ─── RIGHT SIDE: Visual Item Preview Box ───
          Expanded(
            flex: 38,
            child: Container(
              height: 96,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasImage ? accentColor.withValues(alpha: 0.6) : const Color(0xFF334155),
                  width: hasImage ? 1.5 : 1.0,
                ),
                boxShadow: hasImage
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: hasImage
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  Icon(icon, color: accentColor, size: 28),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '⭐ ${preview?['starRating'] ?? 1} Stars',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' • #$cleanId',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: cleanId.isNotEmpty
                              ? accentColor.withValues(alpha: 0.8)
                              : const Color(0xFF475569),
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cleanId.isNotEmpty
                              ? (preview != null ? itemName : 'Item #$cleanId')
                              : 'No Item',
                          style: TextStyle(
                            color: cleanId.isNotEmpty
                                ? Colors.white70
                                : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        if (cleanId.isNotEmpty)
                          Text(
                            '#$cleanId',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 2: Apply Position to User
  // ─────────────────────────────────────────────────────────────
  Widget _buildApplyPositionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search User to Assign Position',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter user Profile ID (searchId), User ID (uid), Unique ID, or Phone Number.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: TextField(
                          controller: _userSearchController,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _searchUser(),
                          decoration: const InputDecoration(
                            hintText: 'Search by Profile ID / UID / Phone...',
                            hintStyle: TextStyle(color: Color(0xFF64748B)),
                            prefixIcon: Icon(Icons.search, color: Color(0xFF38BDF8)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSearchingUser ? null : _searchUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        icon: _isSearchingUser
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.search, color: Colors.white),
                        label: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // User Profile Card if found
          if (_selectedUser != null) ...[
            _buildSelectedUserCard(),
            const SizedBox(height: 24),
            _buildPositionAssignmentCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedUserCard() {
    final user = _selectedUser!;
    final name = user['fullname'] ?? user['username'] ?? 'User';
    final profileId = user['searchId'] ?? user['id'] ?? '';
    final avatarUrl = user['image'] ?? user['profilePic'] ?? user['photoURL'] ?? '';
    final diamonds = (user['Diamonds'] ?? user['diamonds'] ?? 0).toString();

    final isHost = user['isHost'] == true || user['host'] == true;
    final isAgency = user['isAgency'] == true;
    final isSeller = user['isSeller'] == true;
    final isOfficial = user['isOfficial'] == true;
    final isOfficialAssistant = user['isOfficialAssistant'] == true;
    final userPositions = List<String>.from(user['userPositions'] as List? ?? []);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF334155),
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 32) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profile ID: $profileId | Diamonds: 💎 $diamonds',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF334155)),
          const SizedBox(height: 12),
          const Text(
            'Current Active Positions:',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isHost) _buildRoleChip('Host (হোস্ট)', const Color(0xFF10B981), Icons.mic),
              if (isAgency) _buildRoleChip('Agency (এজেন্সি)', const Color(0xFF3B82F6), Icons.apartment),
              if (isSeller) _buildRoleChip('Seller (সেলার)', const Color(0xFFF59E0B), Icons.diamond),
              if (isOfficial) _buildRoleChip('Official (অফিসিয়াল)', const Color(0xFFA855F7), Icons.verified),
              if (isOfficialAssistant) _buildRoleChip('Official Assistant (অফিসিয়াল অ্যাসিস্ট্যান্ট)', const Color(0xFF06B6D4), Icons.support_agent),
              for (final p in userPositions)
                if (!['host', 'agency', 'seller', 'official', 'official_assistant'].contains(p))
                  _buildRoleChip(p.toUpperCase(), Colors.cyan, Icons.star),
              if (!isHost && !isAgency && !isSeller && !isOfficial && !isOfficialAssistant && userPositions.isEmpty)
                const Chip(
                  backgroundColor: Color(0xFF334155),
                  label: Text('Regular User (No Special Positions)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionAssignmentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Position to Apply',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'The selected position role flag and all configured items (Frame, Badge, Nameplate) will be automatically added to the user\'s inventory.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Position Selection Chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: UserPositionService.supportedPositions.map((pos) {
              final isSelected = _selectedPositionToApply == pos;
              final title = UserPositionService.getPositionDisplayName(pos);

              return ChoiceChip(
                label: Text(title, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFCBD5E1), fontWeight: FontWeight.bold)),
                selected: isSelected,
                selectedColor: const Color(0xFF0284C7),
                backgroundColor: const Color(0xFF0F172A),
                side: BorderSide(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                onSelected: (val) {
                  if (val) setState(() => _selectedPositionToApply = pos);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Duration picker
          Row(
            children: [
              const Text('Duration:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: _selectedDurationDays,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                underline: Container(height: 1, color: Colors.blueAccent),
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 Days')),
                  DropdownMenuItem(value: 90, child: Text('90 Days')),
                  DropdownMenuItem(value: 180, child: Text('180 Days')),
                  DropdownMenuItem(value: 365, child: Text('365 Days (1 Year)')),
                  DropdownMenuItem(value: 3650, child: Text('Permanent (10 Years)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDurationDays = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isApplyingPosition ? null : _applyPositionToSelectedUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isApplyingPosition
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                _isApplyingPosition
                    ? 'Applying Position & Items...'
                    : 'Apply ${_selectedPositionToApply.toUpperCase()} Position & Grant Items',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 3: Position Users List
  // ─────────────────────────────────────────────────────────────
  Widget _buildPositionUsersTab() {
    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: TextField(
                        controller: _listSearchController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (val) {
                          setState(() {
                            _listSearchQuery = val.trim().toLowerCase();
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search by Name or Profile ID in list...',
                          hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          prefixIcon: Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSyncingAll ? null : _syncAllExistingPositionUsers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isSyncingAll
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: Text(
                      _isSyncingAll ? 'Syncing...' : '🔄 Auto-Sync All Users',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterTabChip('all', 'All Positions'),
                    const SizedBox(width: 8),
                    _buildFilterTabChip('host', '🎙️ Hosts'),
                    const SizedBox(width: 8),
                    _buildFilterTabChip('agency', '🏢 Agencies'),
                    const SizedBox(width: 8),
                    _buildFilterTabChip('seller', '💎 Sellers'),
                    const SizedBox(width: 8),
                    _buildFilterTabChip('official', '👑 Officials'),
                    const SizedBox(width: 8),
                    _buildFilterTabChip('official_assistant', '🎧 Official Assistants'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Stream list of users
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: UserPositionService.getPositionUsersStream(
              filterPosition: _activePositionFilter == 'all' ? null : _activePositionFilter,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.blue));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                );
              }

              var users = snapshot.data ?? [];

              if (_listSearchQuery.isNotEmpty) {
                users = users.where((u) {
                  final name = (u['fullname'] ?? u['username'] ?? '').toString().toLowerCase();
                  final id = (u['searchId'] ?? u['id'] ?? '').toString().toLowerCase();
                  return name.contains(_listSearchQuery) || id.contains(_listSearchQuery);
                }).toList();
              }

              if (users.isEmpty) {
                return const Center(
                  child: Text('No users found for this filter', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final u = users[index];
                  return _buildUserListItem(u);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabChip(String key, String label) {
    final isSelected = _activePositionFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: const Color(0xFF0F172A),
      side: BorderSide(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
      onSelected: (val) {
        if (val) setState(() => _activePositionFilter = key);
      },
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> user) {
    final userId = user['id'];
    final name = user['fullname'] ?? user['username'] ?? 'User';
    final profileId = user['searchId'] ?? userId;
    final avatarUrl = user['image'] ?? user['profilePic'] ?? user['photoURL'] ?? '';

    final isHost = user['isHost'] == true || user['host'] == true;
    final isAgency = user['isAgency'] == true;
    final isSeller = user['isSeller'] == true;
    final isOfficial = user['isOfficial'] == true;
    final isOfficialAssistant = user['isOfficialAssistant'] == true;

    final activePositions = <String>[];
    if (isHost) activePositions.add('host');
    if (isAgency) activePositions.add('agency');
    if (isSeller) activePositions.add('seller');
    if (isOfficial) activePositions.add('official');
    if (isOfficialAssistant) activePositions.add('official_assistant');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF334155),
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 24) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: $profileId',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: activePositions.map((pos) {
                    return Chip(
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: _getPositionColor(pos).withValues(alpha: 0.2),
                      side: BorderSide(color: _getPositionColor(pos)),
                      label: Text(
                        pos.toUpperCase(),
                        style: TextStyle(color: _getPositionColor(pos), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
            color: const Color(0xFF0F172A),
            onSelected: (action) {
              if (action.startsWith('remove_')) {
                final pos = action.replaceFirst('remove_', '');
                _removePositionFromUser(userId, pos, name);
              } else if (action.startsWith('resync_')) {
                final pos = action.replaceFirst('resync_', '');
                UserPositionService.applyPositionToUser(
                  userId: userId,
                  positionKey: pos,
                  adminId: AdminAuthService.currentUserId ?? 'admin',
                );
                _showSnackBar('🔄 Re-synced $pos items for $name', Colors.blue);
              }
            },
            itemBuilder: (context) => [
              for (final pos in activePositions) ...[
                PopupMenuItem(
                  value: 'resync_$pos',
                  child: Row(
                    children: [
                      const Icon(Icons.sync, color: Colors.blueAccent, size: 18),
                      const SizedBox(width: 8),
                      Text('Re-sync ${pos.toUpperCase()} Items', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove_$pos',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Text('Revoke ${pos.toUpperCase()} & Clean Items', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(String pos) {
    switch (pos) {
      case 'host':
        return const Color(0xFF10B981);
      case 'agency':
        return const Color(0xFF3B82F6);
      case 'seller':
        return const Color(0xFFF59E0B);
      case 'official':
        return const Color(0xFFA855F7);
      case 'official_assistant':
        return const Color(0xFF06B6D4);
      default:
        return Colors.cyan;
    }
  }
}
