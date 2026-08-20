import 'package:shopx/infrastructure/dashboard/admin_dashboard_api.dart';

class AdminDashboardRepository {
  final AdminDashboardApi api;

  AdminDashboardRepository(this.api);

  Future<Map<String, dynamic>> getDashboardData() async {
    return await api.fetchDashboard();
  }
}
