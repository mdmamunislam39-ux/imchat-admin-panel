import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';

class InvitationRewardScreen extends StatefulWidget {
  const InvitationRewardScreen({super.key});

  @override
  State<InvitationRewardScreen> createState() => _InvitationRewardScreenState();
}

class _InvitationRewardScreenState extends State<InvitationRewardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  final _rewardController = TextEditingController();
  final _admobAppIdController = TextEditingController();
  final _admobAdUnitIdController = TextEditingController();
  final _adRewardController = TextEditingController();
  final _maxAdsPerDayController = TextEditingController();
  final _watchSecondsController = TextEditingController();
  
  String _videoCompletionType = 'full_video';

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _rewardController.dispose();
    _admobAppIdController.dispose();
    _admobAdUnitIdController.dispose();
    _adRewardController.dispose();
    _maxAdsPerDayController.dispose();
    _watchSecondsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);
      final doc = await _firestore.collection('global_settings').doc('app_settings').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _rewardController.text = (data['invitationRewardDiamonds'] ?? 100).toString();
        _admobAppIdController.text = data['admobAppId'] ?? '';
        _admobAdUnitIdController.text = data['admobAdUnitId'] ?? '';
        _adRewardController.text = (data['adRewardDiamonds'] ?? 10).toString();
        _maxAdsPerDayController.text = (data['maxAdsPerDay'] ?? 5).toString();
        _videoCompletionType = data['videoCompletionType'] ?? 'full_video';
        _watchSecondsController.text = (data['adVideoWatchSeconds'] ?? 0).toString();
      } else {
        _rewardController.text = '100';
        _adRewardController.text = '10';
        _maxAdsPerDayController.text = '5';
        _watchSecondsController.text = '0';
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _isSaving = true);
      await _firestore.collection('global_settings').doc('app_settings').set({
        'invitationRewardDiamonds': int.tryParse(_rewardController.text.trim()) ?? 100,
        'admobAppId': _admobAppIdController.text.trim(),
        'admobAdUnitId': _admobAdUnitIdController.text.trim(),
        'adRewardDiamonds': int.tryParse(_adRewardController.text.trim()) ?? 10,
        'maxAdsPerDay': int.tryParse(_maxAdsPerDayController.text.trim()) ?? 5,
        'videoCompletionType': _videoCompletionType,
        'adVideoWatchSeconds': int.tryParse(_watchSecondsController.text.trim()) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Invitation Referral & Ad Rewards',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Referral Reward Settings', Icons.card_giftcard),
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'When a user successfully invites someone, they receive this reward.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _rewardController,
                              label: 'Reward Amount (Diamonds)',
                              icon: Icons.diamond,
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Please enter a value';
                                if (int.tryParse(val) == null) return 'Must be a valid number';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildSectionHeader('AdMob Integration Settings', Icons.ad_units),
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Configure Google AdMob parameters for rewarded video ads.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _admobAppIdController,
                              label: 'AdMob App ID',
                              icon: Icons.apps,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _admobAdUnitIdController,
                              label: 'AdMob Ad Unit ID (Rewarded Video)',
                              icon: Icons.video_library,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildSectionHeader('Ad Reward & Limits', Icons.monetization_on),
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _adRewardController,
                                    label: 'Reward Amount Per Ad (Diamonds)',
                                    icon: Icons.diamond_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Please enter a value';
                                      if (int.tryParse(val) == null) return 'Must be a valid number';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _maxAdsPerDayController,
                                    label: 'Max Ads Allowed Per Day (Per User)',
                                    icon: Icons.av_timer,
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Please enter a value';
                                      if (int.tryParse(val) == null) return 'Must be a valid number';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Video Completion Requirement',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _videoCompletionType,
                                  isExpanded: true,
                                  dropdownColor: Colors.grey[850],
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'full_video',
                                      child: Text('User must watch full video'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'timer',
                                      child: Text('User must watch for X seconds'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _videoCompletionType = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            if (_videoCompletionType == 'timer') ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _watchSecondsController,
                                label: 'Watch Duration (Seconds)',
                                icon: Icons.timer,
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (_videoCompletionType == 'timer') {
                                    if (val == null || val.trim().isEmpty) return 'Please enter a value';
                                    if (int.tryParse(val) == null) return 'Must be a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save All Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
    );
  }
}
