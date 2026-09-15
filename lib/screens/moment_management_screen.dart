import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../models/moment_post_model.dart';
import '../services/moment_management_service.dart';

class MomentManagementScreen extends StatefulWidget {
  const MomentManagementScreen({super.key});

  @override
  State<MomentManagementScreen> createState() => _MomentManagementScreenState();
}

class _MomentManagementScreenState extends State<MomentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBg = Color(0xFF120B1C);
    const cardBg = Color(0xFF1E142B);

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Row(
          children: [
            Icon(Icons.dynamic_feed, color: Colors.purpleAccent),
            SizedBox(width: 10),
            Text(
              'imChat Moment Management',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          indicatorWeight: 3,
          labelColor: Colors.purpleAccent,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: 'Notice Board'),
            Tab(icon: Icon(Icons.report_problem), text: 'Reported Posts'),
            Tab(icon: Icon(Icons.grid_view), text: 'All Moments'),
            Tab(icon: Icon(Icons.ads_click), text: 'AdSense Config'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NoticeBoardTab(),
          _ReportedPostsTab(),
          _AllMomentsTab(),
          _AdSenseConfigTab(),
        ],
      ),
    );
  }
}

// ─── 1. NOTICE BOARD TAB ───────────────────────────────────────────────────

class _NoticeBoardTab extends StatefulWidget {
  const _NoticeBoardTab();

  @override
  State<_NoticeBoardTab> createState() => _NoticeBoardTabState();
}

class _NoticeBoardTabState extends State<_NoticeBoardTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isPinned = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'mp4', 'mov'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFileBytes = result.files.first.bytes;
          _selectedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _publishNotice() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter notice title and text.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await MomentManagementService.createNoticePost(
      title: title,
      content: content,
      mediaBytes: _selectedFileBytes,
      mediaFileName: _selectedFileName,
      isPinned: _isPinned,
    );

    setState(() => _isSubmitting = false);

    if (result != null) {
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _selectedFileBytes = null;
        _selectedFileName = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Official Notice published to imChat Moment!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to publish notice. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Notice Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E142B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_alert_rounded, color: Colors.amberAccent, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Publish Official Notice to imChat Moment Feed',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Notice Title',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF120B1C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Notice Content / Description',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF120B1C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickMedia,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text(_selectedFileName == null
                          ? 'Attach Image/Video'
                          : 'Change Media'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pin to Top', style: TextStyle(color: Colors.white70)),
                        Switch(
                          value: _isPinned,
                          onChanged: (val) => setState(() => _isPinned = val),
                          activeThumbColor: Colors.purpleAccent,
                        ),
                      ],
                    ),
                  ],
                ),
                if (_selectedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Attached File: $_selectedFileName',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                          onPressed: () => setState(() {
                            _selectedFileBytes = null;
                            _selectedFileName = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _publishNotice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Publish Notice Now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          const Text(
            'Active Official Notices',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Published Notices List Stream
          StreamBuilder<List<NewsFeedPost>>(
            stream: MomentManagementService.getNoticesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: Colors.purpleAccent),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E142B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No active official notices found.',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                  ),
                );
              }

              final notices = snapshot.data!;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notices.length,
                itemBuilder: (context, index) {
                  final notice = notices[index];
                  return Card(
                    color: const Color(0xFF1E142B),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.purple.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber,
                        backgroundImage: notice.userAvatar != null && notice.userAvatar!.isNotEmpty
                            ? NetworkImage(notice.userAvatar!)
                            : null,
                        child: notice.userAvatar == null || notice.userAvatar!.isEmpty
                            ? const Icon(Icons.campaign, color: Colors.black)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Text(
                            notice.noticeTitle ?? 'Official Notice',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                          const Spacer(),
                          if (notice.isPinned)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purpleAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'PINNED',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            notice.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notice.timeAgo,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Delete Notice',
                        onPressed: () => _confirmDeleteNotice(notice.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteNotice(String noticeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E142B),
        title: const Text('Delete Notice', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove this official notice?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await MomentManagementService.deletePost(noticeId);
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Notice deleted successfully.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── 2. REPORTED POSTS TAB ─────────────────────────────────────────────────

class _ReportedPostsTab extends StatelessWidget {
  const _ReportedPostsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: MomentManagementService.getReportedPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purpleAccent),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64),
                SizedBox(height: 14),
                Text(
                  'No reported moments pending review.',
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final reports = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index].data();
            final reportId = reports[index].id;
            final postId = report['postId'] ?? '';
            final reason = report['reason'] ?? 'Violation of Terms';
            final details = report['details'] ?? '';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('news_feed_posts').doc(postId).get(),
              builder: (context, postSnap) {
                if (!postSnap.hasData || !postSnap.data!.exists) {
                  return const SizedBox.shrink();
                }

                final postData = postSnap.data!.data() as Map<String, dynamic>?;
                if (postData == null || (postData['isDeleted'] ?? false)) {
                  return const SizedBox.shrink();
                }

                final post = NewsFeedPost.fromFirestore(postSnap.data!);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E142B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Report Reason Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.report, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  reason,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            post.timeAgo,
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                      if (details.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Report Note: $details',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Reported Post Author Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: post.userAvatar != null ? NetworkImage(post.userAvatar!) : null,
                            child: post.userAvatar == null ? const Icon(Icons.person) : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.userName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                'User ID: ${post.userId}',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.content.isEmpty ? '[No Text Content]' : post.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),

                      const SizedBox(height: 18),

                      // Action Buttons: Delete Post or Dismiss Report
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await MomentManagementService.deleteReportedPost(postId, reportId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Post deleted and report marked as resolved.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                              label: const Text('Delete Post'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await MomentManagementService.dismissReport(reportId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Report dismissed.'),
                                      backgroundColor: Colors.grey,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check, color: Colors.greenAccent, size: 18),
                              label: const Text('Dismiss', style: TextStyle(color: Colors.greenAccent)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.greenAccent),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── 3. ALL MOMENTS MANAGEMENT TAB ─────────────────────────────────────────

class _AllMomentsTab extends StatelessWidget {
  const _AllMomentsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NewsFeedPost>>(
      stream: MomentManagementService.getAllMomentsStream(limit: 60),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purpleAccent),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No moments posts found.', style: TextStyle(color: Colors.white54, fontSize: 16)),
          );
        }

        final posts = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final hasVideo = post.media.any((m) => m.type == 'video');
            final hasImage = post.media.any((m) => m.type == 'image');

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E142B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: post.isPinned
                      ? Colors.purpleAccent.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: post.userAvatar != null ? NetworkImage(post.userAvatar!) : null,
                    child: post.userAvatar == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (post.isNotice)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NOTICE',
                                  style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (hasVideo)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'VIDEO',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (hasImage && !hasVideo)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'IMAGE',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              post.timeAgo,
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.content.isEmpty ? '[Media Content]' : post.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Likes: ${post.likeCount}  |  Comments: ${post.commentCount}  |  Reports: ${post.reportCount}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      post.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: post.isPinned ? Colors.purpleAccent : Colors.white38,
                    ),
                    tooltip: post.isPinned ? 'Unpin' : 'Pin',
                    onPressed: () => MomentManagementService.togglePinPost(post.id, !post.isPinned),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Delete Post',
                    onPressed: () => MomentManagementService.deletePost(post.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── 4. ADSENSE CONFIG TAB ─────────────────────────────────────────────────

class _AdSenseConfigTab extends StatefulWidget {
  const _AdSenseConfigTab();

  @override
  State<_AdSenseConfigTab> createState() => _AdSenseConfigTabState();
}

class _AdSenseConfigTabState extends State<_AdSenseConfigTab> {
  // Ad Unit IDs
  final TextEditingController _bannerIdController = TextEditingController();
  final TextEditingController _interstitialIdController = TextEditingController();
  final TextEditingController _nativeIdController = TextEditingController();

  // Placement Toggles
  bool _adsEnabled = true;
  bool _showInFeed = true;
  bool _showInReels = true;
  bool _showInPostDetails = true;
  bool _showInComments = false;

  // Frequency & Interval Settings
  final TextEditingController _feedAdIntervalController = TextEditingController(text: '4');
  final TextEditingController _reelsAdIntervalController = TextEditingController(text: '5');
  final TextEditingController _interstitialIntervalController = TextEditingController(text: '5');
  final TextEditingController _maxAdsPerSessionController = TextEditingController(text: '10');

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _bannerIdController.dispose();
    _interstitialIdController.dispose();
    _nativeIdController.dispose();
    _feedAdIntervalController.dispose();
    _reelsAdIntervalController.dispose();
    _interstitialIntervalController.dispose();
    _maxAdsPerSessionController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final data = await MomentManagementService.getAdSettings();
      if (data != null) {
        _adsEnabled = data['adsEnabled'] ?? true;
        _bannerIdController.text = data['bannerUnitId'] ?? 'ca-app-pub-3940256099942544/6300978111';
        _interstitialIdController.text = data['interstitialUnitId'] ?? 'ca-app-pub-3940256099942544/1033173712';
        _nativeIdController.text = data['nativeUnitId'] ?? 'ca-app-pub-3940256099942544/2247696110';

        _showInFeed = data['showInFeed'] ?? true;
        _showInReels = data['showInReels'] ?? true;
        _showInPostDetails = data['showInPostDetails'] ?? true;
        _showInComments = data['showInComments'] ?? false;

        _feedAdIntervalController.text = (data['feedAdInterval'] ?? 4).toString();
        _reelsAdIntervalController.text = (data['reelsAdInterval'] ?? 5).toString();
        _interstitialIntervalController.text = (data['interstitialIntervalMinutes'] ?? 5).toString();
        _maxAdsPerSessionController.text = (data['maxAdsPerSession'] ?? 10).toString();
      } else {
        _bannerIdController.text = 'ca-app-pub-3940256099942544/6300978111';
        _interstitialIdController.text = 'ca-app-pub-3940256099942544/1033173712';
        _nativeIdController.text = 'ca-app-pub-3940256099942544/2247696110';
      }
    } catch (e) {
      debugPrint('Error loading ad settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);

    final configMap = {
      'adsEnabled': _adsEnabled,
      'bannerUnitId': _bannerIdController.text.trim(),
      'interstitialUnitId': _interstitialIdController.text.trim(),
      'nativeUnitId': _nativeIdController.text.trim(),
      
      // Placements
      'showInFeed': _showInFeed,
      'showInReels': _showInReels,
      'showInPostDetails': _showInPostDetails,
      'showInComments': _showInComments,

      // Frequency & Intervals
      'feedAdInterval': int.tryParse(_feedAdIntervalController.text.trim()) ?? 4,
      'reelsAdInterval': int.tryParse(_reelsAdIntervalController.text.trim()) ?? 5,
      'interstitialIntervalMinutes': int.tryParse(_interstitialIntervalController.text.trim()) ?? 5,
      'maxAdsPerSession': int.tryParse(_maxAdsPerSessionController.text.trim()) ?? 10,
    };

    await MomentManagementService.updateAdSettings(configMap);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ AdSense / AdMob settings & placement details updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
    }

    const cardBg = Color(0xFF1E142B);
    const fieldBg = Color(0xFF120B1C);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Master Toggle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.ads_click, color: Colors.amberAccent, size: 30),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google AdSense / AdMob Control Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Configure ad placements, units & display frequency',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      _adsEnabled ? 'Ads Active' : 'Ads Disabled',
                      style: TextStyle(
                        color: _adsEnabled ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _adsEnabled,
                      onChanged: (val) => setState(() => _adsEnabled = val),
                      activeThumbColor: Colors.purpleAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SECTION 1: AD PLACEMENT LOCATIONS (কোন কোন জায়গায় দেখানো হবে)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.place_outlined, color: Colors.cyanAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Ad Placement Locations (কোন কোন জায়গায় বিজ্ঞাপন দেখাবে)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                
                SwitchListTile(
                  title: const Text('Show Ads in News Feed (মুহুর্ত ফিড তালিকা)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Insert banner/native ads between feed posts', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  value: _showInFeed,
                  onChanged: (val) => setState(() => _showInFeed = val),
                  activeThumbColor: Colors.purpleAccent,
                ),
                SwitchListTile(
                  title: const Text('Show Ads in Moment Reels (ভিডিও রিলস সেকশন)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Display ads while user scrolls video reels', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  value: _showInReels,
                  onChanged: (val) => setState(() => _showInReels = val),
                  activeThumbColor: Colors.purpleAccent,
                ),
                SwitchListTile(
                  title: const Text('Show Ads in Single Post View (পোস্ট ডিটেইলস স্ক্রিন)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Display banner ad inside individual post screen', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  value: _showInPostDetails,
                  onChanged: (val) => setState(() => _showInPostDetails = val),
                  activeThumbColor: Colors.purpleAccent,
                ),
                SwitchListTile(
                  title: const Text('Show Ads in Comments Sheet (কমেন্ট সেকশন)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Display banner ad inside post comments bottom sheet', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  value: _showInComments,
                  onChanged: (val) => setState(() => _showInComments = val),
                  activeThumbColor: Colors.purpleAccent,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SECTION 2: DISPLAY FREQUENCY & INTERVALS (কতক্ষণ বা কত পোস্ট পর পর দেখানো হবে)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Display Frequency & Intervals (কতক্ষণ বা কত পোস্ট পর পর দেখানো হবে)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _feedAdIntervalController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'News Feed Post Interval (পোস্ট সংখ্যা)',
                          hintText: 'e.g. 4 (Show ad after every 4 posts)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: fieldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.purpleAccent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _reelsAdIntervalController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Reels Video Interval (রিলস সংখ্যা)',
                          hintText: 'e.g. 5 (Show ad after every 5 reels)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: fieldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.purpleAccent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _interstitialIntervalController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Interstitial Cooldown (ফুল স্ক্রিন এড মিনিট)',
                          hintText: 'e.g. 5 (Min 5 mins between full ads)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: fieldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.purpleAccent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _maxAdsPerSessionController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Max Ads Per Session (সেশনে সর্বোচ্চ এড)',
                          hintText: 'e.g. 10 (Max ads user can see)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: fieldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.purpleAccent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SECTION 3: AD UNIT IDS (বিজ্ঞাপন ইউনিট আইডিসমূহ)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, color: Colors.amberAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'AdMob / AdSense Unit IDs (বিজ্ঞাপন ইউনিট কোড)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),

                TextField(
                  controller: _bannerIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Banner Ad Unit ID (ব্যনার বিজ্ঞাপন)',
                    hintText: 'ca-app-pub-3940256099942544/6300978111',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: fieldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _interstitialIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Interstitial Ad Unit ID (ফুল স্ক্রিন স্লাইড বিজ্ঞাপন)',
                    hintText: 'ca-app-pub-3940256099942544/1033173712',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: fieldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nativeIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Native / Video Ad Unit ID (নেটিভ/ভিডিও বিজ্ঞাপন)',
                    hintText: 'ca-app-pub-3940256099942544/2247696110',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: fieldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // SAVE BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Save Complete Ad Configurations',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
