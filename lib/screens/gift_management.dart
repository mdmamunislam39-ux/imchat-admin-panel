import 'package:flutter/material.dart';
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
  String _selectedCategory = 'Customized';
  final List<String> _categories = [
    'Customized',
    'Event',
    'Hot',
    'Privilege',
    'Trick',
  ];

  final TextEditingController _DiamondsController = TextEditingController();
  final TextEditingController _giftNameController = TextEditingController();

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
    _loadGifts();
  }

  @override
  void dispose() {
    _DiamondsController.dispose();
    _giftNameController.dispose();
    super.dispose();
  }

  Future<void> _loadGifts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load gifts from the selected category document
      final categoryDoc = await _firestore
          .collection('gift')
          .doc(_selectedCategory)
          .get();

      if (categoryDoc.exists) {
        final data = categoryDoc.data();
        if (data != null && data.containsKey('gifts')) {
          final giftsList = data['gifts'] as List<dynamic>?;
          if (giftsList != null) {
            // Convert the gifts list to a format we can work with
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
    } catch (e) {
      debugPrint('Error loading gifts: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
        allowedExtensions: ['svga', 'png', 'gif', 'mp4', 'webm', 'mov', 'avi'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final ext = file.extension?.toLowerCase();
        if (ext != 'svga' && ext != 'png' && ext != 'gif' && ext != 'mp4' && ext != 'webm' && ext != 'mov' && ext != 'avi') {
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

      final String giftId = (100000 + Random().nextInt(900000)).toString();

      final giftData = {
        'id': giftId,
        'Diamond': Diamonds.toString(),
        'credits': Diamonds,
        'imageUrl': imageUrl,
        'svgaUrl': svgaUrl,
        'type': _categories.indexOf(_selectedCategory).toString(),
        'name': _giftNameController.text,
      };

      // Add to the existing gifts array in the category document
      await _firestore.collection('gift').doc(_selectedCategory).update({
        'gifts': FieldValue.arrayUnion([giftData]),
      });

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
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Optional: Add tap functionality
          },
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
                      Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit and Delete Buttons
                Row(
                  children: [
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
                    const SizedBox(height: 16),
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
                      title: 'Main File (SVGA, PNG, GIF, MP4)',
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
    final TextEditingController editNameController = TextEditingController(text: gift.data['name']?.toString() ?? '');
    final TextEditingController editDiamondController = TextEditingController(text: (gift.data['Diamond'] ?? gift.data['diamond'] ?? gift.data['credits'] ?? gift.data['coin'] ?? gift.data['coins'] ?? gift.data['price'] ?? gift.data['amount'] ?? '0').toString());
    String editCategory = _categories.contains(gift.category) ? gift.category : _categories.first;
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
                      title: 'Main File (SVGA, PNG, GIF, MP4) - Optional',
                      selected: editAnimationBytes != null,
                      fileName: editAnimationName,
                      fileType: editAnimationType,
                      onPickFile: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['svga', 'png', 'gif', 'mp4', 'webm', 'mov', 'avi'],
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
                      updatedData['name'] = newName;
                      updatedData['Diamond'] = newDiamond; // String to match _addGift
                      updatedData['credits'] = int.tryParse(newDiamond) ?? 0; // Int to match mobile app models

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
