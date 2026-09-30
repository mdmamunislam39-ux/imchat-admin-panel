import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/vip_service.dart';

class SvipManagementScreen extends StatefulWidget {
  const SvipManagementScreen({super.key});

  @override
  State<SvipManagementScreen> createState() => _SvipManagementScreenState();
}

class _SvipManagementScreenState extends State<SvipManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _configsSubscription;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String _syncStatusText = '';
  
  final List<String> _vipLevels = ['svip1', 'svip2', 'svip3', 'svip4', 'svip5', 'svip6'];
  Map<String, Map<String, dynamic>> _vipConfigs = {};
  
  // Controllers and FocusNodes for recharge targets
  final Map<String, TextEditingController> _targetControllers = {};
  final Map<String, FocusNode> _targetFocusNodes = {};

  // Controllers and FocusNodes for name colors
  final Map<String, TextEditingController> _colorControllers = {};
  final Map<String, FocusNode> _colorFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _vipLevels.length, vsync: this);
    for (var level in _vipLevels) {
      _targetControllers[level] = TextEditingController();
      _targetFocusNodes[level] = FocusNode();
      _colorControllers[level] = TextEditingController();
      _colorFocusNodes[level] = FocusNode();
    }
    _listenToConfigs();
  }
  
  @override
  void dispose() {
    _configsSubscription?.cancel();
    _tabController.dispose();
    for (var controller in _targetControllers.values) {
      controller.dispose();
    }
    for (var node in _targetFocusNodes.values) {
      node.dispose();
    }
    for (var controller in _colorControllers.values) {
      controller.dispose();
    }
    for (var node in _colorFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _listenToConfigs() {
    _configsSubscription?.cancel();
    _configsSubscription = _firestore
        .collection('config')
        .doc('svip_levels')
        .collection('levels')
        .snapshots()
        .listen((snapshot) {
      Map<String, Map<String, dynamic>> configs = {};
      
      // Initialize defaults
      for (var level in _vipLevels) {
        configs[level] = {
          'rechargeTarget': 0,
          'badgeUrl': '',
          'badgeMediaUrl': '',
          'frameUrl': '',
          'frameMediaUrl': '',
          'entryEffectUrl': '',
          'entryEffectMediaUrl': '',
          'profileSkinUrl': '',
          'profileSkinMediaUrl': '',
          'nameplateUrl': '',
          'nameplateMediaUrl': '',
          'nameColorMode': 'solid',
          'nameColors': ['#FFFFFF'],
          'nameAnimation': 'none',
        };
      }
      
      for (var doc in snapshot.docs) {
        if (_vipLevels.contains(doc.id)) {
          final data = doc.data();
          configs[doc.id] = {
            'rechargeTarget': data['rechargeTarget'] ?? 0,
            'badgeUrl': data['badgeUrl'] ?? '',
            'badgeMediaUrl': data['badgeMediaUrl'] ?? '',
            'frameUrl': data['frameUrl'] ?? '',
            'frameMediaUrl': data['frameMediaUrl'] ?? '',
            'entryEffectUrl': data['entryEffectUrl'] ?? '',
            'entryEffectMediaUrl': data['entryEffectMediaUrl'] ?? '',
            'profileSkinUrl': data['profileSkinUrl'] ?? '',
            'profileSkinMediaUrl': data['profileSkinMediaUrl'] ?? '',
            'nameplateUrl': data['nameplateUrl'] ?? '',
            'nameplateMediaUrl': data['nameplateMediaUrl'] ?? '',
            'nameColorMode': data['nameColorMode'] ?? 'solid',
            'nameColors': List<String>.from(data['nameColors'] ?? ['#FFFFFF']),
            'nameAnimation': data['nameAnimation'] ?? 'none',
          };

          // Update target controller if not focused
          final targetVal = configs[doc.id]!['rechargeTarget'].toString();
          if (!_targetFocusNodes[doc.id]!.hasFocus && _targetControllers[doc.id]!.text != targetVal) {
            _targetControllers[doc.id]!.text = targetVal;
          }

          // Update color controller if not focused
          final colorsVal = (configs[doc.id]!['nameColors'] as List<String>).join(',');
          if (!_colorFocusNodes[doc.id]!.hasFocus && _colorControllers[doc.id]!.text != colorsVal) {
            _colorControllers[doc.id]!.text = colorsVal;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _vipConfigs = configs;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      debugPrint('Error listening to SVIP configs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _saveConfig(String level) async {
    setState(() {
      _isSaving = true;
      _syncStatusText = 'Saving configuration & syncing real-time with active users...';
    });
    try {
      final target = int.tryParse(_targetControllers[level]!.text) ?? 0;
      _vipConfigs[level]!['rechargeTarget'] = target;
      
      await _firestore
          .collection('config')
          .doc('svip_levels')
          .collection('levels')
          .doc(level)
          .set({
            ..._vipConfigs[level]!,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${level.toUpperCase()} saved & synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving $level: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _syncStatusText = '';
        });
      }
    }
  }

  Future<void> _pickAndUploadFile(String level, String field, String label) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'gif', 'mp4', 'vap', 'webp', 'svga', 'json'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final oldUrl = _vipConfigs[level]?[field]?.toString() ?? '';
      setState(() {
        _isSaving = true;
        _syncStatusText = 'Uploading $label & syncing users in real-time...';
      });
      try {
        final bytes = result.files.single.bytes!;
        final extension = result.files.single.extension ?? 'png';
        final fileName = 'svip_${level}_${field}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        
        final ref = FirebaseStorage.instance.ref().child('svip_assets/$fileName');
        final uploadTask = await ref.putData(bytes);
        final newUrl = await uploadTask.ref.getDownloadURL();
        
        setState(() {
          _vipConfigs[level]![field] = newUrl;
        });
        
        // Auto save after upload
        await _saveConfig(level);

        // Real-time synchronization across users
        final updatedUsers = await VipService.syncItemChangeAcrossUsers(
          isSvip: true,
          levelId: level,
          field: field,
          oldUrl: oldUrl,
          newUrl: newUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                updatedUsers > 0
                    ? '$label updated and synced across $updatedUsers users in real-time!'
                    : '$label updated and active for ${level.toUpperCase()}!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error uploading file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _syncStatusText = '';
          });
        }
      }
    }
  }

  Future<void> _enterCustomUrl(String level, String field, String label) async {
    final currentUrl = _vipConfigs[level]?[field]?.toString() ?? '';
    final urlController = TextEditingController(text: currentUrl);

    final bool? shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Edit URL - $label (${level.toUpperCase()})', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter direct image, SVGA, or video URL. Changing this will update active users in real-time.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Apply & Sync', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldUpdate == true) {
      final newUrl = urlController.text.trim();
      if (newUrl == currentUrl) return;

      setState(() {
        _isSaving = true;
        _syncStatusText = 'Updating URL & syncing users in real-time...';
        _vipConfigs[level]![field] = newUrl;
      });

      try {
        await _saveConfig(level);

        final updatedUsers = await VipService.syncItemChangeAcrossUsers(
          isSvip: true,
          levelId: level,
          field: field,
          oldUrl: currentUrl,
          newUrl: newUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                updatedUsers > 0
                    ? '$label updated and synced across $updatedUsers users in real-time!'
                    : '$label updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating URL: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _syncStatusText = '';
          });
        }
      }
    }
  }

  Future<void> _removeItem(String level, String field, String label) async {
    final currentUrl = _vipConfigs[level]?[field]?.toString() ?? '';
    if (currentUrl.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text('Remove $label?', style: const TextStyle(color: Colors.white, fontSize: 16))),
          ],
        ),
        content: Text(
          'Are you sure you want to remove this $label from ${level.toUpperCase()}?\n\nThis will remove the item in real-time from all users who currently own it or have it equipped in the app.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove & Real-time Sync', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isSaving = true;
        _syncStatusText = 'Removing $label & updating user inventories in real-time...';
        _vipConfigs[level]![field] = '';
      });

      try {
        final removedUsers = await VipService.removeItemAndSync(
          isSvip: true,
          levelId: level,
          field: field,
          currentUrl: currentUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                removedUsers > 0
                    ? '$label removed and cleared from $removedUsers users in real-time!'
                    : '$label removed successfully!',
              ),
              backgroundColor: Colors.orange[800],
            ),
          );
        }
      } catch (e) {
        debugPrint('Error removing item: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing item: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _syncStatusText = '';
          });
        }
      }
    }
  }

  Future<void> _removeRewardPair(String level, String categoryName, String thumbField, String mediaField) async {
    final thumbUrl = _vipConfigs[level]?[thumbField]?.toString() ?? '';
    final mediaUrl = _vipConfigs[level]?[mediaField]?.toString() ?? '';
    if (thumbUrl.isEmpty && mediaUrl.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text('Clear All $categoryName?', style: const TextStyle(color: Colors.white, fontSize: 16))),
          ],
        ),
        content: Text(
          'Are you sure you want to completely remove $categoryName (both Thumbnail & Media effect) from ${level.toUpperCase()}?\n\nThis will remove the item from all users in real-time.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All & Real-time Sync', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isSaving = true;
        _syncStatusText = 'Removing $categoryName & updating user inventories in real-time...';
        _vipConfigs[level]![thumbField] = '';
        _vipConfigs[level]![mediaField] = '';
      });

      try {
        final removedCount = await VipService.removeRewardPairAndSync(
          isSvip: true,
          levelId: level,
          thumbField: thumbField,
          mediaField: mediaField,
          currentThumbUrl: thumbUrl,
          currentMediaUrl: mediaUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                removedCount > 0
                    ? '$categoryName cleared and synced across $removedCount users in real-time!'
                    : '$categoryName cleared successfully!',
              ),
              backgroundColor: Colors.orange[800],
            ),
          );
        }
      } catch (e) {
        debugPrint('Error clearing reward pair: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing reward: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _syncStatusText = '';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('SVIP Management', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _vipLevels.map((level) {
            String label = level.toUpperCase();
            if (label.startsWith('SVIP') && label.length > 4) {
              label = 'SVIP ${label.substring(4)}';
            }
            return Tab(text: label);
          }).toList(),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: _vipLevels.map((level) => _buildVipTab(level)).toList(),
          ),
          if (_isSaving)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        _syncStatusText.isNotEmpty ? _syncStatusText : 'Synchronizing changes in real-time...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildVipTab(String level) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('General Settings'),
          _buildTextField('Monthly Recharge Target (Diamonds)', _targetControllers[level]!, _targetFocusNodes[level]!, isNumber: true),
          
          const SizedBox(height: 24),
          _buildSectionHeader('SVIP Rewards (Thumbnails & Media)'),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Real-Time Sync Active: Any item added, changed, or removed will instantly update across all active users in the app!',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          _buildAssetPair(level, 'Badge', 'badgeUrl', 'badgeMediaUrl'),
          _buildAssetPair(level, 'Avatar Frame', 'frameUrl', 'frameMediaUrl'),
          _buildAssetPair(level, 'Entry Effect', 'entryEffectUrl', 'entryEffectMediaUrl'),
          _buildAssetPair(level, 'Room Background Theme / Profile Skin', 'profileSkinUrl', 'profileSkinMediaUrl'),
          _buildAssetPair(level, 'Nameplate / Title', 'nameplateUrl', 'nameplateMediaUrl'),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Animated Name Settings'),
          _buildDropdown(level, 'Name Color Mode', 'nameColorMode', ['solid', 'gradient']),
          _buildDropdown(level, 'Name Animation Type', 'nameAnimation', ['none', 'shimmer', 'pulse']),
          
          const SizedBox(height: 16),
          const Text('Name Colors (Comma separated hex codes, e.g. #FF0000,#00FF00)', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _colorControllers[level],
            focusNode: _colorFocusNodes[level],
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Hex Colors'),
            onChanged: (val) {
              _vipConfigs[level]!['nameColors'] = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            },
          ),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: () => _saveConfig(level),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              label: const Text('Save Changes & Real-Time Sync', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAssetPair(String level, String label, String thumbField, String mediaField) {
    final thumbUrl = _vipConfigs[level]?[thumbField]?.toString() ?? '';
    final mediaUrl = _vipConfigs[level]?[mediaField]?.toString() ?? '';
    final bool hasAny = thumbUrl.isNotEmpty || mediaUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasAny ? Colors.blue.withOpacity(0.4) : Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.stars, color: hasAny ? Colors.blueAccent : Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              if (hasAny)
                TextButton.icon(
                  onPressed: () => _removeRewardPair(level, label, thumbField, mediaField),
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 16),
                  label: const Text('Clear Category', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildImageUploader(level, 'Thumbnail (UI Grid)', thumbField, thumbUrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildImageUploader(level, 'Media (Effect)', mediaField, mediaUrl)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, FocusNode focusNode, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: _inputDecoration(label),
        ),
      ],
    );
  }

  Widget _buildDropdown(String level, String label, String field, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _vipConfigs[level]![field],
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(label),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt.toUpperCase()))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _vipConfigs[level]![field] = val);
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImageUploader(String level, String label, String field, String currentUrl) {
    final bool hasItem = currentUrl.trim().isNotEmpty;
    final bool isVideo = currentUrl.toLowerCase().contains('.mp4');
    final bool isSvga = currentUrl.toLowerCase().contains('.svga') || currentUrl.toLowerCase().contains('.vap');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasItem ? Colors.blue.withOpacity(0.3) : Colors.grey[850]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasItem ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasItem ? 'Active' : 'Empty',
                  style: TextStyle(
                    color: hasItem ? Colors.greenAccent : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: hasItem
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isVideo)
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_file, color: Colors.blue, size: 36),
                                SizedBox(height: 4),
                                Text('MP4 Video', style: TextStyle(color: Colors.blue, fontSize: 10)),
                              ],
                            ),
                          )
                        else if (isSvga)
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.animation, color: Colors.purpleAccent, size: 36),
                                SizedBox(height: 4),
                                Text('SVGA / VAP', style: TextStyle(color: Colors.purpleAccent, fontSize: 10)),
                              ],
                            ),
                          )
                        else
                          Image.network(
                            currentUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey, size: 36),
                            ),
                          ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[600], size: 28),
                        const SizedBox(height: 4),
                        Text('No item set', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          // Action Buttons: Change/Upload, Direct URL, Remove
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickAndUploadFile(level, field, label),
                  icon: Icon(hasItem ? Icons.change_circle_outlined : Icons.cloud_upload_outlined, size: 14),
                  label: Text(
                    hasItem ? 'Change' : 'Upload',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasItem ? Colors.blue[800] : Colors.blueGrey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => _enterCustomUrl(level, field, label),
                icon: const Icon(Icons.link, size: 16, color: Colors.white70),
                tooltip: 'Edit / Paste URL',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[850],
                  padding: const EdgeInsets.all(6),
                ),
              ),
              if (hasItem) ...[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _removeItem(level, field, label),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  tooltip: 'Remove & Sync Real-Time',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.15),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
    );
  }
}
