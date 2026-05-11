import '../../../../core/database/app_database.dart';

class StepsLocalDataSource {
  Future<List<Map<String, dynamic>>> getSteps(String categoryCode) async {
    try {
      return await AppDatabase.instance.getStepsByCategory(categoryCode);
    } catch (e) {
      throw Exception('Error fetching steps: $e');
    }
  }
}