import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/media_preview_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../widgets/base_screen.dart';

// Data class for handling emoji data
class _EmojiData {
  final String id;
  final Map<String, dynamic> data;
  final String category;

  _EmojiData({
    required this.id,
    required this.data,
    required this.category,
  });

  bool get isDice =>
      data['is_dice'] == true ||
      data['type'] == 'dice' ||
      (data['outcomes'] is List && (data['outcomes'] as List).isNotEmpty);

  List<String> get outcomes {
    final raw = data['outcomes'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }
}

class EmojiManagement extends StatefulWidget {
  const EmojiManagement({super.key});

  @override
  State<EmojiManagement> createState() => _EmojiManagementState();
}

class _EmojiManagementState extends State<EmojiManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<_EmojiData> _emojis = [];
  bool _isLoading = true;
  String _selectedCategory = 'Activity';
  final List<String> _categories = ['Activity', 'Customize', 'Free'];

  @override
  void initState() {
    super.initState();
    _loadEmojis();
  }

  Future<void> _loadEmojis() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load emojis from the selected category document
      final categoryDoc =
          await _firestore.collection('emoji').doc(_selectedCategory).get();

      if (categoryDoc.exists) {
        final data = categoryDoc.data();
        if (data != null && data.containsKey('emojis')) {
          final emojisList = data['emojis'] as List<dynamic>?;
          if (emojisList != null) {
            final List<_EmojiData> emojisData =
                emojisList.asMap().entries.map((entry) {
              final emojiMap = entry.value as Map<String, dynamic>;
              return _EmojiData(
                id: '${_selectedCategory}_${entry.key}',
                data: emojiMap,
                category: _selectedCategory,
              );
            }).toList();

            setState(() {
              _emojis = emojisData;
              _isLoading = false;
            });
            return;
          }
        }
      }

      setState(() {
        _emojis = [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading emojis: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEmoji(String emojiId) async {
    try {
      final emojiIndex = _emojis.indexWhere((emoji) => emoji.id == emojiId);
      if (emojiIndex == -1) return;

      final categoryDoc =
          await _firestore.collection('emoji').doc(_selectedCategory).get();
      if (!categoryDoc.exists) return;

      final data = categoryDoc.data();
      if (data == null || !data.containsKey('emojis')) return;

      final emojisList = List<dynamic>.from(data['emojis'] as List<dynamic>);
      if (emojiIndex >= emojisList.length) return;

      emojisList.removeAt(emojiIndex);

      await _firestore.collection('emoji').doc(_selectedCategory).update({
        'emojis': emojisList,
      });

      setState(() {
        _emojis.removeAt(emojiIndex);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emoji deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting emoji: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting emoji: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddEmojiDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddEmojiDialog(
        initialCategory: _selectedCategory,
        categories: _categories,
        onEmojiAdded: () {
          _loadEmojis();
        },
      ),
    );
  }

  void _showDicePreviewDialog(_EmojiData emoji) {
    showDialog(
      context: context,
      builder: (context) => _DiceOutcomesPreviewDialog(emoji: emoji),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Emoji Management',
      actions: [
        ElevatedButton.icon(
          onPressed: _showAddEmojiDialog,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add Emoji / Dice'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Column(
              children: [
                _buildCategoryFilter(),
                _buildEmojisList(),
              ],
            ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 1,
        ),
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
                  _loadEmojis();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojisList() {
    final categoryEmojis = _emojis.where((emoji) {
      return emoji.category == _selectedCategory;
    }).toList();

    if (categoryEmojis.isEmpty) {
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
                    Icons.emoji_emotions_outlined,
                    size: 40,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No emojis found',
                  style: TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add emojis or ludo dice to the $_selectedCategory category',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _showAddEmojiDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Emoji / Dice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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
          itemCount: categoryEmojis.length,
          itemBuilder: (context, index) {
            final emoji = categoryEmojis[index];
            return _buildEmojiListItem(emoji: emoji);
          },
        ),
      ),
    );
  }

  Widget _buildEmojiListItem({required _EmojiData emoji}) {
    final data = emoji.data;
    final name = data['emoji_name']?.toString() ?? 'Unnamed Emoji';
    final emojiUrl = data['emoji_url']?.toString();
    final fileType = data['file_type']?.toString() ?? 'png';
    final bool isDice = emoji.isDice;
    final List<String> outcomes = emoji.outcomes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDice
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
              : const Color(0xFF2A2A2A),
          width: isDice ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDice ? () => _showDicePreviewDialog(emoji) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Emoji Preview Thumbnail
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDice
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                          : const Color(0xFF2A2A2A),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: emojiUrl != null && emojiUrl.isNotEmpty
                            ? fileType == 'svg'
                                ? SvgPicture.network(
                                    emojiUrl,
                                    fit: BoxFit.contain,
                                    width: 44,
                                    height: 44,
                                    placeholderBuilder: (context) =>
                                        const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF2563EB),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                      Icons.emoji_emotions,
                                      color: Color(0xFF666666),
                                      size: 24,
                                    ),
                                  )
                                : MediaPreviewWidget(
                                    url: emojiUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.contain,
                                  )
                            : const Icon(
                                Icons.emoji_emotions,
                                color: Color(0xFF666666),
                                size: 24,
                              ),
                      ),
                      if (isDice)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.casino,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Emoji Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
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
                          ),
                          if (isDice) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFFEC4899)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.casino,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'DICE (${outcomes.length} Outcomes)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: fileType == 'svg'
                                  ? const Color(0xFF2563EB)
                                      .withValues(alpha: 0.2)
                                  : const Color(0xFF10B981)
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: fileType == 'svg'
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF10B981),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              fileType.toUpperCase(),
                              style: TextStyle(
                                color: fileType == 'svg'
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedCategory,
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (isDice)
                            Text(
                              'Tap to roll & test outcomes',
                              style: TextStyle(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.8),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Preview Outcomes Button (for Dice)
                if (isDice)
                  IconButton(
                    onPressed: () => _showDicePreviewDialog(emoji),
                    tooltip: 'View Outcomes & Roll Test',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                    ),
                  ),

                // Delete Button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
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
                      onTap: () => _deleteEmoji(emoji.id),
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
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Outcome Slot Model for Dice Upload
// ---------------------------------------------------------------------------
class _OutcomeSlot {
  File? file;
  Uint8List? bytes;
  String? fileType;
  String? fileName;

  _OutcomeSlot();

  bool get hasFile => file != null || bytes != null;
}

// ---------------------------------------------------------------------------
// Add Emoji Dialog Widget (Supports Standard & Ludo Dice with 1-10 outcomes)
// ---------------------------------------------------------------------------
class _AddEmojiDialog extends StatefulWidget {
  final String initialCategory;
  final List<String> categories;
  final VoidCallback onEmojiAdded;

  const _AddEmojiDialog({
    required this.initialCategory,
    required this.categories,
    required this.onEmojiAdded,
  });

  @override
  State<_AddEmojiDialog> createState() => _AddEmojiDialogState();
}

class _AddEmojiDialogState extends State<_AddEmojiDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _emojiNameController = TextEditingController();
  late String _selectedCategory;

  // 'standard' or 'dice'
  String _emojiType = 'standard';

  // Standard mode file
  File? _standardFile;
  Uint8List? _standardBytes;
  String? _standardFileType;
  String? _standardFileName;

  // Dice mode main thumbnail
  File? _diceThumbFile;
  Uint8List? _diceThumbBytes;
  String? _diceThumbFileType;
  String? _diceThumbFileName;

  // Dice mode outcome slots (1 to 10 outcomes)
  final List<_OutcomeSlot> _outcomeSlots = [
    _OutcomeSlot(),
    _OutcomeSlot(),
  ];

  bool _isUploading = false;
  String _uploadProgressText = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _emojiNameController.dispose();
    super.dispose();
  }

  Future<void> _pickStandardFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg', 'gif', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          if (kIsWeb) {
            _standardBytes = file.bytes;
            _standardFile = null;
          } else {
            _standardFile = File(file.path!);
            _standardBytes = null;
          }
          _standardFileType = file.extension?.toLowerCase() ?? 'png';
          _standardFileName = file.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking standard file: $e');
    }
  }

  Future<void> _pickDiceThumbFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'svg'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          if (kIsWeb) {
            _diceThumbBytes = file.bytes;
            _diceThumbFile = null;
          } else {
            _diceThumbFile = File(file.path!);
            _diceThumbBytes = null;
          }
          _diceThumbFileType = file.extension?.toLowerCase() ?? 'png';
          _diceThumbFileName = file.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking dice thumb file: $e');
    }
  }

  Future<void> _pickOutcomeFile(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'svg'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          if (kIsWeb) {
            _outcomeSlots[index].bytes = file.bytes;
            _outcomeSlots[index].file = null;
          } else {
            _outcomeSlots[index].file = File(file.path!);
            _outcomeSlots[index].bytes = null;
          }
          _outcomeSlots[index].fileType = file.extension?.toLowerCase() ?? 'png';
          _outcomeSlots[index].fileName = file.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking outcome file at $index: $e');
    }
  }

  void _addOutcomeSlot() {
    if (_outcomeSlots.length < 10) {
      setState(() {
        _outcomeSlots.add(_OutcomeSlot());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 outcome images allowed! (সর্বোচ্চ ১০টি আউটকাম ইমেজ যোগ করা যাবে)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeOutcomeSlot(int index) {
    if (_outcomeSlots.length > 1) {
      setState(() {
        _outcomeSlots.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 1 outcome image is required!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<String?> _uploadFileToStorage({
    required File? file,
    required Uint8List? bytes,
    required String? fileType,
    required String path,
  }) async {
    if (file == null && bytes == null) return null;

    try {
      final ref = _storage.ref().child(path);
      UploadTask uploadTask;
      if (kIsWeb && bytes != null) {
        uploadTask = ref.putData(bytes);
      } else if (file != null) {
        uploadTask = ref.putFile(file);
      } else {
        return null;
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Storage upload error ($path): $e');
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    final emojiName = _emojiNameController.text.trim();
    if (emojiName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter emoji name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_emojiType == 'standard') {
      // Standard Emoji validation
      if (_standardFile == null && _standardBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an emoji file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgressText = 'Uploading emoji file...';
      });

      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final emojiUrl = await _uploadFileToStorage(
          file: _standardFile,
          bytes: _standardBytes,
          fileType: _standardFileType,
          path: 'emoji/emoji_$timestamp.$_standardFileType',
        );

        if (emojiUrl == null) {
          throw Exception('Failed to upload emoji file');
        }

        final emojiData = {
          'emoji_name': emojiName,
          'emoji_url': emojiUrl,
          'file_type': _standardFileType,
          'type': 'standard',
          'is_dice': false,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _firestore.collection('emoji').doc(_selectedCategory).update({
          'emojis': FieldValue.arrayUnion([emojiData]),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Standard Emoji added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onEmojiAdded();
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Error adding standard emoji: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
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
    } else {
      // Dice Emoji Validation
      if (_diceThumbFile == null && _diceThumbBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Main Thumbnail (মেন পিএনজি/থাম্বনেল সিলেক্ট করুন)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final emptySlots = _outcomeSlots.where((s) => !s.hasFile).toList();
      if (emptySlots.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please select images for all outcome slots (${emptySlots.length} slot(s) empty)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_outcomeSlots.isEmpty || _outcomeSlots.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outcomes must be between 1 and 10 images'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgressText = 'Uploading Main Thumbnail PNG...';
      });

      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        // 1. Upload Main Thumbnail
        final mainThumbUrl = await _uploadFileToStorage(
          file: _diceThumbFile,
          bytes: _diceThumbBytes,
          fileType: _diceThumbFileType,
          path: 'emoji/dice_thumb_$timestamp.$_diceThumbFileType',
        );

        if (mainThumbUrl == null) {
          throw Exception('Failed to upload main thumbnail');
        }

        // 2. Upload Outcome Images
        final List<String> outcomeUrls = [];
        for (int i = 0; i < _outcomeSlots.length; i++) {
          if (mounted) {
            setState(() {
              _uploadProgressText =
                  'Uploading Outcome ${i + 1} of ${_outcomeSlots.length}...';
            });
          }

          final slot = _outcomeSlots[i];
          final url = await _uploadFileToStorage(
            file: slot.file,
            bytes: slot.bytes,
            fileType: slot.fileType,
            path: 'emoji/dice_outcomes/outcome_${timestamp}_$i.${slot.fileType}',
          );

          if (url != null) {
            outcomeUrls.add(url);
          } else {
            throw Exception('Failed to upload outcome image #${i + 1}');
          }
        }

        if (mounted) {
          setState(() {
            _uploadProgressText = 'Saving to database...';
          });
        }

        // 3. Save to Firestore
        final emojiData = {
          'emoji_name': emojiName,
          'emoji_url': mainThumbUrl,
          'file_type': _diceThumbFileType ?? 'png',
          'type': 'dice',
          'is_dice': true,
          'outcomes': outcomeUrls,
          'outcome_count': outcomeUrls.length,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _firestore.collection('emoji').doc(_selectedCategory).update({
          'emojis': FieldValue.arrayUnion([emojiData]),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Ludo Dice "$emojiName" added with ${outcomeUrls.length} outcomes successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onEmojiAdded();
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Error adding dice emoji: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
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
  }

  Widget _buildFilePreviewBox({
    required File? file,
    required Uint8List? bytes,
    required String? fileType,
    required double size,
  }) {
    if (file == null && bytes == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined,
            color: Color(0xFF666666), size: 24),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2563EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: kIsWeb && bytes != null
            ? (fileType?.toLowerCase() == 'svg'
                ? SvgPicture.memory(bytes, fit: BoxFit.contain)
                : Image.memory(bytes, fit: BoxFit.contain))
            : (file != null
                ? (fileType?.toLowerCase() == 'svg'
                    ? FutureBuilder<String>(
                        future: file.readAsString(),
                        builder: (context, snapshot) => snapshot.hasData
                            ? SvgPicture.string(snapshot.data!,
                                fit: BoxFit.contain)
                            : const Center(
                                child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                      )
                    : Image.file(file, fit: BoxFit.contain))
                : const SizedBox()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 760),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _emojiType == 'dice'
                          ? const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                          : const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF38BDF8)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _emojiType == 'dice' ? Icons.casino : Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _emojiType == 'dice'
                            ? 'Add Ludo Dice (Random Roll Emoji)'
                            : 'Add New Emoji',
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _emojiType == 'dice'
                            ? 'Upload main thumbnail & up to 10 outcome images (১-১০টি সংখ্যা বা ইমেজ)'
                            : 'Upload SVG, GIF, or PNG emoji',
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _isUploading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2A2A2A), height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji Type Selector Tabs
                    const Text(
                      'Emoji Type / ইমোজি ধরন',
                      style: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _isUploading
                                  ? null
                                  : () => setState(() => _emojiType = 'standard'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _emojiType == 'standard'
                                      ? const Color(0xFF2563EB)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.emoji_emotions_outlined,
                                      size: 18,
                                      color: _emojiType == 'standard'
                                          ? Colors.white
                                          : const Color(0xFF888888),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Standard Emoji (সাধারণ)',
                                      style: TextStyle(
                                        color: _emojiType == 'standard'
                                            ? Colors.white
                                            : const Color(0xFF888888),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _isUploading
                                  ? null
                                  : () => setState(() => _emojiType = 'dice'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: _emojiType == 'dice'
                                      ? const LinearGradient(colors: [
                                          Color(0xFF8B5CF6),
                                          Color(0xFFEC4899)
                                        ])
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.casino,
                                      size: 18,
                                      color: _emojiType == 'dice'
                                          ? Colors.white
                                          : const Color(0xFF888888),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ludo Dice (লুডু ডাইস / র‍্যান্ডম)',
                                      style: TextStyle(
                                        color: _emojiType == 'dice'
                                            ? Colors.white
                                            : const Color(0xFF888888),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Emoji Name Field
                    TextField(
                      controller: _emojiNameController,
                      enabled: !_isUploading,
                      style: const TextStyle(
                          color: Color(0xFFE0E0E0), fontSize: 14),
                      decoration: InputDecoration(
                        labelText: _emojiType == 'dice'
                            ? 'Dice Name (e.g., Ludo 6 Dice / লাকি ডাইস)'
                            : 'Emoji Name',
                        labelStyle: const TextStyle(
                            color: Color(0xFF888888), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF0F0F0F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF2A2A2A)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF2A2A2A)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _emojiType == 'dice'
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      dropdownColor: const Color(0xFF1A1A1A),
                      style: const TextStyle(
                          color: Color(0xFFE0E0E0), fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: const TextStyle(
                            color: Color(0xFF888888), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF0F0F0F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF2A2A2A)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF2A2A2A)),
                        ),
                      ),
                      items: widget.categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: _isUploading
                          ? null
                          : (String? val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                    ),

                    const SizedBox(height: 20),

                    // Form Body for STANDARD vs DICE
                    if (_emojiType == 'standard') ...[
                      const Text(
                        'Emoji Asset File (SVG, PNG, GIF, JPG)',
                        style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _isUploading ? null : _pickStandardFile,
                        child: Container(
                          width: double.infinity,
                          height: 130,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F0F),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (_standardFile != null ||
                                      _standardBytes != null)
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF2A2A2A),
                              width: 1.5,
                            ),
                          ),
                          child: (_standardFile != null ||
                                  _standardBytes != null)
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      _buildFilePreviewBox(
                                        file: _standardFile,
                                        bytes: _standardBytes,
                                        fileType: _standardFileType,
                                        size: 60,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _standardFileName ?? '',
                                        style: const TextStyle(
                                            color: Colors.green, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Tap to change file',
                                        style: TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file_rounded,
                                        color: Color(0xFF888888), size: 36),
                                    SizedBox(height: 8),
                                    Text('Tap to select file',
                                        style: TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 14)),
                                    SizedBox(height: 4),
                                    Text('SVG, PNG, JPG, GIF',
                                        style: TextStyle(
                                            color: Color(0xFF666666),
                                            fontSize: 12)),
                                  ],
                                ),
                        ),
                      ),
                    ] else ...[
                      // ---------------------------------------------------
                      // LUDO DICE FORM: MAIN THUMBNAIL + 1-10 OUTCOMES
                      // ---------------------------------------------------

                      // Section 1: Main Thumbnail (মেন পিএনজি / থাম্বনেল)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F0F),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_diceThumbFile != null ||
                                    _diceThumbBytes != null)
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF2A2A2A),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.image,
                                      color: Color(0xFF8B5CF6), size: 16),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Main PNG / Thumbnail (মেন পিএনজি থাম্বনেল)',
                                  style: TextStyle(
                                    color: Color(0xFFE0E0E0),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (_diceThumbFile != null ||
                                    _diceThumbBytes != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Selected',
                                        style: TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'This main image will be shown as the icon in the emoji tray / picker.',
                              style: TextStyle(
                                  color: Color(0xFF888888), fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildFilePreviewBox(
                                  file: _diceThumbFile,
                                  bytes: _diceThumbBytes,
                                  fileType: _diceThumbFileType,
                                  size: 56,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _diceThumbFileName ??
                                            'No main thumbnail chosen',
                                        style: TextStyle(
                                          color: (_diceThumbFile != null ||
                                                  _diceThumbBytes != null)
                                              ? const Color(0xFFE0E0E0)
                                              : const Color(0xFF666666),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      ElevatedButton.icon(
                                        onPressed: _isUploading
                                            ? null
                                            : _pickDiceThumbFile,
                                        icon: const Icon(
                                            Icons.file_upload_outlined,
                                            size: 16),
                                        label: Text(
                                          (_diceThumbFile != null ||
                                                  _diceThumbBytes != null)
                                              ? 'Change Main PNG'
                                              : 'Pick Main PNG',
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF2A2A2A),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section 2: Outcomes (র‍্যান্ডম আউটকাম ইমেজ - ১ থেকে ১০টি)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.casino,
                                color: Color(0xFFEC4899), size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Outcome Images (র‍্যান্ডম আউটকাম ১-১০টি)',
                            style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_outcomeSlots.length} / 10',
                              style: const TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: (_outcomeSlots.length < 10 &&
                                    !_isUploading)
                                ? _addOutcomeSlot
                                : null,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Outcome Slot'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEC4899),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'লুডু ডাইস ঘোরার পর এই আউটকামগুলোর মধ্য থেকে র‍্যান্ডমভাবে যেকোনো একটি সংখ্যা/ইমেজ ডিসপ্লে হবে। (যেমন ১, ২, ৩, ৪, ৫, ৬ বা কাস্টম ১ থেকে ১০টি ছবি)',
                        style:
                            TextStyle(color: Color(0xFF888888), fontSize: 12),
                      ),
                      const SizedBox(height: 12),

                      // List of Outcome Slots
                      ..._outcomeSlots.asMap().entries.map((entry) {
                        final index = entry.key;
                        final slot = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: slot.hasFile
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.4)
                                  : const Color(0xFF2A2A2A),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFFEC4899)
                                  ]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildFilePreviewBox(
                                file: slot.file,
                                bytes: slot.bytes,
                                fileType: slot.fileType,
                                size: 44,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slot.fileName ?? 'Outcome #${index + 1}',
                                      style: TextStyle(
                                        color: slot.hasFile
                                            ? const Color(0xFFE0E0E0)
                                            : const Color(0xFF777777),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      slot.hasFile
                                          ? 'Ready (${slot.fileType?.toUpperCase()})'
                                          : 'Select image for this outcome',
                                      style: TextStyle(
                                        color: slot.hasFile
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF555555),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _isUploading
                                    ? null
                                    : () => _pickOutcomeFile(index),
                                icon: const Icon(Icons.file_upload_outlined,
                                    size: 14),
                                label: Text(
                                    slot.hasFile ? 'Replace' : 'Upload',
                                    style: const TextStyle(fontSize: 11)),
                                style: TextButton.styleFrom(
                                  foregroundColor: slot.hasFile
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF8B5CF6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                ),
                              ),
                              if (_outcomeSlots.length > 1)
                                IconButton(
                                  onPressed: _isUploading
                                      ? null
                                      : () => _removeOutcomeSlot(index),
                                  icon: const Icon(Icons.delete_outline,
                                      color: Color(0xFFEF4444), size: 18),
                                  tooltip: 'Remove slot',
                                ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Upload Progress Status
                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F0F),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF2563EB),
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _uploadProgressText,
                                style: const TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(color: Color(0xFF2A2A2A), height: 1),

            // Dialog Footer Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isUploading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFF888888))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _emojiType == 'dice'
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _emojiType == 'dice'
                                ? 'Add Ludo Dice'
                                : 'Add Emoji',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dice Outcomes Preview & Interactive Roll Simulation Dialog
// ---------------------------------------------------------------------------
class _DiceOutcomesPreviewDialog extends StatefulWidget {
  final _EmojiData emoji;

  const _DiceOutcomesPreviewDialog({required this.emoji});

  @override
  State<_DiceOutcomesPreviewDialog> createState() =>
      _DiceOutcomesPreviewDialogState();
}

class _DiceOutcomesPreviewDialogState extends State<_DiceOutcomesPreviewDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _rollController;
  int? _rolledIndex;
  int? _animatingIndex;
  bool _isRolling = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _rollController.addListener(() {
      final outcomes = widget.emoji.outcomes;
      if (outcomes.isEmpty) return;

      if (_rollController.value < 0.9) {
        // Fast flicker
        setState(() {
          _animatingIndex = _random.nextInt(outcomes.length);
        });
      } else {
        // Land on rolled index
        setState(() {
          _animatingIndex = _rolledIndex;
        });
      }
    });

    _rollController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isRolling = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  void _rollDice() {
    final outcomes = widget.emoji.outcomes;
    if (outcomes.isEmpty || _isRolling) return;

    final target = _random.nextInt(outcomes.length);
    setState(() {
      _isRolling = true;
      _rolledIndex = target;
      _animatingIndex = 0;
    });

    _rollController.reset();
    _rollController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.emoji.data;
    final name = data['emoji_name']?.toString() ?? 'Ludo Dice';
    final mainThumbUrl = data['emoji_url']?.toString();
    final outcomes = widget.emoji.outcomes;

    return Dialog(
      backgroundColor: const Color(0xFF161616),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Main Thumb
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: mainThumbUrl != null
                        ? MediaPreviewWidget(
                            url: mainThumbUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          )
                        : const Icon(Icons.casino, color: Color(0xFF8B5CF6)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFFEC4899)
                              ]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('DICE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Outcomes: ${outcomes.length} | Category: ${widget.emoji.category}',
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF888888)),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 16),

            // Roll simulation banner
            if (_animatingIndex != null && outcomes.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      const Color(0xFFEC4899).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRolling
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF10B981),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: MediaPreviewWidget(
                          url: outcomes[_animatingIndex!],
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRolling
                                ? '🎲 Rolling dice...'
                                : '🎉 Rolled Outcome #${_animatingIndex! + 1}!',
                            style: TextStyle(
                              color: _isRolling
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFF10B981),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isRolling
                                ? 'Selecting random outcome...'
                                : 'This image will be revealed in the chat & slot.',
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const Text(
              'Uploaded Outcome Images (১-১০টি আউটকাম):',
              style: TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Grid of Outcomes
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: outcomes.isEmpty
                  ? const Center(
                      child: Text(
                        'No outcomes found for this dice.',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: outcomes.length,
                      itemBuilder: (context, index) {
                        final isHighlighted = _animatingIndex == index;

                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F0F),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isHighlighted
                                  ? (_isRolling
                                      ? const Color(0xFF8B5CF6)
                                      : const Color(0xFF10B981))
                                  : const Color(0xFF2A2A2A),
                              width: isHighlighted ? 2.5 : 1,
                            ),
                            boxShadow: isHighlighted
                                ? [
                                    BoxShadow(
                                      color: _isRolling
                                          ? const Color(0xFF8B5CF6)
                                              .withValues(alpha: 0.5)
                                          : const Color(0xFF10B981)
                                              .withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: MediaPreviewWidget(
                                      url: outcomes[index],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? (_isRolling
                                          ? const Color(0xFF8B5CF6)
                                          : const Color(0xFF10B981))
                                      : const Color(0xFF1A1A1A),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(9),
                                    bottomRight: Radius.circular(9),
                                  ),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isHighlighted
                                        ? Colors.white
                                        : const Color(0xFF888888),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            // Footer Actions (Roll Test + Close)
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isRolling ? null : _rollDice,
                  icon: const Icon(Icons.casino, size: 18),
                  label: Text(_isRolling ? 'Rolling...' : '🎲 Test Dice Roll'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close',
                      style: TextStyle(color: Color(0xFF888888))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
