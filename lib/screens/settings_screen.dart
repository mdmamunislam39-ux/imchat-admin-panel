import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/base_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  
  // Family Settings
  final _familyFormKey = GlobalKey<FormState>();
  final _levelController = TextEditingController();
  final _diamondsController = TextEditingController();
  final _memberLimitController = TextEditingController();
  
  // App Settings (Global) & Agora RTC
  final _appSettingsFormKey = GlobalKey<FormState>();
  final _agoraAppIdController = TextEditingController();
  final _agoraAppCertificateController = TextEditingController();
  bool _obscureCertificate = true;
  
  bool _isAudioCallEnabled = true;
  bool _isVideoCallEnabled = true;
  bool _isGroupCallEnabled = true;
  bool _isVoiceRoomEnabled = true;
  bool _isLiveVideoRoomEnabled = true;

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSavingFamily = false;
  bool _isSavingApp = false;

  // Default running Agora credentials
  static const String _defaultAgoraAppId = 'c74eafbb98784225bae6be9b7e7f6225';
  static const String _defaultAgoraCertificate = 'eb4c5875fba74804b9d348882d7365f0';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _levelController.dispose();
    _diamondsController.dispose();
    _memberLimitController.dispose();
    _agoraAppIdController.dispose();
    _agoraAppCertificateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);

      // Load Family Settings
      final familyDoc = await _firestore.collection('system_configs').doc('family_settings').get();
      if (familyDoc.exists && familyDoc.data() != null) {
        final data = familyDoc.data()!;
        _levelController.text = (data['requiredLevel'] ?? 1).toString();
        _diamondsController.text = (data['requiredDiamonds'] ?? 100).toString();
        _memberLimitController.text = (data['memberLimit'] ?? 50).toString();
      } else {
        _levelController.text = '1';
        _diamondsController.text = '100';
        _memberLimitController.text = '50';
      }

      // Load App Settings & Agora credentials
      final appDoc = await _firestore.collection('global_settings').doc('app_settings').get();
      if (appDoc.exists && appDoc.data() != null) {
        final data = appDoc.data()!;
        _isAudioCallEnabled = data['isAudioCallEnabled'] ?? true;
        _isVideoCallEnabled = data['isVideoCallEnabled'] ?? true;
        _isGroupCallEnabled = data['isGroupCallEnabled'] ?? true;
        _isVoiceRoomEnabled = data['isVoiceRoomEnabled'] ?? true;
        _isLiveVideoRoomEnabled = data['isLiveVideoRoomEnabled'] ?? true;

        final savedAppId = data['agoraAppId'] as String?;
        final savedCert = (data['agoraAppCertificate'] ?? data['agoraCertificate']) as String?;

        _agoraAppIdController.text = (savedAppId != null && savedAppId.trim().isNotEmpty)
            ? savedAppId.trim()
            : _defaultAgoraAppId;
        _agoraAppCertificateController.text = (savedCert != null && savedCert.trim().isNotEmpty)
            ? savedCert.trim()
            : _defaultAgoraCertificate;
      } else {
        // Pre-fill with current running Agora credentials
        _agoraAppIdController.text = _defaultAgoraAppId;
        _agoraAppCertificateController.text = _defaultAgoraCertificate;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _agoraAppIdController.text = _defaultAgoraAppId;
      _agoraAppCertificateController.text = _defaultAgoraCertificate;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFamilySettings() async {
    if (!_familyFormKey.currentState!.validate()) return;
    try {
      setState(() => _isSavingFamily = true);
      await _firestore.collection('system_configs').doc('family_settings').set({
        'requiredLevel': int.parse(_levelController.text.trim()),
        'requiredDiamonds': int.parse(_diamondsController.text.trim()),
        'memberLimit': int.parse(_memberLimitController.text.trim()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() => _isSavingFamily = false);
      _showSuccess('Family settings updated successfully!');
    } catch (e) {
      setState(() => _isSavingFamily = false);
      _showError('Failed to save settings: $e');
    }
  }

  Future<void> _saveAppSettings() async {
    if (!_appSettingsFormKey.currentState!.validate()) return;
    try {
      setState(() => _isSavingApp = true);
      final newAppId = _agoraAppIdController.text.trim();
      final newCert = _agoraAppCertificateController.text.trim();

      final settingsPayload = {
        'isAudioCallEnabled': _isAudioCallEnabled,
        'isVideoCallEnabled': _isVideoCallEnabled,
        'isGroupCallEnabled': _isGroupCallEnabled,
        'isVoiceRoomEnabled': _isVoiceRoomEnabled,
        'isLiveVideoRoomEnabled': _isLiveVideoRoomEnabled,
        'agoraAppId': newAppId,
        'agoraAppCertificate': newCert,
        'agoraCertificate': newCert,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Primary storage: global_settings/app_settings
      await _firestore.collection('global_settings').doc('app_settings').set(
        settingsPayload,
        SetOptions(merge: true),
      );

      // 2. Cross-compatibility mirror: global_settings/server_config & settings/global
      try {
        await _firestore.collection('global_settings').doc('server_config').set({
          'agoraAppId': newAppId,
          'agoraAppCertificate': newCert,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore.collection('settings').doc('global').set({
          'agoraAppId': newAppId,
          'agoraAppCertificate': newCert,
          'agoraCertificate': newCert,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (err) {
        debugPrint('Mirror settings error: $err');
      }

      setState(() => _isSavingApp = false);
      _showSuccess('App & Agora settings updated successfully in real time!');
    } catch (e) {
      setState(() => _isSavingApp = false);
      _showError('Failed to save settings: $e');
    }
  }

  void _showSuccess(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }
  void _showError(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Global Settings',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'App Settings & Features'),
                    Tab(text: 'Family System Settings'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppSettingsTab(),
                      _buildFamilySettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _appSettingsFormKey,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- AGORA RTC ENGINE SETTINGS ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.hub_outlined, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agora RTC Engine Configuration',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Real-time token generation & audio/video calling credentials',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sync, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Real-Time Sync',
                          style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This App ID & Certificate are directly linked to the Cloud Token Generator and Mobile Clients. Any change saved here immediately applies across all voice rooms and calls in real time.',
                        style: TextStyle(color: Colors.blue[100], fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Agora App ID Input
              _buildTextInputField(
                controller: _agoraAppIdController,
                label: 'Agora App ID',
                hint: 'e.g. c74eafbb98784225bae6be9b7e7f6225',
                icon: Icons.vpn_key_outlined,
                onCopy: () {
                  final text = _agoraAppIdController.text.trim();
                  if (text.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: text));
                    _showSuccess('Agora App ID copied to clipboard');
                  }
                },
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Agora App ID is required';
                  if (val.trim().length < 16) return 'Please enter a valid Agora App ID';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Agora App Certificate Input
              _buildTextInputField(
                controller: _agoraAppCertificateController,
                label: 'Agora App Certificate (Primary Token Server)',
                hint: 'e.g. eb4c5875fba74804b9d348882d7365f0',
                icon: Icons.lock_outline,
                obscureText: _obscureCertificate,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCertificate ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  tooltip: _obscureCertificate ? 'Show Certificate' : 'Hide Certificate',
                  onPressed: () => setState(() => _obscureCertificate = !_obscureCertificate),
                ),
                onCopy: () {
                  final text = _agoraAppCertificateController.text.trim();
                  if (text.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: text));
                    _showSuccess('Agora App Certificate copied to clipboard');
                  }
                },
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Agora App Certificate is required';
                  if (val.trim().length < 16) return 'Please enter a valid Agora App Certificate';
                  return null;
                },
              ),

              const SizedBox(height: 28),
              Divider(color: Colors.grey[800], height: 1),
              const SizedBox(height: 24),

              // --- REAL-TIME FEATURE TOGGLES ---
              const Text(
                'Real-Time Feature Toggles',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Instantly enable or disable specific calling features in the mobile app',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildToggle('Audio Call', _isAudioCallEnabled, (val) => setState(() => _isAudioCallEnabled = val)),
              _buildToggle('Video Call', _isVideoCallEnabled, (val) => setState(() => _isVideoCallEnabled = val)),
              _buildToggle('Group Call', _isGroupCallEnabled, (val) => setState(() => _isGroupCallEnabled = val)),
              _buildToggle('Voice Room', _isVoiceRoomEnabled, (val) => setState(() => _isVoiceRoomEnabled = val)),
              _buildToggle('Live Video Room', _isLiveVideoRoomEnabled, (val) => setState(() => _isLiveVideoRoomEnabled = val)),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSavingApp ? null : _saveAppSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSavingApp
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save App Settings',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool obscureText = false,
    Widget? suffixIcon,
    VoidCallback? onCopy,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
            if (onCopy != null)
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 13, color: Colors.blue[300]),
                      const SizedBox(width: 4),
                      Text('Copy', style: TextStyle(color: Colors.blue[300], fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400], size: 18) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey[850],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildToggle(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }

  Widget _buildFamilySettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _familyFormKey,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[800]!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Family System Settings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildNumberInputField(controller: _levelController, label: 'Required User Level to Create Family', hint: 'e.g. 5'),
              const SizedBox(height: 20),
              _buildNumberInputField(controller: _diamondsController, label: 'Required Diamonds to Create Family', hint: 'e.g. 100'),
              const SizedBox(height: 20),
              _buildNumberInputField(controller: _memberLimitController, label: 'Family Member Limit', hint: 'e.g. 50'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _isSavingFamily ? null : _saveFamilySettings,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _isSavingFamily ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Family Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInputField({required TextEditingController controller, required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
            filled: true, fillColor: Colors.grey[850],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter a value';
            if (int.tryParse(val.trim()) == null) return 'Please enter a valid integer';
            return null;
          },
        ),
      ],
    );
  }
}

