import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/media_preview_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../widgets/base_screen.dart';

// Simple data class for handling emoji data
class _EmojiData {
  final String id;
  final Map<String, dynamic> data;
  final String category;

  _EmojiData({
    required this.id,
    required this.data,
    required this.category,
  });
}

class EmojiManagement extends StatefulWidget {
  const EmojiManagement({super.key});

  @override
  State<EmojiManagement> createState() => _EmojiManagementState();
}

class _EmojiManagementState extends State<EmojiManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  List<_EmojiData> _emojis = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String _selectedCategory = 'Activity';
  final List<String> _categories = ['Activity', 'Customize', 'Free'];
  
  final TextEditingController _emojiNameController = TextEditingController();
  File? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _selectedFileType;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadEmojis();
  }

  @override
  void dispose() {
    _emojiNameController.dispose();
    super.dispose();
  }

  Future<void> _loadEmojis() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load emojis from the selected category document
      final categoryDoc = await _firestore.collection('emoji').doc(_selectedCategory).get();
      
      if (categoryDoc.exists) {
        final data = categoryDoc.data();
        if (data != null && data.containsKey('emojis')) {
          final emojisList = data['emojis'] as List<dynamic>?;
          if (emojisList != null) {
            // Convert the emojis list to a format we can work with
            final List<_EmojiData> emojisData = emojisList.asMap().entries.map((entry) {
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg', 'gif', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        debugPrint('File selected: ${file.name}, extension: ${file.extension}, bytes: ${file.bytes?.length}');
        
        setState(() {
          if (kIsWeb) {
            // For web, use bytes instead of path
            _selectedFileBytes = file.bytes;
            _selectedFile = null;
            debugPrint('Web: Using bytes, length: ${_selectedFileBytes?.length}');
          } else {
            // For mobile/desktop, use path
            _selectedFile = File(file.path!);
            _selectedFileBytes = null;
            debugPrint('Mobile: Using file path: ${_selectedFile?.path}');
          }
          _selectedFileType = file.extension;
          _selectedFileName = file.name;
        });
        
        debugPrint('State updated - FileType: $_selectedFileType, FileName: $_selectedFileName');
        debugPrint('After setState - File: ${_selectedFile != null}, Bytes: ${_selectedFileBytes != null}');
      } else {
        debugPrint('No file selected');
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadFile() async {
    if (_selectedFile == null && _selectedFileBytes == null) return null;

    try {
      final fileName = 'emoji_${DateTime.now().millisecondsSinceEpoch}.$_selectedFileType';
      final ref = _storage.ref().child('emoji/$fileName');
      
      UploadTask uploadTask;
      if (kIsWeb && _selectedFileBytes != null) {
        // For web, upload using bytes
        uploadTask = ref.putData(_selectedFileBytes!);
      } else if (_selectedFile != null) {
        // For mobile/desktop, upload using file
        uploadTask = ref.putFile(_selectedFile!);
      } else {
        throw Exception('No file data available for upload');
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _addEmoji() async {
    try {
      if (_emojiNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter emoji name'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedFile == null && _selectedFileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final emojiUrl = await _uploadFile();
      if (emojiUrl == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final emojiData = {
        'emoji_name': _emojiNameController.text,
        'emoji_url': emojiUrl,
        'file_type': _selectedFileType,
      };

      // Add to the existing emojis array in the category document
      await _firestore.collection('emoji').doc(_selectedCategory).update({
        'emojis': FieldValue.arrayUnion([emojiData])
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emoji added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _clearForm();
      _loadEmojis();
    } catch (e) {
      debugPrint('Error adding emoji: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding emoji: $e'),
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
    _emojiNameController.clear();
    setState(() {
      _selectedFile = null;
      _selectedFileBytes = null;
      _selectedFileType = null;
      _selectedFileName = null;
    });
  }

  Future<void> _deleteEmoji(String emojiId) async {
    try {
      // Find the emoji in the current list
      final emojiIndex = _emojis.indexWhere((emoji) => emoji.id == emojiId);
      if (emojiIndex == -1) {
        debugPrint('Emoji not found in current list');
        return;
      }

      // Get the current emojis list from Firestore
      final categoryDoc = await _firestore.collection('emoji').doc(_selectedCategory).get();
      if (!categoryDoc.exists) {
        debugPrint('Category document does not exist');
        return;
      }

      final data = categoryDoc.data();
      if (data == null || !data.containsKey('emojis')) {
        debugPrint('No emojis found in category');
        return;
      }

      final emojisList = data['emojis'] as List<dynamic>;
      if (emojiIndex >= emojisList.length) {
        debugPrint('Emoji index out of bounds');
        return;
      }

      // Remove the emoji from the list
      emojisList.removeAt(emojiIndex);

      // Update the document with the new list
      await _firestore.collection('emoji').doc(_selectedCategory).update({
        'emojis': emojisList,
      });

      // Remove from local list immediately for better UX
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

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Emoji Management',
      actions: [
        IconButton(
          onPressed: () => _showAddEmojiDialog(),
          icon: const Icon(Icons.add),
          tooltip: 'Add Emoji',
        ),
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
                  _loadEmojis(); // Reload emojis when category changes
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
                  'Add emojis to the $_selectedCategory category',
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
                  label: const Text('Add Emoji'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            final data = emoji.data;
            
            final name = data['emoji_name']?.toString() ?? 'Unnamed Emoji';
            final emojiUrl = data['emoji_url']?.toString();
            final fileType = data['file_type']?.toString() ?? 'gif';
            
            return _buildEmojiListItem(
              emojiId: emoji.id,
              name: name,
              emojiUrl: emojiUrl,
              fileType: fileType,
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmojiListItem({
    required String emojiId,
    required String name,
    String? emojiUrl,
    required String fileType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 1,
        ),
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
                // Emoji Preview
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
                    child: emojiUrl != null && emojiUrl.isNotEmpty
                        ? fileType == 'svg'
                            ? SvgPicture.network(
                                emojiUrl,
                                fit: BoxFit.contain,
                                placeholderBuilder: (context) => const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF2563EB),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.emoji_emotions,
                                  color: Color(0xFF666666),
                                  size: 24,
                                ),
                              )
                            : MediaPreviewWidget(
                                url: emojiUrl,
                                width: 48,
                                height: 48,
                              )
                        : const Icon(
                            Icons.emoji_emotions,
                            color: Color(0xFF666666),
                            size: 24,
                          ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Emoji Info
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: fileType == 'svg' 
                                  ? const Color(0xFF2563EB).withValues(alpha: 0.2)
                                  : const Color(0xFF10B981).withValues(alpha: 0.2),
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
                
                // Delete Button
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
                      onTap: () => _deleteEmoji(emojiId),
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

  void _showAddEmojiDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add New Emoji',
              style: TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji Name Field
              TextField(
                controller: _emojiNameController,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Emoji Name',
                  labelStyle: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0F0F0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0F0F0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // File Upload Area
              GestureDetector(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_selectedFile != null || _selectedFileBytes != null) 
                          ? const Color(0xFF2563EB) 
                          : const Color(0xFF2A2A2A),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _isUploading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF2563EB),
                                strokeWidth: 2,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Uploading...',
                                style: TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : (() {
                          final hasFile = _selectedFile != null || _selectedFileBytes != null;
                          return hasFile ? _buildAssetPreview() : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.upload_file_rounded,
                                    color: Color(0xFF888888),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap to select file',
                                  style: TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'SVG, PNG, JPG, GIF',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                        })(),
                ),
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
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF888888),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isUploading ? null : _addEmoji,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Add Emoji',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    debugPrint('Building image preview - FileType: $_selectedFileType, HasFile: ${_selectedFile != null}, HasBytes: ${_selectedFileBytes != null}');
    
    // Check if we have a file selected
    if (_selectedFile == null && _selectedFileBytes == null) {
      debugPrint('No file selected, showing placeholder');
      return const Icon(Icons.emoji_emotions, color: Colors.grey, size: 32);
    }
    
    // Check if it's an SVG file
    if (_selectedFileType?.toLowerCase() == 'svg') {
      debugPrint('Rendering SVG file');
      if (kIsWeb && _selectedFileBytes != null) {
        return SvgPicture.memory(
          _selectedFileBytes!,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorBuilder: (context, error, stackTrace) {
            debugPrint('SVG error: $error');
            return const Icon(Icons.error, color: Colors.red, size: 32);
          },
        );
      } else if (_selectedFile != null) {
        return FutureBuilder<String>(
          future: _selectedFile!.readAsString(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SvgPicture.string(
                snapshot.data!,
                fit: BoxFit.contain,
                placeholderBuilder: (context) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('SVG string error: $error');
                  return const Icon(Icons.error, color: Colors.red, size: 32);
                },
              );
            } else if (snapshot.hasError) {
              debugPrint('SVG read error: ${snapshot.error}');
              return const Icon(Icons.error, color: Colors.red, size: 32);
            } else {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
          },
        );
      }
    } else {
      // Handle image files (JPG, PNG, GIF, etc.)
      debugPrint('Rendering image file: $_selectedFileType');
      if (kIsWeb && _selectedFileBytes != null) {
        return Image.memory(
          _selectedFileBytes!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image memory error: $error');
            return const Icon(Icons.emoji_emotions, color: Colors.grey, size: 32);
          },
        );
      } else if (_selectedFile != null) {
        return Image.file(
          _selectedFile!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image file error: $error');
            return const Icon(Icons.emoji_emotions, color: Colors.grey, size: 32);
          },
        );
      }
    }
    
    debugPrint('Fallback to placeholder');
    return const Icon(Icons.emoji_emotions, color: Colors.grey, size: 32);
  }

  Widget _buildAssetPreview() {
    debugPrint('Building asset preview - FileType: $_selectedFileType, HasFile: ${_selectedFile != null}, HasBytes: ${_selectedFileBytes != null}');
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Asset preview
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImagePreview(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // File info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _selectedFileName ?? 'Unknown file',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text(
          _selectedFileType?.toUpperCase() ?? '',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
