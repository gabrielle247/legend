import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/constants/app_routes.dart';
import 'package:legend/data/constants/app_strings.dart';
import 'package:legend/data/vmodels/settings_vmodel.dart';
import 'package:provider/provider.dart';

// -----------------------------------------------------------------------------
// SCREEN IMPLEMENTATION
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, _) {
        // 1. LOADING
        if (viewModel.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
          );
        }

        // 2. ERROR
        if (viewModel.error != null) {
          return _buildErrorState(context, viewModel);
        }

        // 3. CONTENT
        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundBlack,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              AppStrings.pageTitle,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              children: [
                _buildProfileCard(context, viewModel),
                const SizedBox(height: 24),

                _buildSettingsGroup(
                  title: AppStrings.secIdentity,
                  children: [
                    _buildTile(
                      icon: Icons.person_outline,
                      iconColor: Colors.blueAccent,
                      title: AppStrings.itemEditProfile,
                      subtitle: AppStrings.subManageProfile,
                      isLocked: true,
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildTile(
                      icon: Icons.school_outlined,
                      iconColor: Colors.blueAccent,
                      title: AppStrings.itemSchool,
                      subtitle: AppStrings.subSchoolConfig,
                      isLocked: true,
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSettingsGroup(
                  title: AppStrings.secApp,
                  children: [
                    _buildSwitch(
                      icon: Icons.dark_mode_outlined,
                      iconColor: Colors.purpleAccent,
                      title: AppStrings.itemTheme,
                      subtitle: AppStrings.subThemeFixed,
                      value: viewModel.isDarkMode,
                      onChanged: (val) async {
                        await viewModel.toggleDarkMode();
                        if (mounted) setState(() {});
                      },
                    ),
                    _buildDivider(),
                    _buildSwitch(
                      icon: Icons.notifications_active_outlined,
                      iconColor: Colors.orangeAccent,
                      title: AppStrings.itemNotifs,
                      subtitle: AppStrings.subPushAlerts,
                      value: viewModel.pushNotifications,
                      onChanged: (val) async {
                        await viewModel.togglePushNotifications();
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSettingsGroup(
                  title: AppStrings.secData,
                  children: [
                    _buildSwitch(
                      icon: Icons.receipt_long_outlined,
                      iconColor: AppColors.successGreen,
                      title: AppStrings.itemAutoBilling,
                      subtitle: AppStrings.subAutoBillingDesc,
                      value: viewModel.autoBillingEnabled,
                      onChanged: (val) async {
                        await viewModel.toggleAutoBilling(val);
                        if (mounted) setState(() {});
                        if (viewModel.autoBillingLocked && mounted) {
                          await _showAutoBillingLockDialog(context, viewModel);
                        } else if (viewModel.autoBillingError != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(viewModel.autoBillingError!),
                                backgroundColor: AppColors.errorRed),
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildTile(
                      icon: Icons.error_outline,
                      iconColor: AppColors.errorRed,
                      title: AppStrings.itemAutoBillingErrors,
                      subtitle: AppStrings.subAutoBillingErrors,
                      onTap: () => _showAutoBillingErrors(context, viewModel),
                    ),
                    _buildDivider(),
                    _buildSyncTile(viewModel),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSettingsGroup(
                  title: AppStrings.secSupport,
                  children: [
                    _buildTile(
                      icon: Icons.code,
                      iconColor: Colors.cyanAccent,
                      title: AppStrings.itemContactDev,
                      subtitle: AppStrings.subContactDev,
                      onTap: () => context.push('${AppRoutes.settings}/${AppRoutes.contactDev}'),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                _buildSettingsGroup(
                  title: AppStrings.secDangerZone,
                  children: [
                    _buildTile(
                      icon: Icons.delete_forever,
                      iconColor: AppColors.errorRed,
                      title: AppStrings.itemDeleteAllStudentData,
                      subtitle: AppStrings.subDeleteAllStudentData,
                      onTap: viewModel.isDeletingData
                          ? () {}
                          : () => _confirmDeleteAllData(context, viewModel),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildLogoutButton(context, viewModel),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // UI COMPONENTS
  // ===========================================================================

  Widget _buildProfileCard(BuildContext context, SettingsViewModel viewModel) {
    final name = (viewModel.userName ?? '').trim();
    final role = (viewModel.userRole ?? '').trim();
    final displayName = name.isEmpty ? AppStrings.unknownUser : name;
    final initials = _getInitials(displayName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withAlpha(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(100), width: 4),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
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

  Widget _buildSettingsGroup({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isLocked ? AppColors.textGrey : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textGrey.withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLightGrey.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    AppStrings.locked,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: AppColors.textGrey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textGrey.withAlpha(150),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
            activeTrackColor: AppColors.primaryBlue.withAlpha(60),
            inactiveThumbColor: AppColors.textGrey,
            inactiveTrackColor: AppColors.backgroundBlack,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncTile(SettingsViewModel viewModel) {
    // Determine Sync UI State
    final status = viewModel.syncStatus;
    Color color = AppColors.textGrey;
    String statusText = AppStrings.syncDisconnected;
    IconData statusIcon = Icons.cloud_off;
    bool isSyncing = false;

    if (status != null) {
      if (status.anyError != null) {
        color = AppColors.errorRed;
        statusText = AppStrings.syncError;
        statusIcon = Icons.error_outline;
      } else if (status.connecting || status.downloading || status.uploading) {
        color = AppColors.primaryBlue;
        statusText = AppStrings.syncSyncing;
        isSyncing = true;
      } else if (status.connected) {
        color = AppColors.successGreen;
        statusText = AppStrings.syncSynchronized;
        statusIcon = Icons.check_circle;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isSyncing 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color))
              : Icon(Icons.sync, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.itemSync,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  "${AppStrings.syncStatusPrefix}${viewModel.syncStatusLabel}",
                  style: TextStyle(color: AppColors.textGrey.withAlpha(150), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isSyncing) Icon(statusIcon, size: 12, color: color),
                if (!isSyncing) const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, SettingsViewModel viewModel) {
    return GestureDetector(
      onTap: () async {
        try {
          await viewModel.logout();
          if (context.mounted) context.go(AppRoutes.login);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.errorRed.withAlpha(100)),
          borderRadius: BorderRadius.circular(16),
          color: AppColors.errorRed.withAlpha(10),
        ),
        child: const Center(
          child: Text(
            AppStrings.itemLogout,
            style: TextStyle(
              color: AppColors.errorRed,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.backgroundBlack.withAlpha(100),
      indent: 60, // Align with text, skipping icon
    );
  }

  Widget _buildErrorState(BuildContext context, SettingsViewModel viewModel) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
            const SizedBox(height: 16),
            Text(viewModel.error!, style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: viewModel.refresh,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return AppStrings.initialsFallback;
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return "${parts[0][0]}${parts[1][0]}".toUpperCase();
  }

  Future<void> _showAutoBillingLockDialog(BuildContext context, SettingsViewModel viewModel) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDarkGrey,
          title: const Text(
            AppStrings.autoBillingLockedTitle,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            AppStrings.autoBillingLockedBody,
            style: TextStyle(color: AppColors.textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.textGrey)),
            ),
            TextButton(
              onPressed: () async {
                await viewModel.takeOverAutoBilling();
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text(AppStrings.autoBillingTakeOver, style: TextStyle(color: AppColors.primaryBlue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAutoBillingErrors(BuildContext context, SettingsViewModel viewModel) async {
    final errors = await viewModel.loadAutoBillingErrors();
    if (!context.mounted) return;

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.autoBillingNoErrors)),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDarkGrey,
          title: const Text(
            AppStrings.autoBillingErrorsTitle,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors.map((e) {
                  final ts = (e['ts'] ?? '').toString();
                  final msg = (e['message'] ?? '').toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ts, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await viewModel.clearAutoBillingErrors();
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text(AppStrings.autoBillingClearLog, style: TextStyle(color: AppColors.errorRed)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.close, style: TextStyle(color: AppColors.primaryBlue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAllData(BuildContext context, SettingsViewModel viewModel) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDarkGrey,
          title: const Text(
            AppStrings.deleteAllDataTitle,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.deleteAllDataBody,
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.deleteAllDataPrompt,
                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppStrings.deleteAllDataHint,
                  hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(150)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(40)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.errorRed),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.textGrey)),
            ),
            TextButton(
              onPressed: () {
                final ok = controller.text.trim().toUpperCase() == AppStrings.deleteAllDataHint;
                Navigator.of(dialogContext).pop(ok);
              },
              child: const Text(AppStrings.delete, style: TextStyle(color: AppColors.errorRed)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const AlertDialog(
          backgroundColor: AppColors.surfaceDarkGrey,
          content: SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.errorRed),
            ),
          ),
        );
      },
    );

    try {
      await viewModel.deleteAllStudentData();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.deleteAllDataSuccess),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
      );
    }
  }
}
