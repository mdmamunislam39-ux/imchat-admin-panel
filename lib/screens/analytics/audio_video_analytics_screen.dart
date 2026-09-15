import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/dashboard_analytics_service.dart';
import '../../widgets/base_screen.dart';
import '../../widgets/media_preview_widget.dart';
import '../user_history_stats.dart';

class AudioVideoAnalyticsScreen extends StatefulWidget {
  final String initialPeriod;

  const AudioVideoAnalyticsScreen({
    super.key,
    this.initialPeriod = 'daily',
  });

  @override
  State<AudioVideoAnalyticsScreen> createState() =>
      _AudioVideoAnalyticsScreenState();
}

class _AudioVideoAnalyticsScreenState extends State<AudioVideoAnalyticsScreen> {
  late String _selectedPeriod; // 'daily', 'weekly', 'monthly', 'all', 'custom'
  DateTimeRange? _customDateRange;
  bool _isLoading = true;
  List<AgoraUserUsage> _usersUsage = [];
  StreamSubscription<List<AgoraUserUsage>>? _streamSubscription;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'audio_call', 'video_call', 'audio_room', 'live_room'
  String _sortBy = 'total'; // 'total', 'audio_call', 'video_call', 'audio_room', 'live_room'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    DashboardAnalyticsService.syncAndInitializeAgoraMinutesToFirestore();
    _startRealtimeListener();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startRealtimeListener() {
    _streamSubscription?.cancel();
    setState(() => _isLoading = true);
    _streamSubscription = DashboardAnalyticsService.getAgoraUserUsageStream(
      period: _selectedPeriod,
      customRange: _customDateRange,
    ).listen((data) {
      if (!mounted) return;
      setState(() {
        _usersUsage = data;
        _isLoading = false;
      });
    }, onError: (e) {
      debugPrint('Error in Agora user usage stream: $e');
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _loadData() {
    _startRealtimeListener();
  }

  // Aggregate totals
  int get _totalAudioCallMins =>
      _usersUsage.fold(0, (sum, item) => sum + item.audioCallMinutes);
  int get _totalVideoCallMins =>
      _usersUsage.fold(0, (sum, item) => sum + item.videoCallMinutes);
  int get _totalAudioRoomMins =>
      _usersUsage.fold(0, (sum, item) => sum + item.audioRoomMinutes);
  int get _totalLiveRoomMins =>
      _usersUsage.fold(0, (sum, item) => sum + item.liveRoomMinutes);
  int get _grandTotalMins =>
      _totalAudioCallMins +
      _totalVideoCallMins +
      _totalAudioRoomMins +
      _totalLiveRoomMins;

  List<AgoraUserUsage> get _filteredUsers {
    var list = _usersUsage.where((u) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return u.username.toLowerCase().contains(query) ||
          u.profileId.toLowerCase().contains(query);
    }).toList();

    // Category filter
    if (_selectedCategory == 'audio_call') {
      list = list.where((u) => u.audioCallMinutes > 0).toList();
    } else if (_selectedCategory == 'video_call') {
      list = list.where((u) => u.videoCallMinutes > 0).toList();
    } else if (_selectedCategory == 'audio_room') {
      list = list.where((u) => u.audioRoomMinutes > 0).toList();
    } else if (_selectedCategory == 'live_room') {
      list = list.where((u) => u.liveRoomMinutes > 0).toList();
    }

    // Sorting
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'audio_call':
          cmp = a.audioCallMinutes.compareTo(b.audioCallMinutes);
          break;
        case 'video_call':
          cmp = a.videoCallMinutes.compareTo(b.videoCallMinutes);
          break;
        case 'audio_room':
          cmp = a.audioRoomMinutes.compareTo(b.audioRoomMinutes);
          break;
        case 'live_room':
          cmp = a.liveRoomMinutes.compareTo(b.liveRoomMinutes);
          break;
        case 'total':
        default:
          cmp = a.totalMinutes.compareTo(b.totalMinutes);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Agora Voice & Video Usage Analytics',
      actions: [
        IconButton(
          icon: const Icon(Icons.sync, color: Colors.greenAccent),
          tooltip: 'Sync & Populate Real-Time Agora Minutes to Firestore',
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Syncing Agora minutes to Firestore database...')),
            );
            final updated = await DashboardAnalyticsService.syncAndInitializeAgoraMinutesToFirestore();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully synced $updated users with live Agora minutes!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
          tooltip: 'Add / Test Live Minutes for User',
          onPressed: _showAddMinutesDialog,
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh Analytics',
          onPressed: _loadData,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            _buildHeaderBanner(),
            const SizedBox(height: 20),

            // Time Period Filters
            _buildPeriodSelector(),
            const SizedBox(height: 20),

            // KPI Summary Cards
            _buildSummaryKpiCards(),
            const SizedBox(height: 24),

            // Breakdown Distribution Visual
            _buildUsageDistributionCard(),
            const SizedBox(height: 24),

            // User-Wise Usage Breakdown Section
            _buildUserUsageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.multitrack_audio, color: Colors.cyanAccent, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agora Real-Time Voice & Video Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Monitor comprehensive usage across Audio Call, Video Call, Audio Rooms & Live Video Rooms per user.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'id': 'daily', 'label': 'Today', 'icon': Icons.today},
      {'id': 'weekly', 'label': 'This Week', 'icon': Icons.date_range},
      {'id': 'monthly', 'label': 'This Month', 'icon': Icons.calendar_month},
      {'id': 'all', 'label': 'All Time', 'icon': Icons.all_inclusive},
      {'id': 'custom', 'label': 'Custom Range', 'icon': Icons.tune},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: periods.map((p) {
            final isSelected = _selectedPeriod == p['id'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  p['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.grey[400],
                ),
                label: Text(
                  p['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[300],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF334155),
                  ),
                ),
                onSelected: (selected) async {
                  if (p['id'] == 'custom') {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                      initialDateRange: _customDateRange ??
                          DateTimeRange(
                            start: DateTime.now().subtract(const Duration(days: 7)),
                            end: DateTime.now(),
                          ),
                    );
                    if (range != null) {
                      setState(() {
                        _selectedPeriod = 'custom';
                        _customDateRange = range;
                      });
                      _loadData();
                    }
                  } else {
                    setState(() {
                      _selectedPeriod = p['id'] as String;
                    });
                    _loadData();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryKpiCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final cardWidth = isDesktop
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Audio Call',
                value: _formatMinutes(_totalAudioCallMins),
                subtitle: '1-on-1 & Group Calls',
                icon: Icons.call,
                color: const Color(0xFF3B82F6),
                bgGradient: const [Color(0xFF1E3A8A), Color(0xFF172554)],
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Video Call',
                value: _formatMinutes(_totalVideoCallMins),
                subtitle: 'Agora RTC High Def',
                icon: Icons.videocam,
                color: const Color(0xFFEC4899),
                bgGradient: const [Color(0xFF831843), Color(0xFF500724)],
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Audio Room',
                value: _formatMinutes(_totalAudioRoomMins),
                subtitle: 'Party & Multi-Mic Rooms',
                icon: Icons.mic,
                color: const Color(0xFF10B981),
                bgGradient: const [Color(0xFF064E3B), Color(0xFF022C22)],
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Live Video Room',
                value: _formatMinutes(_totalLiveRoomMins),
                subtitle: 'Live Stream Broadcasts',
                icon: Icons.live_tv,
                color: const Color(0xFFF59E0B),
                bgGradient: const [Color(0xFF78350F), Color(0xFF451A03)],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> bgGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isLoading ? '...' : value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageDistributionCard() {
    final total = _grandTotalMins > 0 ? _grandTotalMins : 1;
    final audioCallPct = (_totalAudioCallMins / total * 100).toStringAsFixed(1);
    final videoCallPct = (_totalVideoCallMins / total * 100).toStringAsFixed(1);
    final audioRoomPct = (_totalAudioRoomMins / total * 100).toStringAsFixed(1);
    final liveRoomPct = (_totalLiveRoomMins / total * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Usage Distribution Breakdown',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: ${_formatMinutes(_grandTotalMins)}',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Multi-color Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(
                    flex: _totalAudioCallMins > 0 ? _totalAudioCallMins : 1,
                    child: Container(color: const Color(0xFF3B82F6)),
                  ),
                  Expanded(
                    flex: _totalVideoCallMins > 0 ? _totalVideoCallMins : 1,
                    child: Container(color: const Color(0xFFEC4899)),
                  ),
                  Expanded(
                    flex: _totalAudioRoomMins > 0 ? _totalAudioRoomMins : 1,
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                  Expanded(
                    flex: _totalLiveRoomMins > 0 ? _totalLiveRoomMins : 1,
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend Row
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildLegendItem('Audio Call', '$audioCallPct%', const Color(0xFF3B82F6)),
              _buildLegendItem('Video Call', '$videoCallPct%', const Color(0xFFEC4899)),
              _buildLegendItem('Audio Room', '$audioRoomPct%', const Color(0xFF10B981)),
              _buildLegendItem('Live Video Room', '$liveRoomPct%', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String pct, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          '($pct)',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildUserUsageSection() {
    final filtered = _filteredUsers;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User-Wise Agora Usage Breakdown (${filtered.length} Users)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Search & Filter Row
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search user by name or Search ID...',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category Filter Dropdown
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: const Color(0xFF0F172A),
                            icon: const Icon(Icons.filter_list, color: Colors.white70, size: 20),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Channels')),
                              DropdownMenuItem(value: 'audio_call', child: Text('Audio Call Users')),
                              DropdownMenuItem(value: 'video_call', child: Text('Video Call Users')),
                              DropdownMenuItem(value: 'audio_room', child: Text('Audio Room Users')),
                              DropdownMenuItem(value: 'live_room', child: Text('Live Room Users')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 1),

          // User Table List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.person_off, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 12),
                    Text(
                      'No usage records found for selected period',
                      style: TextStyle(color: Colors.grey[400], fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  return const Color(0xFF1E293B);
                }),
                columns: [
                  const DataColumn(
                    label: Text('User Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        const Icon(Icons.call, color: Color(0xFF3B82F6), size: 16),
                        const SizedBox(width: 4),
                        const Text('Audio Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(
                            _sortBy == 'audio_call' ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.unfold_more,
                            size: 14,
                            color: _sortBy == 'audio_call' ? Colors.blue : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_sortBy == 'audio_call') {
                                _sortAscending = !_sortAscending;
                              } else {
                                _sortBy = 'audio_call';
                                _sortAscending = false;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        const Icon(Icons.videocam, color: Color(0xFFEC4899), size: 16),
                        const SizedBox(width: 4),
                        const Text('Video Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(
                            _sortBy == 'video_call' ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.unfold_more,
                            size: 14,
                            color: _sortBy == 'video_call' ? Colors.pink : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_sortBy == 'video_call') {
                                _sortAscending = !_sortAscending;
                              } else {
                                _sortBy = 'video_call';
                                _sortAscending = false;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        const Icon(Icons.mic, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 4),
                        const Text('Audio Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(
                            _sortBy == 'audio_room' ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.unfold_more,
                            size: 14,
                            color: _sortBy == 'audio_room' ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_sortBy == 'audio_room') {
                                _sortAscending = !_sortAscending;
                              } else {
                                _sortBy = 'audio_room';
                                _sortAscending = false;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        const Icon(Icons.live_tv, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 4),
                        const Text('Live Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(
                            _sortBy == 'live_room' ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.unfold_more,
                            size: 14,
                            color: _sortBy == 'live_room' ? Colors.orange : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_sortBy == 'live_room') {
                                _sortAscending = !_sortAscending;
                              } else {
                                _sortBy = 'live_room';
                                _sortAscending = false;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.cyanAccent, size: 16),
                        const SizedBox(width: 4),
                        const Text('Total Agora Mins', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(
                            _sortBy == 'total' ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.unfold_more,
                            size: 14,
                            color: _sortBy == 'total' ? Colors.cyanAccent : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_sortBy == 'total') {
                                _sortAscending = !_sortAscending;
                              } else {
                                _sortBy = 'total';
                                _sortAscending = false;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const DataColumn(
                    label: Text('Action', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
                rows: filtered.map((u) {
                  return DataRow(
                    cells: [
                      // User Info Cell
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (u.profilePicture != null && u.profilePicture!.isNotEmpty)
                              MediaPreviewWidget(
                                url: u.profilePicture!,
                                width: 34,
                                height: 34,
                                borderRadius: BorderRadius.circular(17),
                              )
                            else
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: const Color(0xFF3B82F6),
                                child: Text(
                                  u.username.isNotEmpty ? u.username[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  u.username,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(
                                  'ID: ${u.profileId}',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Audio Call
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${u.audioCallMinutes} min',
                            style: const TextStyle(color: Color(0xFF93C5FD), fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ),
                      // Video Call
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${u.videoCallMinutes} min',
                            style: const TextStyle(color: Color(0xFFF472B6), fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ),
                      // Audio Room
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${u.audioRoomMinutes} min',
                            style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ),
                      // Live Room
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${u.liveRoomMinutes} min',
                            style: const TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ),
                      // Total Minutes
                      DataCell(
                        Text(
                          _formatMinutes(u.totalMinutes),
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Action Cell
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.analytics_outlined, color: Colors.white70, size: 20),
                          tooltip: 'View User History Stats',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserHistoryStats(
                                  userId: u.userId,
                                  username: u.username,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddMinutesDialog() {
    if (_usersUsage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users found in database')),
      );
      return;
    }

    String selectedUserId = _usersUsage.first.userId;
    String selectedType = 'audio_room';
    final TextEditingController minsController = TextEditingController(text: '15');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: Colors.cyanAccent),
              SizedBox(width: 8),
              Text('Record / Add Agora Live Minutes', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select User:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedUserId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    items: _usersUsage.map((u) {
                      return DropdownMenuItem(
                        value: u.userId,
                        child: Text(
                          '${u.username} (${u.profileId})',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedUserId = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Category:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    items: const [
                      DropdownMenuItem(value: 'audio_call', child: Text('📞 Audio Call (Agora)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'video_call', child: Text('📹 Video Call (Agora)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'audio_room', child: Text('🎙️ Audio Room (Voice Channel)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'live_room', child: Text('🔴 Live Video Room (Broadcast)', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedType = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Minutes:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: minsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter minutes',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              onPressed: () async {
                final mins = int.tryParse(minsController.text.trim()) ?? 0;
                if (mins > 0) {
                  Navigator.pop(ctx);
                  await DashboardAnalyticsService.recordAgoraUsage(
                    userId: selectedUserId,
                    type: selectedType,
                    minutes: mins,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Recorded $mins minutes in real-time!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save & Update Live'),
            ),
          ],
        ),
      ),
    );
  }
}
