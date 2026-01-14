import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/repo/dashboard_repo.dart';
import 'package:legend/services/auth/auth.dart';
import 'package:provider/provider.dart';
import 'package:legend/constants/app_constants.dart';
import 'package:legend/models/additional_models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // We use Streams to listen to the DB in real-time
  Stream<List<LegendNotification>>? _notificationsStream;
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    // 1. Initialize the Stream
    // We use postFrameCallback to safely access Provider in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      final repo = context.read<DashboardRepository>();
      
      final school = authService.activeSchool;
      if (school != null) {
        setState(() {
          _schoolId = school.id;
          _notificationsStream = repo.watchNotifications(school.id);
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // ACTIONS (Wired to Repository)
  // ---------------------------------------------------------------------------

  Future<void> _handleMarkAsRead(String notiId) async {
    await context.read<DashboardRepository>().markAsRead(notiId);
  }

  Future<void> _handleMarkAllRead() async {
    if (_schoolId == null) return;
    
    await context.read<DashboardRepository>().markAllAsRead(_schoolId!);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All notifications marked as read"),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _handleClearAll() async {
    if (_schoolId == null) return;

    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDarkGrey,
        title: const Text("Clear All?", style: TextStyle(color: Colors.white)),
        content: const Text("This will permanently delete all notifications.", style: TextStyle(color: AppColors.textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear", style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DashboardRepository>().clearAllNotifications(_schoolId!);
    }
  }

  void _handleNotificationTap(LegendNotification noti) {
    // 1. Mark as read immediately
    if (!noti.isRead) {
      _handleMarkAsRead(noti.id);
    }

    // 2. Handle Navigation (Smart Routing)
    // Checks the 'metadata' JSON to see if we should go somewhere
    if (noti.metadata.containsKey('invoice_id')) {
      // Example: context.push('${AppRoutes.finance}/invoice/${noti.metadata['invoice_id']}');
    } else if (noti.metadata.containsKey('student_id')) {
      context.push('${AppRoutes.students}/view/${noti.metadata['student_id']}');
    }
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // If stream is not initialized yet (rare, but possible on fast load)
    if (_notificationsStream == null) {
      return const Scaffold(backgroundColor: AppColors.backgroundBlack, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      
      // APP BAR
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_remove, color: AppColors.textGrey),
            tooltip: "Clear All",
            onPressed: _handleClearAll,
          ),
          const SizedBox(width: 8),
        ],
      ),

      // LIVE BODY
      body: StreamBuilder<List<LegendNotification>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          
          // 2. Error
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: AppColors.errorRed)));
          }

          final list = snapshot.data ?? [];

          // 3. Empty
          if (list.isEmpty) {
            return _buildEmptyState();
          }

          // 4. Data
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildGlowCard(list[index]);
            },
          );
        },
      ),
            
      // BOTTOM ACTION
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _handleMarkAllRead,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.surfaceLightGrey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Mark all as read", style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET HELPERS
  // ---------------------------------------------------------------------------

  Widget _buildGlowCard(LegendNotification noti) {
    Color accentColor;
    IconData icon;
    Color glowColor;

    switch (noti.type) {
      case NotificationType.success:
        accentColor = const Color(0xFF10B981);
        glowColor = accentColor.withAlpha(40);
        icon = Icons.check_circle;
        break;
      case NotificationType.warning:
        accentColor = const Color(0xFFF59E0B);
        glowColor = accentColor.withAlpha(40);
        icon = Icons.priority_high;
        break;
      case NotificationType.system:
      case NotificationType.insight:
        accentColor = const Color(0xFFEF4444);
        glowColor = accentColor.withAlpha(40);
        icon = Icons.error_outline;
        break;
      case NotificationType.info:
        accentColor = AppColors.primaryBlue;
        glowColor = accentColor.withAlpha(40);
        icon = Icons.info_outline;
        break;
    }

    return GestureDetector(
      onTap: () => _handleNotificationTap(noti),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(16),
          // BORDER: Transparent if read, Colored if unread
          border: Border.all(
            color: noti.isRead ? Colors.transparent : accentColor.withAlpha(50), 
            width: 1,
          ),
          // GLOW: Only if unread
          boxShadow: [
            if (!noti.isRead)
              BoxShadow(
                color: glowColor,
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        noti.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        // Simple time formatting
                        "${noti.createdAt.hour}:${noti.createdAt.minute.toString().padLeft(2,'0')}", 
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    noti.message,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppColors.textGrey.withAlpha(50)),
          const SizedBox(height: 16),
          const Text("No new notifications", style: TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}