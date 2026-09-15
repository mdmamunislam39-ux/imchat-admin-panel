import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/room_game_model.dart';
import '../services/room_game_service.dart';
import '../widgets/media_preview_widget.dart';

class RoomGameManagementScreen extends StatefulWidget {
  const RoomGameManagementScreen({super.key});

  @override
  State<RoomGameManagementScreen> createState() => _RoomGameManagementScreenState();
}

class _RoomGameManagementScreenState extends State<RoomGameManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gameCodeController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  final _gameUrlController = TextEditingController();
  String _selectedCategory = 'game'; // 'mode' or 'game'

  bool _isEditing = false;
  String? _editingGameId;

  // File Upload State
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploading = false;

  // Built-in Room Games & Modes metadata definition
  final List<Map<String, dynamic>> _builtInGames = [
    {
      'key': 'ludo',
      'title': 'Ludo (লুডু গেম)',
      'category': 'mode',
      'categoryLabel': 'Room Mode',
      'categoryColor': Colors.deepOrange,
      'icon': Icons.gamepad_rounded,
      'iconColor': Colors.deepOrangeAccent,
      'description': 'Interactive multiplayer Ludo board inside audio room',
    },
    {
      'key': 'carrom',
      'title': 'Carrom (ক্যারাম গেম)',
      'category': 'mode',
      'categoryLabel': 'Room Mode',
      'categoryColor': Colors.amber,
      'icon': Icons.blur_circular_rounded,
      'iconColor': Colors.amberAccent,
      'description': 'Multiplayer Carrom board game for room participants',
    },
    {
      'key': 'youtube',
      'title': 'YouTube (ইউটিউব প্লেয়ার)',
      'category': 'mode',
      'categoryLabel': 'Room Mode',
      'categoryColor': Colors.red,
      'icon': Icons.smart_display_rounded,
      'iconColor': Colors.redAccent,
      'description': 'Synchronized YouTube video player in seat 1',
    },
    {
      'key': 'vote_pro',
      'title': 'Vote Pro (ভোট ও পোলিং)',
      'category': 'game',
      'categoryLabel': 'Room Game',
      'categoryColor': Colors.purple,
      'icon': Icons.how_to_vote_rounded,
      'iconColor': Colors.purpleAccent,
      'description': 'Real-time room polling and voting competitions',
    },
    {
      'key': 'dice',
      'title': 'Dice (ছক্কা / ডাইস রোল)',
      'category': 'game',
      'categoryLabel': 'Room Game',
      'categoryColor': Colors.cyan,
      'icon': Icons.casino_rounded,
      'iconColor': Colors.cyanAccent,
      'description': 'Broadcast dice rolling animation in room chat',
    },
    {
      'key': 'custom_roulette',
      'title': 'Custom Roulette (কাস্টম রুলেট)',
      'category': 'game',
      'categoryLabel': 'Room Game',
      'categoryColor': Colors.teal,
      'icon': Icons.circle_notifications_rounded,
      'iconColor': Colors.tealAccent,
      'description': 'Custom customizable spinning wheel for games & giveaways',
    },
    {
      'key': 'pk_battle',
      'title': 'PK Battle (পিকে ব্যাটল)',
      'category': 'game',
      'categoryLabel': 'Room Game',
      'categoryColor': Colors.blue,
      'icon': Icons.sports_kabaddi_rounded,
      'iconColor': Colors.blueAccent,
      'description': 'In-room or Room vs Room PK battle competition',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _gameCodeController.dispose();
    _thumbnailUrlController.dispose();
    _gameUrlController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingGameId = null;
      _selectedCategory = 'game';
      _nameController.clear();
      _gameCodeController.clear();
      _thumbnailUrlController.clear();
      _gameUrlController.clear();
      _selectedFileBytes = null;
      _selectedFileName = null;
      _isUploading = false;
    });
  }

  void _editGame(RoomGameModel game) {
    setState(() {
      _isEditing = true;
      _editingGameId = game.id;
      _selectedCategory = game.category.isNotEmpty ? game.category : 'game';
      _nameController.text = game.name;
      _gameCodeController.text = game.gameCode.isNotEmpty ? game.gameCode : game.id;
      _thumbnailUrlController.text = game.thumbnailUrl;
      _gameUrlController.text = game.gameUrl;
      _selectedFileBytes = null;
      _selectedFileName = null;
      _isUploading = false;
    });
    _showGameFormDialog(context);
  }

  Future<void> _pickThumbnailImage(StateSetter setDialogState) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setDialogState(() {
          _selectedFileBytes = result.files.first.bytes;
          _selectedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking thumbnail image: $e');
    }
  }

  Future<String?> _uploadThumbnail(Uint8List bytes, String fileName) async {
    try {
      final storagePath =
          'room_game_thumbnails/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading room game thumbnail: $e');
      return null;
    }
  }

  Future<void> _submitForm(StateSetter setDialogState) async {
    if (!_formKey.currentState!.validate()) return;

    if (_thumbnailUrlController.text.trim().isEmpty && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('গেমের থাম্বনেইল ছবি সিলেক্ট বা আপলোড করুন')),
      );
      return;
    }

    setDialogState(() {
      _isUploading = true;
    });

    try {
      String finalThumbnailUrl = _thumbnailUrlController.text.trim();

      if (_selectedFileBytes != null && _selectedFileName != null) {
        final uploadedUrl = await _uploadThumbnail(
          _selectedFileBytes!,
          _selectedFileName!,
        );
        if (uploadedUrl != null) {
          finalThumbnailUrl = uploadedUrl;
        } else {
          throw Exception('Failed to upload image to Firebase Storage');
        }
      }

      String gameCode = _gameCodeController.text.trim();
      String gameUrl = _gameUrlController.text.trim();

      if (gameCode.isEmpty) {
        gameCode = _nameController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
        if (gameCode.isEmpty) {
          gameCode = 'room_game_${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      final game = RoomGameModel(
        id: _editingGameId ?? '',
        gameCode: gameCode,
        name: _nameController.text.trim(),
        thumbnailUrl: finalThumbnailUrl,
        gameUrl: gameUrl,
        category: _selectedCategory,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await RoomGameService.updateRoomGame(game);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room Game updated successfully')),
          );
        }
      } else {
        await RoomGameService.createRoomGame(game);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New Room Game created successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        setDialogState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showGameFormDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !_isUploading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? 'Edit Room Game' : 'Add New Room Game',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Game Name (গেমের নাম)',
                          hintText: 'e.g. Ludo Club, Teen Patti, 3D Chess',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.title, color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'গেমের নাম লিখুন'
                                : null,
                      ),
                      const SizedBox(height: 14),

                      // Game Code
                      TextFormField(
                        controller: _gameCodeController,
                        style: const TextStyle(color: Colors.amber),
                        decoration: InputDecoration(
                          labelText: 'Game ID / Code (e.g. html5_ludo_pro)',
                          hintText: 'খালি রাখলে নামের ভিত্তিতে অটো জেনারেট হবে',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.tag, color: Colors.amber),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Category Selector
                      Text(
                        'Category (ক্যাটাগরি)',
                        style: TextStyle(color: Colors.grey[300], fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Room Mode (রুম মোড)')),
                              selected: _selectedCategory == 'mode',
                              selectedColor: Colors.deepOrange.withValues(alpha: 0.3),
                              labelStyle: TextStyle(
                                color: _selectedCategory == 'mode' ? Colors.deepOrangeAccent : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() => _selectedCategory = 'mode');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Room Game (রুম গেম)')),
                              selected: _selectedCategory == 'game',
                              selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                              labelStyle: TextStyle(
                                color: _selectedCategory == 'game' ? Colors.blueAccent : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() => _selectedCategory = 'game');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Game URL
                      TextFormField(
                        controller: _gameUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Game Launch URL / HTML5 Link',
                          hintText: 'https://my-game.web.app (WebView Link)',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.link, color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Thumbnail
                      Text(
                        'Game Thumbnail Icon / Photo (থাম্বনেইল ছবি)',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        child: Column(
                          children: [
                            if (_selectedFileBytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  _selectedFileBytes!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (_thumbnailUrlController.text.isNotEmpty)
                              MediaPreviewWidget(
                                url: _thumbnailUrlController.text,
                                width: 80,
                                height: 80,
                              )
                            else
                              Icon(
                                Icons.image_search,
                                size: 60,
                                color: Colors.grey[500],
                              ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _isUploading
                                  ? null
                                  : () => _pickThumbnailImage(setDialogState),
                              icon: const Icon(Icons.photo_library),
                              label: Text(
                                _selectedFileBytes != null ||
                                        _thumbnailUrlController.text.isNotEmpty
                                    ? 'Change Image'
                                    : 'Select Image from Gallery',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isUploading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(color: Colors.blueAccent),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Uploading image and saving room game...',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isUploading
                    ? null
                    : () {
                        Navigator.pop(context);
                        _resetForm();
                      },
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _isUploading ? null : () => _submitForm(setDialogState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(_isEditing ? 'Update Game' : 'Create Game'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      if (!_isEditing) _resetForm();
    });
  }

  Widget _buildBuiltInGameCard({
    required String key,
    required String title,
    required String categoryLabel,
    required Color categoryColor,
    required IconData icon,
    required Color iconColor,
    required String description,
    required Map<String, dynamic> configData,
  }) {
    // Check active status in config
    bool isActive = true;
    final gameConfig = configData[key];
    if (gameConfig != null) {
      if (gameConfig is Map) {
        final activeVal = gameConfig['isActive'] ?? gameConfig['isEnabled'] ?? gameConfig['active'];
        if (activeVal != null) {
          isActive = activeVal != false && activeVal != 0 && activeVal != 'false' && activeVal != '0';
        }
      } else if (gameConfig is bool) {
        isActive = gameConfig;
      }
    }
    // Also check flat key
    if (configData.containsKey('${key}_active')) {
      isActive = configData['${key}_active'] == true;
    }

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.white10 : Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: categoryColor.withValues(alpha: 0.5), width: 0.8),
              ),
              child: Text(
                categoryLabel,
                style: TextStyle(
                  color: categoryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    isActive ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: isActive ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? 'Status: Active (Visible in app)' : 'Status: Hidden (অ্যাপে লুকানো থাকবে)',
                    style: TextStyle(
                      color: isActive ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Switch(
          value: isActive,
          onChanged: (value) async {
            try {
              await RoomGameService.toggleBuiltInGameStatus(key, value);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? '$title is now ACTIVE (অ্যাপে দৃশ্যমান)'
                          : '$title is now HIDDEN (অ্যাপে লুকানো হয়েছে)',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating status: $e')),
                );
              }
            }
          },
          activeThumbColor: Colors.blueAccent,
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
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.meeting_room_rounded, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text(
              'Room Game Management',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _resetForm();
          _showGameFormDialog(context);
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Room Game',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withValues(alpha: 0.15),
                    Colors.purpleAccent.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.blueAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ভয়েস রুম গেম ও ফিচার ম্যানেজমেন্ট',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'অ্যাপের নিজস্ব রুম গেমসমূহ (যেমন লুডু, ক্যারাম, ইউটিউব) অন/অফ করতে পারবেন এবং নতুন যেকোনো HTML5 রুম গেম যোগ করতে পারবেন।',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Section 1: Built-in Room Games & Modes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.extension_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Built-in Room Games & Modes (অ্যাপের নিজস্ব গেমসমূহ)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Stream for built-in games config
            StreamBuilder<DocumentSnapshot>(
              stream: RoomGameService.getBuiltInRoomGamesConfigStream(),
              builder: (context, snapshot) {
                final Map<String, dynamic> configData =
                    (snapshot.hasData && snapshot.data!.exists)
                        ? (snapshot.data!.data() as Map<String, dynamic>? ?? {})
                        : {};

                return Column(
                  children: _builtInGames.map((gameMeta) {
                    return _buildBuiltInGameCard(
                      key: gameMeta['key'] as String,
                      title: gameMeta['title'] as String,
                      categoryLabel: gameMeta['categoryLabel'] as String,
                      categoryColor: gameMeta['categoryColor'] as Color,
                      icon: gameMeta['icon'] as IconData,
                      iconColor: gameMeta['iconColor'] as Color,
                      description: gameMeta['description'] as String,
                      configData: configData,
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white12, thickness: 1),
            const SizedBox(height: 8),

            // Section 2: Custom / Webview Room Games
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sports_esports_rounded, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Webview & Custom Room Games (নতুন রুম গেমসমূহ)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _resetForm();
                      _showGameFormDialog(context);
                    },
                    icon: const Icon(Icons.add, size: 16, color: Colors.blueAccent),
                    label: const Text('Add Game', style: TextStyle(color: Colors.blueAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Stream for custom room games
            StreamBuilder<List<RoomGameModel>>(
              stream: RoomGameService.getRoomGamesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                  );
                }

                final builtInKeys = _builtInGames.map((g) => g['key'] as String).toSet();
                // Filter out documents that represent built-in keys if any
                final games = (snapshot.data ?? [])
                    .where((g) => !builtInKeys.contains(g.id) && !builtInKeys.contains(g.gameCode))
                    .toList();

                if (games.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gamepad_outlined, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 12),
                          const Text(
                            'কোনো কাস্টম রুম গেম যোগ করা হয়নি',
                            style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'উপরে "Add Game" বাটনে ক্লিক করে HTML5 / WebView রুম গেম অ্যাড করুন',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final isMode = game.category == 'mode';

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: game.isActive ? Colors.white10 : Colors.redAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: MediaPreviewWidget(
                            url: game.thumbnailUrl,
                            width: 54,
                            height: 54,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                game.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isMode ? Colors.deepOrange : Colors.blueAccent).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (isMode ? Colors.deepOrange : Colors.blueAccent).withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isMode ? 'Room Mode' : 'Room Game',
                                style: TextStyle(
                                  color: isMode ? Colors.deepOrangeAccent : Colors.blueAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (game.gameCode.isNotEmpty)
                                Text(
                                  'ID: ${game.gameCode}',
                                  style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                                ),
                              if (game.gameUrl.isNotEmpty)
                                Text(
                                  'URL: ${game.gameUrl}',
                                  style: TextStyle(color: Colors.blue[300], fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    game.isActive ? Icons.visibility : Icons.visibility_off,
                                    size: 14,
                                    color: game.isActive ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    game.isActive ? 'Active (Visible in room)' : 'Hidden (অ্যাপে লুকানো)',
                                    style: TextStyle(
                                      color: game.isActive ? Colors.greenAccent : Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: game.isActive,
                              onChanged: (value) {
                                RoomGameService.toggleRoomGameStatus(game.id, value);
                              },
                              activeThumbColor: Colors.blueAccent,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                              onPressed: () => _editGame(game),
                              tooltip: 'Edit Game',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    title: const Text(
                                      'Delete Room Game',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete "${game.name}"?',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          RoomGameService.deleteRoomGame(game.id);
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              tooltip: 'Delete Game',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
