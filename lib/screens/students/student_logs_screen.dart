import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legend/constants/app_constants.dart';
import 'package:legend/constants/app_strings.dart';
import 'package:legend/models/all_models.dart';
import 'package:legend/vmodels/student_logs_view_model.dart';

// =============================================================================
// 3. SCREEN IMPLEMENTATION
// =============================================================================
class StudentLogsScreen extends StatefulWidget {
  //TODO Using real data here
  final String? studentId;

  const StudentLogsScreen({super.key, this.studentId});

  @override
  State<StudentLogsScreen> createState() => _StudentLogsScreenState();
}

class _StudentLogsScreenState extends State<StudentLogsScreen> {
  late StudentLogsViewModel _vm;
  String _filter = AppStrings.strNew; // "All", "Financial", "System"

  @override
  void initState() {
    super.initState();
    _vm = StudentLogsViewModel(widget.studentId ?? AppStrings.exampleStuId);
    _initLoad();
  }

  void _initLoad() async {
    await _vm.loadLogs();
    if (mounted) setState(() {});
  }

  // Filter Logic
  List<LogEntry> get _filteredLogs {
    if (_filter == AppStrings.strNew) return _vm.logs;
    if (_filter == AppStrings.logsF) {
      return _vm.logs.where((l) => l.type == LogType.financial).toList();
    }
    if (_filter == AppStrings.logsS) {
      return _vm.logs.where((l) => l.type == LogType.system).toList();
    }
    if (_filter == AppStrings.logsA) {
      return _vm.logs.where((l) => l.type == LogType.alert).toList();
    }
    return _vm.logs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          AppStrings.activityHistory,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.download_outlined,
              color: AppColors.primaryBlue,
            ),
            tooltip: AppStrings.exportLogs,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.actionMessageExporting),
                  backgroundColor: AppColors.surfaceLightGrey,
                ),
              );
            },
          ),
        ],
      ),
      body: _vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : Column(
              children: [
                // 1. FILTER CHIPS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip(AppStrings.strAll),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppStrings.logsF),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppStrings.logsS),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppStrings.logsA),
                    ],
                  ),
                ),

                // 2. TIMELINE LIST
                Expanded(
                  child: _filteredLogs.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = _filteredLogs[index];
                            final isLast = index == _filteredLogs.length - 1;
                            return _buildTimelineItem(log, isLast);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // ===========================================================================
  // WIDGET BUILDERS
  // ===========================================================================

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _filter = label),
      selectedColor: AppColors.primaryBlue,
      backgroundColor: AppColors.surfaceDarkGrey,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textGrey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : AppColors.surfaceLightGrey.withAlpha(50),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(LogEntry log, bool isLast) {
    Color typeColor;
    IconData typeIcon;

    switch (log.type) {
      case LogType.financial:
        typeColor = AppColors.successGreen;
        typeIcon = Icons.attach_money;
        break;
      case LogType.alert:
        typeColor = AppColors.errorRed;
        typeIcon = Icons.warning_amber_rounded;
        break;
      case LogType.academic:
        typeColor = Colors.orangeAccent;
        typeIcon = Icons.school_outlined;
        break;
      case LogType.system:
        typeColor = AppColors.primaryBlue;
        typeIcon = Icons.settings_outlined;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DATE COLUMN
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat(AppStrings.mmm).format(log.timestamp).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat(AppStrings.dd).format(log.timestamp),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(AppStrings.hhmm).format(log.timestamp),
                  style: TextStyle(
                    color: AppColors.textGrey.withAlpha(150),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 2. TIMELINE LINE
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.backgroundBlack,
                  shape: BoxShape.circle,
                  border: Border.all(color: typeColor, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: typeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.surfaceLightGrey.withAlpha(30),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // 3. CONTENT CARD
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.surfaceLightGrey.withAlpha(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(typeIcon, size: 14, color: typeColor),
                        const SizedBox(width: 6),
                        Text(
                          log.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.description,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 12,
                          color: AppColors.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "By: ${log.performedBy}",
                          style: TextStyle(
                            color: AppColors.textGrey.withAlpha(150),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 48, color: AppColors.textGrey),
          SizedBox(height: 16),
          Text(AppStrings.errLogsNotFound, style: TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}
