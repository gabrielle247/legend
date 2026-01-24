import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/constants/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDevScreen extends StatefulWidget {
  const ContactDevScreen({super.key});

  @override
  State<ContactDevScreen> createState() => _ContactDevScreenState();
}

class _ContactDevScreenState extends State<ContactDevScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late AnimationController _gridController;

  @override
  void initState() {
    super.initState();
    // 1. Pulse for the "Heartbeat" effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 2. Spin for the Reactor Rings
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 3. Grid Scan Effect
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spinController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.devUplinkFailed),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // True black for OLED contrast
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              border: Border.all(color: AppColors.primaryBlue.withAlpha(100)),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.primaryBlue, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // 1. RETRO-GRID BACKGROUND
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CyberGridPainter(
                    scanValue: _gridController.value,
                    color: AppColors.primaryBlue.withAlpha(30),
                  ),
                );
              },
            ),
          ),

          // 2. VIGNETTE OVERLAY (Focus attention on center)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(200),
                    Colors.black,
                  ],
                  stops: const [0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. MAIN CONTENT
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // --- THE REACTOR CORE ---
                  _ReactorCore(
                    spinCtrl: _spinController,
                    pulseCtrl: _pulseController,
                  ),

                  const SizedBox(height: 48),

                  // --- IDENTITY BLOCK ---
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, AppColors.primaryBlue],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Text(
                      AppStrings.devContactName,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // --- STATUS BADGE ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.primaryBlue.withAlpha(100), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BlinkingCursor(color: AppColors.successGreen),
                        const SizedBox(width: 8),
                        const Text(
                          AppStrings.devSystemOnline,
                          style: TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    AppStrings.devDirectUplink,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textGrey.withAlpha(200),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // --- TACTICAL BUTTONS ---
                  _buildTacticalButton(
                    context,
                    label: AppStrings.devWhatsAppUplink,
                    subLabel: AppStrings.devWhatsAppUplinkSub,
                    icon: Icons.chat,
                    color: const Color(0xFF25D366),
                    onTap: () => _launch(AppStrings.devWhatsAppUrl),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTacticalButton(
                    context,
                    label: AppStrings.devEmailPayload,
                    subLabel: AppStrings.devEmailPayloadSub,
                    icon: Icons.mark_email_read,
                    color: AppColors.primaryBlue,
                    onTap: () => _launch(AppStrings.devEmailUrl),
                  ),

                  const SizedBox(height: 60),

                  // --- FOOTER SIGNATURE ---
                  Opacity(
                    opacity: 0.5,
                    child: Column(
                      children: [
                        const Icon(Icons.fingerprint, color: AppColors.textGrey, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          "${AppStrings.devFingerprintIdPrefix}${AppStrings.devBuildLabel}",
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildTacticalButton(
    BuildContext context, {
    required String label,
    required String subLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(80), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                        fontSize: 14,
                        shadows: [
                          Shadow(color: color.withAlpha(150), blurRadius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subLabel,
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withAlpha(100)),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOM WIDGETS & PAINTERS
// -----------------------------------------------------------------------------

/// The Spinning "Iron Man" Arc Reactor
class _ReactorCore extends StatelessWidget {
  final AnimationController spinCtrl;
  final AnimationController pulseCtrl;

  const _ReactorCore({required this.spinCtrl, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Outer Ring (Slow Spin)
          AnimatedBuilder(
            animation: spinCtrl,
            builder: (_, _) => Transform.rotate(
              angle: spinCtrl.value * 2 * math.pi,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue.withAlpha(60),
                    width: 1,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue, size: 16),
                  ),
                ),
              ),
            ),
          ),
          // 2. Middle Ring (Fast Reverse Spin)
          AnimatedBuilder(
            animation: spinCtrl,
            builder: (_, _) => Transform.rotate(
              angle: -spinCtrl.value * 4 * math.pi,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue.withAlpha(100),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: CustomPaint(
                  painter: _TechRingPainter(color: AppColors.primaryBlue),
                ),
              ),
            ),
          ),
          // 3. Inner Core (Pulsing)
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, _) => Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withAlpha((100 + (100 * pulseCtrl.value)).toInt()),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withAlpha(200),
                    blurRadius: 30 * pulseCtrl.value,
                    spreadRadius: 10 * pulseCtrl.value,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.code, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws tech-y notches on the rings
class _TechRingPainter extends CustomPainter {
  final Color color;
  _TechRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 3 segments
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 5),
        (i * 120) * (math.pi / 180),
        60 * (math.pi / 180),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Scifi Grid Background
class _CyberGridPainter extends CustomPainter {
  final double scanValue;
  final Color color;

  _CyberGridPainter({required this.scanValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final double gridSpacing = 40.0;
    final double offsetY = scanValue * gridSpacing;

    // Draw Horizontal Lines (Moving down)
    for (double y = -gridSpacing + offsetY; y < size.height; y += gridSpacing) {
      // Fade out at edges
      final opacity = (1.0 - (y / size.height)).clamp(0.0, 1.0);
      paint.color = color.withAlpha((opacity * 255).toInt());
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw Vertical Lines (Static perspective illusion)
    paint.color = color.withAlpha(100);
    final _ = size.width / 2;
    for (double x = 0; x <= size.width; x += gridSpacing) {
       // Slightly angle lines towards bottom center for 3D effect? 
       // Keeping it simple flat grid for now to avoid motion sickness
       canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberGridPainter oldDelegate) => oldDelegate.scanValue != scanValue;
}

/// Simple blinking cursor for terminal text
class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => __BlinkingCursorState();
}

class __BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
