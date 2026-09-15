import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/official_item_model.dart';
import '../models/store_item_model.dart';
import '../services/official_items_service.dart';
import '../services/auth_service.dart';
import '../widgets/media_preview_widget.dart';

class OfficialItemsScreen extends StatefulWidget {
  const OfficialItemsScreen({super.key});

  @override
  State<OfficialItemsScreen> createState() => _OfficialItemsScreenState();
}

class _OfficialItemsScreenState extends State<OfficialItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _statistics = {};
  Map<OfficialItemCategory, List<OfficialItemModel>> _itemsByCategory = {};

  static const _categories = OfficialItemCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Ensure all items have a displayId assigned
      await OfficialItemsService.ensureAllItemsHaveIds();

      final results = await Future.wait([
        OfficialItemsService.getStatistics(),
        OfficialItemsService.getAllOfficialItems(),
      ]);

      if (!mounted) return;

      final allItems = results[1] as List<OfficialItemModel>;
      final grouped = <OfficialItemCategory, List<OfficialItemModel>>{};
      for (final cat in _categories) {
        grouped[cat] = allItems.where((i) => i.category == cat).toList();
      }

      setState(() {
        _statistics = results[0] as Map<String, dynamic>;
        _itemsByCategory = grouped;
      });
    } catch (e) {
      debugPrint('Error loading official items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Official Items',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Item',
            onPressed: _openAddFlow,
          ),
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: 'Assign Item to User',
            onPressed: () => _openAssignFlow(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: _categories.map((cat) {
            final count = _itemsByCategory[cat]?.length ?? 0;
            return Tab(text: '${cat.icon} ${cat.displayName} ($count)');
          }).toList(),
        ),
      ),
      body: StreamBuilder<List<OfficialItemModel>>(
        stream: OfficialItemsService.streamAllOfficialItems(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final allItems = snapshot.data!;
            for (final cat in _categories) {
              _itemsByCategory[cat] = allItems.where((i) => i.category == cat).toList();
            }
          }

          return Column(
            children: [
              _buildStatBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _categories
                      .map((cat) => _buildCategoryTab(cat))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Stats Bar ───

  Widget _buildStatBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.purple[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat(
              'Total Items', '${_statistics['totalItems'] ?? 0}', Icons.inventory),
          _buildMiniStat('Assigned',
              '${_statistics['totalAssignments'] ?? 0}', Icons.assignment),
          _buildMiniStat('Active',
              '${_statistics['activeAssignments'] ?? 0}', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // ─── Category Tab ───

  Widget _buildCategoryTab(OfficialItemCategory category) {
    final items = _itemsByCategory[category] ?? [];

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No ${category.displayName} items yet',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  Widget _buildItemCard(OfficialItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isActive ? item.category.color : Colors.grey,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon / Thumbnail
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: item.category.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                  ? MediaPreviewWidget(
                      url: item.thumbnailUrl!,
                      width: 50,
                      height: 50,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : Center(
                      child: Text(item.category.icon,
                          style: const TextStyle(fontSize: 24)),
                    ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.displayId != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: item.displayId.toString()),
                            );
                            _showSnackBar(
                              'Copied ID ${item.displayId} to clipboard',
                              Colors.green,
                            );
                          },
                          child: Tooltip(
                            message: 'Tap to copy ID',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ID: ${item.displayId}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.copy,
                                    color: Colors.blue,
                                    size: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 11),
                            const SizedBox(width: 3),
                            Text(
                              '${item.starRating} Star${item.starRating > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.category == OfficialItemCategory.badge) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.verificationLevel > 0
                                ? Colors.blueAccent.withValues(alpha: 0.2)
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: item.verificationLevel > 0
                                    ? Colors.blueAccent
                                    : Colors.grey[700]!,
                                width: 0.5),
                          ),
                          child: Text(
                            item.verificationLevel > 0
                                ? 'Ver. Lv.${item.verificationLevel}'
                                : 'Not Verified',
                            style: TextStyle(
                              color: item.verificationLevel > 0
                                  ? Colors.blueAccent
                                  : Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.purple, width: 0.5),
                          ),
                          child: Text(
                            item.badgeSubCategory,
                            style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.fileType,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit Item',
                  onPressed: () => _openEditFlow(item),
                ),
                // Assign button
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.blue),
                  tooltip: 'Assign to User',
                  onPressed: item.isActive
                      ? () => _openAssignFlow(preselectedItem: item)
                      : null,
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Item',
                  onPressed: () => _confirmAndDeleteItem(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Assign Flow ───

  void _openAssignFlow({OfficialItemModel? preselectedItem}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _AssignOfficialItemPage(preselectedItem: preselectedItem),
      ),
    ).then((_) => _loadData());
  }

  void _openAddFlow() {
    final currentCategory = _categories[_tabController.index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddEditOfficialItemPage(preselectedCategory: currentCategory),
      ),
    ).then((_) => _loadData());
  }

  void _openEditFlow(OfficialItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddEditOfficialItemPage(
          preselectedCategory: item.category,
          itemToEdit: item,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _confirmAndDeleteItem(OfficialItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Official Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}"${item.displayId != null ? ' (ID: ${item.displayId})' : ''}?\n\nThis action cannot be undone and will permanently remove the item from both Official Items and Store Market.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await OfficialItemsService.deleteOfficialItem(item.id);
              if (!mounted) return;
              if (success) {
                _showSnackBar('Official item deleted successfully', Colors.orange);
                _loadData();
              } else {
                _showSnackBar('Failed to delete item', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add/Edit Official Item — full-page form with file upload
// ─────────────────────────────────────────────

class _AddEditOfficialItemPage extends StatefulWidget {
  final OfficialItemCategory preselectedCategory;
  final OfficialItemModel? itemToEdit;

  const _AddEditOfficialItemPage({
    required this.preselectedCategory,
    this.itemToEdit,
  });

  @override
  State<_AddEditOfficialItemPage> createState() => _AddEditOfficialItemPageState();
}

class _AddEditOfficialItemPageState extends State<_AddEditOfficialItemPage> {
  final _storage = FirebaseStorage.instance;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  late OfficialItemCategory _selectedCategory;

  // Main file (SVGA only)
  Uint8List? _fileBytes;
  String? _fileName;

  // Thumbnail (PNG/JPEG) — optional
  Uint8List? _thumbnailBytes;
  String? _thumbnailName;
  
  int _selectedStarRating = 5;
  int _selectedVerificationLevel = 0;
  String _selectedBadgeSubCategory = 'Verification';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.preselectedCategory;
    if (widget.itemToEdit != null) {
      _nameController.text = widget.itemToEdit!.name;
      _descController.text = widget.itemToEdit!.description;
      _selectedStarRating = widget.itemToEdit!.starRating;
      _selectedVerificationLevel = widget.itemToEdit!.verificationLevel;
      _selectedBadgeSubCategory = widget.itemToEdit!.badgeSubCategory;
      _selectedCategory = widget.itemToEdit!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _confirmAndDeleteItem() {
    if (widget.itemToEdit == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Official Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.itemToEdit!.name}"?\n\nThis action cannot be undone and will permanently remove the item from both Official Items and Store Market.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isSaving = true);
              final success = await OfficialItemsService.deleteOfficialItem(widget.itemToEdit!.id);
              if (!mounted) return;
              if (success) {
                _showSnackBar('Item deleted successfully', Colors.orange);
                Navigator.pop(context, true);
              } else {
                setState(() => _isSaving = false);
                _showSnackBar('Failed to delete item', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svga', 'png', 'jpg', 'jpeg', 'gif', 'mp4', 'vap', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final ext = file.extension?.toLowerCase();
        if (!['svga', 'png', 'jpg', 'jpeg', 'gif', 'mp4', 'vap', 'webp'].contains(ext)) {
          _showSnackBar('Invalid file format', Colors.red);
          return;
        }
        setState(() {
          _fileBytes = file.bytes;
          _fileName = file.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _thumbnailBytes = result.files.first.bytes;
          _thumbnailName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking thumbnail: $e');
    }
  }

  Future<String?> _uploadToStorage(Uint8List bytes, String name) async {
    try {
      final storageName =
          'official_items/${DateTime.now().millisecondsSinceEpoch}_$name';
      final ref = _storage.ref().child(storageName);
      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Item name is required', Colors.red);
      return;
    }
    
    // For new items, file is required. For edits, it's optional.
    if (widget.itemToEdit == null && (_fileBytes == null || _fileName == null)) {
      _showSnackBar('Please select a file (SVGA/PNG/GIF)', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    String? fileUrl = widget.itemToEdit?.fileUrl;
    String? fileName = widget.itemToEdit?.fileName;
    String? fileType = widget.itemToEdit?.fileType;

    // Upload main file if changed
    if (_fileBytes != null && _fileName != null) {
      final uploadedUrl = await _uploadToStorage(_fileBytes!, _fileName!);
      if (uploadedUrl == null) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        _showSnackBar('Failed to upload file', Colors.red);
        return;
      }
      fileUrl = uploadedUrl;
      fileName = _fileName!;
      final extension = fileName.split('.').last.toLowerCase();
      fileType = '.$extension';
    }

    // Upload thumbnail if selected (not needed for Badges)
    String? thumbnailUrl = widget.itemToEdit?.thumbnailUrl;
    if (_selectedCategory == OfficialItemCategory.badge) {
      thumbnailUrl = fileUrl;
    } else if (_thumbnailBytes != null && _thumbnailName != null) {
      final uploadedThumb = await _uploadToStorage(_thumbnailBytes!, _thumbnailName!);
      if (uploadedThumb != null) thumbnailUrl = uploadedThumb;
    }
    thumbnailUrl ??= fileUrl;

    if (fileUrl == null || fileName == null || fileType == null) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        _showSnackBar('File information is missing.', Colors.red);
        return;
    }

    bool success = false;
    
    if (widget.itemToEdit != null) {
      success = await OfficialItemsService.updateOfficialItem(
        itemId: widget.itemToEdit!.id,
        name: name,
        description: desc,
        category: _selectedCategory,
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
        thumbnailUrl: thumbnailUrl,
        starRating: _selectedStarRating,
        verificationLevel: _selectedVerificationLevel,
        badgeSubCategory: _selectedBadgeSubCategory,
      );
    } else {
      final id = await OfficialItemsService.createOfficialItem(
        name: name,
        description: desc,
        category: _selectedCategory,
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
        thumbnailUrl: thumbnailUrl,
        starRating: _selectedStarRating,
        verificationLevel: _selectedVerificationLevel,
        badgeSubCategory: _selectedBadgeSubCategory,
      );
      success = id != null;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _showSnackBar(widget.itemToEdit != null ? 'Item updated!' : 'Item created!', Colors.green);
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Failed to save item', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.itemToEdit != null ? 'Edit Official Item' : 'Add Official Item',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (widget.itemToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Item',
              onPressed: _confirmAndDeleteItem,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.itemToEdit != null ? 'Edit Official Item' : 'Create Official Item',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                      'Pick a file from your device. It will be uploaded to Firebase Storage.',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Category
            const Text('Category',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<OfficialItemCategory>(
              initialValue: _selectedCategory,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecor('Select category'),
              items: OfficialItemCategory.values
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text('${cat.icon} ${cat.displayName}'),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // Item Name
            const Text('Item Name',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecor('Enter item name'),
            ),

            const SizedBox(height: 20),

            // Description
            const Text('Description',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecor('Enter description'),
            ),

            const SizedBox(height: 20),

            // Star Rating (Top to bottom sorting: Higher stars stay at top)
            const Text('Star Rating (1 - 5 Stars ⭐)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Top-to-bottom sorting: 5-Star items stay at the very top of Badge Wall',
              style: TextStyle(color: Colors.amber, fontSize: 11),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedStarRating,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecor('Select star rating'),
              items: [5, 4, 3, 2, 1]
                  .map((rating) => DropdownMenuItem(
                        value: rating,
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 8),
                            Text('$rating Star${rating > 1 ? 's' : ''} ${rating == 5 ? '(Top Priority)' : ''}'),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedStarRating = val;
                  });
                }
              },
            ),

            if (_selectedCategory == OfficialItemCategory.badge) ...[
              const SizedBox(height: 20),

              // Verification Level (None or 1 - 5)
              const Text('Verification Level (None or 1 - 5 ⭐)',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedVerificationLevel,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecor('Select verification level'),
                items: [0, 1, 2, 3, 4, 5]
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Row(
                            children: [
                              Icon(
                                level == 0
                                    ? Icons.remove_circle_outline
                                    : Icons.verified,
                                color: level == 0 ? Colors.grey : Colors.blueAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                level == 0
                                    ? 'None (Not Verified / সাধারণ ব্যাজ)'
                                    : 'Verification Level $level',
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedVerificationLevel = val;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // Badge Section / Sub-Category (Matching Honor Badge Wall)
              const Text('Badge Category / Section',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Section on Honor Badge Wall (e.g. Verification, Achievement, Honor)',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedBadgeSubCategory,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecor('Select badge section'),
                items: const [
                  DropdownMenuItem(
                    value: 'Verification',
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.blueAccent, size: 16),
                        SizedBox(width: 8),
                        Text('Verification (ভেরিফিকেশন)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Achievement',
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Text('Achievement (অ্যাচিভমেন্ট)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Honor',
                    child: Row(
                      children: [
                        Icon(Icons.military_tech, color: Colors.purpleAccent, size: 16),
                        SizedBox(width: 8),
                        Text('Honor / VIP (অনার)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Activity',
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                        SizedBox(width: 8),
                        Text('Activity (অ্যাক্টিভিটি)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Special',
                    child: Row(
                      children: [
                        Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 16),
                        SizedBox(width: 8),
                        Text('Special (স্পেশাল)'),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedBadgeSubCategory = val;
                    });
                  }
                },
              ),
            ],

            const SizedBox(height: 20),

            // Main Preview / Animation File picker
            const Text('Preview / Animation File (SVGA, VAP, MP4, PNG, GIF)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Supported formats: .svga, .png, .jpg, .gif, .mp4, .vap, .webp',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildFilePickerCard(
              fileName: _fileName,
              imageBytes: _fileBytes,
              onPick: _pickFile,
              label: 'Select Preview / Animation File',
              icon: Icons.movie_filter,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            // Thumbnail picker (optional - NOT required for Badges)
            if (_selectedCategory != OfficialItemCategory.badge) ...[
              const SizedBox(height: 20),
              const Text('Thumbnail Image (PNG / JPEG / WebP)',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Static preview image displayed in lists, bag, and item walls',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              _buildFilePickerCard(
                fileName: _thumbnailName,
                imageBytes: _thumbnailBytes,
                onPick: _pickThumbnail,
                label: 'Select Thumbnail Image',
                icon: Icons.image,
                color: Colors.purple,
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveItem,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isSaving
                    ? 'Saving...'
                    : (widget.itemToEdit != null ? 'Update Item' : 'Upload & Create Item')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerCard({
    required String? fileName,
    Uint8List? imageBytes,
    required VoidCallback onPick,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final ext = fileName?.split('.').last.toLowerCase() ?? '';
    final isImage = ['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext);

    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fileName != null ? Colors.green : Colors.grey[700]!,
            width: fileName != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (imageBytes != null && isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  imageBytes,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: fileName != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isImage ? 'Image Selected' : 'Animation/Media Selected',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 12),
                        ),
                        Text(
                          fileName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : Text(label,
                      style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            Icon(
              fileName != null ? Icons.check_circle : Icons.add_circle_outline,
              color: fileName != null ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.grey[800],
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Assign Official Item — full-page flow
// ─────────────────────────────────────────────

class _AssignOfficialItemPage extends StatefulWidget {
  final OfficialItemModel? preselectedItem;

  const _AssignOfficialItemPage({this.preselectedItem});

  @override
  State<_AssignOfficialItemPage> createState() =>
      _AssignOfficialItemPageState();
}

class _AssignOfficialItemPageState extends State<_AssignOfficialItemPage> {
  final TextEditingController _profileIdController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  Map<String, dynamic>? _foundUser;
  List<OfficialItemModel> _allItems = [];
  List<UserStoreItemModel> _userAssignments = [];
  OfficialItemModel? _selectedItem;
  bool _isSearching = false;
  bool _isAssigning = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.preselectedItem;
    _durationController.text = '30';
    _loadItems();
  }

  @override
  void dispose() {
    _profileIdController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await OfficialItemsService.getAllOfficialItems();
    if (!mounted) return;
    setState(() {
      _allItems = items.where((i) => i.isActive).toList();
      _isLoading = false;
    });
  }

  Future<void> _searchUser() async {
    final profileId = _profileIdController.text.trim();
    if (profileId.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
      _userAssignments = [];
    });

    final user = await OfficialItemsService.searchUserByProfileId(profileId);

    if (!mounted) return;
    setState(() => _isSearching = false);

    if (user != null) {
      setState(() => _foundUser = user);
      _loadUserAssignments(user['id']);
    } else {
      _showSnackBar('User not found', Colors.red);
    }
  }

  Future<void> _loadUserAssignments(String userId) async {
    final assignments = await OfficialItemsService.getUserAssignments(userId);
    if (!mounted) return;
    setState(() => _userAssignments = assignments);
  }

  Future<void> _assignItem() async {
    if (_foundUser == null || _selectedItem == null) return;

    final days = int.tryParse(_durationController.text.trim());
    if (days == null || days <= 0) {
      _showSnackBar('Enter a valid number of days', Colors.red);
      return;
    }

    setState(() => _isAssigning = true);

    final success = await OfficialItemsService.assignItemToUser(
      officialItemId: _selectedItem!.id,
      itemName: _selectedItem!.name,
      itemCategory: _selectedItem!.category,
      userId: _foundUser!['id'],
      userProfileId: _foundUser!['profileId'],
      username: _foundUser!['name'],
      durationDays: days,
      adminId: AuthService.currentUser?.uid ?? 'admin',
    );

    if (!mounted) return;
    setState(() => _isAssigning = false);

    if (success) {
      _showSnackBar(
          '"${_selectedItem!.name}" assigned to ${_foundUser!['name']} for $days days',
          Colors.green);
      _loadUserAssignments(_foundUser!['id']);
    } else {
      _showSnackBar('Failed to assign item', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Assign Official Item',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Step 1: Search User ──
                  _buildSectionTitle('Step 1: Search User'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _profileIdController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter User Profile ID',
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _searchUser(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.search),
                      ),
                    ],
                  ),

                  // Found user card
                  if (_foundUser != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[800],
                            child: const Icon(Icons.person,
                                size: 24, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _foundUser!['name'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Profile ID: ${_foundUser!['profileId']}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 28),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Step 2: Select Item ──
                  _buildSectionTitle('Step 2: Select Item'),
                  const SizedBox(height: 8),
                  _buildItemSelector(),

                  const SizedBox(height: 24),

                  // ── Step 3: Choose Duration ──
                  _buildSectionTitle('Step 3: Choose Duration (Days)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...[7, 15, 30, 60, 90].map((d) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('$d',
                                  style:
                                      const TextStyle(color: Colors.white)),
                              selected:
                                  _durationController.text == d.toString(),
                              selectedColor: Colors.blue,
                              backgroundColor: Colors.grey[800],
                              onSelected: (_) {
                                setState(() {
                                  _durationController.text = d.toString();
                                });
                              },
                            ),
                          )),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _durationController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Custom',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Assign Button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_foundUser != null &&
                              _selectedItem != null &&
                              !_isAssigning)
                          ? _assignItem
                          : null,
                      icon: _isAssigning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isAssigning
                            ? 'Assigning...'
                            : _foundUser == null
                                ? 'Search a user first'
                                : _selectedItem == null
                                    ? 'Select an item first'
                                    : 'Assign "${_selectedItem!.name}" to ${_foundUser!['name']}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_foundUser != null && _selectedItem != null)
                                ? Colors.green
                                : Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // ── User's Current Assignments ──
                  if (_foundUser != null) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle(
                        'Current Assignments for ${_foundUser!['name']}'),
                    const SizedBox(height: 8),
                    if (_userAssignments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No items assigned yet',
                            style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ..._userAssignments
                          .map((a) => _buildAssignmentCard(a)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildItemSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedItem != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedItem!.category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _selectedItem!.category.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(_selectedItem!.category.icon,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedItem!.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedItem!.category.displayName,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () =>
                        setState(() => _selectedItem = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showItemPicker,
              icon: const Icon(Icons.list),
              label: Text(_selectedItem == null
                  ? 'Select an Item'
                  : 'Change Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Select Item',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 450,
          height: 400,
          child: _allItems.isEmpty
              ? const Center(
                  child: Text('No active items available',
                      style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  itemCount: _allItems.length,
                  itemBuilder: (_, index) {
                    final item = _allItems[index];
                    final isSelected = _selectedItem?.id == item.id;
                    return ListTile(
                      leading: Text(item.category.icon,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(item.name,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        item.category.displayName,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: Colors.green)
                          : null,
                      tileColor: isSelected
                          ? Colors.blue.withValues(alpha: 0.1)
                          : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      onTap: () {
                        setState(() => _selectedItem = item);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(UserStoreItemModel assignment) {
    final isExpired = assignment.isExpired;
    final statusText = assignment.statusText;
    final statusColor = isExpired
        ? Colors.red
        : !assignment.isActive
            ? Colors.grey
            : Colors.green;

    String remainingText = '';
    if (assignment.expiresAt != null) {
      if (isExpired) {
        remainingText = 'Expired';
      } else {
        final remaining = assignment.expiresAt!.difference(DateTime.now());
        if (remaining.inDays > 0) {
          remainingText = '${remaining.inDays} days left';
        } else if (remaining.inHours > 0) {
          remainingText = '${remaining.inHours} hours left';
        } else {
          remainingText = '${remaining.inMinutes} min left';
        }
      }
    } else {
      remainingText = 'Permanent';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(_storeTypeIcon(assignment.itemType),
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.storeItemName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  remainingText,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () async {
              final success = await OfficialItemsService.removeAssignment(
                  assignment.id);
              if (!mounted) return;
              if (success) {
                _showSnackBar('Assignment removed', Colors.orange);
                _loadUserAssignments(_foundUser!['id']);
              }
            },
          ),
        ],
      ),
    );
  }

  String _storeTypeIcon(StoreItemType type) {
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
        return '🎤';
      case StoreItemType.roomProfileBackground:
        return '🖼️';
      case StoreItemType.shortProfileTheme:
        return '🖼️';
      case StoreItemType.roomEntry:
        return '🚪';
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Edit Official Item — allows updating details
// ─────────────────────────────────────────────

class _EditOfficialItemPage extends StatefulWidget {
  final OfficialItemModel item;

  const _EditOfficialItemPage({required this.item});

  @override
  State<_EditOfficialItemPage> createState() => _EditOfficialItemPageState();
}

class _EditOfficialItemPageState extends State<_EditOfficialItemPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late int _selectedStarRating;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descController = TextEditingController(text: widget.item.description);
    try {
      _selectedStarRating = widget.item.starRating;
      if (![1, 2, 3, 4, 5].contains(_selectedStarRating)) {
        _selectedStarRating = 1;
      }
    } catch (e) {
      // Handles Hot Reload artifacts where new non-nullable fields are null in memory
      _selectedStarRating = 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Item name is required', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    final success = await OfficialItemsService.updateOfficialItem(
      itemId: widget.item.id,
      name: name,
      description: desc,
      starRating: _selectedStarRating,
      category: widget.item.category,
      fileUrl: widget.item.fileUrl,
      fileName: widget.item.fileName,
      fileType: widget.item.fileType,
      thumbnailUrl: widget.item.thumbnailUrl,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _showSnackBar('Item updated successfully!', Colors.green);
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Failed to update item', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Edit Official Item',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit ${widget.item.category.displayName}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                      'Update the details for this official item.',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Item Name
            const Text('Item Name',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecor('Enter item name'),
            ),

            const SizedBox(height: 20),

            // Description
            const Text('Description',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecor('Enter description'),
            ),

            const SizedBox(height: 20),

            // Star Rating
            const Text('Star Rating',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedStarRating,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecor('Select star rating'),
              items: [1, 2, 3, 4, 5]
                  .map((rating) => DropdownMenuItem(
                        value: rating,
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 8),
                            Text('$rating Star${rating > 1 ? 's' : ''}'),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedStarRating = val;
                  });
                }
              },
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving
                    ? 'Saving Changes...'
                    : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

