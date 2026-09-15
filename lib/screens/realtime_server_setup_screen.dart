import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/base_screen.dart';

class RealtimeServerSetupScreen extends StatefulWidget {
  const RealtimeServerSetupScreen({super.key});

  @override
  State<RealtimeServerSetupScreen> createState() => _RealtimeServerSetupScreenState();
}

class _RealtimeServerSetupScreenState extends State<RealtimeServerSetupScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // Active Engines & Failover Master Controls
  String _activeRtcEngine = 'VPS'; // 'VPS' or 'AGORA'
  String _activeStorageEngine = 'VPS'; // 'VPS' or 'FIREBASE'
  bool _autoFailoverRtcToAgora = true;
  bool _autoFailoverStorageToFirebase = true;
  final _healthCheckIntervalController = TextEditingController(text: '3');
  final _failoverTimeoutController = TextEditingController(text: '2000');

  // VPS Real-time RTC Configuration (Audio, Video, Audio Rooms)
  final _vpsRtcEndpointController = TextEditingController();
  final _vpsRtcAuthTokenController = TextEditingController();
  final _vpsRtcHealthUrlController = TextEditingController();
  String _vpsProtocolType = 'LiveKit'; // 'LiveKit', 'SRS', 'ZLM', 'Janus'

  // VPS Real-time Storage Configuration (Moments & Reels Video)
  final _vpsStorageEndpointController = TextEditingController();
  final _vpsStorageBucketController = TextEditingController();
  final _vpsStorageAccessKeyController = TextEditingController();
  final _vpsStorageSecretKeyController = TextEditingController();

  // Agora Fallback Configuration
  final _agoraAppIdController = TextEditingController();
  final _agoraAppCertificateController = TextEditingController();
  String _agoraRegion = 'Global';

  // Cloud Backup Storage Configuration
  final _backupStorageBucketController = TextEditingController();

  // VPS Connection Health State
  bool _isTestingHealth = false;
  String _healthStatusMessage = 'Click test to check server status';
  Color _healthStatusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadServerSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _healthCheckIntervalController.dispose();
    _failoverTimeoutController.dispose();
    _vpsRtcEndpointController.dispose();
    _vpsRtcAuthTokenController.dispose();
    _vpsRtcHealthUrlController.dispose();
    _vpsStorageEndpointController.dispose();
    _vpsStorageBucketController.dispose();
    _vpsStorageAccessKeyController.dispose();
    _vpsStorageSecretKeyController.dispose();
    _agoraAppIdController.dispose();
    _agoraAppCertificateController.dispose();
    _backupStorageBucketController.dispose();
    super.dispose();
  }

  Future<void> _loadServerSettings() async {
    try {
      setState(() => _isLoading = true);

      final doc = await _firestore
          .collection('global_settings')
          .doc('server_config')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _activeRtcEngine = data['activeRtcEngine'] ?? 'VPS';
        _activeStorageEngine = data['activeStorageEngine'] ?? 'VPS';
        _autoFailoverRtcToAgora = data['autoFailoverRtcToAgora'] ?? true;
        _autoFailoverStorageToFirebase =
            data['autoFailoverStorageToFirebase'] ?? true;

        _healthCheckIntervalController.text =
            (data['healthCheckIntervalSec'] ?? 3).toString();
        _failoverTimeoutController.text =
            (data['failoverTimeoutMs'] ?? 2000).toString();

        _vpsRtcEndpointController.text = data['vpsRtcEndpoint'] ?? '';
        _vpsRtcAuthTokenController.text = data['vpsRtcAuthToken'] ?? '';
        _vpsRtcHealthUrlController.text = data['vpsRtcHealthUrl'] ?? '';
        _vpsProtocolType = data['vpsProtocolType'] ?? 'LiveKit';

        _vpsStorageEndpointController.text = data['vpsStorageEndpoint'] ?? '';
        _vpsStorageBucketController.text = data['vpsStorageBucket'] ?? '';
        _vpsStorageAccessKeyController.text = data['vpsStorageAccessKey'] ?? '';
        _vpsStorageSecretKeyController.text = data['vpsStorageSecretKey'] ?? '';

        _agoraAppIdController.text = data['agoraAppId'] ?? '';
        _agoraAppCertificateController.text = data['agoraAppCertificate'] ?? '';
        _agoraRegion = data['agoraRegion'] ?? 'Global';

        _backupStorageBucketController.text = data['backupStorageBucket'] ?? '';
      } else {
        // Defaults
        _vpsRtcEndpointController.text = 'https://rtc.vps.imchat.com';
        _vpsRtcHealthUrlController.text = 'https://rtc.vps.imchat.com/health';
        _vpsStorageEndpointController.text = 'https://media.vps.imchat.com';
        _vpsStorageBucketController.text = 'imchat-media';
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading server settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveServerSettings() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _isSaving = true);

      final configData = {
        'activeRtcEngine': _activeRtcEngine,
        'activeStorageEngine': _activeStorageEngine,
        'autoFailoverRtcToAgora': _autoFailoverRtcToAgora,
        'autoFailoverStorageToFirebase': _autoFailoverStorageToFirebase,
        'healthCheckIntervalSec':
            int.tryParse(_healthCheckIntervalController.text.trim()) ?? 3,
        'failoverTimeoutMs':
            int.tryParse(_failoverTimeoutController.text.trim()) ?? 2000,
        'vpsRtcEndpoint': _vpsRtcEndpointController.text.trim(),
        'vpsRtcAuthToken': _vpsRtcAuthTokenController.text.trim(),
        'vpsRtcHealthUrl': _vpsRtcHealthUrlController.text.trim(),
        'vpsProtocolType': _vpsProtocolType,
        'vpsStorageEndpoint': _vpsStorageEndpointController.text.trim(),
        'vpsStorageBucket': _vpsStorageBucketController.text.trim(),
        'vpsStorageAccessKey': _vpsStorageAccessKeyController.text.trim(),
        'vpsStorageSecretKey': _vpsStorageSecretKeyController.text.trim(),
        'agoraAppId': _agoraAppIdController.text.trim(),
        'agoraAppCertificate': _agoraAppCertificateController.text.trim(),
        'agoraRegion': _agoraRegion,
        'backupStorageBucket': _backupStorageBucketController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('global_settings')
          .doc('server_config')
          .set(configData, SetOptions(merge: true));

      setState(() => _isSaving = false);
      _showSuccess('Realtime server configuration updated successfully!');
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to save settings: $e');
    }
  }

  Future<void> _testVpsConnection() async {
    final healthUrl = _vpsRtcHealthUrlController.text.trim();
    if (healthUrl.isEmpty) {
      _showError('Please enter a VPS Health Check URL first');
      return;
    }

    setState(() {
      _isTestingHealth = true;
      _healthStatusMessage = 'Pinging VPS server...';
      _healthStatusColor = Colors.orange;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 4));
      stopwatch.stop();

      if (response.statusCode == 200) {
        setState(() {
          _isTestingHealth = false;
          _healthStatusMessage =
              '🟢 VPS Online! Latency: ${stopwatch.elapsedMilliseconds} ms (HTTP 200 OK)';
          _healthStatusColor = Colors.green;
        });
      } else {
        setState(() {
          _isTestingHealth = false;
          _healthStatusMessage =
              '🟡 VPS Responded with HTTP Status: ${response.statusCode}';
          _healthStatusColor = Colors.amber;
        });
      }
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _isTestingHealth = false;
        _healthStatusMessage =
            '🔴 VPS Unreachable / Offline (${e.toString().split('\n').first})';
        _healthStatusColor = Colors.red;
      });
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Realtime Server Setup',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  isScrollable: true,
                  tabs: const [
                    Tab(icon: Icon(Icons.swap_calls), text: 'Engine & Failover'),
                    Tab(icon: Icon(Icons.dns), text: 'VPS RTC & Media'),
                    Tab(icon: Icon(Icons.cloud), text: 'Agora & Cloud Backup'),
                    Tab(icon: Icon(Icons.network_check), text: 'Health & Test'),
                  ],
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEngineAndFailoverTab(),
                        _buildVpsSetupTab(),
                        _buildAgoraAndBackupTab(),
                        _buildHealthTestTab(),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[900],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveServerSettings,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Saving Settings...' : 'Save Realtime Server Config',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // --- TAB 1: Engine & Failover ---
  Widget _buildEngineAndFailoverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Master Engine Selection',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select primary media and RTC streaming engine for audio, video, audio rooms, reels, and moments.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // RTC Engine Selector
            _buildDropdownField(
              label: 'Primary RTC Engine (Audio Call, Video Call, Audio Rooms)',
              value: _activeRtcEngine,
              items: const [
                DropdownMenuItem(
                    value: 'VPS',
                    child: Text('VPS Live Engine (SRS / LiveKit / ZLM)')),
                DropdownMenuItem(
                    value: 'AGORA', child: Text('Agora Cloud RTC Engine')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _activeRtcEngine = val);
              },
            ),
            const SizedBox(height: 20),

            // Storage Engine Selector
            _buildDropdownField(
              label: 'Primary Media Storage Engine (Moments & Reels Video)',
              value: _activeStorageEngine,
              items: const [
                DropdownMenuItem(
                    value: 'VPS',
                    child: Text('VPS Storage Engine (MinIO / Nginx Node)')),
                DropdownMenuItem(
                    value: 'FIREBASE',
                    child: Text('Firebase Storage / AWS S3')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _activeStorageEngine = val);
              },
            ),

            const Divider(color: Colors.grey, height: 40),

            const Text(
              '🛡️ Automatic Failover Rules (Auto Switch to Backup)',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Auto-Failover Audio/Video to Agora when VPS is Down',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'If VPS ping fails or disconnects, app automatically switches call/room to Agora SDK.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              value: _autoFailoverRtcToAgora,
              onChanged: (val) =>
                  setState(() => _autoFailoverRtcToAgora = val),
              activeThumbColor: Colors.blue,
            ),

            SwitchListTile(
              title: const Text('Auto-Failover Media Upload/Stream to Firebase Storage',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'If VPS MinIO storage fails, app automatically uses Firebase Storage.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              value: _autoFailoverStorageToFirebase,
              onChanged: (val) =>
                  setState(() => _autoFailoverStorageToFirebase = val),
              activeThumbColor: Colors.blue,
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _healthCheckIntervalController,
                    label: 'Health Check Interval (seconds)',
                    hint: 'e.g. 3',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    controller: _failoverTimeoutController,
                    label: 'Failover Timeout (ms)',
                    hint: 'e.g. 2000',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: VPS Setup ---
  Widget _buildVpsSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌐 VPS Streaming & RTC Server Settings',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'VPS RTC Streaming Protocol',
              value: _vpsProtocolType,
              items: const [
                DropdownMenuItem(value: 'LiveKit', child: Text('LiveKit WebRTC Engine')),
                DropdownMenuItem(value: 'SRS', child: Text('SRS (Simple Realtime Server)')),
                DropdownMenuItem(value: 'ZLM', child: Text('ZLMediaKit Server')),
                DropdownMenuItem(value: 'Janus', child: Text('Janus WebRTC Gateway')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _vpsProtocolType = val);
              },
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _vpsRtcEndpointController,
              label: 'VPS RTC Endpoint URL (Audio, Video, Audio Rooms)',
              hint: 'e.g. https://rtc.vps.imchat.com:7880 or wss://rtc.vps.imchat.com',
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _vpsRtcHealthUrlController,
              label: 'VPS RTC Health-Check Ping URL',
              hint: 'e.g. https://rtc.vps.imchat.com/health',
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _vpsRtcAuthTokenController,
              label: 'VPS API Secret Key / Token',
              hint: 'Enter VPS secret key or API token',
              isObscure: true,
            ),

            const Divider(color: Colors.grey, height: 40),

            const Text(
              '📦 VPS Media & Storage Settings (Moments & Reels)',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _vpsStorageEndpointController,
              label: 'VPS Storage Base CDN Endpoint URL',
              hint: 'e.g. https://media.vps.imchat.com',
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _vpsStorageBucketController,
              label: 'VPS MinIO Storage Bucket Name',
              hint: 'e.g. imchat-reels-moments',
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _vpsStorageAccessKeyController,
                    label: 'MinIO Access Key',
                    hint: 'Access Key ID',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    controller: _vpsStorageSecretKeyController,
                    label: 'MinIO Secret Key',
                    hint: 'Secret Access Key',
                    isObscure: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: Agora & Cloud Backup ---
  Widget _buildAgoraAndBackupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📡 Agora RTC Cloud Fallback Settings',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Used automatically if VPS is offline or selected as primary RTC provider.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            _buildInputField(
              controller: _agoraAppIdController,
              label: 'Agora App ID',
              hint: 'Enter 32-character Agora App ID',
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _agoraAppCertificateController,
              label: 'Agora App Certificate (Primary Token Server)',
              hint: 'Enter Agora App Certificate',
              isObscure: true,
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Agora Primary Cloud Region',
              value: _agoraRegion,
              items: const [
                DropdownMenuItem(value: 'Global', child: Text('Global Automatic Area')),
                DropdownMenuItem(value: 'US', child: Text('North America (US)')),
                DropdownMenuItem(value: 'EU', child: Text('Europe (EU)')),
                DropdownMenuItem(value: 'AP', child: Text('Asia Pacific (AP)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _agoraRegion = val);
              },
            ),

            const Divider(color: Colors.grey, height: 40),

            const Text(
              '☁️ Firebase / Cloud Backup Storage',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _backupStorageBucketController,
              label: 'Firebase Storage / S3 Backup Bucket Name',
              hint: 'e.g. imchat-app.appspot.com',
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 4: Health Test ---
  Widget _buildHealthTestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 VPS Health & Realtime Status Monitor',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test real-time connection, HTTP latency, and status of your configured VPS server endpoints.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _healthStatusColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, color: _healthStatusColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _healthStatusMessage,
                      style: TextStyle(
                          color: _healthStatusColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isTestingHealth ? null : _testVpsConnection,
                icon: _isTestingHealth
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.flash_on, color: Colors.white),
                label: Text(
                  _isTestingHealth ? 'Pinging VPS Server...' : 'Test VPS Server Ping & Health Now',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'ℹ️ Troubleshooting Checklist:',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Ensure your VPS has CORS enabled for API requests from Web/Mobile.\n'
              '• Verify your SSL certificate (HTTPS/WSS) is valid on the VPS domain.\n'
              '• Check firewall rules (Port 80/443, 7880 for LiveKit, 1935 for RTMP).\n'
              '• If VPS ping fails, client apps automatically route calls to Agora.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Form Widgets ---
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: Colors.grey[850],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
