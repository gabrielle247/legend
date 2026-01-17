// lib/screens/finance/finance_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legend/data/constants/app_constants.dart';
import 'package:legend/data/constants/app_routes.dart';
import 'package:legend/data/vmodels/finance_vmodel.dart';
import 'package:provider/provider.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceViewModel>().init();
    });
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION (NO PLACEBO)
  // ---------------------------------------------------------------------------
  void _navToCreateInvoice() {
    // Adjust if your routes differ.
    context.push('${AppRoutes.finance}/${AppRoutes.createInvoice}');
  }

  void _navToRecordPayment() {
    // Adjust if your routes differ.
    context.push('${AppRoutes.finance}/${AppRoutes.recordPayment}');
  }

  void _navToStudentIfPossible(Map<String, dynamic> item) {
    final targetId = item['targetId']?.toString();
    if (targetId == null || targetId.isEmpty) return;
    context.push('${AppRoutes.students}/view/$targetId');
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        if (vm.error != null) {
          return _ErrorScaffold(
            title: 'Finance',
            message: vm.error!,
            onRetry: vm.refresh,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundBlack,
            elevation: 0,
            centerTitle: false,
            automaticallyImplyLeading: false,
            title: const Text(
              'Finance',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: vm.refresh,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;

                // Keep content readable on very wide screens without “desktop-specific” UI.
                const contentMaxWidth = 980.0;
                final horizontalPadding = maxW < 420 ? 14.0 : 20.0;

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        10,
                        horizontalPadding,
                        110,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ActionStrip(
                            onCreateInvoice: _navToCreateInvoice,
                            onRecordPayment: _navToRecordPayment,
                          ),
                          const SizedBox(height: 16),

                          _StatsGrid(
                            width: maxW,
                            revenue: vm.totalRevenue,
                            pending: vm.pendingAmount,
                            unpaidCount: vm.unpaidInvoiceCount,
                            percentGrowth: vm.percentGrowth,
                            onTapRevenue: null, // No placebo screen
                            onTapPending: null, // No placebo screen
                          ),

                          const SizedBox(height: 18),

                          _CollectionsTrendCard(
                            monthlyCollections: vm.monthlyCollections,
                            monthLabels: vm.monthLabels,
                          ),

                          const SizedBox(height: 18),

                          _SectionHeaderRow(
                            title: 'Recent Activity',
                            right: Text(
                              'Tap a row to open student (if linked)',
                              style: TextStyle(
                                color: AppColors.textGrey.withAlpha(170),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          if (vm.recentActivity.isEmpty)
                            _EmptyStateCard(
                              icon: Icons.receipt_long,
                              title: 'No activity yet',
                              subtitle:
                                  'Once payments and invoices are recorded, activity will appear here.',
                            )
                          else
                            ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: vm.recentActivity.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final raw = vm.recentActivity[index];
                                final item = _sanitizeActivity(raw);

                                final canOpenStudent = (item['targetId'] != null &&
                                    item['targetId'].toString().isNotEmpty);

                                return _ActivityTile(
                                  name: item['name'] as String,
                                  desc: item['desc'] as String,
                                  amount: item['amount'] as double,
                                  time: item['time'] as String,
                                  kind: item['kind'] as _ActivityKind,
                                  enabled: canOpenStudent,
                                  onTap: () => _navToStudentIfPossible(item),
                                );
                              },
                            ),

                          const SizedBox(height: 18),

                          _InvoicesAndPaymentsCard(
                            pendingAmount: vm.pendingAmount,
                            unpaidInvoiceCount: vm.unpaidInvoiceCount,
                            onCreateInvoice: _navToCreateInvoice,
                            onRecordPayment: _navToRecordPayment,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: _PrimaryFab(
            onCreateInvoice: _navToCreateInvoice,
            onRecordPayment: _navToRecordPayment,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HARDEN ACTIVITY ROWS (NO CRASH, NO ASSUMPTIONS)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _sanitizeActivity(Map<String, dynamic> raw) {
    final name = (raw['name'] ?? 'Unknown').toString().trim();
    final desc = (raw['desc'] ?? raw['description'] ?? 'No description')
        .toString()
        .trim();

    final amountNum = raw['amount'];
    final amount = (amountNum is num) ? amountNum.toDouble() : 0.0;

    final time = (raw['time'] ?? '').toString().trim();
    final type = (raw['type'] ?? '').toString().toLowerCase().trim();

    final targetId = raw['targetId'] ?? raw['studentId'] ?? raw['student_id'];

    // Determine kind from type/amount direction (no toy “WARNING” assumptions).
    // - payment -> income
    // - invoice/debit -> expense
    // fallback: amount >= 0 => income, else expense
    final kind = (type.contains('payment'))
        ? _ActivityKind.income
        : (type.contains('invoice') || type.contains('debit'))
            ? _ActivityKind.expense
            : (amount >= 0 ? _ActivityKind.income : _ActivityKind.expense);

    return {
      'name': name,
      'desc': desc,
      'amount': amount.abs(),
      'time': time.isEmpty ? '—' : time,
      'kind': kind,
      'targetId': targetId?.toString(),
    };
  }
}

// =============================================================================
// UI PARTS
// =============================================================================

class _ErrorScaffold extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.errorRed, size: 44),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  final VoidCallback onCreateInvoice;
  final VoidCallback onRecordPayment;

  const _ActionStrip({
    required this.onCreateInvoice,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PrimaryActionButton(
              icon: Icons.add_circle_outline,
              label: 'Generate Invoice',
              onTap: onCreateInvoice,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PrimaryActionButton(
              icon: Icons.payments_outlined,
              label: 'Record Payments',
              onTap: onRecordPayment,
              color: AppColors.successGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundBlack,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(90)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final double width;
  final double revenue;
  final double pending;
  final int unpaidCount;
  final double percentGrowth;

  final VoidCallback? onTapRevenue;
  final VoidCallback? onTapPending;

  const _StatsGrid({
    required this.width,
    required this.revenue,
    required this.pending,
    required this.unpaidCount,
    required this.percentGrowth,
    required this.onTapRevenue,
    required this.onTapPending,
  });

  @override
  Widget build(BuildContext context) {
    // 2-up on most sizes; on very wide you still keep readable width due to parent constraint.
    final isNarrow = width < 420;

    final growth = percentGrowth.isFinite ? percentGrowth : 0.0;
    final growthPrefix = growth >= 0 ? '+' : '';
    final growthLabel = '$growthPrefix${growth.toStringAsFixed(1)}% vs previous';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: isNarrow ? double.infinity : (width - 12) / 2,
          child: _StatCard(
            title: 'REVENUE',
            amount: '\$${revenue.toStringAsFixed(0)}',
            subtitle: growthLabel,
            icon: Icons.attach_money,
            color: AppColors.successGreen,
            onTap: onTapRevenue,
          ),
        ),
        SizedBox(
          width: isNarrow ? double.infinity : (width - 12) / 2,
          child: _StatCard(
            title: 'PENDING',
            amount: '\$${pending.toStringAsFixed(0)}',
            subtitle: '$unpaidCount unpaid invoices',
            icon: Icons.pending_actions_outlined,
            color: Colors.orangeAccent,
            onTap: onTapPending,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (enabled)
                  Icon(Icons.chevron_right,
                      color: AppColors.textGrey.withAlpha(70), size: 18),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textGrey.withAlpha(220),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionsTrendCard extends StatelessWidget {
  final List<double> monthlyCollections;
  final List<String> monthLabels;

  const _CollectionsTrendCard({
    required this.monthlyCollections,
    required this.monthLabels,
  });

  @override
  Widget build(BuildContext context) {
    // Harden list lengths.
    final n = monthlyCollections.length < monthLabels.length
        ? monthlyCollections.length
        : monthLabels.length;

    final values = (n <= 0) ? <double>[] : monthlyCollections.take(n).toList();
    final labels = (n <= 0) ? <String>[] : monthLabels.take(n).toList();

    final maxVal = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final safeMax = (maxVal.isFinite && maxVal > 0) ? maxVal : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collections Trend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            safeMax == 0
                ? 'No collection data yet'
                : 'Peak month: \$${safeMax.toStringAsFixed(0)}',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 16),

          if (safeMax == 0 || values.isEmpty)
            const _MiniEmptyChart()
          else
            SizedBox(
              height: 170,
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final barCount = values.length;

                  // Dynamic bar width: never overflow, never microscopic.
                  final gap = 10.0;
                  final rawBarW =
                      (w - (gap * (barCount - 1))) / barCount;
                  final barW = rawBarW.clamp(16.0, 44.0);

                  return Align(
                    alignment: Alignment.bottomLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(barCount, (i) {
                          final v = values[i];
                          final pct = (v.isFinite && v > 0) ? (v / safeMax) : 0.0;
                          final label = labels[i];

                          return Padding(
                            padding: EdgeInsets.only(right: i == barCount - 1 ? 0 : gap),
                            child: _Bar(
                              width: barW,
                              heightPct: pct.clamp(0.0, 1.0),
                              label: label,
                              value: v,
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniEmptyChart extends StatelessWidget {
  const _MiniEmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.backgroundBlack,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(25)),
      ),
      child: Text(
        'No bars to render',
        style: TextStyle(
          color: AppColors.textGrey.withAlpha(200),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double heightPct;
  final String label;
  final double value;

  const _Bar({
    required this.width,
    required this.heightPct,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final barHeight = 120.0 * heightPct;

    return Tooltip(
      message: '\$${value.toStringAsFixed(2)}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            width: width,
            height: barHeight < 6 ? 6 : barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.primaryBlue, AppColors.primaryBlueLight],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: width + 8,
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textGrey.withAlpha(220),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  final String title;
  final Widget right;

  const _SectionHeaderRow({required this.title, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Flexible(child: right),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryBlue.withAlpha(20),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ActivityKind { income, expense }

class _ActivityTile extends StatelessWidget {
  final String name;
  final String desc;
  final double amount;
  final String time;
  final _ActivityKind kind;
  final bool enabled;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.name,
    required this.desc,
    required this.amount,
    required this.time,
    required this.kind,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = kind == _ActivityKind.income;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: (isIncome
                      ? AppColors.successGreen
                      : AppColors.errorRed)
                  .withAlpha(20),
              child: Icon(
                isIncome ? Icons.call_received : Icons.call_made,
                color: isIncome ? AppColors.successGreen : AppColors.errorRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textGrey.withAlpha(230),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isIncome ? AppColors.successGreen : AppColors.errorRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textGrey.withAlpha(70)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvoicesAndPaymentsCard extends StatelessWidget {
  final double pendingAmount;
  final int unpaidInvoiceCount;
  final VoidCallback onCreateInvoice;
  final VoidCallback onRecordPayment;

  const _InvoicesAndPaymentsCard({
    required this.pendingAmount,
    required this.unpaidInvoiceCount,
    required this.onCreateInvoice,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoices & Payments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pending: \$${pendingAmount.toStringAsFixed(2)} • $unpaidInvoiceCount invoices',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCreateInvoice,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Generate Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRecordPayment,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Record Payments'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryFab extends StatelessWidget {
  final VoidCallback onCreateInvoice;
  final VoidCallback onRecordPayment;

  const _PrimaryFab({
    required this.onCreateInvoice,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    // Small-screen: single FAB is cleaner. Provide a mini menu.
    return FloatingActionButton(
      backgroundColor: AppColors.primaryBlue,
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDarkGrey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SheetAction(
                      icon: Icons.add_circle_outline,
                      label: 'Generate Invoice',
                      color: AppColors.primaryBlue,
                      onTap: () {
                        Navigator.pop(context);
                        onCreateInvoice();
                      },
                    ),
                    const SizedBox(height: 10),
                    _SheetAction(
                      icon: Icons.payments_outlined,
                      label: 'Record Payments (Bulk)',
                      color: AppColors.successGreen,
                      onTap: () {
                        Navigator.pop(context);
                        onRecordPayment();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundBlack,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(100)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textGrey.withAlpha(80)),
            ],
          ),
        ),
      ),
    );
  }
}
