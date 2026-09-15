import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class WebsiteLandingManagementScreen extends StatefulWidget {
  const WebsiteLandingManagementScreen({super.key});

  @override
  State<WebsiteLandingManagementScreen> createState() =>
      _WebsiteLandingManagementScreenState();
}

class _WebsiteLandingManagementScreenState
    extends State<WebsiteLandingManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isSaving = false;

  // File upload progress states
  bool _isUploadingLogo = false;
  bool _isUploadingWebsiteLogo = false;
  bool _isUploadingApk = false;
  bool _isUploadingScreenshot = false;
  bool _isUploadingPrivacy = false;
  bool _isUploadingTerms = false;

  // Form Controllers
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _appVersionController = TextEditingController();
  final TextEditingController _playStoreUrlController = TextEditingController();
  final TextEditingController _appStoreUrlController = TextEditingController();
  final TextEditingController _apkUrlController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  final TextEditingController _websiteLogoUrlController = TextEditingController();
  final TextEditingController _supportEmailController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _privacyPolicyUrlController = TextEditingController();
  final TextEditingController _termsOfServiceUrlController = TextEditingController();
  
  bool _showAnnouncement = true;
  
  // Lists for Screenshots & Features
  List<String> _screenshots = [];
  List<Map<String, String>> _features = [];

  // Dialog Controllers for new item insertion
  final TextEditingController _newScreenshotController = TextEditingController();
  final TextEditingController _featureTitleController = TextEditingController();
  final TextEditingController _featureDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLandingData();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _appVersionController.dispose();
    _playStoreUrlController.dispose();
    _appStoreUrlController.dispose();
    _apkUrlController.dispose();
    _logoUrlController.dispose();
    _websiteLogoUrlController.dispose();
    _supportEmailController.dispose();
    _announcementController.dispose();
    _privacyPolicyUrlController.dispose();
    _termsOfServiceUrlController.dispose();
    _newScreenshotController.dispose();
    _featureTitleController.dispose();
    _featureDescController.dispose();
    super.dispose();
  }

  Future<void> _loadLandingData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('settings').doc('website_landing').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _appNameController.text = data['appName'] ?? 'IMChat';
        _taglineController.text = data['tagline'] ?? 'Connect, Voice Chat & Share Moments';
        _descriptionController.text = data['description'] ??
            'IMChat is the ultimate voice audio room and live community app. Connect with people around the world, play exciting games, and enjoy live audio entertainment.';
        _appVersionController.text = data['appVersion'] ?? 'v1.0.0';
        _playStoreUrlController.text = data['playStoreUrl'] ?? '';
        _appStoreUrlController.text = data['appStoreUrl'] ?? '';
        _apkUrlController.text = data['apkUrl'] ?? '';
        _logoUrlController.text = data['logoUrl'] ?? '';
        _websiteLogoUrlController.text = data['websiteLogoUrl'] ?? '';
        _supportEmailController.text = data['supportEmail'] ?? 'support@imchatapp.com';
        _announcementController.text = data['announcement'] ??
            '🔥 Download the latest version of IMChat now for enhanced voice rooms & games!';
        _privacyPolicyUrlController.text = data['privacyPolicyUrl'] ?? '';
        _termsOfServiceUrlController.text = data['termsOfServiceUrl'] ?? '';
        _showAnnouncement = data['showAnnouncement'] ?? true;

        if (data['screenshots'] != null) {
          _screenshots = List<String>.from(data['screenshots']);
        } else {
          _screenshots = [];
        }

        if (data['features'] != null) {
          _features = (data['features'] as List).map((f) => {
            'title': (f['title'] ?? '').toString(),
            'desc': (f['desc'] ?? '').toString(),
            'icon': (f['icon'] ?? 'mic').toString(),
          }).toList();
        } else {
          _setDefaultFeatures();
        }
      } else {
        // Defaults
        _appNameController.text = 'IMChat';
        _taglineController.text = 'Connect, Voice Chat & Share Moments';
        _descriptionController.text =
            'IMChat is the ultimate voice audio room and live community app. Connect with people around the world, play exciting games, and enjoy live audio entertainment.';
        _appVersionController.text = 'v1.0.0';
        _playStoreUrlController.text = 'https://play.google.com';
        _appStoreUrlController.text = 'https://apps.apple.com';
        _apkUrlController.text = '';
        _logoUrlController.text = '';
        _websiteLogoUrlController.text = '';
        _supportEmailController.text = 'support@imchatapp.com';
        _announcementController.text =
            '🔥 Download the latest version of IMChat now for enhanced voice rooms & games!';
        _privacyPolicyUrlController.text = '';
        _termsOfServiceUrlController.text = '';
        _showAnnouncement = true;
        _screenshots = [];
        _setDefaultFeatures();
      }
    } catch (e) {
      debugPrint('Error loading website landing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setDefaultFeatures() {
    _features = [
      {
        'title': 'High-Quality Audio Rooms',
        'desc': 'Host and join crystal-clear multi-seat voice rooms with friends and fans.',
        'icon': 'mic'
      },
      {
        'title': 'Interactive In-Room Games',
        'desc': 'Play Greedy, Wheel, Lucky Bags and exciting games directly in voice rooms.',
        'icon': 'gamepad'
      },
      {
        'title': 'Gifts & Custom Effects',
        'desc': 'Send stunning 3D animated gifts, vehicle entrances, and VIP frames.',
        'icon': 'card_giftcard'
      },
      {
        'title': 'Global Community',
        'desc': 'Meet users worldwide, join agency hosts, and level up your intimacy profile.',
        'icon': 'public'
      }
    ];
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'apk':
        return 'application/vnd.android.package-archive';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  // File Upload Helper to Firebase Storage
  Future<String?> _uploadFileToStorage({
    required String pathPrefix,
    List<String>? allowedExtensions,
    FileType fileType = FileType.custom,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final Uint8List? bytes = file.bytes;
        final String fileName = file.name;

        if (bytes == null || bytes.isEmpty) {
          debugPrint('File bytes are empty or null');
          return null;
        }

        final storagePath = 'website_landing/$pathPrefix/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final ref = FirebaseStorage.instance.ref().child(storagePath);
        final metadata = SettableMetadata(contentType: _getMimeType(fileName));
        
        final uploadTask = ref.putData(bytes, metadata);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
    return null;
  }

  Future<void> _pickAndUploadLogo() async {
    setState(() => _isUploadingLogo = true);
    final url = await _uploadFileToStorage(
      pathPrefix: 'logo',
      fileType: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'svg'],
    );
    if (url != null && mounted) {
      setState(() => _logoUrlController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App logo uploaded successfully!'), backgroundColor: Colors.green),
      );
    }
    if (mounted) setState(() => _isUploadingLogo = false);
  }

  Future<void> _pickAndUploadWebsiteLogo() async {
    setState(() => _isUploadingWebsiteLogo = true);
    final url = await _uploadFileToStorage(
      pathPrefix: 'website_logo',
      fileType: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'svg', 'ico'],
    );
    if (url != null && mounted) {
      setState(() => _websiteLogoUrlController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website logo & favicon uploaded successfully!'), backgroundColor: Colors.green),
      );
    }
    if (mounted) setState(() => _isUploadingWebsiteLogo = false);
  }

  Future<void> _pickAndUploadApk() async {
    setState(() => _isUploadingApk = true);
    final url = await _uploadFileToStorage(
      pathPrefix: 'apks',
      fileType: FileType.any,
    );
    if (url != null && mounted) {
      setState(() => _apkUrlController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('APK file uploaded successfully!'), backgroundColor: Colors.green),
      );
    }
    if (mounted) setState(() => _isUploadingApk = false);
  }

  Future<void> _pickAndUploadScreenshot() async {
    setState(() => _isUploadingScreenshot = true);
    final url = await _uploadFileToStorage(
      pathPrefix: 'screenshots',
      fileType: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (url != null && mounted) {
      setState(() => _screenshots.add(url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screenshot uploaded and added to gallery!'), backgroundColor: Colors.green),
      );
    }
    if (mounted) setState(() => _isUploadingScreenshot = false);
  }

  Future<void> _pickAndUploadPrivacyPolicy() async {
    setState(() => _isUploadingPrivacy = true);
    final url = await _uploadFileToStorage(
      pathPrefix: 'docs',
      fileType: FileType.custom,
      allowedExtensions: ['pdf', 'html', 'txt', 'doc', 'docx'],
    );
    if (url != null && mounted) {
      setState(() => _privacyPolicyUrlController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy Policy document uploaded successfully!'), backgroundColor: Colors.green),
      );
    }
    if (mounted) setState(() => _isUploadingPrivacy = false);
  }

  Future<void> _pickAndUploadTermsOfService() async {
    setState(() => _isUploadingTerms = true);
    final url = await _uploadFileToStorage(
      pathPrefix: 'docs',
      fileType: FileType.custom,
      allowedExtensions: ['pdf', 'html', 'txt', 'doc', 'docx'],
    );
    if (url != null && mounted) {
      setState(() => _termsOfServiceUrlController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terms of Service document uploaded successfully!'), backgroundColor: Colors.green),
      );
    }
    if (mounted) setState(() => _isUploadingTerms = false);
  }

  Future<void> _saveLandingData() async {
    setState(() => _isSaving = true);
    try {
      final payload = {
        'appName': _appNameController.text.trim(),
        'tagline': _taglineController.text.trim(),
        'description': _descriptionController.text.trim(),
        'appVersion': _appVersionController.text.trim(),
        'playStoreUrl': _playStoreUrlController.text.trim(),
        'appStoreUrl': _appStoreUrlController.text.trim(),
        'apkUrl': _apkUrlController.text.trim(),
        'logoUrl': _logoUrlController.text.trim(),
        'websiteLogoUrl': _websiteLogoUrlController.text.trim(),
        'supportEmail': _supportEmailController.text.trim(),
        'announcement': _announcementController.text.trim(),
        'privacyPolicyUrl': _privacyPolicyUrlController.text.trim(),
        'termsOfServiceUrl': _termsOfServiceUrlController.text.trim(),
        'showAnnouncement': _showAnnouncement,
        'screenshots': _screenshots,
        'features': _features,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('settings')
          .doc('website_landing')
          .set(payload, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Website landing settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving landing settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('🌐 Website Landing Config (imchatapp.com)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: _loadLandingData,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isSaving ? null : _saveLandingData,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: const Text('Save Changes'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('📱 General App Information', Icons.info_outline),
                  const SizedBox(height: 12),
                  _buildCard([
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _appNameController,
                            label: 'App Name',
                            hint: 'e.g. IMChat',
                            icon: Icons.title,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _appVersionController,
                            label: 'App Version Name / Code',
                            hint: 'e.g. v1.2.0',
                            icon: Icons.new_releases,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _taglineController,
                      label: 'Tagline / Subtitle',
                      hint: 'e.g. Connect, Voice Chat & Share Moments',
                      icon: Icons.subtitles,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Detailed App Description',
                      hint: 'Describe your app features and community...',
                      icon: Icons.description,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _websiteLogoUrlController,
                            label: 'Website Logo & Favicon URL (ওয়েবসাইট লোগো)',
                            hint: 'https://firebasestorage.googleapis.com/.../web_logo.png',
                            icon: Icons.web_asset,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isUploadingWebsiteLogo ? null : _pickAndUploadWebsiteLogo,
                          icon: _isUploadingWebsiteLogo
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(_isUploadingWebsiteLogo ? 'Uploading...' : 'Upload Web Logo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _logoUrlController,
                            label: 'App Mobile Logo Image URL (অ্যাপ মোডাল লোগো)',
                            hint: 'https://firebasestorage.googleapis.com/.../logo.png',
                            icon: Icons.image,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isUploadingLogo ? null : _pickAndUploadLogo,
                          icon: _isUploadingLogo
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(_isUploadingLogo ? 'Uploading...' : 'Upload App Logo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _supportEmailController,
                      label: 'Support Contact Email',
                      hint: 'support@imchatapp.com',
                      icon: Icons.email,
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader('📜 Legal & Policy Documents (Privacy Policy & Terms)', Icons.gavel),
                  const SizedBox(height: 12),
                  _buildCard([
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _privacyPolicyUrlController,
                            label: 'Privacy Policy Page / File URL',
                            hint: 'https://imchatapp.com/privacy.html or uploaded PDF URL',
                            icon: Icons.privacy_tip,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isUploadingPrivacy ? null : _pickAndUploadPrivacyPolicy,
                          icon: _isUploadingPrivacy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(_isUploadingPrivacy ? 'Uploading...' : 'Upload Doc'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _termsOfServiceUrlController,
                            label: 'Terms of Service Page / File URL',
                            hint: 'https://imchatapp.com/terms.html or uploaded PDF URL',
                            icon: Icons.article,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isUploadingTerms ? null : _pickAndUploadTermsOfService,
                          icon: _isUploadingTerms
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(_isUploadingTerms ? 'Uploading...' : 'Upload Doc'),
                        ),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader('📥 App Download Links & Files', Icons.download),
                  const SizedBox(height: 12),
                  _buildCard([
                    _buildTextField(
                      controller: _playStoreUrlController,
                      label: 'Google Play Store URL',
                      hint: 'https://play.google.com/store/apps/details?id=...',
                      icon: Icons.android,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _appStoreUrlController,
                      label: 'Apple App Store URL',
                      hint: 'https://apps.apple.com/app/...',
                      icon: Icons.apple,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _apkUrlController,
                            label: 'Direct APK File URL / Uploaded APK',
                            hint: 'https://firebasestorage.googleapis.com/.../imchat.apk',
                            icon: Icons.folder_zip,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isUploadingApk ? null : _pickAndUploadApk,
                          icon: _isUploadingApk
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.file_upload),
                          label: Text(_isUploadingApk ? 'Uploading APK...' : 'Upload APK File'),
                        ),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader('📢 Website Announcement Banner', Icons.campaign),
                  const SizedBox(height: 12),
                  _buildCard([
                    SwitchListTile(
                      activeTrackColor: Colors.blueAccent,
                      title: const Text(
                        'Show Top Announcement Banner on Website',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      value: _showAnnouncement,
                      onChanged: (val) {
                        setState(() => _showAnnouncement = val);
                      },
                    ),
                    if (_showAnnouncement) ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _announcementController,
                        label: 'Announcement Banner Text',
                        hint: '🔥 Download IMChat now for new room features!',
                        icon: Icons.announcement,
                      ),
                    ]
                  ]),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('📸 App Screenshots (Gallery Carousel)', Icons.photo_library),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isUploadingScreenshot ? null : _pickAndUploadScreenshot,
                            icon: _isUploadingScreenshot
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.drive_folder_upload),
                            label: Text(_isUploadingScreenshot ? 'Uploading...' : 'Upload Screenshot Image'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                            ),
                            onPressed: _showAddScreenshotDialog,
                            icon: const Icon(Icons.link),
                            label: const Text('Add URL'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildScreenshotsSection(),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('✨ Key Features Cards', Icons.featured_play_list),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _showAddFeatureDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Feature'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeaturesSection(),

                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 260,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isSaving ? null : _saveLandingData,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: const Text('Publish to Website'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161823),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: const Color(0xFF0F1017),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildScreenshotsSection() {
    if (_screenshots.isEmpty) {
      return _buildCard([
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No screenshots added yet. Click "Upload Screenshot Image" or "Add URL" to add app preview images.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ),
      ]);
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(_screenshots.length, (index) {
        final url = _screenshots[index];
        return Stack(
          children: [
            Container(
              width: 140,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
                color: const Color(0xFF161823),
                image: url.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: url.isEmpty
                  ? const Center(child: Icon(Icons.image, color: Colors.white30, size: 40))
                  : null,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.red,
                child: IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() => _screenshots.removeAt(index));
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFeaturesSection() {
    if (_features.isEmpty) {
      return _buildCard([
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No custom features added.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ]);
    }

    return Column(
      children: List.generate(_features.length, (index) {
        final feature = _features[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161823),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star, color: Colors.blueAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['desc'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  setState(() => _features.removeAt(index));
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showAddScreenshotDialog() {
    _newScreenshotController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161823),
        title: const Text('Add Screenshot Image URL', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _newScreenshotController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'https://firebasestorage.googleapis.com/.../ss.png',
            hintStyle: TextStyle(color: Colors.white30),
            labelText: 'Image URL',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _newScreenshotController.text.trim();
              if (text.isNotEmpty) {
                setState(() => _screenshots.add(text));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddFeatureDialog() {
    _featureTitleController.clear();
    _featureDescController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161823),
        title: const Text('Add App Feature', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _featureTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Feature Title (e.g. 3D Audio Rooms)',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _featureDescController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Description of the feature...',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = _featureTitleController.text.trim();
              final desc = _featureDescController.text.trim();
              if (title.isNotEmpty) {
                setState(() {
                  _features.add({
                    'title': title,
                    'desc': desc,
                    'icon': 'star',
                  });
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Feature'),
          ),
        ],
      ),
    );
  }
}
