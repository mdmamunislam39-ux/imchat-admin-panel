import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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
    setState(() => _isSaving = true);
    try {
      final target = int.tryParse(_targetControllers[level]!.text) ?? 0;
      _vipConfigs[level]!['rechargeTarget'] = target;
      
      await _firestore
          .collection('config')
          .doc('svip_levels')
          .collection('levels')
          .doc(level)
          .set(_vipConfigs[level]!, SetOptions(merge: true));
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${level.toUpperCase()} saved successfully!'), backgroundColor: Colors.green),
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
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAndUploadFile(String level, String field) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'gif', 'mp4', 'vap', 'webp', 'svga', 'json'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() => _isSaving = true);
      try {
        final bytes = result.files.single.bytes!;
        final extension = result.files.single.extension ?? 'png';
        final fileName = 'svip_${level}_${field}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        
        final ref = FirebaseStorage.instance.ref().child('svip_assets/$fileName');
        final uploadTask = await ref.putData(bytes);
        final url = await uploadTask.ref.getDownloadURL();
        
        setState(() {
          _vipConfigs[level]![field] = url;
        });
        
        // Auto save after upload
        await _saveConfig(level);
      } catch (e) {
        debugPrint('Error uploading file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
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
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.blue)),
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
          const Text(
            'Upload a Thumbnail (PNG/JPG) for the UI grid, and a Media file (SVGA/MP4/GIF/PNG) for the actual effect in the app.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          
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
            child: ElevatedButton(
              onPressed: () => _saveConfig(level),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAssetPair(String level, String label, String thumbField, String mediaField) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildImageUploader(level, 'Thumbnail (UI Grid)', thumbField, _vipConfigs[level]![thumbField] ?? '')),
              const SizedBox(width: 16),
              Expanded(child: _buildImageUploader(level, 'Media (Effect)', mediaField, _vipConfigs[level]![mediaField] ?? '')),
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
    final bool isVideo = currentUrl.toLowerCase().contains('.mp4');
    final bool isSvga = currentUrl.toLowerCase().contains('.svga');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: currentUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isVideo 
                        ? const Center(child: Icon(Icons.video_file, color: Colors.blue, size: 40))
                        : isSvga 
                            ? const Center(child: Icon(Icons.animation, color: Colors.purple, size: 40))
                            : Image.network(currentUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Center(child: Icon(Icons.image, color: Colors.grey, size: 40))),
                  )
                : const Center(child: Icon(Icons.add_photo_alternate, color: Colors.grey, size: 30)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _pickAndUploadFile(level, field),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentUrl.isNotEmpty ? Colors.blue[900] : Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 8)
              ),
              child: Text(currentUrl.isNotEmpty ? 'Change' : 'Upload', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
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
