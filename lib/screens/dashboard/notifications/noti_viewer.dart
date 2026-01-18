import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legend/data/constants/app_routes.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/dashboard_repo.dart';
import 'package:provider/provider.dart'; 
import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/screens/finance/printing_receipt_screen.dart';

class NotificationDetailScreen extends StatelessWidget {
  final LegendNotification notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    // 1. Determine Styles based on Type
    Color accentColor;
    IconData icon;
    String statusLabel;

    switch (notification.type) {
      case NotificationType.success:
        accentColor = AppColors.successGreen;
        icon = Icons.check_circle_outline;
        statusLabel = "SUCCESS";
        break;
      case NotificationType.warning:
        accentColor = Colors.orangeAccent;
        icon = Icons.warning_amber_rounded;
        statusLabel = "ATTENTION";
        break;
      case NotificationType.insight:
        accentColor = const Color(0xFF6366F1); // Indigo
        icon = Icons.auto_awesome;
        statusLabel = "INSIGHT";
        break;
      case NotificationType.system:
        accentColor = AppColors.errorRed;
        icon = Icons.dns_outlined;
        statusLabel = "SYSTEM";
        break;
      case NotificationType.info:
        accentColor = AppColors.primaryBlue;
        icon = Icons.info_outline;
        statusLabel = "INFO";
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textGrey),
            tooltip: "Delete Notification",
            onPressed: () async {
              // WIRED: Delete Logic
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceDarkGrey,
                  title: const Text("Delete?", style: TextStyle(color: Colors.white)),
                  content: const Text("This cannot be undone.", style: TextStyle(color: AppColors.textGrey)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Delete", style: TextStyle(color: AppColors.errorRed)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                // Call Repository
                await context.read<DashboardRepository>().deleteNotification(notification.id);
                if (context.mounted) {
                  Navigator.pop(context); // Close detail screen
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------------------------------------------------
                    // 1. HEADER ICON (Glow Effect)
                    // ---------------------------------------------------------
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(20),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withAlpha(40),
                              blurRadius: 24,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(icon, color: accentColor, size: 40),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ---------------------------------------------------------
                    // 2. METADATA ROW
                    // ---------------------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTag(statusLabel, accentColor),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM d, h:mm a').format(notification.createdAt),
                          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ---------------------------------------------------------
                    // 3. CONTENT
                    // ---------------------------------------------------------
                    Text(
                      notification.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
                      ),
                      child: Text(
                        notification.message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),

                    // ---------------------------------------------------------
                    // 4. CONTEXT DATA (If JSON Payload exists)
                    // ---------------------------------------------------------
                    if (notification.metadata.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        "ADDITIONAL DATA",
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMetadataGrid(notification.metadata),
                    ],
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // 5. ACTION BUTTON (Smart)
            // -----------------------------------------------------------------
            _buildActionButton(context, notification.metadata),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetadataGrid(Map<String, dynamic> data) {
    // Filters out complex objects, just shows simple Key-Values
    final simpleData = data.entries
        .where((e) => e.value is String || e.value is num || e.value is bool)
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: simpleData.length,
      itemBuilder: (context, index) {
        final entry = simpleData[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLightGrey.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.key.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(color: AppColors.textGrey.withAlpha(150), fontSize: 9, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                entry.value.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, Map<String, dynamic> metadata) {
    // LOGIC: Check metadata keys to determine destination
    String label = "Close";
    VoidCallback onTap = () => Navigator.pop(context);
    IconData btnIcon = Icons.close;
    bool isPrimary = false;

    // WIRED: Smart Routing based on Metadata keys
    if (metadata.containsKey('invoice_id')) {
      label = "View Invoice";
      btnIcon = Icons.receipt_long;
      isPrimary = true;
      onTap = () {
        // Route: /finance/invoice/:invoiceId
        final invoiceId = metadata['invoice_id'];
        context.push('${AppRoutes.finance}/${AppRoutes.viewInvoice}'.replaceAll(':invoiceId', invoiceId));
      };
    } else if (metadata.containsKey('student_id')) {
      label = "View Student Profile";
      btnIcon = Icons.person_search;
      isPrimary = true;
      onTap = () {
        // Route: /students/view/:studentId
        final studentId = metadata['student_id'];
        context.push('${AppRoutes.students}/view/$studentId');
      };
    } else if (metadata.containsKey('action_url')) {
      label = "Open Link";
      btnIcon = Icons.open_in_new;
      isPrimary = true;
      onTap = () {
        final now = DateTime.now();
        final data = {
          'id': notification.id,
          'date': now.toIso8601String(),
          'student': notification.title,
          'items': [
            {
              'desc': notification.message,
              'amount': 0.0,
            }
          ],
          'total': 0.0,
          'cashier': 'System',
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrintReceiptScreen(
              data: data,
              type: ReceiptType.invoice,
            ),
          ),
        );
      };
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceLightGrey, width: 0.5)),
        color: AppColors.surfaceDarkGrey,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isPrimary ? AppColors.primaryBlue : AppColors.surfaceLightGrey,
              foregroundColor: Colors.white,
              elevation: isPrimary ? 4 : 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(btnIcon, size: 18),
            label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
