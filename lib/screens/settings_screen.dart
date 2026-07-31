import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  
  // App Settings (Global)
  final _appSettingsFormKey = GlobalKey<FormState>();
  
  bool _isAudioCallEnabled = true;
  bool _isVideoCallEnabled = true;
  bool _isGroupCallEnabled = true;
  bool _isVoiceRoomEnabled = true;
  bool _isLiveVideoRoomEnabled = true;

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSavingFamily = false;
  bool _isSavingApp = false;

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

      // Load App Settings
      final appDoc = await _firestore.collection('global_settings').doc('app_settings').get();
      if (appDoc.exists && appDoc.data() != null) {
        final data = appDoc.data()!;
        _isAudioCallEnabled = data['isAudioCallEnabled'] ?? true;
        _isVideoCallEnabled = data['isVideoCallEnabled'] ?? true;
        _isGroupCallEnabled = data['isGroupCallEnabled'] ?? true;
        _isVoiceRoomEnabled = data['isVoiceRoomEnabled'] ?? true;
        _isLiveVideoRoomEnabled = data['isLiveVideoRoomEnabled'] ?? true;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading settings: $e');
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
      await _firestore.collection('global_settings').doc('app_settings').set({
        'isAudioCallEnabled': _isAudioCallEnabled,
        'isVideoCallEnabled': _isVideoCallEnabled,
        'isGroupCallEnabled': _isGroupCallEnabled,
        'isVoiceRoomEnabled': _isVoiceRoomEnabled,
        'isLiveVideoRoomEnabled': _isLiveVideoRoomEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() => _isSavingApp = false);
      _showSuccess('App settings updated successfully!');
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
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[800]!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Real-Time Feature Toggles', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildToggle('Audio Call', _isAudioCallEnabled, (val) => setState(() => _isAudioCallEnabled = val)),
              _buildToggle('Video Call', _isVideoCallEnabled, (val) => setState(() => _isVideoCallEnabled = val)),
              _buildToggle('Group Call', _isGroupCallEnabled, (val) => setState(() => _isGroupCallEnabled = val)),
              _buildToggle('Voice Room', _isVoiceRoomEnabled, (val) => setState(() => _isVoiceRoomEnabled = val)),
              _buildToggle('Live Video Room', _isLiveVideoRoomEnabled, (val) => setState(() => _isLiveVideoRoomEnabled = val)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _isSavingApp ? null : _saveAppSettings,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _isSavingApp ? const CircularProgressIndicator(color: Colors.white) : const Text('Save App Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
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
