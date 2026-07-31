import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event_model.dart';
import '../services/firebase_data_service.dart';
import '../widgets/media_preview_widget.dart';
import 'event_form_screen.dart'; 
import 'event_dashboard_screen.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  List<EventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final eventsData = await FirebaseDataService.getAllEvents();
    setState(() {
      _events = eventsData.map((e) => EventModel.fromMap(e, e['id'])).toList();
      _isLoading = false;
    });
  }

  void _copyEventInfo(EventModel event) {
    final info = '''
Event ID: ${event.eventId}
Event Name: ${event.eventName}
Event Link: ${event.eventLink}
Deep Link: ${event.deepLink}
Rules: ${event.rules}
Rewards: ${event.rewards.map((r) => '[${r['rank'] ?? 'All'}] ${r['itemName'] ?? r['category']}: ${r['amount'] ?? 0}').join(', ')}
Share Text: Check out ${event.eventName}! Join now: ${event.eventLink}
''';
    Clipboard.setData(ClipboardData(text: info));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied Event Info to Clipboard')));
  }

  Future<void> _deleteEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Event', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this event?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseDataService.deleteEvent(id);
      _loadEvents();
    }
  }

  void _duplicateEvent(EventModel event) async {
     final newEventId = 'EVT${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
     final newEvent = event.toMap();
     newEvent['eventId'] = newEventId;
     newEvent['eventName'] = '${event.eventName} (Copy)';
     newEvent['createdAt'] = DateTime.now();
     newEvent['eventLink'] = 'https://appdomain.com/event/$newEventId';
     newEvent['deepLink'] = 'imchat://event/$newEventId';
     
     await FirebaseDataService.createEvent(newEvent);
     _loadEvents();
     if (!mounted) return;
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event duplicated successfully')));
  }

  Future<void> _toggleStatus(EventModel event, String newStatus) async {
     await FirebaseDataService.updateEvent(event.id, {'status': newStatus});
     _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Event Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.grey[900],
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const Text(
                      'Choose Event Template',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTemplateItem(
                      context,
                      'Weekly Star Event',
                      'weekly_star',
                      Icons.star_rounded,
                      Colors.amber,
                    ),
                    _buildTemplateItem(
                      context,
                      'Game Star Event',
                      'game_star',
                      Icons.videogame_asset_rounded,
                      Colors.purple,
                    ),
                    _buildTemplateItem(
                      context,
                      'Top Gifter & Receiver Event',
                      'gifter_receiver',
                      Icons.card_giftcard_rounded,
                      Colors.pink,
                    ),
                    _buildTemplateItem(
                      context,
                      'Top Room Event',
                      'top_room',
                      Icons.home_work_rounded,
                      Colors.cyan,
                    ),
                    _buildTemplateItem(
                      context,
                      'Top Active Event',
                      'top_active',
                      Icons.flash_on_rounded,
                      Colors.orange,
                    ),
                    _buildTemplateItem(
                      context,
                      'Top Recharge Event',
                      'recharge',
                      Icons.account_balance_wallet_rounded,
                      Colors.tealAccent,
                    ),
                    _buildTemplateItem(
                      context,
                      'Agency Battle Event',
                      'agency_battle',
                      Icons.shield_rounded,
                      Colors.deepOrangeAccent,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                ),
              );
            },
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _events.isEmpty
              ? const Center(child: Text('No events found.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: event.banner.isNotEmpty
                            ? MediaPreviewWidget(url: event.banner, width: 60, height: 60)
                            : Container(width: 60, height: 60, color: Colors.grey[800], child: const Icon(Icons.event, color: Colors.grey)),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${event.eventName} (${event.eventId})',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.blue, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: event.eventId));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event ID copied to clipboard!')));
                                }
                              },
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Status: ${event.status.toUpperCase()}', style: TextStyle(color: event.status == 'active' ? Colors.green : event.status == 'expired' ? Colors.red : Colors.orange)),
                            Text('Starts: ${event.startTime.toLocal().toString().split('.')[0]}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('Ends: ${event.endTime.toLocal().toString().split('.')[0]}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: Colors.grey[850],
                          onSelected: (value) async {
                            switch (value) {
                              case 'dashboard':
                                Navigator.push(context, MaterialPageRoute(builder: (_) => EventDashboardScreen(event: event)));
                                break;
                              case 'edit':
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => EventFormScreen(event: event)));
                                _loadEvents();
                                break;
                              case 'copy':
                                _copyEventInfo(event);
                                break;
                              case 'duplicate':
                                _duplicateEvent(event);
                                break;
                              case 'activate':
                                _toggleStatus(event, 'active');
                                break;
                              case 'deactivate':
                                _toggleStatus(event, 'inactive');
                                break;
                              case 'expire':
                                _toggleStatus(event, 'expired');
                                break;
                              case 'delete':
                                _deleteEvent(event.id);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'dashboard', child: Text('Dashboard', style: TextStyle(color: Colors.blue))),
                            const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                            const PopupMenuItem(value: 'copy', child: Text('Copy Info', style: TextStyle(color: Colors.white))),
                            const PopupMenuItem(value: 'duplicate', child: Text('Duplicate', style: TextStyle(color: Colors.white))),
                            if (event.status != 'active')
                               const PopupMenuItem(value: 'activate', child: Text('Activate', style: TextStyle(color: Colors.green))),
                            if (event.status == 'active')
                               const PopupMenuItem(value: 'deactivate', child: Text('Deactivate', style: TextStyle(color: Colors.orange))),
                            if (event.status != 'expired')
                               const PopupMenuItem(value: 'expire', child: Text('Expire', style: TextStyle(color: Colors.red))),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
              ),
    );
  }

  Widget _buildTemplateItem(
    BuildContext context,
    String title,
    String type,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: () async {
        Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventFormScreen(initialEventType: type),
          ),
        );
        _loadEvents();
      },
    );
  }
}
