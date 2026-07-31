import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../widgets/base_screen.dart';
import '../widgets/media_preview_widget.dart';

class RoomFrameManagementScreen extends StatefulWidget {
  const RoomFrameManagementScreen({super.key});

  @override
  State<RoomFrameManagementScreen> createState() => _RoomFrameManagementScreenState();
}

class _RoomFrameManagementScreenState extends State<RoomFrameManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _frameType = 'png';
  bool _isUploading = false;

  // File Upload State for Thumbnail
  Uint8List? _thumbBytes;
  String? _thumbName;
  
  // File Upload State for Main File
  Uint8List? _mainBytes;
  String? _mainName;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _frameType = 'png';
      _thumbBytes = null;
      _thumbName = null;
      _mainBytes = null;
      _mainName = null;
      _isUploading = false;
    });
  }

  Future<void> _pickThumbFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _thumbBytes = result.files.first.bytes;
        _thumbName = result.files.first.name;
      });
    }
  }
  
  Future<void> _pickMainFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _mainBytes = result.files.first.bytes;
        _mainName = result.files.first.name;
      });
    }
  }

  Future<String?> _uploadToStorage(Uint8List bytes, String name, String folder) async {
    try {
      final storageName = '$folder/${DateTime.now().millisecondsSinceEpoch}_$name';
      final ref = FirebaseStorage.instance.ref().child(storageName);
      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_thumbBytes == null || _mainBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both thumbnail and main file')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final thumbUrl = await _uploadToStorage(_thumbBytes!, _thumbName!, 'room_frames/thumbs');
      if (thumbUrl == null) throw Exception('Failed to upload thumbnail');
      
      final mainUrl = await _uploadToStorage(_mainBytes!, _mainName!, 'room_frames/main');
      if (mainUrl == null) throw Exception('Failed to upload main file');

      await _firestore.collection('room_profile_frames').add({
        'name': _nameController.text.trim(),
        'type': _frameType,
        'thumbnailUrl': thumbUrl,
        'mainUrl': mainUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _resetForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room Frame added successfully')));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
  
  Future<void> _deleteFrame(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Frame'),
        content: const Text('Are you sure you want to delete this room frame?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _firestore.collection('room_profile_frames').doc(id).delete();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Frame deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Room Profile Frames',
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Section
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add New Room Frame', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Frame Name', border: OutlineInputBorder()),
                        validator: (value) => value?.isEmpty ?? true ? 'Required field' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _frameType,
                        decoration: const InputDecoration(labelText: 'Frame Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'png', child: Text('PNG')),
                          DropdownMenuItem(value: 'gif', child: Text('GIF')),
                          DropdownMenuItem(value: 'svga', child: Text('SVGA')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _frameType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Thumbnail Upload
                      const Text('Thumbnail Image (PNG/JPG)', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickThumbFile,
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _thumbBytes != null
                              ? Image.memory(_thumbBytes!, fit: BoxFit.contain)
                              : const Center(child: Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey)),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Main File Upload
                      const Text('Main File (PNG/GIF/SVGA)', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickMainFile,
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _mainName ?? 'Select Main File',
                              style: TextStyle(color: _mainName != null ? Colors.blue : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: _isUploading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text('Add Frame', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // List Section
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Existing Frames', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('room_profile_frames').orderBy('createdAt', descending: true).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          
                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) return const Center(child: Text('No frames found'));
                          
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return Card(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: MediaPreviewWidget(
                                          url: data['thumbnailUrl'] ?? '',
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      child: Text(data['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Text('Type: ${data['type'] ?? 'png'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteFrame(doc.id),
                                    )
                                  ],
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
            ),
          ),
        ],
      ),
    );
  }
}
