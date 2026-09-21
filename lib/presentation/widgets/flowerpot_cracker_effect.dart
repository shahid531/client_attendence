import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum _ParticleType { circle, star, diamond, petal }

class _CrackerParticle {
  double x;
  double y;
  double vx;
  double vy;
  final double initialVx;
  final double initialVy;
  final double size;
  final Color color;
  final double maxLifespan;
  final _ParticleType type;
  final double rotationSpeed;
  final double sparkleFreq;
  double rotation;
  double life; // 0.0 -> 1.0

  _CrackerParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.maxLifespan,
    required this.type,
    required this.rotationSpeed,
    required this.sparkleFreq,
  })  : initialVx = vx,
        initialVy = vy,
        rotation = 0.0,
        life = 0.0;
}

/// An interactive logo widget that bursts a Flowerpot (Anaar) Cracker
/// fountain animation and performs a tactile bounce when tapped.
class FlowerpotCrackerLogo extends StatefulWidget {
  final Widget? child;
  final VoidCallback? onTap;

  const FlowerpotCrackerLogo({
    super.key,
    this.child,
    this.onTap,
  });

  @override
  State<FlowerpotCrackerLogo> createState() => _FlowerpotCrackerLogoState();
}

class _FlowerpotCrackerLogoState extends State<FlowerpotCrackerLogo>
    with TickerProviderStateMixin {
  late final AnimationController _crackerController;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  final List<_CrackerParticle> _particles = [];
  final math.Random _random = math.Random();

  // Coordinated festive palette matching app theme
  static const List<Color> _palette = [
    Color(0xFFFFD700), // Pure Gold
    Color(0xFFF59E0B), // Warm Amber / Orange Spark
    AppColors.primaryBlue, // Royal Blue (0xFF1D4ED8)
    Color(0xFF38BDF8), // Electric Sky Blue
    AppColors.successEmerald, // Emerald Glint (0xFF059669)
    Color(0xFFF43F5E), // Festive Rose Spark (0xFFF43F5E)
    Colors.white, // Diamond Sparkle
  ];

  @override
  void initState() {
    super.initState();

    _crackerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        _updateParticles();
      });

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  void _triggerCracker() {
    _bounceController.forward(from: 0.0);
    _spawnParticles();
    _crackerController.forward(from: 0.0);
    widget.onTap?.call();
  }

  void _spawnParticles() {
    _particles.clear();
    const particleCount = 65;

    for (int i = 0; i < particleCount; i++) {
      // Upward cone spread (-80° to -100° with side flares -45° to -135°)
      // angle in radians: -pi/2 is straight up
      final angleSpread = (_random.nextDouble() - 0.5) * 1.3; // ~ -37° to +37° from straight up
      final angle = -math.pi / 2 + angleSpread;

      // Higher velocity for fountain jet effect
      final speed = 180.0 + _random.nextDouble() * 260.0;
      final vx = math.cos(angle) * speed;
      final vy = math.sin(angle) * speed;

      final color = _palette[_random.nextInt(_palette.length)];
      final size = 2.5 + _random.nextDouble() * 4.5;
      final lifespan = 0.6 + _random.nextDouble() * 0.4; // 0.6 to 1.0 of animation progress

      final typeIndex = _random.nextInt(10);
      final _ParticleType type = typeIndex < 5
          ? _ParticleType.circle
          : (typeIndex < 8 ? _ParticleType.star : _ParticleType.petal);

      _particles.add(
        _CrackerParticle(
          x: 0,
          y: -10, // Start slightly near top of logo
          vx: vx,
          vy: vy,
          size: size,
          color: color,
          maxLifespan: lifespan,
          type: type,
          rotationSpeed: (_random.nextDouble() - 0.5) * 12.0,
          sparkleFreq: 10.0 + _random.nextDouble() * 20.0,
        ),
      );
    }
  }

  void _updateParticles() {
    final t = _crackerController.value;
    const dt = 0.016; // approx 60fps delta
    const gravity = 320.0; // Gravity pulling sparks down

    for (final p in _particles) {
      p.life = (t / p.maxLifespan).clamp(0.0, 1.0);
      if (p.life < 1.0) {
        // Drag + Gravity physics
        p.vy += gravity * dt;
        p.vx *= 0.985;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.rotation += p.rotationSpeed * dt;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _crackerController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerCracker,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Fountain Cracker Particle Painter
          if (_crackerController.isAnimating)
            Positioned.fill(
              child: CustomPaint(
                painter: _FlowerpotPainter(
                  particles: _particles,
                  progress: _crackerController.value,
                ),
              ),
            ),

          // Logo with bounce scale animation
          ScaleTransition(
            scale: _bounceAnimation,
            child: widget.child ?? _buildDefaultLogo(),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.apartment_rounded,
        size: 38,
        color: AppColors.primaryNavy,
      ),
    );
  }
}

class _FlowerpotPainter extends CustomPainter {
  final List<_CrackerParticle> particles;
  final double progress;

  _FlowerpotPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Initial Fountain Base Glow / Shockwave
    if (progress < 0.4) {
      final ringProgress = progress / 0.4;
      final ringRadius = 36.0 + ringProgress * 30.0;
      final ringOpacity = (1.0 - ringProgress).clamp(0.0, 1.0);

      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: ringOpacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1.0 - ringProgress);
      canvas.drawCircle(center, ringRadius, glowPaint);
    }

    // 2. Draw Particles & Trails
    for (final p in particles) {
      if (p.life >= 1.0) continue;

      final remainingLife = 1.0 - p.life;
      // Sparkle flicker
      final flicker = 0.7 + 0.3 * math.sin(progress * p.sparkleFreq);
      final alpha = (remainingLife * flicker).clamp(0.0, 1.0);
      final currentSize = p.size * (0.4 + 0.6 * remainingLife);

      final particlePos = center + Offset(p.x, p.y);

      // Sparkler glow halo
      final haloPaint = Paint()
        ..color = p.color.withValues(alpha: alpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(particlePos, currentSize * 1.8, haloPaint);

      // Core particle paint
      final corePaint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      // Draw particle according to its type
      switch (p.type) {
        case _ParticleType.circle:
          canvas.drawCircle(particlePos, currentSize, corePaint);
          break;

        case _ParticleType.star:
          _drawStar(canvas, particlePos, currentSize * 1.4, p.rotation, corePaint);
          break;

        case _ParticleType.diamond:
        case _ParticleType.petal:
          _drawPetal(canvas, particlePos, currentSize * 1.3, p.rotation, corePaint);
          break;
      }

      // Sparkler trailing spark line
      if (remainingLife > 0.3 && p.vy.abs() > 30) {
        final trailLength = (p.vy * 0.04).clamp(-12.0, 12.0);
        final trailPaint = Paint()
          ..color = p.color.withValues(alpha: alpha * 0.5)
          ..strokeWidth = currentSize * 0.6
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          particlePos,
          particlePos - Offset(p.vx * 0.02, trailLength),
          trailPaint,
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final tipX = math.cos(angle) * size;
      final tipY = math.sin(angle) * size;
      if (i == 0) {
        path.moveTo(tipX, tipY);
      } else {
        path.lineTo(tipX, tipY);
      }
      final midAngle = angle + (math.pi / 4);
      final midX = math.cos(midAngle) * (size * 0.3);
      final midY = math.sin(midAngle) * (size * 0.3);
      path.lineTo(midX, midY);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawPetal(Canvas canvas, Offset center, double size, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final rect = Rect.fromCenter(center: Offset.zero, width: size * 0.8, height: size * 1.6);
    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlowerpotPainter oldDelegate) {
    return true;
  }
}
