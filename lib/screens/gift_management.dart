import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../widgets/base_screen.dart';
import '../widgets/media_preview_widget.dart';
import '../services/simple_auth_service.dart';
import '../services/admin_permission_service.dart';
import '../models/gift_transaction_model.dart';
import 'gift_history_screen.dart';

// Simple data class for handling gift data
class _GiftData {
  final String id;
  final Map<String, dynamic> data;
  final String category;

  _GiftData({required this.id, required this.data, required this.category});

  bool get isActive => data['isActive'] ?? true;
  String get giftId => data['id']?.toString() ?? '2001';
}

class GiftManagement extends StatefulWidget {
  const GiftManagement({super.key});

  @override
  State<GiftManagement> createState() => _GiftManagementState();
}

class _GiftManagementState extends State<GiftManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<_GiftData> _gifts = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String _selectedCategory = 'Hot';
  final List<String> _categories = [
    'Hot',
    'Event',
    'Lucky',
    'Local',
    'Privilege',
    'Trick',
    'Customized',
  ];

  final TextEditingController _DiamondsController = TextEditingController();
  final TextEditingController _giftNameController = TextEditingController();
  final TextEditingController _diamondCountPercentController = TextEditingController(text: '80');
  final TextEditingController _minMultiplierController = TextEditingController(text: '2');
  final TextEditingController _maxMultiplierController = TextEditingController(text: '500');

  // Thumbnail (PNG)
  Uint8List? _selectedThumbnailBytes;
  String? _selectedThumbnailName;

  // Animation (SVGA)
  Uint8List? _selectedAnimationBytes;
  String? _selectedAnimationName;
  String? _selectedAnimationType;

  @override
  void initState() {
    super.initState();
    _syncCategoryMetadata();
    _ensureAllGiftsHaveIds();
    _loadGifts();
  }

  Future<void> _ensureAllGiftsHaveIds() async {
    try {
      final categoriesSnap = await _firestore.collection('gift').get();
      int maxExisting = 2000;
      for (final doc in categoriesSnap.docs) {
        final data = doc.data();
        final giftsList = data['gifts'] as List<dynamic>?;
        if (giftsList != null) {
          for (final giftMap in giftsList) {
            if (giftMap is Map<String, dynamic>) {
              final rawId = giftMap['id'] ?? giftMap['displayId'] ?? giftMap['giftId'];
              if (rawId != null) {
                final parsed = int.tryParse(rawId.toString());
                if (parsed != null && parsed >= 2001 && parsed < 100000) {
                  if (parsed > maxExisting) maxExisting = parsed;
                }
              }
            }
          }
        }
      }

      int currentId = maxExisting + 1;
      bool updatedAny = false;

      for (final doc in categoriesSnap.docs) {
        if (doc.id == 'categories_config') continue;
        final data = doc.data();
        final giftsList = data['gifts'] as List<dynamic>?;
        if (giftsList != null && giftsList.isNotEmpty) {
          List<Map<String, dynamic>> updatedGifts = [];
          bool docNeedsUpdate = false;

          for (final giftItem in giftsList) {
            if (giftItem is Map<String, dynamic>) {
              final map = Map<String, dynamic>.from(giftItem);
              bool itemModified = false;

              final rawId = map['id'] ?? map['displayId'] ?? map['giftId'];
              final parsed = rawId != null ? int.tryParse(rawId.toString()) : null;

              if (rawId == null || parsed == null || parsed >= 100000) {
                map['id'] = currentId.toString();
                currentId++;
                itemModified = true;
              }

              if (!map.containsKey('isActive') || map['isActive'] == null) {
                map['isActive'] = true;
                itemModified = true;
              }

              if (itemModified) docNeedsUpdate = true;
              updatedGifts.add(map);
            }
          }

          if (docNeedsUpdate) {
            await _firestore.collection('gift').doc(doc.id).update({'gifts': updatedGifts});
            updatedAny = true;
          }
        }
      }
      if (updatedAny && mounted) {
        _loadGifts();
      }
    } catch (e) {
      debugPrint('Error ensuring gift IDs: $e');
    }
  }

  Future<String> _generateNextGiftId() async {
    try {
      int maxId = 2000;
      final categoriesSnap = await _firestore.collection('gift').get();
      for (final doc in categoriesSnap.docs) {
        final data = doc.data();
        if (data.containsKey('gifts')) {
          final giftsList = data['gifts'] as List<dynamic>?;
          if (giftsList != null) {
            for (final giftMap in giftsList) {
              if (giftMap is Map<String, dynamic>) {
                final rawId = giftMap['id'] ?? giftMap['displayId'] ?? giftMap['giftId'];
                if (rawId != null) {
                  final parsed = int.tryParse(rawId.toString());
                  if (parsed != null && parsed >= 2001 && parsed < 100000) {
                    if (parsed > maxId) {
                      maxId = parsed;
                    }
                  }
                }
              }
            }
          }
        }
      }
      return (maxId + 1).toString();
    } catch (e) {
      debugPrint('Error generating next gift ID: $e');
      return '2001';
    }
  }

  Future<void> _toggleGiftStatus(_GiftData gift, bool newStatus) async {
    try {
      final oldDocRef = _firestore.collection('gift').doc(gift.category);
      final snapshot = await oldDocRef.get();
      if (!snapshot.exists) return;

      List<dynamic> gifts = List.from(snapshot.data()?['gifts'] ?? []);
      final index = gifts.indexWhere((g) =>
        (g is Map && g['id']?.toString() == gift.giftId) ||
        (g is Map && g['name'] == gift.data['name'] && g['imageUrl'] == gift.data['imageUrl'])
      );

      if (index != -1) {
        final Map<String, dynamic> updatedMap = Map<String, dynamic>.from(gifts[index]);
        updatedMap['isActive'] = newStatus;
        gifts[index] = updatedMap;

        await oldDocRef.update({'gifts': gifts});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus
                ? 'Gift activated (${gift.data['name']})'
                : 'Gift deactivated (${gift.data['name']})'),
              backgroundColor: newStatus ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        _loadGifts();
      }
    } catch (e) {
      debugPrint('Error toggling gift status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _syncCategoryMetadata() async {
    try {
      final batch = _firestore.batch();

      // Sync Category Order Metadata in gift/categories_config & system_settings/gift_categories
      final categoryOrderData = {
        'categories': _categories,
        'order': _categories,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(
        _firestore.collection('gift').doc('categories_config'),
        categoryOrderData,
        SetOptions(merge: true),
      );

      batch.set(
        _firestore.collection('system_settings').doc('gift_categories'),
        categoryOrderData,
        SetOptions(merge: true),
      );

      // Ensure every category document exists and has metadata (order, category, title, type)
      for (int i = 0; i < _categories.length; i++) {
        final catName = _categories[i];
        final catDocRef = _firestore.collection('gift').doc(catName);
        batch.set(
          catDocRef,
          {
            'category': catName,
            'categoryName': catName,
            'title': catName,
            'order': i,
            'type': i.toString(),
            'categoryIndex': i,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error syncing category metadata: $e');
    }
  }

  StreamSubscription<DocumentSnapshot>? _giftSubscription;

  @override
  void dispose() {
    _giftSubscription?.cancel();
    _DiamondsController.dispose();
    _giftNameController.dispose();
    _diamondCountPercentController.dispose();
    _minMultiplierController.dispose();
    _maxMultiplierController.dispose();
    super.dispose();
  }

  void _loadGifts() {
    _giftSubscription?.cancel();
    setState(() {
      _isLoading = true;
    });

    // Listen to real-time changes in selected category document
    _giftSubscription = _firestore
        .collection('gift')
        .doc(_selectedCategory)
        .snapshots()
        .listen(
      (categoryDoc) {
        if (!mounted) return;
        if (categoryDoc.exists) {
          final data = categoryDoc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('gifts')) {
            final giftsList = data['gifts'] as List<dynamic>?;
            if (giftsList != null) {
              final List<_GiftData> giftsData = giftsList.asMap().entries.map((
                entry,
              ) {
                final giftMap = entry.value as Map<String, dynamic>;
                return _GiftData(
                  id: '${_selectedCategory}_${entry.key}',
                  data: giftMap,
                  category: _selectedCategory,
                );
              }).toList();

              setState(() {
                _gifts = giftsData;
                _isLoading = false;
              });
              return;
            }
          }
        }

        setState(() {
          _gifts = [];
          _isLoading = false;
        });
      },
      onError: (e) {
        debugPrint('Error listening to gifts stream: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _pickThumbnail() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.extension?.toLowerCase() != 'png') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only PNG files are allowed for thumbnails'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        setState(() {
          _selectedThumbnailBytes = file.bytes;
          _selectedThumbnailName = file.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking thumbnail: $e');
    }
  }

  Future<void> _pickAnimation() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svga', 'png', 'gif', 'webp', 'mp4', 'vap', 'webm', 'mov', 'avi'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final ext = file.extension?.toLowerCase();
        if (ext != 'svga' && ext != 'png' && ext != 'gif' && ext != 'webp' && ext != 'mp4' && ext != 'vap' && ext != 'webm' && ext != 'mov' && ext != 'avi') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unsupported file format for main file.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        setState(() {
          _selectedAnimationBytes = file.bytes;
          _selectedAnimationName = file.name;
          _selectedAnimationType = file.extension;
        });
      }
    } catch (e) {
      debugPrint('Error picking animation: $e');
    }
  }

  Future<String?> _uploadFile(Uint8List bytes, String name) async {
    try {
      final fileName = 'gift_${DateTime.now().millisecondsSinceEpoch}_$name';
      final ref = _storage.ref().child('gift/$fileName');
      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _addGift() async {
    try {
      if (_DiamondsController.text.isEmpty || _giftNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedThumbnailBytes == null || _selectedAnimationBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both thumbnail and main file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final Diamonds = int.tryParse(_DiamondsController.text);
      if (Diamonds == null || Diamonds <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid Diamond amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      // Upload Thumbnail
      final imageUrl = await _uploadFile(
        _selectedThumbnailBytes!,
        _selectedThumbnailName!,
      );
      if (imageUrl == null) throw Exception('Failed to upload thumbnail');

      // Upload Animation
      final svgaUrl = await _uploadFile(
        _selectedAnimationBytes!,
        _selectedAnimationName!,
      );
      if (svgaUrl == null) throw Exception('Failed to upload animation');

      final String giftId = await _generateNextGiftId();

      final diamondCountVal = double.tryParse(_diamondCountPercentController.text) ?? 80.0;
      final minMultVal = int.tryParse(_minMultiplierController.text) ?? 2;
      final maxMultVal = int.tryParse(_maxMultiplierController.text) ?? 500;

      final giftData = {
        'id': giftId,
        'Diamond': Diamonds.toString(),
        'diamond': Diamonds.toString(),
        'credits': Diamonds,
        'imageUrl': imageUrl,
        'svgaUrl': svgaUrl,
        'type': _categories.indexOf(_selectedCategory).toString(),
        'category': _selectedCategory,
        'categoryName': _selectedCategory,
        'categoryIndex': _categories.indexOf(_selectedCategory),
        'name': _giftNameController.text,
        'isActive': true,
        if (_selectedCategory == 'Lucky') ...{
          'isLuckyGift': true,
          'diamondCountPercent': diamondCountVal,
          'minMultiplier': minMultVal,
          'maxMultiplier': maxMultVal,
          'luckyMultipliers': [
            minMultVal,
            10,
            50,
            100,
            maxMultVal,
          ],
          'winRate': diamondCountVal,
          'jackpotMaxMultiplier': maxMultVal,
        },
      };

      // Set with merge: true so it creates document and array if doc doesn't exist yet!
      await _firestore.collection('gift').doc(_selectedCategory).set({
        'gifts': FieldValue.arrayUnion([giftData]),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gift added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _clearForm();
      if (mounted) Navigator.pop(context);
      _loadGifts();
    } catch (e) {
      debugPrint('Error adding gift: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding gift: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _clearForm() {
    _DiamondsController.clear();
    _giftNameController.clear();
    _diamondCountPercentController.text = '80';
    _minMultiplierController.text = '2';
    _maxMultiplierController.text = '500';
    setState(() {
      _selectedThumbnailBytes = null;
      _selectedThumbnailName = null;
      _selectedAnimationBytes = null;
      _selectedAnimationName = null;
      _selectedAnimationType = null;
    });
  }

  Future<void> _deleteGift(_GiftData gift) async {
    try {
      await _firestore.collection('gift').doc(gift.category).update({
        'gifts': FieldValue.arrayRemove([gift.data]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gift deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadGifts();
    } catch (e) {
      debugPrint('Error deleting gift: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting gift: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Gift Management',
      actions: [
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GiftHistoryScreen()),
          ),
          icon: const Icon(Icons.history),
          tooltip: 'Gift History',
        ),
        IconButton(
          onPressed: () => _showAddGiftDialog(),
          icon: const Icon(Icons.add),
          tooltip: 'Add Gift',
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(children: [_buildCategoryFilter(), _buildGiftsList()]),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.category_outlined,
            color: Color(0xFF888888),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Category',
            style: TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedCategory,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              underline: const SizedBox(),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF888888),
                size: 20,
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                  _loadGifts(); // Reload gifts when category changes
                }
              },
            ),
          ),
          if (_selectedCategory == 'Lucky') ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showLuckyGiftSettingsDialog(),
              icon: const Icon(Icons.settings_suggest, size: 16, color: Colors.white),
              label: const Text(
                'Lucky Gift Settings ⚙️',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[800],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGiftsList() {
    final categoryGifts = _gifts.where((gift) {
      return gift.category == _selectedCategory;
    }).toList();

    if (categoryGifts.isEmpty) {
      return Expanded(
        child: Container(
          color: const Color(0xFF0A0A0A),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2A2A2A),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_outlined,
                    size: 40,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No gifts found',
                  style: TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add gifts to the $_selectedCategory category',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _showAddGiftDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Gift'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        color: const Color(0xFF0A0A0A),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: categoryGifts.length,
          itemBuilder: (context, index) {
            final gift = categoryGifts[index];
            final data = gift.data;

            final name = data['name']?.toString() ?? 'Unnamed Gift';
            final Diamonds = (data['Diamond'] ?? data['diamond'] ?? data['credits'] ?? data['coin'] ?? data['coins'] ?? data['price'] ?? data['amount'] ?? '0').toString();
            final imageUrl = data['imageUrl']?.toString();

            return _buildGiftListItem(
              gift: gift,
              name: name,
              Diamonds: Diamonds,
              imageUrl: imageUrl,
            );
          },
        ),
      ),
    );
  }

  Widget _buildGiftListItem({
    required _GiftData gift,
    required String name,
    required String Diamonds,
    String? imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gift.isActive ? const Color(0xFF2A2A2A) : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Gift Preview
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2A2A2A),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? MediaPreviewWidget(
                            url: imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(8),
                          )
                        : const Icon(
                            Icons.card_giftcard,
                            color: Color(0xFF666666),
                            size: 24,
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                // Gift Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: gift.isActive ? const Color(0xFFE0E0E0) : Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ID Badge
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: gift.giftId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Copied Gift ID ${gift.giftId} to clipboard'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.4), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ID: ${gift.giftId}',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy, color: Colors.blueAccent, size: 10),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (gift.isActive ? Colors.green : Colors.red).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (gift.isActive ? Colors.green : Colors.red).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: gift.isActive ? Colors.greenAccent : Colors.redAccent,
                                  size: 7,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  gift.isActive ? 'Active' : 'Deactive',
                                  style: TextStyle(
                                    color: gift.isActive ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFF59E0B),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monetization_on_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  Diamonds,
                                  style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedCategory,
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (_selectedCategory == 'Lucky' || gift.data['isLuckyGift'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.amber, Colors.purpleAccent],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.casino, color: Colors.white, size: 11),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lucky (${gift.data['minMultiplier'] ?? 2}x - ${gift.data['maxMultiplier'] ?? 500}x | ${gift.data['diamondCountPercent'] ?? gift.data['winRate'] ?? 80}%)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Edit and Delete Buttons + Status Switch
                Row(
                  children: [
                    Tooltip(
                      message: gift.isActive ? 'Deactivate Gift' : 'Activate Gift',
                      child: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: gift.isActive,
                          activeColor: Colors.greenAccent,
                          inactiveThumbColor: Colors.redAccent,
                          inactiveTrackColor: Colors.red.withValues(alpha: 0.3),
                          onChanged: (bool val) {
                            _toggleGiftStatus(gift, val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2438),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1E3A8A),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showEditGiftDialog(gift),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Color(0xFF3B82F6),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4A1A1A),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _deleteGift(gift),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLuckyGiftSettingsDialog() async {
    final docSnap = await _firestore.collection('gift').doc('Lucky').get();
    final data = docSnap.data() as Map<String, dynamic>? ?? {};
    final configMap = data['luckyGiftConfig'] as Map<String, dynamic>? ?? {};

    final returnRateController = TextEditingController(text: (configMap['returnRate'] ?? 80).toString());
    final mult5xController = TextEditingController(text: (configMap['prob5x'] ?? 25).toString());
    final mult10xController = TextEditingController(text: (configMap['prob10x'] ?? 10).toString());
    final mult50xController = TextEditingController(text: (configMap['prob50x'] ?? 3).toString());
    final mult100xController = TextEditingController(text: (configMap['prob100x'] ?? 1).toString());
    final mult500xController = TextEditingController(text: (configMap['prob500x'] ?? 0.1).toString());
    final jackpotSeedController = TextEditingController(text: (configMap['jackpotSeedPool'] ?? 100000).toString());
    String announceThreshold = (configMap['announceThreshold'] ?? '50x').toString();

    bool isSaving = false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.casino, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Lucky Gift Settings ⚙️',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                        'Configure Win Probabilities, Multipliers & Return Rates for Lucky Gifts in Real-Time',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      // Overall Return Rate (RTP %)
                      TextField(
                        controller: returnRateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Overall Return Rate (RTP %)',
                          hintText: 'e.g. 80',
                          prefixIcon: const Icon(Icons.percent, color: Colors.amber),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Multiplier Win Probabilities (%)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: mult5xController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '5x Win Rate (%)',
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: mult10xController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '10x Win Rate (%)',
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: mult50xController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '50x Win Rate (%)',
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: mult100xController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '100x Win Rate (%)',
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: mult500xController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: '👑 500x Jackpot Win Rate (%)',
                          hintText: 'e.g. 0.1',
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Jackpot Pool Seed
                      TextField(
                        controller: jackpotSeedController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Jackpot Initial Pool (Diamonds)',
                          prefixIcon: const Icon(Icons.monetization_on, color: Colors.amber),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Room Announcement Threshold
                      DropdownButtonFormField<String>(
                        value: announceThreshold,
                        dropdownColor: Colors.grey[800],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Global Banner Announcement Threshold',
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: '10x', child: Text('Win >= 10x')),
                          DropdownMenuItem(value: '50x', child: Text('Win >= 50x (Recommended)')),
                          DropdownMenuItem(value: '100x', child: Text('Win >= 100x')),
                          DropdownMenuItem(value: '500x', child: Text('Win >= 500x Jackpot Only')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => announceThreshold = val);
                          }
                        },
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
                          setDialogState(() => isSaving = true);
                          try {
                            final luckyConfig = {
                              'returnRate': double.tryParse(returnRateController.text) ?? 80,
                              'prob5x': double.tryParse(mult5xController.text) ?? 25,
                              'prob10x': double.tryParse(mult10xController.text) ?? 10,
                              'prob50x': double.tryParse(mult50xController.text) ?? 3,
                              'prob100x': double.tryParse(mult100xController.text) ?? 1,
                              'prob500x': double.tryParse(mult500xController.text) ?? 0.1,
                              'jackpotSeedPool': int.tryParse(jackpotSeedController.text) ?? 100000,
                              'announceThreshold': announceThreshold,
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            // Save to both gift/Lucky doc and system_settings/lucky_gift_config doc
                            await _firestore.collection('gift').doc('Lucky').set(
                              {'luckyGiftConfig': luckyConfig},
                              SetOptions(merge: true),
                            );

                            await _firestore.collection('system_settings').doc('lucky_gift_config').set(
                              luckyConfig,
                              SetOptions(merge: true),
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lucky Gift Settings saved successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error saving lucky gift settings: $e');
                            setDialogState(() => isSaving = false);
                          }
                        },
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: Text(isSaving ? 'Saving...' : 'Save Lucky Settings'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[800]),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddGiftDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Add New Gift',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<String>(
                      future: _generateNextGiftId(),
                      builder: (context, snapshot) {
                        final nextId = snapshot.data ?? '2001...';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tag_rounded, color: Colors.blueAccent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Auto Gift ID: $nextId',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                '(Starts from 2001)',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    TextField(
                      controller: _giftNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Gift Name',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _DiamondsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Diamonds',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                    if (_selectedCategory == 'Lucky') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.purple, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.casino, color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Lucky Gift Custom Settings 🎰',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _diamondCountPercentController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Diamond Count Rate (%)',
                                hintText: 'e.g. 80 (কত পারসেন্ট ডায়মন্ড কাউন্ট হবে)',
                                labelStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.percent, color: Colors.amber, size: 16),
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _minMultiplierController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Min Multipliers (সর্বনিম্ন)',
                                      hintText: 'e.g. 2',
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
                                    controller: _maxMultiplierController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Max Multipliers (সর্বোচ্চ)',
                                      hintText: 'e.g. 500',
                                      labelStyle: const TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Thumbnail Upload
                    _buildUploadSection(
                      title: 'Thumbnail (PNG only)',
                      selected: _selectedThumbnailBytes != null,
                      fileName: _selectedThumbnailName,
                      onPickFile: () async {
                        await _pickThumbnail();
                        setDialogState(() {});
                      },
                      icon: Icons.image,
                    ),
                    const SizedBox(height: 16),
                    // Main File Upload
                    _buildUploadSection(
                      title: 'Main File (SVGA, PNG, GIF, WEBP, MP4)',
                      selected: _selectedAnimationBytes != null,
                      fileName: _selectedAnimationName,
                      fileType: _selectedAnimationType,
                      onPickFile: () async {
                        await _pickAnimation();
                        setDialogState(() {});
                      },
                      icon: Icons.auto_awesome,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearForm();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isUploading
                      ? null
                      : () async {
                          setDialogState(() {
                            _isUploading = true;
                          });
                          await _addGift();
                          if (mounted) {
                            setDialogState(() {
                              _isUploading = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add Gift'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUploadSection({
    required String title,
    required bool selected,
    String? fileName,
    String? fileType,
    required VoidCallback onPickFile,
    required IconData icon,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : onPickFile,
          child: Container(
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
                        onPressed: onClear ?? () {
                          setState(() {
                            if (title.contains('Thumbnail')) {
                              _selectedThumbnailBytes = null;
                              _selectedThumbnailName = null;
                            } else {
                              _selectedAnimationBytes = null;
                              _selectedAnimationName = null;
                              _selectedAnimationType = null;
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
        ),
      ],
    );
  }

  void _showEditGiftDialog(_GiftData gift) {
    final TextEditingController editIdController = TextEditingController(text: gift.giftId);
    final TextEditingController editNameController = TextEditingController(text: gift.data['name']?.toString() ?? '');
    final TextEditingController editDiamondController = TextEditingController(text: (gift.data['Diamond'] ?? gift.data['diamond'] ?? gift.data['credits'] ?? gift.data['coin'] ?? gift.data['coins'] ?? gift.data['price'] ?? gift.data['amount'] ?? '0').toString());
    final TextEditingController editDiamondCountController = TextEditingController(text: (gift.data['diamondCountPercent'] ?? gift.data['winRate'] ?? 80).toString());
    final TextEditingController editMinMultController = TextEditingController(text: (gift.data['minMultiplier'] ?? 2).toString());
    final TextEditingController editMaxMultController = TextEditingController(text: (gift.data['maxMultiplier'] ?? 500).toString());
    String editCategory = _categories.contains(gift.category) ? gift.category : _categories.first;
    bool editIsActive = gift.isActive;
    bool isSaving = false;

    Uint8List? editThumbnailBytes;
    String? editThumbnailName;

    Uint8List? editAnimationBytes;
    String? editAnimationName;
    String? editAnimationType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Edit Gift', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gift ID Field
                    TextField(
                      controller: editIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Gift ID (Starts from 2001)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.tag, color: Colors.blueAccent),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Active / Deactive Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: editIsActive ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.power_settings_new,
                                color: editIsActive ? Colors.greenAccent : Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status: ${editIsActive ? "Active (সক্রিয়)" : "Deactive (নিষ্ক্রিয়)"}',
                                style: TextStyle(
                                  color: editIsActive ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: editIsActive,
                            activeColor: Colors.greenAccent,
                            inactiveThumbColor: Colors.redAccent,
                            onChanged: (val) {
                              setDialogState(() {
                                editIsActive = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Gift Name',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editDiamondController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Diamonds',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: editCategory,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            editCategory = newValue;
                          });
                        }
                      },
                    ),
                    if (editCategory == 'Lucky') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.purple, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.casino, color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Lucky Gift Custom Settings 🎰',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: editDiamondCountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Diamond Count Rate (%)',
                                hintText: 'e.g. 80 (কত পারসেন্ট ডায়মন্ড কাউন্ট হবে)',
                                labelStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.percent, color: Colors.amber, size: 16),
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: editMinMultController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Min Multiplier (সর্বনিম্ন)',
                                      hintText: 'e.g. 2',
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
                                    controller: editMaxMultController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Max Multiplier (সর্বোচ্চ)',
                                      hintText: 'e.g. 500',
                                      labelStyle: const TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildUploadSection(
                      title: 'Thumbnail (PNG only) - Optional',
                      selected: editThumbnailBytes != null,
                      fileName: editThumbnailName,
                      onPickFile: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['png'],
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            setDialogState(() {
                              editThumbnailBytes = file.bytes;
                              editThumbnailName = file.name;
                            });
                          }
                        } catch (e) {
                          debugPrint('Error picking thumbnail: $e');
                        }
                      },
                      icon: Icons.image,
                      onClear: () {
                        setDialogState(() {
                          editThumbnailBytes = null;
                          editThumbnailName = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildUploadSection(
                      title: 'Main File (SVGA, PNG, GIF, WEBP, MP4) - Optional',
                      selected: editAnimationBytes != null,
                      fileName: editAnimationName,
                      fileType: editAnimationType,
                      onPickFile: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['svga', 'png', 'gif', 'webp', 'mp4', 'vap', 'webm', 'mov', 'avi'],
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            setDialogState(() {
                              editAnimationBytes = file.bytes;
                              editAnimationName = file.name;
                              editAnimationType = file.extension;
                            });
                          }
                        } catch (e) {
                          debugPrint('Error picking animation: $e');
                        }
                      },
                      icon: Icons.auto_awesome,
                      onClear: () {
                        setDialogState(() {
                          editAnimationBytes = null;
                          editAnimationName = null;
                          editAnimationType = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final newName = editNameController.text.trim();
                    final newDiamond = editDiamondController.text.trim();
                    if (newName.isEmpty || newDiamond.isEmpty) return;

                    setDialogState(() => isSaving = true);

                    try {
                      final updatedData = Map<String, dynamic>.from(gift.data);
                      final newId = editIdController.text.trim();
                      updatedData['id'] = newId.isNotEmpty ? newId : gift.giftId;
                      updatedData['isActive'] = editIsActive;
                      updatedData['name'] = newName;
                      updatedData['Diamond'] = newDiamond; // String to match _addGift
                      updatedData['credits'] = int.tryParse(newDiamond) ?? 0; // Int to match mobile app models

                      if (editCategory == 'Lucky') {
                        updatedData['isLuckyGift'] = true;
                        updatedData['diamondCountPercent'] = double.tryParse(editDiamondCountController.text) ?? 80.0;
                        updatedData['minMultiplier'] = int.tryParse(editMinMultController.text) ?? 2;
                        updatedData['maxMultiplier'] = int.tryParse(editMaxMultController.text) ?? 500;
                        updatedData['luckyMultipliers'] = [
                          int.tryParse(editMinMultController.text) ?? 2,
                          10,
                          50,
                          100,
                          int.tryParse(editMaxMultController.text) ?? 500,
                        ];
                        updatedData['winRate'] = double.tryParse(editDiamondCountController.text) ?? 80.0;
                        updatedData['jackpotMaxMultiplier'] = int.tryParse(editMaxMultController.text) ?? 500;
                      }

                      if (editThumbnailBytes != null && editThumbnailName != null) {
                        final imageUrl = await _uploadFile(editThumbnailBytes!, editThumbnailName!);
                        if (imageUrl != null) updatedData['imageUrl'] = imageUrl;
                      }

                      if (editAnimationBytes != null && editAnimationName != null) {
                        final svgaUrl = await _uploadFile(editAnimationBytes!, editAnimationName!);
                        if (svgaUrl != null) updatedData['svgaUrl'] = svgaUrl;
                      }

                      updatedData['type'] = _categories.indexOf(editCategory).toString();

                      final oldDocRef = _firestore.collection('gift').doc(gift.category);
                      final newDocRef = _firestore.collection('gift').doc(editCategory);
                      
                      await _firestore.runTransaction((transaction) async {
                        if (gift.category == editCategory) {
                          final snapshot = await transaction.get(oldDocRef);
                          if (!snapshot.exists) return;
                          
                          List<dynamic> gifts = List.from(snapshot.data()?['gifts'] ?? []);
                          final index = gifts.indexWhere((g) => 
                            g['name'] == gift.data['name'] && g['Diamond'] == gift.data['Diamond'] && g['imageUrl'] == gift.data['imageUrl']
                          );
                          
                          if (index != -1) {
                            gifts[index] = updatedData;
                            transaction.update(oldDocRef, {'gifts': gifts});
                          } else {
                            transaction.update(oldDocRef, {
                              'gifts': FieldValue.arrayRemove([gift.data])
                            });
                            transaction.update(oldDocRef, {
                              'gifts': FieldValue.arrayUnion([updatedData])
                            });
                          }
                        } else {
                          transaction.update(oldDocRef, {
                            'gifts': FieldValue.arrayRemove([gift.data])
                          });
                          transaction.update(newDocRef, {
                            'gifts': FieldValue.arrayUnion([updatedData])
                          });
                        }
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        _loadGifts();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gift updated successfully'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'svg':
      case 'svga':
        return Icons.auto_awesome;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'webm':
      case 'mov':
      case 'avi':
        return Icons.movie;
      default:
        return Icons.insert_drive_file;
    }
  }
}
