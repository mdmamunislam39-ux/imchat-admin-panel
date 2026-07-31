import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getFeedbackStream(String status) {
    return FirebaseFirestore.instance
        .collection('feedbacks')
        .where('status', isEqualTo: status)
        .limit(100)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          'Feedback Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_empty, size: 16),
                  SizedBox(width: 6),
                  Text('Pending'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 6),
                  Text('In Review'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16),
                  SizedBox(width: 6),
                  Text('Resolved'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedbackList('pending'),
          _buildFeedbackList('in_review'),
          _buildFeedbackList('resolved'),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFeedbackStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 12),
                Text(
                  'No $status feedbacks',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Sort client-side by createdAt descending (avoids composite index requirement)
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
        sortedDocs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildFeedbackCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildFeedbackCard(String docId, Map<String, dynamic> data) {
    final hasReply = data['adminReply'] != null &&
        (data['adminReply'] as String).isNotEmpty;
    final category = data['category'] ?? 'General';

    final createdAt = data['createdAt'];
    String dateStr = '';
    if (createdAt is Timestamp) {
      dateStr =
          DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate());
    }

    Color categoryColor;
    switch (category) {
      case 'Bug Report':
        categoryColor = Colors.redAccent;
        break;
      case 'Feature Request':
        categoryColor = Colors.blueAccent;
        break;
      case 'Voice Room Issue':
        categoryColor = Colors.orangeAccent;
        break;
      case 'Payment Issue':
        categoryColor = Colors.amber;
        break;
      case 'Account Issue':
        categoryColor = Colors.tealAccent;
        break;
      default:
        categoryColor = Colors.purpleAccent;
    }

    return Card(
      color: const Color(0xFF161B22),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showFeedbackDetail(docId, data),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: User info + category
              Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: (data['userPhoto'] != null &&
                            (data['userPhoto'] as String).isNotEmpty)
                        ? NetworkImage(data['userPhoto'])
                        : null,
                    child: (data['userPhoto'] == null ||
                            (data['userPhoto'] as String).isEmpty)
                        ? const Icon(Icons.person, color: Colors.grey, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['userName'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'ID: ${data['searchId'] ?? data['userId'] ?? ''}',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(color: categoryColor, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Subject
              Text(
                data['subject'] ?? 'No subject',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              // Message preview
              Text(
                data['message'] ?? '',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Footer: date + reply indicator
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                  const Spacer(),
                  if (hasReply)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.reply, size: 14, color: Colors.greenAccent),
                        const SizedBox(width: 4),
                        const Text(
                          'Replied',
                          style: TextStyle(
                              color: Colors.greenAccent, fontSize: 11),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDetail(String docId, Map<String, dynamic> data) {
    final replyController =
        TextEditingController(text: data['adminReply'] ?? '');
    String selectedStatus = data['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final createdAt = data['createdAt'];
            String dateStr = '';
            if (createdAt is Timestamp) {
              dateStr = DateFormat('dd MMM yyyy, hh:mm a')
                  .format(createdAt.toDate());
            }

            return Dialog(
              backgroundColor: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: 600,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Icon(Icons.feedback,
                              color: Colors.purpleAccent, size: 24),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Feedback Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.grey, height: 24),

                      // User info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: (data['userPhoto'] != null &&
                                    (data['userPhoto'] as String).isNotEmpty)
                                ? NetworkImage(data['userPhoto'])
                                : null,
                            child: (data['userPhoto'] == null ||
                                    (data['userPhoto'] as String).isEmpty)
                                ? const Icon(Icons.person,
                                    color: Colors.grey, size: 24)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['userName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'ID: ${data['searchId'] ?? data['userId'] ?? ''}',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(dateStr,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category + Status
                      Row(
                        children: [
                          _chipBadge(
                              'Category: ${data['category'] ?? 'General'}',
                              Colors.purpleAccent),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Subject
                      const Text('Subject',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        data['subject'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),

                      // Message
                      const Text('Message',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['message'] ?? '',
                          style: TextStyle(
                              color: Colors.grey[300], fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Status Selector
                      const Text('Update Status',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF161B22),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            items: const [
                              DropdownMenuItem(
                                  value: 'pending', child: Text('⏳ Pending')),
                              DropdownMenuItem(
                                  value: 'in_review',
                                  child: Text('👁️ In Review')),
                              DropdownMenuItem(
                                  value: 'resolved',
                                  child: Text('✅ Resolved')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedStatus = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Admin Reply
                      const Text('Admin Reply',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: replyController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              'Write your reply to the user...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: const Color(0xFF0D1117),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Colors.purpleAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _saveReply(
                                  docId,
                                  replyController.text.trim(),
                                  selectedStatus),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purpleAccent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Save & Reply',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),

                      // Delete button
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => _deleteFeedback(docId),
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red, size: 18),
                          label: const Text('Delete Feedback',
                              style:
                                  TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _chipBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Future<void> _saveReply(
      String docId, String reply, String status) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reply.isNotEmpty) {
        updateData['adminReply'] = reply;
        updateData['adminReplyAt'] = FieldValue.serverTimestamp();
        updateData['repliedBy'] = 'admin';
      }

      await FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(docId)
          .update(updateData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback updated successfully! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFeedback(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Delete Feedback',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete this feedback?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('feedbacks')
            .doc(docId)
            .delete();

        if (mounted) {
          Navigator.pop(context); // close detail dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feedback deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
