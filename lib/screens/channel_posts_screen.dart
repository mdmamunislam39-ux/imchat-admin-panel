import 'package:flutter/material.dart';
import '../models/channel_model.dart';
import '../models/channel_post_model.dart';
import '../services/channel_service.dart';
import '../widgets/media_preview_widget.dart';
import 'channel_post_composer_screen.dart';

class ChannelPostsScreen extends StatefulWidget {
  final ChannelModel channel;

  const ChannelPostsScreen({super.key, required this.channel});

  @override
  State<ChannelPostsScreen> createState() => _ChannelPostsScreenState();
}

class _ChannelPostsScreenState extends State<ChannelPostsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${widget.channel.name} Posts'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChannelPostComposerScreen(channel: widget.channel),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ChannelPostModel>>(
        stream: ChannelService.getChannelPostsStream(widget.channel.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'No posts yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Posted: ${post.createdAt.toLocal().toString().split('.')[0]}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              ChannelService.deletePost(post.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (post.textContent != null &&
                          post.textContent!.isNotEmpty) ...[
                        Text(
                          post.textContent!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (post.imageUrl != null &&
                          post.imageUrl!.isNotEmpty) ...[
                        MediaPreviewWidget(
                          url: post.imageUrl!,
                          width: double.infinity,
                          height: 200,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (post.audioUrl != null &&
                          post.audioUrl!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.audiotrack, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Voice Message: ${post.audioUrl}',
                                  style: const TextStyle(color: Colors.green),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (post.linkUrl != null && post.linkUrl!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.link, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                post.linkUrl!,
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (post.voiceRoomId != null &&
                          post.voiceRoomId!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.headset_mic,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Join Room ID: ${post.voiceRoomId}',
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
