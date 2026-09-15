import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../widgets/media_preview_widget.dart';

class CoupleLevelManagementScreen extends StatefulWidget {
  const CoupleLevelManagementScreen({super.key});

  @override
  State<CoupleLevelManagementScreen> createState() => _CoupleLevelManagementScreenState();
}

class _CoupleLevelManagementScreenState extends State<CoupleLevelManagementScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _levelController = TextEditingController();
  final _pointsController = TextEditingController();
  
  bool _isSaving = false;
  String? _editingDocId;
  
  String? _currentBadgeUrl;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  String? _currentFrameUrl;
  Uint8List? _selectedFrameBytes;
  String? _selectedFrameName;

  @override
  void dispose() {
    _levelController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _levelController.clear();
      _pointsController.clear();
      _editingDocId = null;
      _currentBadgeUrl = null;
      _selectedFileBytes = null;
      _selectedFileName = null;
      _currentFrameUrl = null;
      _selectedFrameBytes = null;
      _selectedFrameName = null;
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'svga', 'webp'],
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() {
          _selectedFileBytes = result.files.first.bytes;
          _selectedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _pickFrame() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'svga', 'webp'],
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() {
          _selectedFrameBytes = result.files.first.bytes;
          _selectedFrameName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking Frame: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick Frame: $e')),
        );
      }
    }
  }

  Future<void> _saveLevel() async {
    final levelVal = int.tryParse(_levelController.text.trim());
    final pointsVal = int.tryParse(_pointsController.text.trim());

    if (levelVal == null || levelVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid level number (greater than 0)')),
      );
      return;
    }

    if (pointsVal == null || pointsVal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid points/diamonds amount (0 or more)')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String badgeUrl = _currentBadgeUrl ?? '';
      if (_selectedFileBytes != null && _selectedFileName != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('couple_levels/${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName');
        final uploadTask = storageRef.putData(_selectedFileBytes!);
        final snapshot = await uploadTask;
        badgeUrl = await snapshot.ref.getDownloadURL();
      }

      String frameUrl = _currentFrameUrl ?? '';
      if (_selectedFrameBytes != null && _selectedFrameName != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('couple_levels/${DateTime.now().millisecondsSinceEpoch}_$_selectedFrameName');
        final uploadTask = storageRef.putData(_selectedFrameBytes!);
        final snapshot = await uploadTask;
        frameUrl = await snapshot.ref.getDownloadURL();
      }

      final docId = _editingDocId ?? 'level_$levelVal';
      await _firestore.collection('couple_levels').doc(docId).set({
        'level': levelVal,
        'requiredPoints': pointsVal,
        'badgeUrl': badgeUrl,
        'frameUrl': frameUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couple relationship level saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save level: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _startEdit(Map<String, dynamic> data, String docId) {
    setState(() {
      _editingDocId = docId;
      _levelController.text = (data['level'] ?? 0).toString();
      _pointsController.text = (data['requiredPoints'] ?? 0).toString();
      _currentBadgeUrl = data['badgeUrl'] as String?;
      _currentFrameUrl = data['frameUrl'] as String?;
      _selectedFileBytes = null;
      _selectedFileName = null;
      _selectedFrameBytes = null;
      _selectedFrameName = null;
    });
  }

  Future<void> _deleteLevel(String docId, String? badgeUrl, String? frameUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1F3F),
        title: const Text('Delete Couple Level', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this couple level configuration?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final List<String?> urlsToDelete = [badgeUrl, frameUrl];
      for (final url in urlsToDelete) {
        if (url != null && url.isNotEmpty) {
          try {
            final storageRef = FirebaseStorage.instance.refFromURL(url);
            await storageRef.delete();
          } catch (storageErr) {
            debugPrint('Error deleting storage file: $storageErr');
          }
        }
      }

      await _firestore.collection('couple_levels').doc(docId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couple level configuration deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete level: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMediaPreview({
    required Uint8List? selectedFileBytes,
    required String? selectedFileName,
    required String? currentUrl,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    if (selectedFileBytes != null && selectedFileName != null) {
      final isSvga = selectedFileName.toLowerCase().endsWith('.svga');
      return Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1E142B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor, width: 1.5),
        ),
        child: isSvga
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.animation, color: accentColor, size: 24),
                    const SizedBox(height: 4),
                    const Text('SVGA file', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(selectedFileBytes, fit: BoxFit.contain),
              ),
      );
    }

    if (currentUrl != null && currentUrl.isNotEmpty) {
      return Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1E142B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor, width: 1.5),
        ),
        child: MediaPreviewWidget(
          url: currentUrl,
          width: 80,
          height: 80,
          fit: BoxFit.contain,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1E142B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: Colors.white54, size: 28),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E142B),
      appBar: AppBar(
        title: const Text('Couple Level Management', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2D1F3F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Card
            Card(
              color: const Color(0xFF2D1F3F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingDocId != null 
                              ? 'Update Couple Level' 
                              : 'Add Couple Level',
                          style: const TextStyle(
                            color: Colors.pinkAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_editingDocId != null)
                          TextButton.icon(
                            onPressed: _clearForm,
                            icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                            label: const Text('Cancel Edit', style: TextStyle(color: Colors.grey)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Media Previews Row
                        Column(
                          children: [
                            Row(
                              children: [
                                _buildMediaPreview(
                                  selectedFileBytes: _selectedFileBytes,
                                  selectedFileName: _selectedFileName,
                                  currentUrl: _currentBadgeUrl,
                                  label: 'Badge',
                                  onTap: _pickFile,
                                  accentColor: Colors.pinkAccent,
                                ),
                                const SizedBox(width: 12),
                                _buildMediaPreview(
                                  selectedFileBytes: _selectedFrameBytes,
                                  selectedFileName: _selectedFrameName,
                                  currentUrl: _currentFrameUrl,
                                  label: 'Frame',
                                  onTap: _pickFrame,
                                  accentColor: Colors.pinkAccent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap blocks to upload PNG/GIF/SVGA/WEBP',
                              style: TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: _levelController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Level Number',
                                  labelStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: const Color(0xFF1E142B),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _pointsController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Required Diamonds',
                                  labelStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: const Color(0xFF1E142B),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveLevel,
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined, color: Colors.white),
                          label: Text(
                            _editingDocId != null ? 'Update Level' : 'Save Level Configuration',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Configured Couple Levels',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Levels List Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('couple_levels')
                    .orderBy('level', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No couple relationship levels configured yet.\nDefault thresholds (0, 100, 500, ...) will be used.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final level = data['level'] ?? 0;
                      final requiredPoints = data['requiredPoints'] ?? 0;
                      final badgeUrl = data['badgeUrl'] as String? ?? '';
                      final frameUrl = data['frameUrl'] as String? ?? '';
                      final docId = docs[index].id;

                      return Card(
                        color: const Color(0xFF2D1F3F),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (badgeUrl.isNotEmpty) ...[
                                MediaPreviewWidget(
                                  url: badgeUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (frameUrl.isNotEmpty) ...[
                                MediaPreviewWidget(
                                  url: frameUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                              ],
                              if (badgeUrl.isEmpty && frameUrl.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.pinkAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    'Lv.$level',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            'Level $level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '$requiredPoints Diamonds required',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _startEdit(data, docId),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteLevel(docId, badgeUrl, frameUrl),
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
      ),
    );
  }
}
