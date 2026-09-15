import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../services/official_notification_service.dart';
import '../services/firebase_data_service.dart';
import '../widgets/media_preview_widget.dart';

class OfficialNotificationsScreen extends StatefulWidget {
  const OfficialNotificationsScreen({super.key});

  @override
  State<OfficialNotificationsScreen> createState() => _OfficialNotificationsScreenState();
}

class _OfficialNotificationsScreenState extends State<OfficialNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _titleController = TextEditingController(text: 'imChat Official team');
  final _messageController = TextEditingController();
  final _linkController = TextEditingController();
  final _searchController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Search and selection state
  List<Map<String, dynamic>> _searchedUsers = [];
  final Map<String, Map<String, dynamic>> _selectedUsers = {};
  bool _isSearchingUsers = false;
  bool _isLoadingDefaultUsers = true;
  String _selectedTargetGroup = 'custom';

  // Media state
  Uint8List? _imageBytes;
  String? _imageName;
  Uint8List? _audioBytes;
  String? _audioName;

  // Audio rooms search for sharing
  List<Map<String, dynamic>> _audioRooms = [];
  String? _selectedRoomId;
  String? _selectedRoomName;
  bool _isLoadingRooms = false;

  // Progress/Broadcast state
  bool _isSending = false;
  double _sendProgress = 0.0;
  String _sendProgressStatus = '';

  @override
  void initState() {
    super.initState();
    _loadDefaultUsers();
    _fetchAudioRooms();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _linkController.dispose();
    _searchController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // --- Data Loading & Search Logic ---

  Future<void> _loadDefaultUsers() async {
    setState(() => _isLoadingDefaultUsers = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Users')
          .limit(30)
          .get();
      _displayUsers(snap.docs);
    } catch (e) {
      debugPrint('Error loading default users: $e');
    } finally {
      setState(() => _isLoadingDefaultUsers = false);
    }
  }

  Future<void> _fetchAudioRooms() async {
    setState(() => _isLoadingRooms = true);
    try {
      _audioRooms = await FirebaseDataService.getAllAudioRooms();
    } catch (e) {
      debugPrint('Error fetching audio rooms: $e');
    } finally {
      setState(() => _isLoadingRooms = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (_selectedTargetGroup == 'custom') {
        _loadDefaultUsers();
      }
    } else {
      if (_selectedTargetGroup != 'custom') {
        setState(() {
          _selectedTargetGroup = 'custom';
        });
      }
      _searchUsers(query);
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isSearchingUsers = true);
    try {
      final q = FirebaseFirestore.instance.collection('Users');
      QuerySnapshot<Map<String, dynamic>>? snap;

      // 1. Search by exact searchId as numeric
      final numQuery = int.tryParse(query);
      if (numQuery != null) {
        snap = await q.where('searchId', isEqualTo: numQuery).limit(20).get();
      }

      // 2. Search by exact searchId as string
      if (snap == null || snap.docs.isEmpty) {
        snap = await q.where('searchId', isEqualTo: query).limit(20).get();
      }

      // 3. Search by username prefix
      if (snap.docs.isEmpty) {
        snap = await q
            .where('username', isGreaterThanOrEqualTo: query)
            .where('username', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(25)
            .get();
      }

      // 4. Search by fullname prefix
      if (snap.docs.isEmpty) {
        snap = await q
            .where('fullname', isGreaterThanOrEqualTo: query)
            .where('fullname', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(25)
            .get();
      }

      // 5. Check if it matches a direct Document ID (userId)
      if (snap.docs.isEmpty && query.length >= 20) {
        final doc = await q.doc(query).get();
        if (doc.exists) {
          _displayUsers([doc]);
          return;
        }
      }

      _displayUsers(snap.docs);
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      setState(() => _isSearchingUsers = false);
    }
  }

  void _displayUsers(List<DocumentSnapshot<Map<String, dynamic>>> docs) {
    setState(() {
      _searchedUsers = docs.map((doc) {
        final data = doc.data() ?? {};
        return {
          'userId': doc.id,
          'fullname': data['fullname'] ?? data['name'] ?? 'Unknown User',
          'username': data['username'] ?? '',
          'searchId': data['searchId']?.toString() ?? '',
          'profileImage': data['profileImage'] ?? data['imageUrl'] ?? '',
          'deviceToken': data['deviceToken'] ?? '',
        };
      }).toList();
    });
  }

  Future<void> _applyTargetGroup(String group) async {
    if (group == 'custom') {
      return;
    }

    setState(() {
      _isLoadingDefaultUsers = true;
      _selectedUsers.clear();
      _searchedUsers.clear();
    });

    try {
      final q = FirebaseFirestore.instance.collection('Users');
      List<DocumentSnapshot<Map<String, dynamic>>> docs = [];

      if (group == 'all') {
        final snap = await q.get();
        docs = snap.docs;
      } else if (group == 'host') {
        final snap1 = await q.where('isHost', isEqualTo: true).get();
        final snap2 = await q.where('userType', isEqualTo: 'host').get();
        
        final merged = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (var doc in snap1.docs) {
          merged[doc.id] = doc;
        }
        for (var doc in snap2.docs) {
          merged[doc.id] = doc;
        }
        docs = merged.values.toList();
      } else if (group == 'agency') {
        final snap1 = await q.where('userType', isEqualTo: 'agency').get();
        final snap2 = await q.where('userType', isEqualTo: 'agency_owner').get();
        
        final merged = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (var doc in snap1.docs) {
          merged[doc.id] = doc;
        }
        for (var doc in snap2.docs) {
          merged[doc.id] = doc;
        }
        docs = merged.values.toList();
      } else if (group == 'seller') {
        final snap = await q.where('userType', isEqualTo: 'seller').get();
        docs = snap.docs;
      } else if (group == 'new') {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        final snap = await q
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
            .get();
        docs = snap.docs;
      }

      setState(() {
        _searchedUsers = docs.map((doc) {
          final data = doc.data() ?? {};
          final userMap = {
            'userId': doc.id,
            'fullname': data['fullname'] ?? data['name'] ?? 'Unknown User',
            'username': data['username'] ?? '',
            'searchId': data['searchId']?.toString() ?? '',
            'profileImage': data['profileImage'] ?? data['imageUrl'] ?? '',
            'deviceToken': data['deviceToken'] ?? '',
          };
          _selectedUsers[doc.id] = userMap;
          return userMap;
        }).toList();
        
        _isLoadingDefaultUsers = false;
      });
    } catch (e) {
      debugPrint('Error applying target group: $e');
      setState(() {
        _isLoadingDefaultUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading target group: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Picker Actions ---

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imageBytes = result.files.first.bytes;
          _imageName = result.files.first.name;
          _imageUrlController.clear(); // Clear direct link if uploading
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _audioBytes = result.files.first.bytes;
          _audioName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking audio: $e');
    }
  }

  // --- Send Broadcast ---

  Future<void> _sendBroadcast() async {
    if (_isSending) return;
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient user.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _sendProgress = 0.0;
      _sendProgressStatus = 'Initializing...';
    });

    try {
      String? finalImageUrl = _imageUrlController.text.trim();
      String? finalAudioUrl;

      // 1. Upload image if selected
      if (_imageBytes != null && _imageName != null) {
        setState(() => _sendProgressStatus = 'Uploading image...');
        finalImageUrl = await OfficialNotificationService.uploadFile(
          bytes: _imageBytes!,
          name: _imageName!,
          path: 'images',
        );
        if (finalImageUrl == null) throw Exception('Failed to upload image file.');
      }

      // 2. Upload audio if selected
      if (_audioBytes != null && _audioName != null) {
        setState(() => _sendProgressStatus = 'Uploading voice message...');
        finalAudioUrl = await OfficialNotificationService.uploadFile(
          bytes: _audioBytes!,
          name: _audioName!,
          path: 'audio',
        );
        if (finalAudioUrl == null) throw Exception('Failed to upload audio file.');
      }

      // 3. Structure voice room share if selected
      Map<String, dynamic>? roomShare;
      if (_selectedRoomId != null) {
        roomShare = {
          'roomId': _selectedRoomId,
          'roomName': _selectedRoomName ?? '',
          'roomImage': '',
          'description': 'Tap to join live voice room!',
        };
      }

      // 4. Send notifications sequentially
      final total = _selectedUsers.length;
      int count = 0;

      for (final user in _selectedUsers.values) {
        final receiverId = user['userId'] as String;
        final deviceToken = user['deviceToken'] as String;
        final name = user['fullname'] as String;

        setState(() {
          count++;
          _sendProgress = count / total;
          _sendProgressStatus = 'Sending to $name ($count/$total)...';
        });

        // Insert interactive placeholders if present in message
        String customizedMessage = _messageController.text;
        customizedMessage = customizedMessage.replaceAll('[UserName]', name);
        customizedMessage = customizedMessage.replaceAll('[Amount]', ''); // Optional placeholder cleanups

        await OfficialNotificationService.sendOfficialNotification(
          receiverId: receiverId,
          receiverDeviceToken: deviceToken,
          title: _titleController.text.trim(),
          messageText: customizedMessage,
          imageUrl: finalImageUrl,
          audioUrl: finalAudioUrl,
          linkUrl: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
          roomShare: roomShare,
        );

        // Slight artificial delay to prevent rate-limiting FCM or Firestore
        await Future.delayed(const Duration(milliseconds: 150));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Push Notifications sent successfully to $total users!'),
            backgroundColor: Colors.green,
          ),
        );
        _resetComposer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _resetComposer() {
    setState(() {
      _messageController.clear();
      _linkController.clear();
      _imageUrlController.clear();
      _imageBytes = null;
      _imageName = null;
      _audioBytes = null;
      _audioName = null;
      _selectedRoomId = null;
      _selectedRoomName = null;
      _selectedUsers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[950],
        foregroundColor: Colors.white,
        title: const Text(
          'imChat Official Notification Desk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Left Column: Search & Target Users ---
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.grey[900]?.withValues(alpha: 0.5),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Target Group Selection
                      const Text(
                        'Target Audience Group',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedTargetGroup,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[850],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'custom', child: Text('Custom Selection (Choose below)')),
                          DropdownMenuItem(value: 'all', child: Text('All Users')),
                          DropdownMenuItem(value: 'host', child: Text('Only Hosts')),
                          DropdownMenuItem(value: 'agency', child: Text('Only Agency Owners')),
                          DropdownMenuItem(value: 'seller', child: Text('Only Sellers')),
                          DropdownMenuItem(value: 'new', child: Text('New Users (Last 7 Days)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedTargetGroup = val;
                            });
                            _applyTargetGroup(val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Search Header
                      const Text(
                        'Select Target Users',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      // Search Input
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by User ID, Name, or Search ID...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Multi-select bulk options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedUsers.length} Selected',
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    for (final u in _searchedUsers) {
                                      _selectedUsers[u['userId']] = u;
                                    }
                                  });
                                },
                                child: const Text('Select Page'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedUsers.clear();
                                  });
                                },
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const Divider(color: Colors.grey, height: 1),
                      const SizedBox(height: 10),

                      // User list
                      Expanded(
                        child: (_isLoadingDefaultUsers || _isSearchingUsers)
                            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                            : _searchedUsers.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No users found.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _searchedUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = _searchedUsers[index];
                                      final userId = user['userId'];
                                      final isSelected = _selectedUsers.containsKey(userId);
                                      final hasToken = (user['deviceToken'] as String).isNotEmpty;

                                      return Card(
                                        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.grey[850],
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        child: CheckboxListTile(
                                          activeColor: Colors.blue,
                                          title: Row(
                                            children: [
                                              if ((user['profileImage'] as String).isNotEmpty)
                                                MediaPreviewWidget(
                                                  url: user['profileImage'],
                                                  width: 32,
                                                  height: 32,
                                                  borderRadius: BorderRadius.circular(16),
                                                )
                                              else
                                                const CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: Colors.grey,
                                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                                ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  user['fullname'],
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Text(
                                            'ID: ${user['searchId']} ${hasToken ? "📲 (Push Ready)" : "⚠️ (No Push Token)"}',
                                            style: TextStyle(
                                              color: hasToken ? Colors.green[300] : Colors.amber[300],
                                              fontSize: 12,
                                            ),
                                          ),
                                          value: isSelected,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedTargetGroup = 'custom';
                                              if (val == true) {
                                                _selectedUsers[userId] = user;
                                              } else {
                                                _selectedUsers.remove(userId);
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Vertical divider
              Container(width: 1, color: Colors.grey[850]),

              // --- Right Column: Compose Notification & Live Preview ---
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Compose Official Push Notification',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Notification Title
                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Notification Title',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[900],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Text Content
                          TextFormField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Message Body',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              hintText: 'Write message text. Use [UserName] to inject recipient fullname dynamically.',
                              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                              filled: true,
                              fillColor: Colors.grey[900],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (val) {
                              if (_imageBytes == null && _audioBytes == null && _selectedRoomId == null && (val == null || val.trim().isEmpty)) {
                                return 'Please specify message text or attach an image, audio, or voice room.';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),

                          // Target URL Link (Optional)
                          TextFormField(
                            controller: _linkController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Target Link URL (Optional)',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[900],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Share Voice Room (Autocomplete search)
                          const Text('Share Voice Room (Optional)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _isLoadingRooms
                              ? const Center(child: CircularProgressIndicator())
                              : Autocomplete<Map<String, dynamic>>(
                                  optionsBuilder: (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<Map<String, dynamic>>.empty();
                                    }
                                    return _audioRooms.where((room) {
                                      final name = (room['roomName'] ?? '').toString().toLowerCase();
                                      final id = (room['roomId'] ?? room['id'] ?? '').toString().toLowerCase();
                                      final query = textEditingValue.text.toLowerCase();
                                      return name.contains(query) || id.contains(query);
                                    });
                                  },
                                  displayStringForOption: (Map<String, dynamic> option) =>
                                      '${option['roomName']} (${option['roomId'] ?? option['id']})',
                                  onSelected: (Map<String, dynamic> selection) {
                                    setState(() {
                                      _selectedRoomId = (selection['roomId'] ?? selection['id']).toString();
                                      _selectedRoomName = selection['roomName'];
                                    });
                                  },
                                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Search voice room by name or ID...',
                                        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        filled: true,
                                        fillColor: Colors.grey[900],
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                          if (_selectedRoomId != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.headset_mic, color: Colors.purpleAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sharing Voice Room: $_selectedRoomName ($_selectedRoomId)',
                                      style: const TextStyle(color: Colors.purpleAccent, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                                    onPressed: () => setState(() {
                                      _selectedRoomId = null;
                                      _selectedRoomName = null;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Media attachments selectors
                          Row(
                            children: [
                              // Picture Attachment
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey[850]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.photo, color: Colors.blue, size: 18),
                                          SizedBox(width: 6),
                                          Text('Attach Image', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (_imageBytes != null) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(_imageBytes!, height: 100, fit: BoxFit.cover),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _imageName ?? 'image.png',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                          label: const Text('Remove Image', style: TextStyle(color: Colors.red, fontSize: 12)),
                                          onPressed: () => setState(() {
                                            _imageBytes = null;
                                            _imageName = null;
                                          }),
                                        ),
                                      ] else ...[
                                        // Option 1: File Picker
                                        ElevatedButton(
                                          onPressed: _pickImage,
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                                          child: const Text('Choose Image File', style: TextStyle(color: Colors.white)),
                                        ),
                                        const SizedBox(height: 8),
                                        // Option 2: Image URL
                                        TextFormField(
                                          controller: _imageUrlController,
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                          decoration: const InputDecoration(
                                            hintText: 'Or enter direct image URL...',
                                            hintStyle: TextStyle(color: Colors.white24),
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Audio Attachment
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey[850]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.mic, color: Colors.orange, size: 18),
                                          SizedBox(width: 6),
                                          Text('Attach Voice Message', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (_audioBytes != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.audiotrack, color: Colors.orange),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _audioName ?? 'audio.mp3',
                                                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                          label: const Text('Remove Audio', style: TextStyle(color: Colors.red, fontSize: 12)),
                                          onPressed: () => setState(() {
                                            _audioBytes = null;
                                            _audioName = null;
                                          }),
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: _pickAudio,
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                                          child: const Text('Select Audio File', style: TextStyle(color: Colors.white)),
                                        ),
                                        const SizedBox(height: 28), // balance height alignment
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Visual Preview Card section
                          const Text('Live Channel Message Preview', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildLivePreviewCard(),
                          const SizedBox(height: 32),

                          // Action Send button
                          ElevatedButton(
                            onPressed: _isSending ? null : _sendBroadcast,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send),
                                const SizedBox(width: 8),
                                Text(
                                  'Send Official Notification to ${_selectedUsers.length} Users',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Sending overlay progress dialog
          if (_isSending)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.blue, strokeWidth: 4),
                        const SizedBox(height: 24),
                        Text(
                          _sendProgressStatus,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 250,
                          child: LinearProgressIndicator(
                            value: _sendProgress,
                            backgroundColor: Colors.grey[800],
                            color: Colors.blue,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_sendProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard() {
    final hasImage = _imageBytes != null || _imageUrlController.text.isNotEmpty;
    final hasAudio = _audioBytes != null;
    final hasRoom = _selectedRoomId != null;
    final rawText = _messageController.text;
    final messagePreviewText = rawText.isEmpty
        ? 'Welcome! This is where your custom notification text body goes.'
        : rawText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[950],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.campaign, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'imChat Team',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.verified, color: Colors.blue, size: 14),
                      ],
                    ),
                    const Text(
                      'Just Now',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Text Message body
                Text(
                  messagePreviewText,
                  style: TextStyle(
                    color: rawText.isEmpty ? Colors.grey[600] : Colors.white,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                
                // Embedded Image Preview
                if (hasImage) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, height: 140, width: double.infinity, fit: BoxFit.cover)
                        : Image.network(
                            _imageUrlController.text.trim(),
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 140,
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: Colors.red, size: 36),
                                ),
                              );
                            },
                          ),
                  ),
                ],

                // Embedded Audio Player Bubble Preview
                if (hasAudio) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Container(
                          width: 120,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 30,
                              height: 3,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '0:05',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],

                // Embedded Room Join card preview
                if (hasRoom) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.headset_mic, color: Colors.purpleAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRoomName ?? 'Live Voice Room',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Tap to join live voice room!',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.purpleAccent, size: 12),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
