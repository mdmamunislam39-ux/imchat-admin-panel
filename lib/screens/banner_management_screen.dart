import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../services/banner_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../widgets/media_preview_widget.dart';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _redirectUrlController = TextEditingController();
  final _eventIdController = TextEditingController();
  bool _isEditing = false;
  String? _editingBannerId;
  int _currentOrderIndex = 0;

  // File Upload State
  Uint8List? _fileBytes;
  String? _fileName;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _redirectUrlController.dispose();
    _eventIdController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingBannerId = null;
      _redirectUrlController.clear();
      _eventIdController.clear();
      _fileBytes = null;
      _fileName = null;
      _uploadedImageUrl = null;
      _isUploading = false;
    });
  }

  void _editBanner(BannerModel banner) {
    setState(() {
      _isEditing = true;
      _editingBannerId = banner.id;
      _uploadedImageUrl = banner.imageUrl;
      _redirectUrlController.text = banner.redirectUrl ?? '';
      _eventIdController.text = banner.eventId ?? '';
      _currentOrderIndex = banner.orderIndex;
      _fileBytes = null;
      _fileName = null;
    });
    _showBannerFormDialog(context);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'svga', 'mp4'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _fileBytes = result.files.first.bytes;
          _fileName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<String?> _uploadToStorage(Uint8List bytes, String name) async {
    try {
      final storageName = 'banners/${DateTime.now().millisecondsSinceEpoch}_$name';
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
    
    if (_uploadedImageUrl == null && _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image first')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String finalImageUrl = _uploadedImageUrl ?? '';
      if (_fileBytes != null && _fileName != null) {
        final uploaded = await _uploadToStorage(_fileBytes!, _fileName!);
        if (uploaded != null) {
          finalImageUrl = uploaded;
        } else {
          throw Exception('Failed to upload image');
        }
      }

      final banner = BannerModel(
        id: _editingBannerId ?? '',
        imageUrl: finalImageUrl,
        redirectUrl: _redirectUrlController.text.isEmpty ? null : _redirectUrlController.text,
        eventId: _eventIdController.text.isEmpty ? null : _eventIdController.text,
        orderIndex: _isEditing ? _currentOrderIndex : 999,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await BannerService.updateBanner(banner);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner updated successfully')));
      } else {
        await BannerService.createBanner(banner);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner created successfully')));
      }

      if (mounted) {
        Navigator.pop(context);
        _resetForm();
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _showBannerFormDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          _isEditing ? 'Edit Banner' : 'Add New Banner',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Banner Image Field
                    GestureDetector(
                      onTap: () async {
                        await _pickFile();
                        setStateDialog(() {}); // Refresh dialog state
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[600]!),
                        ),
                        child: _fileBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_fileBytes!, fit: BoxFit.cover),
                              )
                            : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                                ? MediaPreviewWidget(
                                    url: _uploadedImageUrl!,
                                    width: double.infinity,
                                    height: 120,
                                    borderRadius: BorderRadius.circular(12),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate, color: Colors.blue, size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to select Banner Image',
                                        style: TextStyle(color: Colors.grey[400]),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Show link field only if image is uploaded/selected
                    if (_fileBytes != null || (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)) ...[
                      TextFormField(
                        controller: _redirectUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Redirect URL (Optional)',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _eventIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Event ID (Optional)',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isUploading ? null : _submitForm,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: _isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text(_isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    ).then((_) {
      if (!_isEditing) _resetForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Banner Management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _resetForm();
          _showBannerFormDialog(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<BannerModel>>(
        stream: BannerService.getBannersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          final banners = snapshot.data ?? [];

          if (banners.isEmpty) {
            return const Center(
              child: Text('No banners found. Add one!', style: TextStyle(color: Colors.grey)),
            );
          }

          return ReorderableListView.builder(
            itemCount: banners.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final item = banners.removeAt(oldIndex);
                banners.insert(newIndex, item);
                // Update all orders in Firestore
                BannerService.updateBannerOrders(banners);
              });
            },
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                key: ValueKey(banner.id),
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: MediaPreviewWidget(
                    url: banner.imageUrl,
                    width: 80,
                    height: 60,
                  ),
                  title: Text(
                    banner.redirectUrl?.isNotEmpty == true ? banner.redirectUrl! : 'No Redirect URL',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: banner.eventId?.isNotEmpty == true
                      ? Text(
                          'Event ID: ${banner.eventId}',
                          style: const TextStyle(color: Colors.blueAccent),
                        )
                      : null,

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: banner.isActive,
                        onChanged: (value) {
                          BannerService.toggleBannerStatus(banner.id, value);
                        },
                        activeThumbColor: Colors.blue,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editBanner(banner),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text('Delete Banner', style: TextStyle(color: Colors.white)),
                              content: const Text('Are you sure you want to delete this banner?', style: TextStyle(color: Colors.grey)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    BannerService.deleteBanner(banner.id);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.drag_handle, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
