import 'package:legend/app_libs.dart';

class DashboardActivityScreen extends StatefulWidget {
  const DashboardActivityScreen({super.key});

  @override
  State<DashboardActivityScreen> createState() => _DashboardActivityScreenState();
}

class _DashboardActivityScreenState extends State<DashboardActivityScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final auth = context.read<AuthService>();
    final school = auth.activeSchool;
    if (school == null) {
      throw Exception("No active school. Please log in again.");
    }
    return context.read<FinanceRepository>().getRecentActivity(school.id, limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        title: const Text("Recent Activity", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: AppColors.errorRed),
              ),
            );
          }

          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const Center(
              child: Text("No recent activity.", style: TextStyle(color: AppColors.textGrey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _sanitizeActivity(rows[index]);
              final isIncome = item['kind'] == _ActivityKind.income;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkGrey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surfaceLightGrey.withAlpha(20),
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? AppColors.successGreen : AppColors.errorRed,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(item['desc'], style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${isIncome ? '+' : '-'}\$${item['amount'].toStringAsFixed(0)}",
                          style: TextStyle(
                            color: isIncome ? AppColors.successGreen : AppColors.errorRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(item['time'], style: TextStyle(color: AppColors.textGrey.withAlpha(120), fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, dynamic> _sanitizeActivity(Map<String, dynamic> raw) {
    final name = (raw['name'] ?? 'Unknown').toString().trim();
    final desc = (raw['desc'] ?? raw['description'] ?? 'No description').toString().trim();
    final amountNum = raw['amount'];
    final amount = (amountNum is num) ? amountNum.toDouble() : 0.0;
    final time = (raw['time'] ?? '').toString().trim();
    final type = (raw['type'] ?? '').toString().toLowerCase().trim();

    final kind = (type.contains('payment') || type.contains('income'))
        ? _ActivityKind.income
        : (type.contains('invoice') || type.contains('debit') || type.contains('expense'))
            ? _ActivityKind.expense
            : (amount >= 0 ? _ActivityKind.income : _ActivityKind.expense);

    return {
      'name': name,
      'desc': desc,
      'amount': amount.abs(),
      'time': time.isEmpty ? '—' : time,
      'kind': kind,
    };
  }
}

enum _ActivityKind { income, expense }
