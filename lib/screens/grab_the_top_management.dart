import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/base_screen.dart';
import '../widgets/media_preview_widget.dart';
import '../models/grab_the_top_model.dart';

class GrabTheTopManagementScreen extends StatefulWidget {
  const GrabTheTopManagementScreen({super.key});

  @override
  State<GrabTheTopManagementScreen> createState() => _GrabTheTopManagementScreenState();
}

class _GrabTheTopManagementScreenState extends State<GrabTheTopManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isFeatureEnabled = true;
  List<GrabTheTopRuleModel> _rules = [];
  List<Map<String, dynamic>> _availableGifts = [];

  StreamSubscription<QuerySnapshot>? _rulesSubscription;
  StreamSubscription<DocumentSnapshot>? _configSubscription;

  @override
  void initState() {
    super.initState();
    _loadAvailableGifts();
    _listenToFeatureConfig();
    _listenToRules();
  }

  @override
  void dispose() {
    _rulesSubscription?.cancel();
    _configSubscription?.cancel();
    super.dispose();
  }

  /// Load available gifts from Firestore for the gift dropdown selector
  Future<void> _loadAvailableGifts() async {
    try {
      final List<Map<String, dynamic>> giftsList = [];
      final categoriesSnap = await _firestore.collection('gift').get();

      for (final doc in categoriesSnap.docs) {
        if (doc.id == 'categories_config') continue;
        final data = doc.data();
        if (data.containsKey('gifts') && data['gifts'] is List) {
          final list = data['gifts'] as List;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final String id = item['id']?.toString() ?? '';
              final String name = item['name']?.toString() ?? '';
              final String? imageUrl = item['imageUrl']?.toString() ?? item['pngUrl']?.toString();
              if (name.isNotEmpty) {
                giftsList.add({
                  'id': id.isNotEmpty ? id : '2001',
                  'name': name,
                  'imageUrl': imageUrl,
                  'category': doc.id,
                });
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableGifts = giftsList;
        });
      }
    } catch (e) {
      debugPrint('Error loading available gifts: $e');
    }
  }

  void _listenToFeatureConfig() {
    _configSubscription = _firestore
        .collection('platform_config')
        .doc('grab_the_top')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        setState(() {
          _isFeatureEnabled = data['isFeatureEnabled'] ?? true;
        });
      }
    });
  }

  void _listenToRules() {
    _rulesSubscription = _firestore
        .collection('platform_config')
        .doc('grab_the_top')
        .collection('rules')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        final loaded = snapshot.docs.map((doc) => GrabTheTopRuleModel.fromFirestore(doc)).toList();
        setState(() {
          _rules = loaded;
          _isLoading = false;
        });
      },
      onError: (e) {
        debugPrint('Error listening to Grab The Top rules: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _toggleGlobalFeature(bool enabled) async {
    try {
      await _firestore.collection('platform_config').doc('grab_the_top').set({
        'isFeatureEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled
                ? 'Grab the Top 🪑 feature is ENABLED globally'
                : 'Grab the Top 🪑 feature is DISABLED globally'),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling global feature: $e');
    }
  }

  Future<void> _toggleRuleStatus(GrabTheTopRuleModel rule, bool newStatus) async {
    try {
      await _firestore
          .collection('platform_config')
          .doc('grab_the_top')
          .collection('rules')
          .doc(rule.id)
          .update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? 'Rule activated for ${rule.giftName} (${rule.minGiftCount}x)'
                : 'Rule deactivated for ${rule.giftName}'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling rule status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteRule(GrabTheTopRuleModel rule) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Delete Rule', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete the Grab the Top rule for "${rule.giftName}" (${rule.minGiftCount}x)?',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await _firestore
          .collection('platform_config')
          .doc('grab_the_top')
          .collection('rules')
          .doc(rule.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rule deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting rule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Grab the Top 🪑 Management',
      actions: [
        IconButton(
          onPressed: () => _showRuleDialog(),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Add Rule',
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderControlBar(),
                  const SizedBox(height: 16),
                  _buildStatsBar(),
                  const SizedBox(height: 20),
                  _buildRulesHeader(),
                  const SizedBox(height: 12),
                  _buildRulesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderControlBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E1E2C), const Color(0xFF2A2A3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_seat_rounded, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grab the Top 🪑 Feature',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isFeatureEnabled
                      ? 'Global feature is ACTIVE. Matching gift sends will trigger Top Seat banner for Sender & Receiver.'
                      : 'Global feature is INACTIVE. Top Seat banners are disabled.',
                  style: TextStyle(
                    color: _isFeatureEnabled ? Colors.greenAccent : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: _isFeatureEnabled,
              activeColor: Colors.greenAccent,
              inactiveThumbColor: Colors.redAccent,
              onChanged: (val) => _toggleGlobalFeature(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final activeCount = _rules.where((r) => r.isActive).length;
    final inactiveCount = _rules.length - activeCount;
    final uniqueGifts = _rules.map((r) => r.giftId).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Rules',
            value: _rules.length.toString(),
            icon: Icons.rule,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Active Rules',
            value: activeCount.toString(),
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Inactive Rules',
            value: inactiveCount.toString(),
            icon: Icons.pause_circle_outline,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Gifts Targeted',
            value: uniqueGifts.toString(),
            icon: Icons.card_giftcard,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRulesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Configured Trigger Rules',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showRuleDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New Rule'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildRulesList() {
    if (_rules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_seat, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No Grab the Top 🪑 rules configured yet',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Click "Add New Rule" to configure which gift and quantity triggers the Top Seat banner.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _rules.length,
      itemBuilder: (context, index) {
        final rule = _rules[index];
        return _buildRuleCard(rule);
      },
    );
  }

  Widget _buildRuleCard(GrabTheTopRuleModel rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rule.isActive ? const Color(0xFF2A2A2A) : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Gift Preview Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: rule.giftImageUrl != null && rule.giftImageUrl!.isNotEmpty
                  ? MediaPreviewWidget(
                      url: rule.giftImageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      borderRadius: BorderRadius.circular(8),
                    )
                  : const Icon(Icons.card_giftcard, color: Colors.amber, size: 24),
            ),
          ),
          const SizedBox(width: 16),

          // Gift Details & Rule Settings
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rule.giftName,
                      style: TextStyle(
                        color: rule.isActive ? Colors.white : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Gift ID Chip
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: rule.giftId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied Gift ID ${rule.giftId}'), duration: const Duration(seconds: 1)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ID: ${rule.giftId}',
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, color: Colors.blueAccent, size: 10),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Active Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (rule.isActive ? Colors.green : Colors.red).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: (rule.isActive ? Colors.green : Colors.red).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: rule.isActive ? Colors.greenAccent : Colors.redAccent, size: 7),
                          const SizedBox(width: 4),
                          Text(
                            rule.isActive ? 'Active' : 'Deactive',
                            style: TextStyle(
                              color: rule.isActive ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Gift Quantity Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, color: Colors.amber, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Min Gift Count: ${rule.minGiftCount}x',
                            style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Showing Time Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.purpleAccent, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Showing Time: ${rule.showingTimeSeconds}s',
                            style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions Row (Switch, Edit, Delete)
          Row(
            children: [
              Tooltip(
                message: rule.isActive ? 'Deactivate Rule' : 'Activate Rule',
                child: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: rule.isActive,
                    activeColor: Colors.greenAccent,
                    inactiveThumbColor: Colors.redAccent,
                    onChanged: (val) => _toggleRuleStatus(rule, val),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                onPressed: () => _showRuleDialog(rule: rule),
                tooltip: 'Edit Rule',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () => _deleteRule(rule),
                tooltip: 'Delete Rule',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRuleDialog({GrabTheTopRuleModel? rule}) {
    final isEditing = rule != null;

    Map<String, dynamic>? selectedGift;
    final TextEditingController giftIdController = TextEditingController(text: rule?.giftId ?? '');
    final TextEditingController giftNameController = TextEditingController(text: rule?.giftName ?? '');
    final TextEditingController giftQuantityController = TextEditingController(text: (rule?.minGiftCount ?? 10).toString());
    final TextEditingController showingTimeController = TextEditingController(text: (rule?.showingTimeSeconds ?? 10).toString());
    final TextEditingController bannerTitleController = TextEditingController(text: rule?.bannerTitle ?? '👑 {sender} sent {count}x {gift} to {receiver} and Grabbed the Top! 🪑');
    
    bool ruleIsActive = rule?.isActive ?? true;
    String? selectedGiftImageUrl = rule?.giftImageUrl;
    bool isSaving = false;

    // Match initial selected gift if editing
    if (isEditing && _availableGifts.isNotEmpty) {
      final matched = _availableGifts.firstWhere(
        (g) => g['id'] == rule.giftId || g['name'] == rule.giftName,
        orElse: () => {},
      );
      if (matched.isNotEmpty) {
        selectedGift = matched;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.event_seat, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Edit Grab the Top Rule 🪑' : 'Add Grab the Top Rule 🪑',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select gift and count required to trigger Top Seat Banner for Sender & Receiver.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      // Gift Dropdown Selector
                      const Text('Select Gift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: selectedGift,
                        dropdownColor: Colors.grey[850],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Choose Gift from Store/Gifts List',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _availableGifts.map((giftMap) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: giftMap,
                            child: Row(
                              children: [
                                if (giftMap['imageUrl'] != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: MediaPreviewWidget(
                                      url: giftMap['imageUrl']!,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  '${giftMap['name']} (ID: ${giftMap['id']})',
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedGift = val;
                              giftIdController.text = val['id'] ?? '';
                              giftNameController.text = val['name'] ?? '';
                              selectedGiftImageUrl = val['imageUrl'];
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Manual Gift ID & Gift Name Fields
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: giftIdController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Gift ID',
                                hintText: 'e.g. 2001',
                                labelStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: giftNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Gift Name',
                                hintText: 'e.g. Rose',
                                labelStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Gift Quantity & Showing Time
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: giftQuantityController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Gift Shonkha / Quantity (কয়টা গিফট)',
                                hintText: 'e.g. 10',
                                labelStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Colors.amber, size: 18),
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: showingTimeController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Showing Time (seconds)',
                                hintText: 'e.g. 10',
                                labelStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.timer, color: Colors.purpleAccent, size: 18),
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Active Status Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ruleIsActive ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.power_settings_new,
                                  color: ruleIsActive ? Colors.greenAccent : Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Status: ${ruleIsActive ? "Active (সক্রিয়)" : "Deactive (নিষ্ক্রিয়)"}',
                                  style: TextStyle(
                                    color: ruleIsActive ? Colors.greenAccent : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: ruleIsActive,
                              activeColor: Colors.greenAccent,
                              inactiveThumbColor: Colors.redAccent,
                              onChanged: (val) {
                                setDialogState(() {
                                  ruleIsActive = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final String gId = giftIdController.text.trim();
                          final String gName = giftNameController.text.trim();
                          final int gQty = int.tryParse(giftQuantityController.text.trim()) ?? 1;
                          final int showTime = int.tryParse(showingTimeController.text.trim()) ?? 10;

                          if (gId.isEmpty || gName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select or enter Gift ID and Name'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            final ruleData = {
                              'giftId': gId,
                              'giftName': gName,
                              'giftImageUrl': selectedGiftImageUrl,
                              'minGiftCount': gQty,
                              'giftQuantity': gQty,
                              'showingTimeSeconds': showTime,
                              'showingTime': showTime,
                              'isActive': ruleIsActive,
                              'bannerTitle': bannerTitleController.text.trim(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            if (isEditing) {
                              await _firestore
                                  .collection('platform_config')
                                  .doc('grab_the_top')
                                  .collection('rules')
                                  .doc(rule.id)
                                  .update(ruleData);
                            } else {
                              ruleData['createdAt'] = FieldValue.serverTimestamp();
                              await _firestore
                                  .collection('platform_config')
                                  .doc('grab_the_top')
                                  .collection('rules')
                                  .add(ruleData);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEditing ? 'Rule updated successfully' : 'Rule added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error saving rule: $e');
                            setDialogState(() => isSaving = false);
                          }
                        },
                  icon: const Icon(Icons.save, color: Colors.white, size: 18),
                  label: Text(isSaving ? 'Saving...' : (isEditing ? 'Save Edits' : 'Create Rule')),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
