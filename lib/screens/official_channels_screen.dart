import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/media_preview_widget.dart';
import '../models/channel_model.dart';
import '../services/channel_service.dart';
import 'channel_posts_screen.dart';

class OfficialChannelsScreen extends StatefulWidget {
  const OfficialChannelsScreen({super.key});

  @override
  State<OfficialChannelsScreen> createState() => _OfficialChannelsScreenState();
}

class _OfficialChannelsScreenState extends State<OfficialChannelsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isEditing = false;
  String? _editingChannelId;
  int _currentSubscriberCount = 0;
  DateTime? _createdAt;

  // Image Upload State
  Uint8List? _fileBytes;
  String? _fileName;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  
  // Verification State
  bool _isVerifiedToggle = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingChannelId = null;
      _nameController.clear();
      _currentSubscriberCount = 0;
      _createdAt = null;
      
      _fileBytes = null;
      _fileName = null;
      _uploadedImageUrl = null;
      _isUploading = false;
      _isVerifiedToggle = false;
    });
  }

  void _editChannel(ChannelModel channel) {
    setState(() {
      _isEditing = true;
      _editingChannelId = channel.id;
      _nameController.text = channel.name;
      _currentSubscriberCount = channel.subscriberCount;
      _createdAt = channel.createdAt;
      
      _uploadedImageUrl = channel.imageUrl;
      _isVerifiedToggle = channel.isVerified;
      
      _fileBytes = null;
      _fileName = null;
      _isUploading = false;
    });
    _showChannelFormDialog(context);
  }

  Future<void> _pickFile(StateSetter setStateDialog) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setStateDialog(() {
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
      final storageName = 'official_channels/avatars/${DateTime.now().millisecondsSinceEpoch}_$name';
      final ref = FirebaseStorage.instance.ref().child(storageName);
      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _submitForm(StateSetter setStateDialog) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_uploadedImageUrl == null && _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a profile image')));
      return;
    }

    setStateDialog(() => _isUploading = true);

    try {
      String? finalImageUrl = _uploadedImageUrl;

      if (_fileBytes != null && _fileName != null) {
        final uploadedUrl = await _uploadToStorage(_fileBytes!, _fileName!);
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          throw Exception('Failed to upload image');
        }
      }

      final channel = ChannelModel(
        id: _editingChannelId ?? '',
        name: _nameController.text,
        imageUrl: finalImageUrl ?? '',
        isVerified: _isVerifiedToggle,
        subscriberCount: _currentSubscriberCount,
        createdAt: _createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await ChannelService.updateChannel(channel);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Channel updated successfully')));
        }
      } else {
        await ChannelService.createChannel(channel);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Channel created successfully')));
        }
      }

      if (mounted) {
        Navigator.pop(context);
        _resetForm();
      }
    } catch (e) {
      setStateDialog(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _showChannelFormDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !_isUploading,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              _isEditing ? 'Edit Channel' : 'Create Channel',
              style: const TextStyle(color: Colors.white),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Image Field
                    GestureDetector(
                      onTap: _isUploading
                          ? null
                          : () async {
                              await _pickFile(setStateDialog);
                            },
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: _fileBytes != null
                            ? ClipOval(
                                child: Image.memory(_fileBytes!, fit: BoxFit.cover),
                              )
                            : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                                ? MediaPreviewWidget(
                                    url: _uploadedImageUrl!,
                                    width: 120,
                                    height: 120,
                                    borderRadius: BorderRadius.circular(60),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_a_photo, color: Colors.blue, size: 32),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Upload',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Channel Name',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                      enabled: !_isUploading,
                      validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Verification Blue Badge', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        _isVerifiedToggle ? 'Active' : 'Inactive',
                        style: TextStyle(color: _isVerifiedToggle ? Colors.blue : Colors.grey),
                      ),
                      value: _isVerifiedToggle,
                      activeThumbColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
                      onChanged: _isUploading
                          ? null
                          : (value) {
                              setStateDialog(() {
                                _isVerifiedToggle = value;
                              });
                            },
                    ),
                    
                    if (_isUploading) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 8),
                      const Text('Uploading and saving...', style: TextStyle(color: Colors.grey)),
                    ]
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
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _isUploading ? null : () => _submitForm(setStateDialog),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(_isEditing ? 'Update' : 'Create'),
            ),
          ],
        );
      }
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
        title: const Text('Official Channels'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _resetForm();
          _showChannelFormDialog(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ChannelModel>>(
        stream: ChannelService.getChannelsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          final channels = snapshot.data ?? [];

          if (channels.isEmpty) {
            return const Center(
              child: Text('No channels found.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: MediaPreviewWidget(
                    url: channel.imageUrl,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Row(
                    children: [
                      Text(channel.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      if (channel.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Icon(Icons.verified, color: Colors.blue, size: 16),
                        ),
                    ],
                  ),
                  subtitle: Text('${channel.subscriberCount} Subscribers', style: TextStyle(color: Colors.grey[400])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.post_add, color: Colors.green),
                        tooltip: 'Manage Posts',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChannelPostsScreen(channel: channel),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          channel.isVerified ? Icons.check_circle : Icons.check_circle_outline,
                          color: channel.isVerified ? Colors.blue : Colors.grey,
                        ),
                        tooltip: 'Toggle Verification',
                        onPressed: () {
                          ChannelService.toggleVerification(channel.id, !channel.isVerified);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editChannel(channel),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text('Delete Channel', style: TextStyle(color: Colors.white)),
                              content: const Text('Are you sure you want to delete this channel and all its posts?', style: TextStyle(color: Colors.grey)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ChannelService.deleteChannel(channel.id);
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
