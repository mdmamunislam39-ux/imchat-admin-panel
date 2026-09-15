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
  final TextEditingController _price3DaysController = TextEditingController();
  final TextEditingController _price7DaysController = TextEditingController();
  final TextEditingController _price15DaysController = TextEditingController();
  final TextEditingController _price30DaysController = TextEditingController();

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
    _price3DaysController.dispose();
    _price7DaysController.dispose();
    _price15DaysController.dispose();
    _price30DaysController.dispose();
    super.dispose();
  }

  bool _hasAnyValidityPrice() {
    return _price3DaysController.text.trim().isNotEmpty ||
        _price7DaysController.text.trim().isNotEmpty ||
        _price15DaysController.text.trim().isNotEmpty ||
        _price30DaysController.text.trim().isNotEmpty;
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
      case StoreItemType.shortProfileTheme:
        return '🖼️';
      case StoreItemType.roomEntry:
        return '🚪';
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
        return 'Room Background Theme';
      case StoreItemType.roomTheme:
        return 'Profile Skin';
      case StoreItemType.seatDecor:
        return 'Seat Decor';
      case StoreItemType.micRefill:
        return 'Mic Refill';
      case StoreItemType.roomProfileBackground:
        return 'RP Background';
      case StoreItemType.shortProfileTheme:
        return 'Short Profile Theme';
      case StoreItemType.roomEntry:
        return 'Room Entry';
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
      allowedExtensions: ['png', 'gif', 'jpg', 'jpeg', 'svg', 'svga', 'webp', 'mp4', 'vap'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final ext = file.extension?.toLowerCase() ?? 'png';
      setState(() {
        _normalImageBytes = file.bytes;
        _normalImageName = file.name;
        _normalUploadedUrl = null; // reset

        // Auto-match file type if supported
        final dottedExt = '.$ext';
        final supported = StoreService.getSupportedFileTypes(_selectedType);
        if (supported.contains(dottedExt)) {
          _selectedFileType = dottedExt;
        }
      });
      // Auto-fill file name if empty
      if (_fileNameController.text.isEmpty) {
        _fileNameController.text = file.name.split('.').first;
      }
    }
  }

  Future<void> _pickLockedImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'gif', 'jpg', 'jpeg', 'webp'],
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
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
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
      _showErrorSnackBar('Please select a Preview / Main file first');
      return;
    }
    if (_selectedType == StoreItemType.seatDecor &&
        _lockedImageBytes == null &&
        _lockedUploadedUrl == null) {
      _showErrorSnackBar('Please pick a Locked Seat image first');
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Upload preview / normal image
      if (_normalImageBytes != null && _normalUploadedUrl == null) {
        setState(() => _isUploadingNormal = true);
        _normalUploadedUrl = await _uploadFile(
          _normalImageBytes!,
          _normalImageName!,
          'normal',
        );
        setState(() => _isUploadingNormal = false);
        if (_normalUploadedUrl == null) {
          _showErrorSnackBar('Failed to upload Preview / Main file');
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
            _showErrorSnackBar('Failed to upload Locked Seat image');
            setState(() => _isCreating = false);
            return;
          }
        }
        lockedUrl = _lockedUploadedUrl;
      }

      // Upload thumbnail (optional or provided)
      if (_thumbnailBytes != null && _thumbnailUploadedUrl == null) {
        setState(() => _isUploadingThumbnail = true);
        _thumbnailUploadedUrl = await _uploadFile(
          _thumbnailBytes!,
          _thumbnailName!,
          'thumbnails',
        );
        setState(() => _isUploadingThumbnail = false);
      }

      // Effective Thumbnail URL: if explicit thumbnail was uploaded use it;
      // otherwise, if the main file is an image format, fallback to the main file URL.
      final normalExt = (_normalImageName ?? '').split('.').last.toLowerCase();
      final isImageFormat = ['png', 'jpg', 'jpeg', 'webp', 'gif', 'svg'].contains(normalExt);
      final effectiveThumbnailUrl = _thumbnailUploadedUrl ?? (isImageFormat ? _normalUploadedUrl : null);

      // Collect validity prices map
      final Map<String, dynamic> validityPrices = {};
      final p3 = int.tryParse(_price3DaysController.text.trim());
      if (p3 != null && p3 > 0) validityPrices['3'] = p3;
      final p7 = int.tryParse(_price7DaysController.text.trim());
      if (p7 != null && p7 > 0) validityPrices['7'] = p7;
      final p15 = int.tryParse(_price15DaysController.text.trim());
      if (p15 != null && p15 > 0) validityPrices['15'] = p15;
      final p30 = int.tryParse(_price30DaysController.text.trim());
      if (p30 != null && p30 > 0) validityPrices['30'] = p30;

      // Calculate effective diamond price and expiration duration
      double effectiveDiamondPrice;
      if (_diamondPriceController.text.trim().isNotEmpty) {
        effectiveDiamondPrice = double.tryParse(_diamondPriceController.text.trim()) ?? 0.0;
      } else if (validityPrices.isNotEmpty) {
        effectiveDiamondPrice = (p7 ?? p3 ?? p15 ?? p30 ?? 0).toDouble();
      } else {
        effectiveDiamondPrice = 0.0;
      }

      int effectiveExpirationDuration;
      if (_isPermanent) {
        effectiveExpirationDuration = 0;
      } else if (_expirationDurationController.text.trim().isNotEmpty) {
        effectiveExpirationDuration = int.tryParse(_expirationDurationController.text.trim()) ?? 7;
      } else if (validityPrices.isNotEmpty) {
        if (p7 != null) {
          effectiveExpirationDuration = 7;
        } else if (p3 != null) {
          effectiveExpirationDuration = 3;
        } else if (p15 != null) {
          effectiveExpirationDuration = 15;
        } else {
          effectiveExpirationDuration = 30;
        }
      } else {
        effectiveExpirationDuration = 7;
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
          thumbnailUrl: effectiveThumbnailUrl,
          lockedFileUrl: lockedUrl,
          diamondPrice: effectiveDiamondPrice,
          expirationDuration: effectiveExpirationDuration,
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
          diamondPrice: effectiveDiamondPrice,
          expirationDuration: effectiveExpirationDuration,
          starRating: _selectedStarRating,
          thumbnailUrl: effectiveThumbnailUrl,
          lockedFileUrl: lockedUrl,
          adminId: AuthService.currentUser?.uid,
          validityPrices: validityPrices.isNotEmpty ? validityPrices : null,
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
        _showErrorSnackBar('Failed to create store item: $e');
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
    String? buttonText,
    bool required = true,
    Color borderColor = Colors.blue,
  }) {
    final ext = imageName?.split('.').last.toLowerCase() ?? '';
    final isSvga = ext == 'svga';
    final isVap = ext == 'vap';
    final isVideo = ['mp4', 'webm', 'mov', 'avi'].contains(ext);
    final isNonImage = isSvga || isVap || isVideo;

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
                          child: isNonImage
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: (isSvga
                                                  ? Colors.purple
                                                  : isVap
                                                      ? Colors.amber
                                                      : Colors.cyan)
                                              .withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isSvga
                                              ? Icons.animation
                                              : isVap
                                                  ? Icons.movie_filter
                                                  : Icons.video_collection,
                                          size: 44,
                                          color: isSvga
                                              ? Colors.purpleAccent
                                              : isVap
                                                  ? Colors.amberAccent
                                                  : Colors.cyanAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isSvga
                                            ? '✨ SVGA Animation Ready'
                                            : isVap
                                                ? '🎬 VAP Animation Ready'
                                                : '📹 Video File Ready',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(imageBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB • .$ext',
                                        style: const TextStyle(
                                            color: Colors.white60, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                              : Image.memory(
                                  imageBytes,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: 160,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.insert_drive_file,
                                              size: 40, color: borderColor),
                                          const SizedBox(height: 6),
                                          Text(imageName ?? 'File Selected',
                                              style: const TextStyle(
                                                  color: Colors.white70)),
                                        ],
                                      ),
                                    );
                                  },
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
                      buttonText ?? (imageBytes != null ? 'Change' : 'Pick File'),
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

              // ── Media Files (Preview & Thumbnail) Section ─────────────────
              _sectionTitle('📁 Item Media (Preview & Thumbnail)'),
              const SizedBox(height: 4),
              const Text(
                'Upload both the Preview / Animation file and the Thumbnail image for store & bag displays.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 12),

              // 1. Preview / Animation / Main File
              _buildImagePickerCard(
                label: _selectedType == StoreItemType.seatDecor
                    ? 'Preview / Unlocked Seat (.svga, .vap, .mp4, .gif, .png, .webp)'
                    : 'Preview / Animation File (.svga, .vap, .mp4, .gif, .png, .webp)',
                hint: 'Tap to pick Preview / Main animation or image file\n(SVGA, VAP, MP4, GIF, PNG, WEBP)',
                imageBytes: _normalImageBytes,
                imageName: _normalImageName,
                isUploading: _isUploadingNormal,
                onPick: _pickNormalImage,
                buttonText: _normalImageBytes != null ? 'Change Preview' : 'Pick Preview File',
                borderColor: Colors.blueAccent,
                required: true,
              ),

              // 2. Thumbnail Image (Optional / Recommended for store grid)
              if (_selectedType != StoreItemType.badge) ...[
                const SizedBox(height: 16),
                _buildImagePickerCard(
                  label: 'Thumbnail Image (.png, .jpg, .webp, .gif)',
                  hint: 'Tap to pick a static Thumbnail image\n(Used for Store list, Bag & User Profile preview)',
                  imageBytes: _thumbnailBytes,
                  imageName: _thumbnailName,
                  isUploading: _isUploadingThumbnail,
                  onPick: _pickThumbnail,
                  buttonText: _thumbnailBytes != null ? 'Change Thumbnail' : 'Pick Thumbnail',
                  required: false,
                  borderColor: Colors.purpleAccent,
                ),
              ],

              // 3. Locked PNG picker (seatDecor only)
              if (_selectedType == StoreItemType.seatDecor) ...[
                const SizedBox(height: 16),
                _buildImagePickerCard(
                  label: 'Locked Seat Image (.png, .webp)',
                  hint: 'Tap to pick Locked Seat image\n(Shown when seat is locked)',
                  imageBytes: _lockedImageBytes,
                  imageName: _lockedImageName,
                  isUploading: _isUploadingLocked,
                  onPick: _pickLockedImage,
                  buttonText: _lockedImageBytes != null ? 'Change Locked Image' : 'Pick Locked Image',
                  borderColor: Colors.orangeAccent,
                ),
              ],

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
                label: 'Default Diamond Price',
                hint: 'Enter default price in diamonds (Optional if validity prices entered)',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final hasValidity = _hasAnyValidityPrice();
                  if (!hasValidity) {
                    if (v == null || v.trim().isEmpty) return 'Please enter diamond price or validity prices';
                    final price = double.tryParse(v);
                    if (price == null || price <= 0) return 'Please enter a valid price';
                  } else if (v != null && v.trim().isNotEmpty) {
                    final price = double.tryParse(v);
                    if (price == null || price <= 0) return 'Please enter a valid price';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              const Text(
                'Validity Prices (Optional - separate prices for 3, 7, 15, 30 days):',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _price3DaysController,
                      label: '3 Days Price',
                      hint: 'e.g. 500',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _price7DaysController,
                      label: '7 Days Price',
                      hint: 'e.g. 1000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _price15DaysController,
                      label: '15 Days Price',
                      hint: 'e.g. 2000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _price30DaysController,
                      label: '30 Days Price',
                      hint: 'e.g. 3500',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
                      final hasValidity = _hasAnyValidityPrice();
                      if (!hasValidity) {
                        if (v == null || v.trim().isEmpty) return 'Please enter expiration duration or validity prices';
                        final d = int.tryParse(v);
                        if (d == null || d <= 0) return 'Please enter a valid duration';
                      } else if (v != null && v.trim().isNotEmpty) {
                        final d = int.tryParse(v);
                        if (d == null || d <= 0) return 'Please enter a valid duration';
                      }
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
