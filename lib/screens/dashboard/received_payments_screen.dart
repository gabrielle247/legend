import 'package:legend/app_libs.dart';
import 'package:legend/data/constants/app_routes.dart';

class ReceivedPaymentsScreen extends StatefulWidget {
  const ReceivedPaymentsScreen({super.key});

  @override
  State<ReceivedPaymentsScreen> createState() => _ReceivedPaymentsScreenState();
}

class _ReceivedPaymentsScreenState extends State<ReceivedPaymentsScreen> {
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
    return context.read<FinanceRepository>().getRecentPayments(
          school.id,
          limit: 50,
          onDate: DateTime.now(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        title: const Text("Today's Received", style: TextStyle(color: Colors.white)),
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
              child: Text("No payments received today.", style: TextStyle(color: AppColors.textGrey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final row = rows[index];
              final name = (row['name'] ?? 'Unknown').toString();
              final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
              final method = (row['method'] ?? '—').toString();
              final time = (row['time'] ?? '—').toString();
              final studentId = (row['studentId'] ?? '').toString();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkGrey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
                ),
                child: InkWell(
                  onTap: studentId.isEmpty ? null : () => context.go('${AppRoutes.students}/view/$studentId'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.successGreen.withAlpha(20),
                        child: const Icon(Icons.arrow_downward, color: AppColors.successGreen, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(method, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "+\$${amount.toStringAsFixed(0)}",
                            style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(time, style: TextStyle(color: AppColors.textGrey.withAlpha(120), fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
