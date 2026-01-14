import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/constants/app_constants.dart';
import 'package:legend/constants/app_strings.dart';
import 'package:legend/vmodels/settings_vmodel.dart';
import 'package:provider/provider.dart';


// -----------------------------------------------------------------------------
// 2. SCREEN IMPLEMENTATION
// -----------------------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize settings when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,

          // APP BAR
          appBar: AppBar(
            backgroundColor: AppColors.backgroundBlack,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false, // Root tab
            title: const Text(
              AppStrings.pageTitle,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // BODY
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Profile Card ---
                _buildProfileHeader(context),

                const SizedBox(height: 32),

                // ================= SECTION 1: IDENTITY =================
                _buildSectionHeader(AppStrings.secIdentity),
                _buildSettingsTile(
                  context,
                  icon: Icons.person_outline,
                  title: AppStrings.itemEditProfile,
                  subtitle: AppStrings.subEditProfile,
                  onTap: () {
                    //TODO Edit Profile Screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit Profile coming soon'),
                        backgroundColor: AppColors.surfaceLightGrey,
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.business_outlined,
                  title: AppStrings.itemSchool,
                  subtitle: AppStrings.subSchool,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    //TODO Edit School Screen
                      const SnackBar(
                        content: Text('Edit School Details coming soon'),
                        backgroundColor: AppColors.surfaceLightGrey,
                      ),
                    ),
                ),

                const SizedBox(height: 24),

                // ================= SECTION 2: APP SETTINGS =================
                _buildSectionHeader(AppStrings.secApp),

                // Dark Mode Switch
                _buildSwitchTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: AppStrings.itemTheme,
                  value: viewModel.isDarkMode,
                  onChanged: (val) async {
                    await viewModel.toggleDarkMode();
                    if (mounted) setState(() {});
                  },
                ),

                const SizedBox(height: 8), // Small spacing between switches
                // Notifications Switch
                _buildSwitchTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: AppStrings.itemNotifs,
                  value: viewModel.pushNotifications,
                  onChanged: (val) async {
                    await viewModel.togglePushNotifications();
                    if (mounted) setState(() {});
                  },
                ),

                const SizedBox(height: 24),

                // ================= SECTION 3: DATA =================
                _buildSectionHeader(AppStrings.secData),
                _buildSettingsTile(
                  context,
                  icon: Icons.sync,
                  title: AppStrings.itemSync,
                  subtitle: AppStrings.subSync,
                  trailing: const Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                    size: 18,
                  ),
                  onTap: () {},
                ),

                const SizedBox(height: 24),

                // ================= SECTION 4: SUPPORT =================
                _buildSectionHeader(AppStrings.secSupport),
                _buildSettingsTile(
                  context,
                  icon: Icons.code,
                  title: AppStrings.itemContactDev,
                  subtitle: AppStrings.subContactDev,
                  onTap: () => context.push(
                    '${AppRoutes.settings}/${AppRoutes.contactDev}',
                  ),
                ),

                const SizedBox(height: 32),

                // LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      // TODO: Implement Auth Logout Logic
                      context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout, color: AppColors.errorRed),
                    label: const Text(
                      AppStrings.itemLogout,
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.errorRed.withAlpha(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40), // Bottom padding
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withAlpha(60),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(
              child: Text(
                "SL", // Initials
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sir Legend",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Owner • KwaLegend Academy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textGrey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: AppColors.surfaceDarkGrey, // Legend Dark Theme background
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLightGrey.withAlpha(50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
              )
            : null,
        trailing:
            trailing ??
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textGrey,
            ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLightGrey.withAlpha(50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        value: value,
        activeThumbColor: AppColors.primaryBlue,
        activeTrackColor: AppColors.primaryBlue.withAlpha(100),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: AppColors.surfaceLightGrey,
        onChanged: onChanged,
      ),
    );
  }
}
