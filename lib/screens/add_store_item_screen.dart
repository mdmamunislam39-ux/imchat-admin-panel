import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/store_item_model.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';
import '../services/official_items_service.dart';
import '../models/official_item_model.dart';

class AddStoreItemScreen extends StatefulWidget {
  const AddStoreItemScreen({super.key});

  @override
  State<AddStoreItemScreen> createState() => _AddStoreItemScreenState();
}

class _AddStoreItemScreenState extends State<AddStoreItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _diamondPriceController = TextEditingController();
  final TextEditingController _expirationDurationController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();

  StoreItemType _selectedType = StoreItemType.avatarFrame;
  StoreCategory _selectedCategory = StoreCategory.store;
  String _selectedFileType = '.png';
  int _selectedStarRating = 1;
  bool _isPermanent = true;
  bool _isCreating = false;

  // Normal PNG
  Uint8List? _normalImageBytes;
  String? _normalImageName;
  bool _isUploadingNormal = false;
  String? _normalUploadedUrl;

  // Locked PNG (for seatDecor only)
  Uint8List? _lockedImageBytes;
  String? _lockedImageName;
  bool _isUploadingLocked = false;
  String? _lockedUploadedUrl;

  // Thumbnail (optional)
  Uint8List? _thumbnailBytes;
  String? _thumbnailName;
  bool _isUploadingThumbnail = false;
  String? _thumbnailUploadedUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _diamondPriceController.dispose();
    _expirationDurationController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _updateFileTypes() {
    final supportedTypes = StoreService.getSupportedFileTypes(_selectedType);
    if (!supportedTypes.contains(_selectedFileType)) {
      setState(() {
        _selectedFileType = supportedTypes.first;
      });
    }
  }

  String _getTypeIcon(StoreItemType type) {
    switch (type) {
      case StoreItemType.avatarFrame:
        return '🖼️';
      case StoreItemType.entryEffect:
        return '✨';
      case StoreItemType.badge:
        return '🏆';
      case StoreItemType.backgroundTheme:
        return '🎭';
      case StoreItemType.roomTheme:
        return '🎨';
      case StoreItemType.seatDecor:
        return '🪑';
      case StoreItemType.micRefill:
        return '🎙️';
      case StoreItemType.roomProfileBackground:
        return '🖼️';
    }
  }

  String _getTypeDisplayName(StoreItemType type) {
    switch (type) {
      case StoreItemType.avatarFrame:
        return 'Avatar Frame';
      case StoreItemType.entryEffect:
        return 'Entry Effect';
      case StoreItemType.badge:
        return 'Badge';
      case StoreItemType.backgroundTheme:
        return 'Profile Skin';
      case StoreItemType.roomTheme:
        return 'Room Theme';
      case StoreItemType.seatDecor:
        return 'Seat Decor';
      case StoreItemType.micRefill:
        return 'Mic Refill';
      case StoreItemType.roomProfileBackground:
        return 'RP Background';
    }
  }

  String _getCategoryDisplayName(StoreCategory category) {
    switch (category) {
      case StoreCategory.store:
        return 'Store';
      case StoreCategory.officialStore:
        return 'Official Store';
    }
  }

  // ─── Pick file from gallery ───────────────────────────────────────────────

  Future<void> _pickNormalImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'gif', 'jpg', 'jpeg', 'svg', 'svga'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _normalImageBytes = result.files.single.bytes;
        _normalImageName = result.files.single.name;
        _normalUploadedUrl = null; // reset
      });
      // Auto-fill file name if empty
      if (_fileNameController.text.isEmpty) {
        _fileNameController.text = result.files.single.name.split('.').first;
      }
    }
  }

  Future<void> _pickLockedImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'gif', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _lockedImageBytes = result.files.single.bytes;
        _lockedImageName = result.files.single.name;
        _lockedUploadedUrl = null;
      });
    }
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _thumbnailBytes = result.files.single.bytes;
        _thumbnailName = result.files.single.name;
        _thumbnailUploadedUrl = null;
      });
    }
  }

  // ─── Upload to Firebase Storage ───────────────────────────────────────────

  Future<String?> _uploadFile(Uint8List bytes, String fileName, String folder) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('store_items/$folder/${timestamp}_$fileName');
      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // ─── Create item ──────────────────────────────────────────────────────────

  Future<void> _createStoreItem() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate images
    if (_normalImageBytes == null && _normalUploadedUrl == null) {
      _showErrorSnackBar('Please pick a Normal PNG image first');
      return;
    }
    if (_selectedType == StoreItemType.seatDecor &&
        _lockedImageBytes == null &&
        _lockedUploadedUrl == null) {
      _showErrorSnackBar('Please pick a Locked Seat PNG image first');
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Upload normal image
      if (_normalImageBytes != null && _normalUploadedUrl == null) {
        setState(() => _isUploadingNormal = true);
        _normalUploadedUrl = await _uploadFile(
          _normalImageBytes!,
          _normalImageName!,
          'normal',
        );
        setState(() => _isUploadingNormal = false);
        if (_normalUploadedUrl == null) {
          _showErrorSnackBar('Failed to upload Normal PNG');
          setState(() => _isCreating = false);
          return;
        }
      }

      // Upload locked image (seatDecor only)
      String? lockedUrl;
      if (_selectedType == StoreItemType.seatDecor) {
        if (_lockedImageBytes != null && _lockedUploadedUrl == null) {
          setState(() => _isUploadingLocked = true);
          _lockedUploadedUrl = await _uploadFile(
            _lockedImageBytes!,
            _lockedImageName!,
            'locked',
          );
          setState(() => _isUploadingLocked = false);
          if (_lockedUploadedUrl == null) {
            _showErrorSnackBar('Failed to upload Locked Seat PNG');
            setState(() => _isCreating = false);
            return;
          }
        }
        lockedUrl = _lockedUploadedUrl;
      }

      // Upload thumbnail (optional)
      if (_thumbnailBytes != null && _thumbnailUploadedUrl == null) {
        setState(() => _isUploadingThumbnail = true);
        _thumbnailUploadedUrl = await _uploadFile(
          _thumbnailBytes!,
          _thumbnailName!,
          'thumbnails',
        );
        setState(() => _isUploadingThumbnail = false);
      }

      // Create Firestore document
      String? itemId;
      
      if (_selectedType == StoreItemType.seatDecor) {
        itemId = await OfficialItemsService.createOfficialItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: OfficialItemCategory.seatDecor,
          fileUrl: _normalUploadedUrl!,
          fileName: _fileNameController.text.trim(),
          fileType: _selectedFileType,
          starRating: _selectedStarRating,
          thumbnailUrl: _thumbnailUploadedUrl,
          lockedFileUrl: lockedUrl,
          diamondPrice: double.parse(_diamondPriceController.text),
          expirationDuration: _isPermanent ? 0 : int.parse(_expirationDurationController.text),
        );
      } else {
        itemId = await StoreService.createStoreItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          category: _selectedCategory,
          fileUrl: _normalUploadedUrl!,
          fileName: _fileNameController.text.trim(),
          fileType: _selectedFileType,
          diamondPrice: double.parse(_diamondPriceController.text),
          expirationDuration:
              _isPermanent ? 0 : int.parse(_expirationDurationController.text),
          starRating: _selectedStarRating,
          thumbnailUrl: _thumbnailUploadedUrl,
          lockedFileUrl: lockedUrl,
          adminId: AuthService.currentUser?.uid,
        );
      }

      if (mounted) {
        setState(() => _isCreating = false);
        if (itemId != null) {
          _showSuccessSnackBar('Store item created successfully!');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('Failed to create store item');
        }
      }
    } catch (e) {
      debugPrint('Error creating store item: $e');
      if (mounted) {
        setState(() => _isCreating = false);
        _showErrorSnackBar('Failed to create store item');
      }
    }
  }

  // ─── UI Helpers ───────────────────────────────────────────────────────────

  Widget _buildImagePickerCard({
    required String label,
    required String hint,
    required Uint8List? imageBytes,
    required String? imageName,
    required bool isUploading,
    required VoidCallback onPick,
    bool required = true,
    Color borderColor = Colors.blue,
  }) {
    return GestureDetector(
      onTap: isUploading ? null : onPick,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imageBytes != null ? Colors.green : borderColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Preview area
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                color: Colors.grey[850],
              ),
              child: isUploading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 8),
                          Text('Uploading...', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  : imageBytes != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: imageName?.toLowerCase().endsWith('.svga') == true
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.animation, size: 48, color: borderColor),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'SVGA Animation Selected',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                )
                              : Image.memory(
                                  imageBytes,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: 160,
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 48, color: borderColor),
                            const SizedBox(height: 8),
                            Text(hint,
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                                textAlign: TextAlign.center),
                          ],
                        ),
            ),
            // Label bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    imageBytes != null ? Icons.check_circle : Icons.image_outlined,
                    color: imageBytes != null ? Colors.green : borderColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      imageBytes != null ? (imageName ?? label) : label,
                      style: TextStyle(
                        color: imageBytes != null ? Colors.green : Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!required)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Optional',
                          style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      imageBytes != null ? 'Change' : 'Pick PNG',
                      style: TextStyle(color: borderColor, fontSize: 12, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Add Store Item',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Images are uploaded directly from your gallery to Firebase Storage. No URL needed!',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),

              const SizedBox(height: 24),

              // ── Basic Information ────────────────────────────────────────
              _sectionTitle('Basic Information'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _nameController,
                label: 'Item Name',
                hint: 'Enter item name',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter item description',
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter description' : null,
              ),

              const SizedBox(height: 24),

              // ── Item Configuration ───────────────────────────────────────
              _sectionTitle('Item Configuration'),
              const SizedBox(height: 12),

              // Item Type dropdown
              DropdownButtonFormField<StoreItemType>(
                initialValue: _selectedType,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.grey[900],
                decoration: _inputDecoration('Item Type'),
                items: StoreItemType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(children: [
                      Text(_getTypeIcon(type)),
                      const SizedBox(width: 8),
                      Text(_getTypeDisplayName(type)),
                    ]),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      // Reset images when type changes
                      _normalImageBytes = null;
                      _normalImageName = null;
                      _normalUploadedUrl = null;
                      _lockedImageBytes = null;
                      _lockedImageName = null;
                      _lockedUploadedUrl = null;
                    });
                    _updateFileTypes();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<StoreCategory>(
                initialValue: _selectedCategory,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.grey[900],
                decoration: _inputDecoration('Category'),
                items: StoreCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryDisplayName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),

              const SizedBox(height: 24),

              // ── Image Upload Section ──────────────────────────────────────
              _sectionTitle(_selectedType == StoreItemType.seatDecor
                  ? '🪑 Seat Images'
                  : '🖼️ Item Image'),
              const SizedBox(height: 12),

              // Normal PNG picker
              _buildImagePickerCard(
                label: _selectedType == StoreItemType.seatDecor
                    ? 'Normal Seat PNG'
                    : 'Item Image / PNG',
                hint: _selectedType == StoreItemType.seatDecor
                    ? 'Tap to pick Normal Seat PNG\n(shown when seat is unlocked)'
                    : 'Tap to pick item image from gallery',
                imageBytes: _normalImageBytes,
                imageName: _normalImageName,
                isUploading: _isUploadingNormal,
                onPick: _pickNormalImage,
                borderColor: Colors.blue,
              ),

              // Locked PNG picker (seatDecor only)
              if (_selectedType == StoreItemType.seatDecor) ...[
                const SizedBox(height: 16),
                _buildImagePickerCard(
                  label: 'Locked Seat PNG',
                  hint: 'Tap to pick Locked Seat PNG\n(shown when seat is locked)',
                  imageBytes: _lockedImageBytes,
                  imageName: _lockedImageName,
                  isUploading: _isUploadingLocked,
                  onPick: _pickLockedImage,
                  borderColor: Colors.orange,
                ),
              ],

              // Thumbnail (optional) - visible for all items now
              const SizedBox(height: 16),
              _buildImagePickerCard(
                label: 'Thumbnail Image (Optional)',
                hint: 'Tap to pick a thumbnail for the store list',
                imageBytes: _thumbnailBytes,
                imageName: _thumbnailName,
                isUploading: _isUploadingThumbnail,
                onPick: _pickThumbnail,
                required: false,
                borderColor: Colors.purple,
              ),

              const SizedBox(height: 16),

              // File Name
              _buildTextField(
                controller: _fileNameController,
                label: 'File Name (Display)',
                hint: 'Auto-filled from picked file',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter file name' : null,
              ),

              const SizedBox(height: 16),

              // File Type dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedFileType,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.grey[900],
                decoration: _inputDecoration('File Type'),
                items: StoreService.getSupportedFileTypes(_selectedType).map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedFileType = value);
                },
              ),

              const SizedBox(height: 24),

              // ── Pricing & Duration ─────────────────────────────────────
              _sectionTitle('Pricing & Duration'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _diamondPriceController,
                label: 'Diamond Price',
                hint: 'Enter price in diamonds',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter diamond price';
                  final price = double.tryParse(v);
                  if (price == null || price <= 0) return 'Please enter a valid price';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Star Rating
              DropdownButtonFormField<int>(
                initialValue: _selectedStarRating,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.grey[900],
                decoration: _inputDecoration('Star Rating'),
                items: [1, 2, 3, 4, 5].map((rating) {
                  return DropdownMenuItem<int>(
                    value: rating,
                    child: Text('⭐️ $rating Star${rating > 1 ? 's' : ''}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedStarRating = value);
                },
              ),

              const SizedBox(height: 16),

              // Permanent checkbox
              CheckboxListTile(
                title: const Text('Permanent Item', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Check if this item has no expiration',
                    style: TextStyle(color: Colors.grey)),
                value: _isPermanent,
                onChanged: (value) => setState(() => _isPermanent = value ?? true),
                activeColor: Colors.blue,
                checkColor: Colors.white,
                tileColor: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),

              if (!_isPermanent) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _expirationDurationController,
                  label: 'Expiration Duration (Days)',
                  hint: 'Enter duration in days',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (!_isPermanent) {
                      if (v == null || v.trim().isEmpty) return 'Please enter expiration duration';
                      final d = int.tryParse(v);
                      if (d == null || d <= 0) return 'Please enter a valid duration';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              // ── Create Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createStoreItem,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_isCreating
                      ? 'Uploading & Creating...'
                      : 'Upload & Create Store Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shared input decoration ──────────────────────────────────────────────

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label).copyWith(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      validator: validator,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
