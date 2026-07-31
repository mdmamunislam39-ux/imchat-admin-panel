import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'media_preview_widget.dart';

class RoomEditDialog extends StatefulWidget {
  final Map<String, dynamic> roomData;
  final String roomId;
  final VoidCallback onSaved;

  const RoomEditDialog({
    super.key,
    required this.roomData,
    required this.roomId,
    required this.onSaved,
  });

  @override
  State<RoomEditDialog> createState() => _RoomEditDialogState();
}

class _RoomEditDialogState extends State<RoomEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late TextEditingController _nameController;
  late TextEditingController _descController;
  
  bool _isPinned = false;
  DateTime? _pinnedUntil;
  
  String? _selectedFrameId;
  DateTime? _frameUntil;
  
  bool _isUploading = false;
  Uint8List? _imageBytes;
  String? _imageName;
  String? _currentImageUrl;

  List<Map<String, dynamic>> _frames = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.roomData['name'] ?? '');
    _descController = TextEditingController(text: widget.roomData['description'] ?? '');
    
    _isPinned = widget.roomData['isPinned'] ?? false;
    
    if (widget.roomData['pinnedUntil'] != null) {
      if (widget.roomData['pinnedUntil'] is Timestamp) {
        _pinnedUntil = (widget.roomData['pinnedUntil'] as Timestamp).toDate();
      }
    }
    
    if (widget.roomData['roomFrameUntil'] != null) {
      if (widget.roomData['roomFrameUntil'] is Timestamp) {
        _frameUntil = (widget.roomData['roomFrameUntil'] as Timestamp).toDate();
      }
    }
    
    _currentImageUrl = widget.roomData['imageUrl'];
    _loadFrames();
  }

  Future<void> _loadFrames() async {
    final snapshot = await _firestore.collection('room_profile_frames').get();
    setState(() {
      _frames = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      
      // Try to find currently assigned frame
      final currentFrameUrl = widget.roomData['roomFrameUrl'];
      if (currentFrameUrl != null && currentFrameUrl.toString().isNotEmpty) {
        try {
          final matched = _frames.firstWhere((f) => f['mainUrl'] == currentFrameUrl);
          _selectedFrameId = matched['id'];
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageName = result.files.first.name;
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool forPin) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (pickedDate != null) {
      if (mounted) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          final dt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          setState(() {
            if (forPin) _pinnedUntil = dt;
            else _frameUntil = dt;
          });
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isPinned && _pinnedUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an expiration date for the Top Pin')));
      return;
    }
    
    if (_selectedFrameId != null && _frameUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an expiration date for the Frame')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? finalImageUrl = _currentImageUrl;
      if (_imageBytes != null && _imageName != null) {
        final ref = FirebaseStorage.instance.ref().child('room_images/${DateTime.now().millisecondsSinceEpoch}_$_imageName');
        final uploadTask = await ref.putData(_imageBytes!);
        finalImageUrl = await uploadTask.ref.getDownloadURL();
      }

      String? frameMainUrl;
      if (_selectedFrameId != null) {
        final frame = _frames.firstWhere((f) => f['id'] == _selectedFrameId);
        frameMainUrl = frame['mainUrl'];
      }

      await _firestore.collection('audio_rooms_v2').doc(widget.roomId).update({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'imageUrl': finalImageUrl,
        'isPinned': _isPinned,
        'pinnedUntil': _pinnedUntil,
        'roomFrameUrl': frameMainUrl,
        'roomFrameUntil': _frameUntil,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room updated successfully')));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Room: ${widget.roomId}'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Room Name'),
                  validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Room Description'),
                ),
                const SizedBox(height: 24),
                
                // Image
                const Text('Room Image', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      height: 80, width: 80,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                      child: _imageBytes != null 
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                          ? MediaPreviewWidget(url: _currentImageUrl!, width: 80, height: 80)
                          : const Icon(Icons.image),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(onPressed: _pickImage, child: const Text('Change Image')),
                  ],
                ),
                
                const Divider(height: 48),
                
                // Top Pin
                const Text('Top Pin Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SwitchListTile(
                  title: const Text('Set as Top Pinned'),
                  value: _isPinned,
                  onChanged: (val) => setState(() => _isPinned = val),
                ),
                if (_isPinned)
                  ListTile(
                    title: Text(_pinnedUntil == null ? 'Select Expiration Date' : 'Expires: ${_pinnedUntil.toString()}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(context, true),
                  ),

                const Divider(height: 48),
                
                // Frame
                const Text('Room Profile Frame Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _selectedFrameId,
                  decoration: const InputDecoration(labelText: 'Select Frame'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Frame')),
                    ..._frames.map((f) => DropdownMenuItem(
                      value: f['id'] as String,
                      child: Row(
                        children: [
                          if (f['thumbnailUrl'] != null)
                            SizedBox(height: 30, width: 30, child: MediaPreviewWidget(url: f['thumbnailUrl'], width: 30, height: 30)),
                          const SizedBox(width: 8),
                          Text(f['name']),
                        ],
                      ),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedFrameId = val;
                      if (val == null) _frameUntil = null;
                    });
                  },
                ),
                if (_selectedFrameId != null)
                  ListTile(
                    title: Text(_frameUntil == null ? 'Select Frame Expiration Date' : 'Expires: ${_frameUntil.toString()}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(context, false),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isUploading ? null : _save,
          child: _isUploading ? const CircularProgressIndicator() : const Text('Save Changes'),
        ),
      ],
    );
  }
}
