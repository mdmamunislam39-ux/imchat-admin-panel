import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../models/channel_model.dart';
import '../models/channel_post_model.dart';
import '../services/channel_service.dart';
import '../services/official_notification_service.dart';
import '../services/firebase_data_service.dart';

class ChannelPostComposerScreen extends StatefulWidget {
  final ChannelModel channel;

  const ChannelPostComposerScreen({super.key, required this.channel});

  @override
  State<ChannelPostComposerScreen> createState() => _ChannelPostComposerScreenState();
}

class _ChannelPostComposerScreenState extends State<ChannelPostComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
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

      final numQuery = int.tryParse(query);
      if (numQuery != null) {
        snap = await q.where('searchId', isEqualTo: numQuery).limit(20).get();
      }

      if (snap == null || snap.docs.isEmpty) {
        snap = await q.where('searchId', isEqualTo: query).limit(20).get();
      }

      if (snap.docs.isEmpty) {
        snap = await q
            .where('username', isGreaterThanOrEqualTo: query)
            .where('username', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(25)
            .get();
      }

      if (snap.docs.isEmpty) {
        snap = await q
            .where('fullname', isGreaterThanOrEqualTo: query)
            .where('fullname', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(25)
            .get();
      }

      if (snap.docs.isEmpty && query.length >= 20) {
        final doc = await q.doc(query).get();
        if (doc.exists) {
          _displayUsers([doc]);
          return;
        }
      }

      if (snap.docs.isNotEmpty) {
        _displayUsers(snap.docs);
      } else {
        setState(() => _searchedUsers = []);
      }
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
          'id': doc.id,
          'userId': doc.id,
          'fullname': data['fullname'] ?? data['name'] ?? 'Unknown User',
          'searchId': data['searchId']?.toString() ?? '',
          'deviceToken': data['deviceToken'] ?? '',
          'profileImageUrl': data['profileImageUrl'] ?? data['imageUrl'] ?? '',
        };
      }).toList();
    });
  }

  Future<void> _applyTargetGroup(String group) async {
    setState(() {
      _selectedTargetGroup = group;
      _isLoadingDefaultUsers = true;
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
      } else if (group == 'new_user') {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        final snap = await q
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
            .get();
        docs = snap.docs;
      }

      setState(() {
        _selectedUsers.clear();
        _displayUsers(docs);
        for (var u in _searchedUsers) {
          _selectedUsers[u['id']] = u;
        }
      });
    } catch (e) {
      debugPrint('Error applying target group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load group users: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingDefaultUsers = false);
    }
  }

  // --- Pick File Logic ---

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imageBytes = result.files.first.bytes;
          _imageName = result.files.first.name;
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
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
        const SnackBar(content: Text('Please select at least one recipient subscriber.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_messageController.text.trim().isEmpty &&
        _imageBytes == null &&
        _imageUrlController.text.trim().isEmpty &&
        _audioBytes == null &&
        _selectedRoomId == null &&
        _linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter message text or attach a file/link/voice room.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _sendProgress = 0.0;
      _sendProgressStatus = 'Initializing...';
    });

    try {
      String? uploadedImageUrl = _imageUrlController.text.trim().isNotEmpty 
          ? _imageUrlController.text.trim() 
          : null;

      if (_imageBytes != null && _imageName != null) {
        setState(() => _sendProgressStatus = 'Uploading Image File...');
        uploadedImageUrl = await OfficialNotificationService.uploadFile(
          bytes: _imageBytes!,
          name: _imageName!,
          path: 'official_channels/posts',
        );
      }

      String? uploadedAudioUrl;
      if (_audioBytes != null && _audioName != null) {
        setState(() => _sendProgressStatus = 'Uploading Audio File...');
        uploadedAudioUrl = await OfficialNotificationService.uploadFile(
          bytes: _audioBytes!,
          name: _audioName!,
          path: 'official_channels/posts',
        );
      }

      final post = ChannelPostModel(
        id: '',
        channelId: widget.channel.id,
        textContent: _messageController.text.isEmpty ? null : _messageController.text,
        imageUrl: uploadedImageUrl,
        audioUrl: uploadedAudioUrl,
        linkUrl: _linkController.text.isEmpty ? null : _linkController.text,
        voiceRoomId: _selectedRoomId,
        createdAt: DateTime.now(),
      );

      final targetUsers = _selectedUsers.values.toList();
      setState(() => _sendProgressStatus = 'Broadcasting to subscribers...');
      
      await ChannelService.createPost(post, targetUsers: targetUsers);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel post sent successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error sending channel post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send broadcast: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendProgress = 0.0;
          _sendProgressStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        title: Text('New Channel Post: ${widget.channel.name}'),
      ),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Left Column: Search & Select ---
              Expanded(
                flex: 5,
                child: Container(
                  color: Colors.grey[900],
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Target Audience Group',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTargetGroup,
                            dropdownColor: Colors.grey[850],
                            style: const TextStyle(color: Colors.white),
                            items: const [
                              DropdownMenuItem(value: 'custom', child: Text('Custom Selection (Search below)')),
                              DropdownMenuItem(value: 'all', child: Text('All Users')),
                              DropdownMenuItem(value: 'host', child: Text('Only Hosts')),
                              DropdownMenuItem(value: 'agency', child: Text('Only Agency Owners')),
                              DropdownMenuItem(value: 'seller', child: Text('Only Sellers')),
                              DropdownMenuItem(value: 'new_user', child: Text('New Users (Last 7 Days)')),
                            ],
                            onChanged: _isSending
                                ? null
                                : (val) {
                                    if (val != null) {
                                      if (val == 'custom') {
                                        setState(() {
                                          _selectedTargetGroup = val;
                                          _selectedUsers.clear();
                                        });
                                        _loadDefaultUsers();
                                      } else {
                                        _applyTargetGroup(val);
                                      }
                                    }
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Search Subscribers (${_selectedUsers.length} selected)',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        enabled: !_isSending,
                        decoration: InputDecoration(
                          hintText: 'Search by User ID, Name, or Username...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: _isSending
                                ? null
                                : () {
                                    setState(() {
                                      _selectedTargetGroup = 'custom';
                                      for (var user in _searchedUsers) {
                                        _selectedUsers[user['id']] = user;
                                      }
                                    });
                                  },
                            icon: const Icon(Icons.select_all, size: 18),
                            label: const Text('Select Page'),
                            style: TextButton.styleFrom(foregroundColor: Colors.blue),
                          ),
                          TextButton.icon(
                            onPressed: _isSending
                                ? null
                                : () {
                                    setState(() {
                                      _selectedTargetGroup = 'custom';
                                      _selectedUsers.clear();
                                    });
                                  },
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Clear All'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.grey, height: 1),
                      Expanded(
                        child: _isLoadingDefaultUsers
                            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                            : _searchedUsers.isEmpty
                                ? Center(
                                    child: Text(
                                      _isSearchingUsers ? 'Searching...' : 'No users found.',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _searchedUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = _searchedUsers[index];
                                      final id = user['id'];
                                      final isSelected = _selectedUsers.containsKey(id);

                                      return CheckboxListTile(
                                        value: isSelected,
                                        activeColor: Colors.blue,
                                        checkColor: Colors.white,
                                        title: Text(
                                          user['fullname'],
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          'ID: ${user['searchId']} ${user['deviceToken'].isNotEmpty ? "â€¢ Push Enabled" : "â€¢ No Push"}',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                        ),
                                        secondary: CircleAvatar(
                                          backgroundColor: Colors.grey[800],
                                          backgroundImage: user['profileImageUrl'].isNotEmpty
                                              ? NetworkImage(user['profileImageUrl'])
                                              : null,
                                          child: user['profileImageUrl'].isEmpty
                                              ? const Icon(Icons.person, color: Colors.grey)
                                              : null,
                                        ),
                                        onChanged: _isSending
                                            ? null
                                            : (bool? checked) {
                                                setState(() {
                                                  _selectedTargetGroup = 'custom';
                                                  if (checked == true) {
                                                    _selectedUsers[id] = user;
                                                  } else {
                                                    _selectedUsers.remove(id);
                                                  }
                                                });
                                              },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(color: Colors.grey, width: 1),

              // --- Right Column: Composer & Live Preview ---
              Expanded(
                flex: 7,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Compose Channel Post',
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Message text
                        TextFormField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 4,
                          enabled: !_isSending,
                          decoration: InputDecoration(
                            labelText: 'Message Body Text',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            hintText: 'Type your channel update message here...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Image attachment row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _imageUrlController,
                                style: const TextStyle(color: Colors.white),
                                enabled: !_isSending,
                                decoration: InputDecoration(
                                  labelText: 'Image Web URL (Optional)',
                                  labelStyle: TextStyle(color: Colors.grey[400]),
                                  hintText: 'https://example.com/image.png',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey[700]!),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blue),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[900],
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _isSending ? null : _pickImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[850],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.image),
                              label: Text(_imageBytes != null ? 'Picked âœ…' : 'Upload'),
                            ),
                          ],
                        ),
                        if (_imageName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Selected file: $_imageName',
                            style: const TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Audio file row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[700]!),
                                ),
                                child: Text(
                                  _audioName != null ? 'Voice Message File: $_audioName' : 'Attach Voice Message (Optional)',
                                  style: TextStyle(
                                    color: _audioName != null ? Colors.white : Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _isSending ? null : _pickAudio,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[850],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.mic),
                              label: Text(_audioBytes != null ? 'Picked âœ…' : 'Pick Audio'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Link URL
                        TextFormField(
                          controller: _linkController,
                          style: const TextStyle(color: Colors.white),
                          enabled: !_isSending,
                          decoration: InputDecoration(
                            labelText: 'Link URL (Optional)',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            hintText: 'https://example.com/page',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),

                        // Audio rooms autocomplete dropdown
                        Text(
                          'Share Audio Room Link (Optional)',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        _isLoadingRooms
                            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
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
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.grey[700]!),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.blue),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        if (_selectedRoomId != null) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isSending
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedRoomId = null;
                                        _selectedRoomName = null;
                                      });
                                    },
                              child: const Text('Clear Shared Room', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),

                        // --- Live Visual Preview ---
                        Text(
                          'Live Visual Preview (Mobile Style)',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[850]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue,
                                backgroundImage: widget.channel.imageUrl.isNotEmpty
                                    ? NetworkImage(widget.channel.imageUrl)
                                    : null,
                                child: widget.channel.imageUrl.isEmpty
                                    ? const Icon(Icons.chat_bubble, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          widget.channel.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, color: Colors.blue, size: 14),
                                        const Spacer(),
                                        Text(
                                          'Just now',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (_messageController.text.trim().isNotEmpty) ...[
                                      Text(
                                        _messageController.text,
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (_imageBytes != null) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          _imageBytes!,
                                          width: double.infinity,
                                          height: 180,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ] else if (_imageUrlController.text.trim().isNotEmpty) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _imageUrlController.text.trim(),
                                          width: double.infinity,
                                          height: 180,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 80,
                                            color: Colors.grey[900],
                                            alignment: Alignment.center,
                                            child: const Text('Invalid image URL format', style: TextStyle(color: Colors.red)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (_audioBytes != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[900],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.play_arrow, color: Colors.blue),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Text(
                                                'ðŸ”Š Voice Message attached',
                                                style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Text(
                                              _audioName ?? '',
                                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (_linkController.text.trim().isNotEmpty) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.link, color: Colors.blue, size: 16),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _linkController.text.trim(),
                                              style: const TextStyle(color: Colors.blue, fontSize: 12, decoration: TextDecoration.underline),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (_selectedRoomId != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.headset_mic, color: Colors.purple, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Join voice room: ${_selectedRoomName ?? _selectedRoomId}',
                                                style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Action buttons
                        ElevatedButton(
                          onPressed: _isSending ? null : _sendBroadcast,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Send Post to Selected Subscribers',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Broadcast transmission overlay modal
          if (_isSending)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 60,
                          width: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Broadcasting Channel Post',
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _sendProgressStatus,
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 300,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _sendProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${(_sendProgress * 100).toInt()}% Completed',
                          style: const TextStyle(color: Colors.grey),
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
}
