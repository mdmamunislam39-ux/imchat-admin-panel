import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';
import '../widgets/media_preview_widget.dart';
import 'fruit_wheel_game_screen.dart';
import 'greedy_game_screen.dart';
import 'pink_greedy_game_screen.dart';
import 'html5_game_management_screen.dart';

class GameManagementScreen extends StatefulWidget {
  const GameManagementScreen({super.key});

  @override
  State<GameManagementScreen> createState() => _GameManagementScreenState();
}

class _GameManagementScreenState extends State<GameManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gameCodeController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  final _gameUrlController = TextEditingController();

  bool _isEditing = false;
  String? _editingGameId;
  double _existingWinRatio = 0.5;

  // File Upload State
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploading = false;

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
      _existingWinRatio = 0.5;
      _nameController.clear();
      _gameCodeController.clear();
      _thumbnailUrlController.clear();
      _gameUrlController.clear();
      _selectedFileBytes = null;
      _selectedFileName = null;
      _isUploading = false;
    });
  }

  void _editGame(GameModel game) {
    setState(() {
      _isEditing = true;
      _editingGameId = game.id;
      _existingWinRatio = game.winRatio;
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
          'game_thumbnails/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading thumbnail: $e');
      return null;
    }
  }

  Future<void> _submitForm(StateSetter setDialogState) async {
    if (!_formKey.currentState!.validate()) return;

    if (_thumbnailUrlController.text.trim().isEmpty && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload or select a thumbnail image')),
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
          throw Exception('Failed to upload image to storage');
        }
      }

      String gameCode = _gameCodeController.text.trim();
      String gameUrl = _gameUrlController.text.trim();

      if (gameCode.isEmpty && gameUrl.isEmpty) {
        setDialogState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('গেম আইডি অথবা URL যেকোনো একটি পূরণ করতে হবে')),
        );
        return;
      }

      // Auto-assign URL if only gameCode is provided
      if (gameUrl.isEmpty) {
        if (gameCode.contains('greedy') || gameCode.contains('html5') || gameCode.contains('market')) {
          gameUrl = 'https://greedy-market-game.web.app';
        }
      }
      // Auto-assign gameCode if only URL is provided
      if (gameCode.isEmpty) {
        gameCode = _editingGameId ?? 'game_${DateTime.now().millisecondsSinceEpoch}';
      }

      final game = GameModel(
        id: _editingGameId ?? '',
        gameCode: gameCode,
        name: _nameController.text.trim(),
        thumbnailUrl: finalThumbnailUrl,
        gameUrl: gameUrl,
        winRatio: _existingWinRatio,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await GameService.updateGame(game);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game updated successfully')),
          );
        }
      } else {
        await GameService.createGame(game);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game created successfully')),
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
            title: Text(
              _isEditing ? 'Edit Game' : 'Add New Game',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Game Name (গেমের নাম)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter a game name'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _gameCodeController,
                      style: const TextStyle(color: Colors.amber),
                      decoration: InputDecoration(
                        labelText: 'Game ID / Code (e.g. html5_greedy_market)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        helperText: 'গেম আইডি অথবা URL যেকোনো একটি দিলেই হবে',
                        helperStyle: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _gameUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Game URL / WebView Link (Optional if ID given)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Game Thumbnail Photo',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: Column(
                        children: [
                          if (_selectedFileBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _selectedFileBytes!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (_thumbnailUrlController.text.isNotEmpty)
                            MediaPreviewWidget(
                              url: _thumbnailUrlController.text,
                              width: 100,
                              height: 100,
                            )
                          else
                            Icon(
                              Icons.image_search,
                              size: 60,
                              color: Colors.grey[500],
                            ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isUploading
                                ? null
                                : () => _pickThumbnailImage(setDialogState),
                            icon: const Icon(Icons.photo_library),
                            label: Text(
                              _selectedFileBytes != null ||
                                      _thumbnailUrlController.text.isNotEmpty
                                  ? 'Change Photo from Gallery'
                                  : 'Select Photo from Gallery',
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
                      const LinearProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 8),
                      const Text(
                        'Uploading image and saving game...',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
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
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () => _submitForm(setDialogState),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text(_isEditing ? 'Update' : 'Create'),
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
    required String docId,
    required String title,
    required IconData icon,
    required Color color,
    Widget? configScreen,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('config').doc(docId).snapshots(),
      builder: (context, snapshot) {
        bool isActive = true;
        String thumbnailUrl = '';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            isActive = (data['isActive'] ?? true) != false;
            thumbnailUrl = data['thumbnailUrl'] as String? ?? '';
          }
        }

        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: thumbnailUrl.isNotEmpty
                ? MediaPreviewWidget(url: thumbnailUrl, width: 48, height: 48)
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
            title: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              isActive ? 'Status: Active (Visible in app)' : 'Status: Inactive (Hidden in app)',
              style: TextStyle(
                color: isActive ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isActive,
                  onChanged: (value) async {
                    await FirebaseFirestore.instance.collection('config').doc(docId).set({
                      'isActive': value,
                      'isEnabled': value,
                      'status': value ? 'active' : 'inactive',
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    try {
                      await FirebaseFirestore.instance.collection('games').doc(docId).set({
                        'isActive': value,
                        'isEnabled': value,
                        'status': value ? 'active' : 'inactive',
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    } catch (_) {}

                    if (docId == 'html5_greedy_game') {
                      try {
                        await FirebaseFirestore.instance.collection('games').doc('html5_greedy_market').set({
                          'isActive': value,
                          'isEnabled': value,
                          'status': value ? 'active' : 'inactive',
                          'updatedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                      } catch (_) {}
                    }
                  },
                  activeThumbColor: Colors.blue,
                ),
                if (configScreen != null)
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => configScreen),
                      );
                    },
                    tooltip: 'Configure Game',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Game Management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _resetForm();
          _showGameFormDialog(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Built-in System Games',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildBuiltInGameCard(
            docId: 'html5_greedy_game',
            title: '🎮 HTML 5 Game (গ্রিডি মার্কেট Live)',
            icon: Icons.sports_esports,
            color: Colors.amber,
            configScreen: const Html5GameManagementScreen(),
          ),
          _buildBuiltInGameCard(
            docId: 'greedy_game',
            title: 'Greedy Game',
            icon: Icons.restaurant,
            color: Colors.orange,
            configScreen: const GreedyGameScreen(),
          ),
          _buildBuiltInGameCard(
            docId: 'fruit_wheel',
            title: 'Fruit Wheel',
            icon: Icons.casino,
            color: Colors.purple,
            configScreen: const FruitWheelGameScreen(),
          ),
          _buildBuiltInGameCard(
            docId: 'pink_greedy_game',
            title: 'Pink Greedy Game',
            icon: Icons.cake,
            color: Colors.pink,
            configScreen: const PinkGreedyGameScreen(),
          ),
          _buildBuiltInGameCard(
            docId: 'food_spin_game',
            title: 'Food Spin Game',
            icon: Icons.local_pizza,
            color: Colors.amber,
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.grey),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Webview & Custom Games',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GameModel>>(
              stream: GameService.getGamesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );
                }

                final games = snapshot.data ?? [];

                if (games.isEmpty) {
                  return const Center(
                    child: Text(
                      'No games found. Add one!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: MediaPreviewWidget(
                          url: game.thumbnailUrl,
                          width: 60,
                          height: 60,
                        ),
                        title: Text(
                          game.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
                                GameService.toggleGameStatus(game.id, value);
                              },
                              activeThumbColor: Colors.blue,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editGame(game),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    title: const Text(
                                      'Delete Game',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to delete this game?',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          GameService.deleteGame(game.id);
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
