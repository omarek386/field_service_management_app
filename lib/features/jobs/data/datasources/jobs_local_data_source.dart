import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/job_model.dart';

abstract class JobsLocalDataSource {
  Future<List<JobModel>> getCachedJobs();
  Future<void> cacheJobs(List<JobModel> jobs);
}

class JobsLocalDataSourceImpl implements JobsLocalDataSource {
  final HiveInterface hive;
  static const String _jobsBoxName = 'jobs_box';
  static const String _jobsKey = 'cached_jobs_list';

  JobsLocalDataSourceImpl(this.hive);

  @override
  Future<List<JobModel>> getCachedJobs() async {
    try {
      final box = await hive.openBox(_jobsBoxName);
      final jsonListString = box.get(_jobsKey) as String?;
      if (jsonListString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonListString) as List<dynamic>;
        return jsonList
            .map((item) => JobModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw const CacheException('Failed to read cached jobs.');
    }
  }

  @override
  Future<void> cacheJobs(List<JobModel> jobs) async {
    try {
      final box = await hive.openBox(_jobsBoxName);
      final jsonListString = jsonEncode(jobs.map((j) => j.toJson()).toList());
      await box.put(_jobsKey, jsonListString);
    } catch (e) {
      throw const CacheException('Failed to cache jobs.');
    }
  }
}
