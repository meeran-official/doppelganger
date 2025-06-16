import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class ExquisiteUIHelpers {
  // Glassmorphism effect
  static Widget buildGlassmorphicCard({
    required Widget child,
    double borderRadius = 16,
    double blur = 10,
    Color color = Colors.white,
    double opacity = 0.1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.5),
          ],
        ),
      ),
      child: child,
    );
  }

  // Animated gradient background
  static Widget buildAnimatedGradientBackground(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF0A0A0A),
                  const Color(0xFF1A1A2E),
                  controller.value,
                )!,
                Color.lerp(
                  const Color(0xFF0A0A0A),
                  const Color(0xFF16213E),
                  controller.value,
                )!,
              ],
            ),
          ),
        );
      },
    );
  }

  // Floating action button with ripple effect
  static Widget buildFloatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
    Color backgroundColor = const Color(0xFF39A7FF),
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        elevation: 0,
        tooltip: tooltip,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  // Shimmer loading effect
  static Widget buildShimmerEffect({
    required Widget child,
    required AnimationController controller,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[800]!,
                Colors.grey[600]!,
                Colors.grey[800]!,
              ],
              stops: [
                controller.value - 0.3,
                controller.value,
                controller.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }

  // Advanced card with hover effect
  static Widget buildAdvancedCard({
    required Widget child,
    required VoidCallback onTap,
    double borderRadius = 16,
    Color borderColor = const Color(0xFF39A7FF),
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),          border: Border.all(
            color: isActive 
                ? borderColor 
                : borderColor.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C1C1E).withValues(alpha: 0.8),
              const Color(0xFF2C2C2E).withValues(alpha: 0.6),
            ],
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: child,
      ),
    );
  }

  // Animated counter
  static Widget buildAnimatedCounter({
    required int value,
    required String label,
    Color color = const Color(0xFF39A7FF),
    double fontSize = 24,
  }) {
    return TweenAnimationBuilder<int>(
      duration: const Duration(milliseconds: 1000),
      tween: IntTween(begin: 0, end: value),
      builder: (context, animatedValue, child) {
        return Column(
          children: [
            Text(
              '$animatedValue',
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
  // Enhanced particle animation effect with floating particles
  static Widget buildParticleBackground({
    Color color = const Color(0xFF39A7FF),
    int particleCount = 25,
    required AnimationController controller,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: EnhancedParticlePainter(
            animationValue: controller.value,
            color: color,
            particleCount: particleCount,
          ),
        );
      },
    );
  }

  // Floating gradient orb effect
  static Widget buildFloatingOrbs({
    required AnimationController controller,
    List<Color> colors = const [Color(0xFF39A7FF), Color(0xFF00D4FF), Color(0xFF4285F4)],
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: colors.asMap().entries.map((entry) {
            int index = entry.key;
            Color color = entry.value;
            
            double offset = (controller.value + index * 0.3) % 1.0;
            return Positioned(
              left: 50 + (index * 100) + (offset * 50),
              top: 100 + (index * 150) + (math.sin(offset * 2 * math.pi) * 30),
              child: Container(
                width: 60 + (index * 10),
                height: 60 + (index * 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Modern app bar with glassmorphism
  static PreferredSizeWidget buildModernAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            elevation: 0,
            leading: leading,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            actions: actions,
            centerTitle: centerTitle,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                border: const Border(
                  bottom: BorderSide(
                    color: Colors.white12,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced quick stats widget
  static Widget buildQuickStats({
    required List<Map<String, dynamic>> stats,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return buildGlassmorphicCard(
      opacity: 0.15,
      child: Container(
        padding: padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: stats.map((stat) => 
            Expanded(
              child: Column(
                children: [
                  buildAnimatedCounter(
                    value: stat['value'],
                    label: stat['label'],
                    color: stat['color'] ?? const Color(0xFF39A7FF),
                  ),
                  if (stat['subtitle'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        stat['subtitle'],
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ).toList(),
        ),
      ),
    );
  }

  // Pulsing dot indicator
  static Widget buildPulsingDot({
    Color color = const Color(0xFF39A7FF),
    double size = 8,
    required AnimationController controller,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: size + (controller.value * 4),
          height: size + (controller.value * 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.8 - (controller.value * 0.3)),            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8 + (controller.value * 4),
                spreadRadius: 1 + (controller.value * 2),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Enhanced particle painter with floating animation
class EnhancedParticlePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final int particleCount;

  EnhancedParticlePainter({
    required this.animationValue,
    required this.color,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final progress = (animationValue + (i * 0.1)) % 1.0;
      final x = (i * 37 + progress * 50) % size.width;
      final y = (i * 73 + progress * 30) % size.height;
      final radius = ((i * 13) % 8) + 1.0;      final opacity = (math.sin(progress * 2 * math.pi) + 1) * 0.1;
      
      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
