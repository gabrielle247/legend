import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDevScreen extends StatefulWidget {
  const ContactDevScreen({super.key});

  @override
  State<ContactDevScreen> createState() => _ContactDevScreenState();
}

class _ContactDevScreenState extends State<ContactDevScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch uplink.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure black for drama
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // 1. BACKGROUND GLOW
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF1A1A2E), // Deep Blue/Purple
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // 2. MAIN CONTENT
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- THE CORE (Icon) ---
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withAlpha(100),
                              blurRadius: 50 + (20 * _controller.value),
                              spreadRadius: 10 * _controller.value,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: const Icon(
                      Icons.coronavirus, // The "Spiky Science" Icon
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 48),

                  // --- THE TITLE ---
                  const Text(
                    "Nyasha Gabriel",
                    style: TextStyle(
                      fontFamily: 'monospace', // Or JetBrains Mono if available
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // --- THE SUBTITLE ---
                  Text(
                    "Contact the developer when ever the app \nmisbehaves so that data can be preserved \nand a solution can be found",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white.withAlpha(150),
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 64),

                  // --- ACTION BUTTONS ---
                  _buildDramaticButton(
                    context,
                    label: "WHATSAPP UPLINK",
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF25D366),
                    onTap: () => _launch("https://wa.me/263785930886"), 
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildDramaticButton(
                    context,
                    label: "SEND PAYLOAD (EMAIL)",
                    icon: Icons.alternate_email,
                    color: AppColors.primaryBlue,
                    onTap: () => _launch("mailto:gabwixgamesite2024@gmail.com"), // Replace with your email
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // --- FOOTER ---
                  Text(
                    "BUILD: KWALEGEND \nALPHA 0.9.2",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.white.withAlpha(133),
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

  Widget _buildDramaticButton(BuildContext context, {
    required String label, 
    required IconData icon, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(color: color.withAlpha(150), width: 1),
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                color.withAlpha(20),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}