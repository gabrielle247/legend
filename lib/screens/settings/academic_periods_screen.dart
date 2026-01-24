import 'package:flutter/material.dart';
import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/constants/app_strings.dart';
import 'package:legend/data/models/academy_year.dart';
import 'package:legend/data/models/term.dart';
import 'package:legend/data/repo/academic_period_repo.dart';
import 'package:legend/data/services/auth/auth.dart';
import 'package:legend/data/vmodels/academic_periods_view_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AcademicPeriodsScreen extends StatelessWidget {
  const AcademicPeriodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return ChangeNotifierProvider(
      create: (_) => AcademicPeriodsViewModel(AcademicPeriodRepository(), auth)..init(),
      child: const _AcademicPeriodsContent(),
    );
  }
}

class _AcademicPeriodsContent extends StatelessWidget {
  const _AcademicPeriodsContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademicPeriodsViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    if (vm.error != null) {
      return _ErrorState(error: vm.error!, onRetry: vm.reload);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        title: const Text("Academic Periods", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoPanel(
              title: "Helper",
              message: "Set an active academic year and term. Admissions and billing depend on this.",
              actionLabel: "Add Academic Year",
              onAction: () => _showAddYearDialog(context, vm),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: "Academic Years",
              trailing: TextButton(
                onPressed: () => _showAddYearDialog(context, vm),
                child: const Text("Add Year"),
              ),
              child: vm.years.isEmpty
                  ? const _EmptyState(message: "No academic years yet.")
                  : Column(
                      children: vm.years.map((y) {
                        final isSelected = vm.selectedYearId == y.id;
                        return _YearCard(
                          year: y,
                          selected: isSelected,
                          onSelect: () => vm.selectYear(y.id),
                          onSetActive: y.isActive ? null : () => vm.setYearActive(y.id),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: "Terms",
              trailing: TextButton(
                onPressed: () => _showAddTermDialog(context, vm),
                child: const Text("Add Term"),
              ),
              child: vm.selectedYearId == null
                  ? const _EmptyState(message: "Select or add an academic year first.")
                  : (vm.terms.isEmpty
                      ? const _EmptyState(message: "No terms for this year yet.")
                      : Column(
                          children: vm.terms.map((t) {
                            return _TermCard(
                              term: t,
                              onSetActive: t.isActive ? null : () => vm.setTermActive(t.id),
                            );
                          }).toList(),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddYearDialog(BuildContext context, AcademicPeriodsViewModel vm) async {
    final nameCtrl = TextEditingController();
    DateTime startDate = DateTime(DateTime.now().year, 1, 1);
    DateTime endDate = DateTime(DateTime.now().year, 12, 31);
    bool setActive = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDarkGrey,
              title: const Text("New Academic Year", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Name",
                      labelStyle: const TextStyle(color: AppColors.textGrey),
                      hintText: "e.g. 2025",
                      hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(120)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(60)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DatePickerRow(
                    label: "Start Date",
                    date: startDate,
                    onPick: () async {
                      final picked = await _pickDate(dialogContext, startDate);
                      if (picked == null) return;
                      setState(() => startDate = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  _DatePickerRow(
                    label: "End Date",
                    date: endDate,
                    onPick: () async {
                      final picked = await _pickDate(dialogContext, endDate);
                      if (picked == null) return;
                      setState(() => endDate = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: setActive,
                    onChanged: (val) => setState(() => setActive = val),
                    title: const Text("Set Active", style: TextStyle(color: Colors.white)),
                    activeColor: AppColors.primaryBlue,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.textGrey)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(AppStrings.save, style: TextStyle(color: AppColors.primaryBlue)),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack(context, "Name is required.");
      return;
    }
    if (endDate.isBefore(startDate)) {
      _showSnack(context, "End date must be after start date.");
      return;
    }

    await vm.addYear(
      name: name,
      startDate: startDate,
      endDate: endDate,
      setActive: setActive,
    );
  }

  Future<void> _showAddTermDialog(BuildContext context, AcademicPeriodsViewModel vm) async {
    final yearId = vm.selectedYearId;
    if (yearId == null) {
      _showSnack(context, "Add or select an academic year first.");
      return;
    }

    final nameCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));
    bool setActive = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDarkGrey,
              title: const Text("New Term", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Name",
                      labelStyle: const TextStyle(color: AppColors.textGrey),
                      hintText: "e.g. Term 1",
                      hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(120)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(60)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DatePickerRow(
                    label: "Start Date",
                    date: startDate,
                    onPick: () async {
                      final picked = await _pickDate(dialogContext, startDate);
                      if (picked == null) return;
                      setState(() => startDate = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  _DatePickerRow(
                    label: "End Date",
                    date: endDate,
                    onPick: () async {
                      final picked = await _pickDate(dialogContext, endDate);
                      if (picked == null) return;
                      setState(() => endDate = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: setActive,
                    onChanged: (val) => setState(() => setActive = val),
                    title: const Text("Set Active", style: TextStyle(color: Colors.white)),
                    activeColor: AppColors.primaryBlue,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.textGrey)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(AppStrings.save, style: TextStyle(color: AppColors.primaryBlue)),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack(context, "Name is required.");
      return;
    }
    if (endDate.isBefore(startDate)) {
      _showSnack(context, "End date must be after start date.");
      return;
    }

    await vm.addTerm(
      academicYearId: yearId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      setActive: setActive,
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              surface: AppColors.surfaceDarkGrey,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _YearCard extends StatelessWidget {
  final AcademicYear year;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onSetActive;

  const _YearCard({
    required this.year,
    required this.selected,
    required this.onSelect,
    required this.onSetActive,
  });

  @override
  Widget build(BuildContext context) {
    final range = "${_fmt(year.startDate)} to ${_fmt(year.endDate)}";
    return InkWell(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.backgroundBlack : AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.surfaceLightGrey.withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(year.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(range, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                ],
              ),
            ),
            if (year.isActive)
              _StatusPill(label: "Active", color: AppColors.successGreen)
            else if (onSetActive != null)
              TextButton(onPressed: onSetActive, child: const Text("Set Active")),
          ],
        ),
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  final Term term;
  final VoidCallback? onSetActive;

  const _TermCard({required this.term, required this.onSetActive});

  @override
  Widget build(BuildContext context) {
    final range = "${_fmt(term.startDate)} to ${_fmt(term.endDate)}";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(60)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(term.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(range, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          if (term.isActive)
            _StatusPill(label: "Active", color: AppColors.successGreen)
          else if (onSetActive != null)
            TextButton(onPressed: onSetActive, child: const Text("Set Active")),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InfoPanel({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onPick;

  const _DatePickerRow({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(60)),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textGrey)),
            const Spacer(),
            Text(_fmt(date), style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_month, color: AppColors.textGrey, size: 16),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlack,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(40)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.textGrey)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 40),
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime date) => DateFormat("yyyy-MM-dd").format(date);
