import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/data/constants/app_constants.dart';

class TosScreen extends StatelessWidget {
  const TosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Protocol & Terms",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          const Text(
            "OPERATIONAL AGREEMENT",
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "By deploying KwaLegend, you agree to the following protocols regarding data sovereignty, financial processing, and system integrity.",
            style: TextStyle(color: AppColors.textGrey, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Accordion Sections
          _buildSection(
            context,
            "1. THE LICENSE",
            "You are granted a non-exclusive, non-transferable license to use KwaLegend for internal school management. This system remains the intellectual property of Greyway.Co.",
          ),
          _buildSection(
            context,
            "2. DATA SOVEREIGNTY",
            "Your data is yours. KwaLegend operates on a 'Local-First' architecture (PowerSync). While data is synced to the cloud for backup, the primary source of truth resides on your device. We do not sell student data.",
          ),
          _buildSection(
            context,
            "3. FINANCIAL LIABILITY",
            "KwaLegend is a recording tool, not a bank. We are not liable for discrepancies between the system's ledger and your actual bank account. Always verify physical cash before logging payments.",
          ),
          _buildSection(
            context,
            "4. SYSTEM UPDATES",
            "We practice 'Continuous Deployment'. Features may evolve. Critical updates will be pushed automatically to ensure security compliance.",
          ),
          _buildSection(
            context,
            "5. TERMINATION",
            "Failure to maintain subscription dues will result in the system entering 'Read-Only' mode. Data will be preserved for 90 days post-termination.",
          ),

          const SizedBox(height: 40),
          
          // Footer
          Center(
            child: Text(
              "Last Updated: January 12, 2026",
              style: TextStyle(
                color: AppColors.textGrey.withAlpha(100),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            iconColor: AppColors.primaryBlue,
            collapsedIconColor: AppColors.textGrey,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                content,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
