import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/service_report_model.dart';

abstract class ReportsLocalDataSource {
  Future<void> cacheReport(ServiceReportModel report);
  Future<List<ServiceReportModel>> getCachedReports();
  Future<List<ServiceReportModel>> getUnsyncedReports();
  Future<void> markAsSynced(String reportId);
}

class ReportsLocalDataSourceImpl implements ReportsLocalDataSource {
  final HiveInterface hive;
  static const String _reportsBoxName = 'reports_box';
  static const String _reportsKey = 'cached_reports_list';
  static const String _syncQueueKey = 'unsynced_reports_list';

  ReportsLocalDataSourceImpl(this.hive);

  @override
  Future<List<ServiceReportModel>> getCachedReports() async {
    try {
      final box = await hive.openBox(_reportsBoxName);
      final jsonListString = box.get(_reportsKey) as String?;
      if (jsonListString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonListString) as List<dynamic>;
        return jsonList
            .map((item) => ServiceReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw const CacheException('Failed to read cached reports.');
    }
  }

  @override
  Future<void> cacheReport(ServiceReportModel report) async {
    try {
      final box = await hive.openBox(_reportsBoxName);
      
      // Update general cached list
      final currentList = await getCachedReports();
      currentList.add(report);
      await box.put(_reportsKey, jsonEncode(currentList.map((r) => r.toJson()).toList()));

      // Put in unsynced list (queue)
      final unsynced = await getUnsyncedReports();
      unsynced.add(report);
      await box.put(_syncQueueKey, jsonEncode(unsynced.map((r) => r.toJson()).toList()));
    } catch (e) {
      throw const CacheException('Failed to cache report.');
    }
  }

  @override
  Future<List<ServiceReportModel>> getUnsyncedReports() async {
    try {
      final box = await hive.openBox(_reportsBoxName);
      final jsonListString = box.get(_syncQueueKey) as String?;
      if (jsonListString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonListString) as List<dynamic>;
        return jsonList
            .map((item) => ServiceReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw const CacheException('Failed to read unsynced reports.');
    }
  }

  @override
  Future<void> markAsSynced(String reportId) async {
    try {
      final box = await hive.openBox(_reportsBoxName);
      final currentUnsynced = await getUnsyncedReports();
      currentUnsynced.removeWhere((r) => r.id == reportId);
      await box.put(_syncQueueKey, jsonEncode(currentUnsynced.map((r) => r.toJson()).toList()));
    } catch (e) {
      throw const CacheException('Failed to update sync queue.');
    }
  }
}
