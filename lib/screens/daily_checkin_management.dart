import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/base_screen.dart';

class DailyCheckInManagementScreen extends StatefulWidget {
  const DailyCheckInManagementScreen({super.key});

  @override
  State<DailyCheckInManagementScreen> createState() => _DailyCheckInManagementScreenState();
}

class _DailyCheckInManagementScreenState extends State<DailyCheckInManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isCheckInActive = true;
  List<Map<String, dynamic>> _rewards = [];
  Map<int, Map<String, dynamic>> _itemDetails = {};

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      setState(() => _isLoading = true);
      
      // Load platform config checkin active status
      final configDoc = await _firestore.collection('platform_config').doc('daily_checkin').get();
      bool isCheckInActive = true;
      if (configDoc.exists) {
        isCheckInActive = configDoc.data()?['isActive'] as bool? ?? true;
      } else {
        await _firestore.collection('platform_config').doc('daily_checkin').set({'isActive': true});
      }
      
      final querySnapshot = await _firestore.collection('daily_checkin_rewards').get();
      List<Map<String, dynamic>> loadedRewards = [];
      
      if (querySnapshot.docs.isEmpty) {
        final defaults = [
          {'dayIndex': 1, 'diamonds': 6000},
          {'dayIndex': 2, 'diamonds': 6000},
          {'dayIndex': 3, 'diamonds': 8000},
          {'dayIndex': 4, 'diamonds': 12000},
          {'dayIndex': 5, 'diamonds': 12000},
          {'dayIndex': 6, 'diamonds': 12000},
          {'dayIndex': 7, 'diamonds': 18000},
        ];
        
        for (var def in defaults) {
          await _firestore.collection('daily_checkin_rewards').doc('day_${def['dayIndex']}').set(def);
        }
        
        final freshQuery = await _firestore.collection('daily_checkin_rewards').get();
        loadedRewards = freshQuery.docs.map((doc) => doc.data()).toList();
      } else {
        loadedRewards = querySnapshot.docs.map((doc) => doc.data()).toList();
      }
      
      // Secondary lookup: Fetch item details from Firestore for any reward that has an itemId
      final Map<int, Map<String, dynamic>> itemDetailsMap = {};
      for (final reward in loadedRewards) {
        final itemId = reward['itemId'] != null ? (reward['itemId'] as num).toInt() : null;
        if (itemId != null) {
          final itemQuery = await _firestore
              .collection('market_items')
              .where('displayId', isEqualTo: itemId)
              .limit(1)
              .get();
          if (itemQuery.docs.isNotEmpty) {
            itemDetailsMap[itemId] = itemQuery.docs.first.data();
          }
        }
      }
      
      // Sort by dayIndex safely
      loadedRewards.sort((a, b) {
        final aDay = a['dayIndex'] != null ? (a['dayIndex'] as num).toInt() : 0;
        final bDay = b['dayIndex'] != null ? (b['dayIndex'] as num).toInt() : 0;
        return aDay.compareTo(bDay);
      });
      
      setState(() {
        _rewards = loadedRewards;
        _itemDetails = itemDetailsMap;
        _isCheckInActive = isCheckInActive;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading check-in rewards: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCheckInStatus(bool val) async {
    try {
      setState(() => _isCheckInActive = val);
      await _firestore.collection('platform_config').doc('daily_checkin').set({'isActive': val}, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val ? 'Daily Check-in service enabled' : 'Daily Check-in service disabled'),
          backgroundColor: val ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('Error toggling check-in status: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateReward(int dayIndex, int diamonds, int? itemId, int? itemDuration) async {
    try {
      final updateData = <String, dynamic>{
        'diamonds': diamonds,
      };
      if (itemId != null) {
        updateData['itemId'] = itemId;
        updateData['itemDuration'] = itemDuration ?? 1;
      } else {
        updateData['itemId'] = FieldValue.delete();
        updateData['itemDuration'] = FieldValue.delete();
      }

      await _firestore.collection('daily_checkin_rewards').doc('day_$dayIndex').update(updateData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reward updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadRewards();
    } catch (e) {
      debugPrint('Error updating reward: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _verifyItemId(int displayId) async {
    try {
      final querySnapshot = await _firestore
          .collection('market_items')
          .where('displayId', isEqualTo: displayId)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return data['name'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showEditDialog(Map<String, dynamic> reward) {
    final dayIndex = reward['dayIndex'] as int;
    final currentDiamonds = reward['diamonds'] != null ? (reward['diamonds'] as num).toInt() : 0;
    final currentItemId = reward['itemId'] as int?;
    final currentDuration = reward['itemDuration'] as int?;

    final diamondsController = TextEditingController(text: currentDiamonds.toString());
    final itemIdController = TextEditingController(text: currentItemId?.toString() ?? '');
    final durationController = TextEditingController(text: currentDuration?.toString() ?? '1');

    String itemStatus = 'No item reward configured';
    if (currentItemId != null) {
      if (_itemDetails[currentItemId] != null) {
        itemStatus = '✅ Found: ${_itemDetails[currentItemId]!['name']}';
      } else {
        itemStatus = '❌ Item ID not found!';
      }
    }
    bool isValidating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text('Edit Day $dayIndex Reward', style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: diamondsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Diamond Amount',
                      labelStyle: TextStyle(color: Colors.grey),
                      hintText: 'Leave empty or 0 if no diamonds',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: itemIdController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Item ID (5-digit)',
                            labelStyle: TextStyle(color: Colors.grey),
                            hintText: 'Leave empty if no item reward',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                          ),
                          onChanged: (val) {
                            setStateDialog(() {
                              if (val.trim().isEmpty) {
                                itemStatus = 'No item reward configured';
                              } else {
                                itemStatus = 'Need verification';
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: isValidating
                            ? null
                            : () async {
                                final idVal = int.tryParse(itemIdController.text.trim());
                                if (idVal != null) {
                                  setStateDialog(() {
                                    isValidating = true;
                                    itemStatus = 'Verifying...';
                                  });
                                  final name = await _verifyItemId(idVal);
                                  setStateDialog(() {
                                    isValidating = false;
                                    if (name != null) {
                                      itemStatus = '✅ Found: $name';
                                    } else {
                                      itemStatus = '❌ Item ID not found!';
                                    }
                                  });
                                } else {
                                  setStateDialog(() {
                                    itemStatus = '⚠️ Enter a valid number';
                                  });
                                }
                              },
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    itemStatus,
                    style: TextStyle(
                      color: itemStatus.startsWith('✅')
                          ? Colors.green
                          : itemStatus.startsWith('❌') || itemStatus.startsWith('⚠️')
                              ? Colors.red
                              : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (itemIdController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Item Duration (Days)',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final diamondsStr = diamondsController.text.trim();
                  int diamondsVal = 0;
                  if (diamondsStr.isNotEmpty) {
                    final parsed = int.tryParse(diamondsStr);
                    if (parsed == null || parsed < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid diamond amount'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    diamondsVal = parsed;
                  }

                  int? itemIdVal;
                  int? durationVal;

                  final itemIdStr = itemIdController.text.trim();

                  if (diamondsVal == 0 && itemIdStr.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a reward (diamonds, item, or both)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (itemIdStr.isNotEmpty) {
                    itemIdVal = int.tryParse(itemIdStr);
                    if (itemIdVal == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid Item ID'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // Only verify from Firestore if not already verified
                    final bool isVerified = itemStatus.startsWith('✅') && 
                        (currentItemId == itemIdVal || itemStatus.contains(itemIdStr));

                    if (!isVerified) {
                      setStateDialog(() {
                        isValidating = true;
                        itemStatus = 'Verifying...';
                      });
                      final name = await _verifyItemId(itemIdVal);
                      setStateDialog(() {
                        isValidating = false;
                      });

                      if (name == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Item ID not found, please verify!'), backgroundColor: Colors.red),
                          );
                        }
                        return;
                      }
                    }

                    durationVal = int.tryParse(durationController.text.trim());
                    if (durationVal == null || durationVal <= 0) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid duration (minimum 1 day)'), backgroundColor: Colors.red),
                        );
                      }
                      return;
                    }
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  _updateReward(dayIndex, diamondsVal, itemIdVal, durationVal);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListRewardItemImage(int itemId) {
    final itemData = _itemDetails[itemId];
    String imageUrl = '';
    if (itemData != null) {
      final thumb = itemData['thumbnailUrl'];
      final file = itemData['fileUrl'];
      imageUrl = (thumb ?? file ?? '').toString();
    }
    final hasImage = imageUrl != '' && !imageUrl.endsWith('.svga');
    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          width: 20,
          height: 20,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.card_giftcard, color: Colors.green, size: 16),
        ),
      );
    }
    return const Icon(Icons.card_giftcard, color: Colors.green, size: 16);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Daily Check-in Management',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure Daily Check-in Rewards',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set the amount of diamonds and optional store/official items users receive when checking in.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[800]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isCheckInActive ? Icons.check_circle : Icons.cancel,
                                color: _isCheckInActive ? Colors.green : Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Daily Check-in Service',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    _isCheckInActive ? 'Currently Active & Enabled' : 'Disabled (Users cannot check-in)',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: _isCheckInActive,
                            activeThumbColor: Colors.green,
                            activeTrackColor: Colors.green.withValues(alpha: 0.5),
                            inactiveTrackColor: Colors.grey[800],
                            onChanged: (val) => _toggleCheckInStatus(val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _rewards.length,
                      itemBuilder: (context, index) {
                        final reward = _rewards[index];
                        final dayIndex = reward['dayIndex'] as int;
                        final diamonds = reward['diamonds'] != null ? (reward['diamonds'] as num).toInt() : 0;
                        final itemId = reward['itemId'] as int?;
                        final itemDuration = reward['itemDuration'] as int?;

                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[800]!),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withValues(alpha: 0.1),
                              child: Text(
                                '$dayIndex',
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              'Day $dayIndex Reward',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (diamonds > 0)
                                  Row(
                                    children: [
                                      const Icon(Icons.diamond, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$diamonds Diamonds',
                                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                if (itemId != null) ...[
                                  if (diamonds > 0) const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildListRewardItemImage(itemId),
                                      const SizedBox(width: 6),
                                      Text(
                                        _itemDetails[itemId] != null
                                            ? '${_itemDetails[itemId]!['name']} (ID: $itemId, $itemDuration Days)'
                                            : 'Item ID: $itemId ($itemDuration Days)',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDialog(reward),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
