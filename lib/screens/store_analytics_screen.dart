import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/store_item_model.dart';
import '../services/store_service.dart';

class StoreAnalyticsScreen extends StatefulWidget {
  const StoreAnalyticsScreen({super.key});

  @override
  State<StoreAnalyticsScreen> createState() => _StoreAnalyticsScreenState();
}

class _StoreAnalyticsScreenState extends State<StoreAnalyticsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _topItems = [];
  List<Map<String, dynamic>> _userActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadAnalytics();
    _animationController.forward();
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final analytics = await StoreService.getAnalytics();
      final topItems = await StoreService.getTopItems();
      final userActivity = await StoreService.getUserActivity();

      setState(() {
        _analytics = analytics;
        _topItems = topItems;
        _userActivity = userActivity;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          '📊 Store Analytics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.blue[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            )
          : AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverviewCards(),
                          const SizedBox(height: 24),
                          _buildChartSection(),
                          const SizedBox(height: 24),
                          _buildTopItemsSection(),
                          const SizedBox(height: 24),
                          _buildUserActivitySection(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📈 Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildAnalyticsCard(
              title: 'Total Revenue',
              value: '\$${_analytics['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
              icon: Icons.attach_money,
              color: Colors.green,
              trend: _analytics['revenueTrend'] ?? 0.0,
            ),
            _buildAnalyticsCard(
              title: 'Active Users',
              value: '${_analytics['activeUsers'] ?? 0}',
              icon: Icons.people,
              color: Colors.blue,
              trend: _analytics['userTrend'] ?? 0.0,
            ),
            _buildAnalyticsCard(
              title: 'Items Sold',
              value: '${_analytics['itemsSold'] ?? 0}',
              icon: Icons.shopping_cart,
              color: Colors.orange,
              trend: _analytics['salesTrend'] ?? 0.0,
            ),
            _buildAnalyticsCard(
              title: 'Conversion Rate',
              value: '${_analytics['conversionRate']?.toStringAsFixed(1) ?? '0.0'}%',
              icon: Icons.trending_up,
              color: Colors.purple,
              trend: _analytics['conversionTrend'] ?? 0.0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trend >= 0 ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trend.abs().toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Sales Chart',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: AnimatedBuilder(
            animation: _chartAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: SalesChartPainter(
                  data: _analytics['salesData'] ?? [],
                  animation: _chartAnimationController,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 Top Items',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._topItems.take(5).map((item) => _buildTopItemCard(item)),
      ],
    );
  }

  Widget _buildTopItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getTypeIcon(item['type']),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item['sales'] ?? 0} sales',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${item['revenue']?.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👥 Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._userActivity.take(10).map((activity) => _buildActivityCard(activity)),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getActivityIcon(activity['type']),
              color: Colors.blue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['description'] ?? 'Unknown activity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatTime(activity['timestamp']),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeIcon(StoreItemType type) {
    switch (type) {
      case StoreItemType.avatarFrame:
        return '🖼️';
      case StoreItemType.entryEffect:
        return '✨';
      case StoreItemType.badge:
        return '🏆';
      case StoreItemType.backgroundTheme:
        return '🎭';
      case StoreItemType.roomTheme:
        return '🎨';
      case StoreItemType.seatDecor:
        return '🪑';
      case StoreItemType.micRefill:
        return '🎙️';
      case StoreItemType.roomProfileBackground:
        return '🖼️';
      case StoreItemType.shortProfileTheme:
        return '🖼️';
      case StoreItemType.roomEntry:
        return '🚪';
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'purchase':
        return Icons.shopping_cart;
      case 'assignment':
        return Icons.person_add;
      case 'creation':
        return Icons.add;
      default:
        return Icons.info;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class SalesChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Animation<double> animation;

  SalesChartPainter({
    required this.data,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxValue = data.map((e) => e['value'] as double).reduce(math.max);
    final minValue = data.map((e) => e['value'] as double).reduce(math.min);
    final range = maxValue - minValue;

    final stepX = size.width / (data.length - 1);
    final stepY = size.height / range;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final value = data[i]['value'] as double;
      final y = size.height - ((value - minValue) * stepY * animation.value);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw data points
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final value = data[i]['value'] as double;
      final y = size.height - ((value - minValue) * stepY * animation.value);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
