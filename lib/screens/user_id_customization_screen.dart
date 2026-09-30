import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/custom_user_id_model.dart';
import '../models/custom_user_id_history_model.dart';
import '../models/id_badge_model.dart';
import '../services/user_customization_service.dart';
import '../services/id_badge_service.dart';
import '../widgets/media_preview_widget.dart';
import '../widgets/user_id_badge_widget.dart';

class UserIdCustomizationScreen extends StatefulWidget {
  const UserIdCustomizationScreen({super.key});

  @override
  State<UserIdCustomizationScreen> createState() => _UserIdCustomizationScreenState();
}

class _UserIdCustomizationScreenState extends State<UserIdCustomizationScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _customIdController = TextEditingController();
  final _durationController = TextEditingController();
  late TabController _tabController;

  Map<String, dynamic>? _selectedUser;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _customIdController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _searchController.clear();
      _customIdController.clear();
      _durationController.text = '30'; // Default 30 days
      _selectedUser = null;
    });
  }

  Future<Map<String, dynamic>?> _searchUser() async {
    final searchId = _searchController.text.trim();
    if (searchId.isEmpty) return null;

    setState(() => _isSearching = true);

    try {
      final user = await UserCustomizationService.searchUserByOriginalId(searchId);
      setState(() {
        _selectedUser = user;
        _isSearching = false;
      });

      if (user == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found! Check Search ID, User ID, phone, or name.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return user;
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e'), backgroundColor: Colors.redAccent),
        );
      }
      return null;
    }
  }

  Future<void> _assignCustomId() async {
    if (!_formKey.currentState!.validate() || _selectedUser == null) return;

    try {
      final days = int.tryParse(_durationController.text) ?? 30;
      final customIdModel = CustomUserIdModel(
        id: _selectedUser!['id'],
        userId: _selectedUser!['id'],
        originalUserId: _selectedUser!['originalSearchId'] ?? _selectedUser!['searchId'] ?? _selectedUser!['id'],
        customUserId: _customIdController.text.trim(),
        userName: _selectedUser!['name'] ?? 'User',
        userImageUrl: _selectedUser!['imageUrl'] ?? '',
        assignedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: days)),
      );

      await UserCustomizationService.assignCustomUserId(customIdModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom User ID assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildAnimatedCustomIdBadge(String customId, {double fontSize = 14, bool showIcon = true}) {
    final length = customId.length;
    Color primaryColor;
    Color secondaryColor;
    Color textColor = Colors.white;
    String label;
    IconData icon;
    List<BoxShadow> shadows = [];

    if (length == 1) {
      primaryColor = const Color(0xFF1A1A1A);
      secondaryColor = const Color(0xFFFFD700);
      textColor = const Color(0xFFFFD700);
      label = '👑 1-Digit Ultra VIP';
      icon = Icons.workspace_premium;
      shadows = [
        BoxShadow(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
          blurRadius: 8,
          spreadRadius: 1,
        )
      ];
    } else if (length == 2) {
      primaryColor = const Color(0xFFB8860B);
      secondaryColor = const Color(0xFFFFE066);
      textColor = Colors.white;
      label = '⭐ 2-Digit Golden';
      icon = Icons.stars;
      shadows = [
        BoxShadow(
          color: const Color(0xFFFFB703).withValues(alpha: 0.35),
          blurRadius: 6,
          spreadRadius: 1,
        )
      ];
    } else if (length >= 3 && length <= 4) {
      primaryColor = const Color(0xFF6A0DAD);
      secondaryColor = const Color(0xFFB5179E);
      textColor = Colors.white;
      label = '💎 3-4 Digit Royal';
      icon = Icons.diamond;
      shadows = [
        BoxShadow(
          color: const Color(0xFF9D4EDD).withValues(alpha: 0.35),
          blurRadius: 6,
          spreadRadius: 1,
        )
      ];
    } else if (length >= 5 && length <= 6) {
      primaryColor = const Color(0xFF0077B6);
      secondaryColor = const Color(0xFF00B4D8);
      textColor = Colors.white;
      label = '⚡ 5-6 Digit Aqua Neon';
      icon = Icons.bolt;
      shadows = [
        BoxShadow(
          color: const Color(0xFF48CAE4).withValues(alpha: 0.35),
          blurRadius: 6,
          spreadRadius: 1,
        )
      ];
    } else {
      primaryColor = Colors.grey[800]!;
      secondaryColor = Colors.grey[700]!;
      label = 'Default ID';
      icon = Icons.tag;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: shadows,
        border: Border.all(
          color: length == 1
              ? const Color(0xFFFFD700)
              : (length == 2 ? Colors.amberAccent : Colors.white24),
          width: length <= 2 ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, color: textColor, size: fontSize + 1),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize - 2,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    if (_durationController.text.isEmpty) {
      _durationController.text = '30';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.badge, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('Assign Custom User ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Original ID / Search ID / Phone / Name',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                            ),
                            onSubmitted: (_) async {
                              setStateDialog(() => _isSearching = true);
                              final found = await _searchUser();
                              setStateDialog(() {
                                _isSearching = false;
                                _selectedUser = found;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isSearching
                              ? null
                              : () async {
                                  setStateDialog(() => _isSearching = true);
                                  final found = await _searchUser();
                                  setStateDialog(() {
                                    _isSearching = false;
                                    _selectedUser = found;
                                  });
                                },
                          icon: _isSearching
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.search, size: 18, color: Colors.white),
                          label: const Text('Search', style: TextStyle(color: Colors.white, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),

                    if (_selectedUser != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            _selectedUser!['imageUrl'].isNotEmpty
                                ? MediaPreviewWidget(
                                    url: _selectedUser!['imageUrl'],
                                    width: 44,
                                    height: 44,
                                    borderRadius: BorderRadius.circular(22),
                                  )
                                : const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.blueAccent,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedUser!['name'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Original ID: ${_selectedUser!['originalSearchId'] ?? _selectedUser!['searchId']}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                  ),
                                  if ((_selectedUser!['phone'] ?? '').isNotEmpty)
                                    Text(
                                      'Phone: ${_selectedUser!['phone']}',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customIdController,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Desired Custom ID (e.g. 8, 99, 777, 8888, 123456)',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.stars, color: Colors.amber),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                        ),
                        onChanged: (val) {
                          setStateDialog(() {});
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a Custom ID';
                          }
                          final len = value.trim().length;
                          if (len < 1 || len > 10) {
                            return 'Custom ID must be between 1 and 10 characters';
                          }
                          return null;
                        },
                      ),
                      if (_customIdController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Badge Preview: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            UserIdBadgeWidget(
                              searchId: _customIdController.text.trim(),
                              badgeHeight: 20,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _durationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Duration (Days)',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.isEmpty) ? 'Please enter duration in days' : null,
                      ),
                    ],
                  ],
                ),
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
                onPressed: _selectedUser != null ? _assignCustomId : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Assign ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      _resetForm();
    });
  }

  void _showEditDialog(BuildContext context, CustomUserIdModel assignment) {
    final editNameController = TextEditingController(text: assignment.userName);
    final editIdController = TextEditingController(text: assignment.customUserId);
    DateTime selectedDate = assignment.expiresAt;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.edit, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('Edit Custom User ID & Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: editNameController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'User Display Name',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter user name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: editIdController,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Custom User ID',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.stars, color: Colors.amber),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    ),
                    onChanged: (val) => setStateDialog(() {}),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a Custom ID' : null,
                  ),
                  if (editIdController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Preview: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        _buildAnimatedCustomIdBadge(editIdController.text.trim()),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Expires:',
                        style: TextStyle(color: Colors.grey[400], fontSize: 15),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDate.toLocal().toString().split(' ')[0],
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month, color: Colors.blueAccent),
                        onPressed: () async {
                          final newDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (newDate != null) {
                            setStateDialog(() {
                              selectedDate = DateTime(newDate.year, newDate.month, newDate.day, 23, 59, 59);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await UserCustomizationService.updateCustomUserId(
                        assignment.id,
                        selectedDate,
                        assignment.isActive,
                        newCustomId: editIdController.text.trim(),
                        newName: editNameController.text.trim(),
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Custom User ID & Name updated successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Edit or Add a Digit ID Badge Modal (Supports PNG, WebP, GIF, SVGA)
  void _showEditBadgeDialog(BuildContext context, {IdBadgeModel? badge, int? defaultDigit}) {
    final int digit = badge?.digitLength ?? defaultDigit ?? 1;
    final nameController = TextEditingController(text: badge?.name ?? (digit == 0 ? 'Default ID Badge' : '$digit-Digit ID Badge'));
    final urlController = TextEditingController(text: badge?.badgeUrl ?? '');
    final widthController = TextEditingController(text: (badge?.width ?? 116.0).toString());
    final heightController = TextEditingController(text: (badge?.height ?? 30.0).toString());
    bool isBadgeActive = badge?.isActive ?? true;
    bool isUploading = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final currentUrl = urlController.text.trim();
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.military_tech, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  digit == 0 ? 'Configure Default ID Badge' : 'Configure $digit-Digit Badge',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Replaces the standard "ID:" text in the app with this custom badge banner (PNG, WebP, GIF, SVGA).',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Badge Title',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.title, color: Colors.blueAccent),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter a badge name' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: urlController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Badge Image / SVGA URL',
                              hintText: 'https://.../badge.png | .webp | .gif | .svga',
                              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: const Icon(Icons.link, color: Colors.blueAccent),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                            ),
                            onChanged: (_) => setStateDialog(() {}),
                            validator: (v) => (v == null || v.isEmpty) ? 'Please enter URL or upload a file' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  try {
                                    final result = await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['png', 'webp', 'gif', 'svga', 'jpg', 'jpeg'],
                                      withData: true,
                                    );

                                    if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
                                      setStateDialog(() => isUploading = true);
                                      final file = result.files.first;
                                      final uploadedUrl = await IdBadgeService.uploadBadgeFile(
                                        file.bytes!,
                                        originalFileName: file.name,
                                      );
                                      setStateDialog(() {
                                        urlController.text = uploadedUrl;
                                        isUploading = false;
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('File uploaded successfully!'), backgroundColor: Colors.green),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    setStateDialog(() => isUploading = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
                                      );
                                    }
                                  }
                                },
                          icon: isUploading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.upload_file, size: 16, color: Colors.white),
                          label: const Text('Upload', style: TextStyle(color: Colors.white, fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: widthController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Width (px)',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setStateDialog(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: heightController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Height (px)',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setStateDialog(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Enable in App:', style: TextStyle(color: Colors.white, fontSize: 14)),
                        Switch(
                          value: isBadgeActive,
                          onChanged: (val) => setStateDialog(() => isBadgeActive = val),
                          activeThumbColor: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (currentUrl.isNotEmpty) ...[
                      const Text('Live Badge Preview (ID inside Banner):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        alignment: Alignment.center,
                        child: () {
                          final pHeight = double.tryParse(heightController.text) ?? 30.0;
                          final pWidth = double.tryParse(widthController.text) ?? 116.0;
                          final sampleId = digit == 0 ? '12870642' : ('74728519'.substring(0, digit.clamp(1, 8)));
                          return SizedBox(
                            width: pWidth,
                            height: pHeight,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: MediaPreviewWidget(
                                    url: currentUrl,
                                    width: pWidth,
                                    height: pHeight,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: pHeight * 1.25,
                                      right: pHeight * 0.25,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          sampleId,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: pHeight * 0.46,
                                            letterSpacing: 0.5,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black54,
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      final updatedBadge = IdBadgeModel(
                        id: digit.toString(),
                        digitLength: digit,
                        name: nameController.text.trim(),
                        badgeUrl: urlController.text.trim(),
                        isActive: isBadgeActive,
                        width: double.tryParse(widthController.text) ?? 116.0,
                        height: double.tryParse(heightController.text) ?? 30.0,
                        updatedAt: DateTime.now(),
                      );
                      await IdBadgeService.saveIdBadge(updatedBadge);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ID Badge saved successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving badge: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text('Save Badge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveAssignments() {
    return StreamBuilder<List<CustomUserIdModel>>(
      stream: UserCustomizationService.getCustomUserIdsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        final assignments = snapshot.data ?? [];

        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_pin, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                const Text('No custom user IDs assigned yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Tap the + button to assign a custom ID to a user.', style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            final isExpired = assignment.isExpired;

            return Card(
              color: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isExpired
                      ? Colors.redAccent.withValues(alpha: 0.3)
                      : (assignment.isActive
                          ? Colors.blueAccent.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        assignment.userImageUrl.isNotEmpty
                            ? MediaPreviewWidget(
                                url: assignment.userImageUrl,
                                width: 46,
                                height: 46,
                                borderRadius: BorderRadius.circular(23),
                              )
                            : const CircleAvatar(
                                radius: 23,
                                backgroundColor: Color(0xFF2A2A3E),
                                child: Icon(Icons.person, color: Colors.white70),
                              ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment.userName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Original ID: ${assignment.originalUserId}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        UserIdBadgeWidget(
                          searchId: assignment.customUserId,
                          badgeHeight: 22,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey[800], height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: !assignment.isActive
                                        ? Colors.grey
                                        : (isExpired ? Colors.redAccent : Colors.greenAccent),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Status: ${!assignment.isActive ? "Deactivated" : (isExpired ? "Expired" : "Active")}',
                                  style: TextStyle(
                                    color: !assignment.isActive
                                        ? Colors.grey
                                        : (isExpired ? Colors.redAccent : Colors.greenAccent),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Expires: ${assignment.expiresAt.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Switch(
                              value: assignment.isActive && !isExpired,
                              onChanged: (value) async {
                                if (isExpired && value) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cannot activate expired ID. Please edit duration or assign a new one.'),
                                      backgroundColor: Colors.orangeAccent,
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  await UserCustomizationService.updateCustomUserId(
                                    assignment.id,
                                    assignment.expiresAt,
                                    value,
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.redAccent),
                                    );
                                  }
                                }
                              },
                              activeThumbColor: Colors.blueAccent,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              tooltip: 'Edit / Extend',
                              onPressed: () {
                                _showEditDialog(context, assignment);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Remove & Restore Original ID',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E1E2E),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Text('Remove Custom User ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    content: Text(
                                      'Are you sure you want to remove Custom ID "${assignment.customUserId}" and restore the user\'s original ID "${assignment.originalUserId}"?',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          try {
                                            await UserCustomizationService.deleteCustomUserId(assignment.id);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Custom ID removed, original ID restored.'), backgroundColor: Colors.green),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        child: const Text('Remove & Restore', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ID Badges Configuration Tab
  Widget _buildIdBadgesTab() {
    return StreamBuilder<List<IdBadgeModel>>(
      stream: IdBadgeService.getIdBadgesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        final existingBadges = snapshot.data ?? [];
        final Map<int, IdBadgeModel> badgeMap = {
          for (var b in existingBadges) b.digitLength: b
        };

        // Standard digit list (1 to 8 + Default 0)
        final standardDigits = [1, 2, 3, 4, 5, 6, 7, 8, 0];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3A0CA3).withValues(alpha: 0.35),
                    const Color(0xFF4361EE).withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '🎨 ডিজিট আইডি ব্যাজ কনফিগারেশন',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'প্রতিটি ডিজিটের দৈর্ঘ্যের জন্য আইডি নাম্বারের সামনে "ID" লেখার বদলে কাস্টম ব্যাজ (PNG, WebP, GIF, SVGA) রিয়েল-টাইমে সেট করুন।',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ...standardDigits.map((digit) {
              final badge = badgeMap[digit];
              final hasBadge = badge != null && badge.badgeUrl.isNotEmpty;
              final label = digit == 0 ? 'Default / All Digits' : '$digit-Digit ID Badge';
              final sampleId = digit == 0 ? '104829' : ('8' * digit);

              return Card(
                color: const Color(0xFF1E1E2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: hasBadge && badge.isActive
                        ? Colors.amber.withValues(alpha: 0.35)
                        : Colors.white10,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Badge Icon / Preview
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        alignment: Alignment.center,
                        child: hasBadge
                            ? MediaPreviewWidget(
                                url: badge.badgeUrl,
                                width: 44,
                                height: 32,
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                digit <= 2
                                    ? Icons.workspace_premium
                                    : (digit <= 4 ? Icons.stars : Icons.military_tech),
                                color: digit == 1
                                    ? Colors.amber
                                    : (digit == 2 ? Colors.amberAccent : Colors.cyanAccent),
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 14),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  badge?.name ?? label,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(width: 6),
                                if (hasBadge)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      badge.fileType.toUpperCase(),
                                      style: const TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // App Preview Simulation
                            Row(
                              children: [
                                const Text('App Display: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                const SizedBox(width: 4),
                                UserIdBadgeWidget(
                                  searchId: sampleId,
                                  badgeHeight: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      if (hasBadge)
                        Switch(
                          value: badge.isActive,
                          activeThumbColor: Colors.amber,
                          onChanged: (val) async {
                            final updated = IdBadgeModel(
                              id: badge.id,
                              digitLength: badge.digitLength,
                              name: badge.name,
                              badgeUrl: badge.badgeUrl,
                              fileType: badge.fileType,
                              isActive: val,
                              width: badge.width,
                              height: badge.height,
                              updatedAt: DateTime.now(),
                            );
                            await IdBadgeService.saveIdBadge(updated);
                          },
                        ),
                      IconButton(
                        icon: Icon(hasBadge ? Icons.edit : Icons.add_photo_alternate, color: Colors.blueAccent),
                        tooltip: 'Configure Badge',
                        onPressed: () {
                          _showEditBadgeDialog(context, badge: badge, defaultDigit: digit);
                        },
                      ),
                      if (hasBadge)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          tooltip: 'Delete Badge',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E2E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Remove ID Badge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                content: Text(
                                  'Are you sure you want to remove the badge for $label? The app will revert to showing "ID:" text.',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await IdBadgeService.deleteIdBadge(digit);
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    child: const Text('Remove', style: TextStyle(color: Colors.white)),
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
            }),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<CustomUserIdHistoryModel>>(
      stream: UserCustomizationService.getCustomUserIdHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        final historyLogs = snapshot.data ?? [];

        if (historyLogs.isEmpty) {
          return const Center(
            child: Text('No user ID customization history found.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: historyLogs.length,
          itemBuilder: (context, index) {
            final log = historyLogs[index];
            IconData actionIcon;
            Color actionColor;

            switch (log.action) {
              case UserIdHistoryAction.assign:
                actionIcon = Icons.add_circle;
                actionColor = Colors.greenAccent;
                break;
              case UserIdHistoryAction.update:
                actionIcon = Icons.edit;
                actionColor = Colors.orangeAccent;
                break;
              case UserIdHistoryAction.remove:
                actionIcon = Icons.delete;
                actionColor = Colors.redAccent;
                break;
            }

            return Card(
              color: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: actionColor.withValues(alpha: 0.15),
                  child: Icon(actionIcon, color: actionColor, size: 22),
                ),
                title: Row(
                  children: [
                    Text(
                      'Custom ID: ${log.customUserId}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${log.action.name.toUpperCase()})',
                      style: TextStyle(color: actionColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Text('User: ${log.userId} | Orig: ${log.currentOwnerId}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    if (log.notes != null && log.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(log.notes!, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                    const SizedBox(height: 2),
                    Text('Admin: ${log.actionByAdminId}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
                trailing: Text(
                  log.timestamp.toLocal().toString().substring(0, 16),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Custom User IDs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.person_pin, size: 18), text: 'Active Assignments'),
            Tab(icon: Icon(Icons.military_tech, size: 18), text: 'ID Badges'),
            Tab(icon: Icon(Icons.history, size: 18), text: 'History Log'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                _resetForm();
                _showAssignDialog(context);
              },
              backgroundColor: Colors.blueAccent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Assign Custom ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : (_tabController.index == 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    _showEditBadgeDialog(context, defaultDigit: 1);
                  },
                  backgroundColor: Colors.amber[700],
                  icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                  label: const Text('Configure Badge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveAssignments(),
          _buildIdBadgesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }
}
