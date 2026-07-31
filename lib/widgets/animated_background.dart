import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    
    _controller1 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _controller2 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);
    
    _controller3 = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
            Color(0xFFf093fb),
            Color(0xFFf5576c),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated circles
          _buildAnimatedCircle(
            controller: _controller1,
            size: 200,
            color: Colors.white.withValues(alpha: 0.1),
            offset: const Offset(0.1, 0.1),
          ),
          _buildAnimatedCircle(
            controller: _controller2,
            size: 150,
            color: Colors.white.withValues(alpha: 0.08),
            offset: const Offset(0.8, 0.2),
          ),
          _buildAnimatedCircle(
            controller: _controller3,
            size: 100,
            color: Colors.white.withValues(alpha: 0.06),
            offset: const Offset(0.3, 0.8),
          ),
          _buildAnimatedCircle(
            controller: _controller1,
            size: 80,
            color: Colors.white.withValues(alpha: 0.05),
            offset: const Offset(0.9, 0.7),
          ),
          // Content
          widget.child,
        ],
      ),
    );
  }

  Widget _buildAnimatedCircle({
    required AnimationController controller,
    required double size,
    required Color color,
    required Offset offset,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Positioned(
          left: offset.dx * MediaQuery.of(context).size.width,
          top: offset.dy * MediaQuery.of(context).size.height,
          child: Transform.scale(
            scale: 0.8 + (0.4 * controller.value),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
