import 'package:legend/app_libs.dart';
import 'package:legend/data/constants/app_routes.dart';

class OutstandingStudentsScreen extends StatefulWidget {
  const OutstandingStudentsScreen({super.key});

  @override
  State<OutstandingStudentsScreen> createState() => _OutstandingStudentsScreenState();
}

class _OutstandingStudentsScreenState extends State<OutstandingStudentsScreen> {
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
    return context.read<FinanceRepository>().getOutstandingStudents(school.id, limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        title: const Text("Outstanding Balances", style: TextStyle(color: Colors.white)),
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
              child: Text("No outstanding balances.", style: TextStyle(color: AppColors.textGrey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final row = rows[index];
              final name = (row['name'] ?? 'Unknown').toString();
              final grade = (row['grade'] ?? '—').toString();
              final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
              final studentId = (row['id'] ?? '').toString();

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
                      backgroundColor: AppColors.errorRed.withAlpha(20),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Grade $grade", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "\$${amount.toStringAsFixed(0)}",
                          style: const TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              onPressed: studentId.isEmpty ? null : () => context.go('${AppRoutes.students}/view/$studentId'),
                              child: const Text("View", style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
                            ),
                            TextButton(
                              onPressed: studentId.isEmpty
                                  ? null
                                  : () => context.go(
                                        '${AppRoutes.finance}/${AppRoutes.recordPayment}?studentId=$studentId',
                                      ),
                              child: const Text("Log Payment", style: TextStyle(color: AppColors.primaryBlue, fontSize: 11)),
                            ),
                          ],
                        ),
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
}
