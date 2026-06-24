import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final HiveInterface hive;
  static const String _userBoxName = 'user_box';
  static const String _userKey = 'cached_user';

  AuthLocalDataSourceImpl(this.hive);

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final box = await hive.openBox(_userBoxName);
      final jsonString = box.get(_userKey) as String?;
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return UserModel.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      throw const CacheException('Failed to read cached user.');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final box = await hive.openBox(_userBoxName);
      final jsonString = jsonEncode(user.toJson());
      await box.put(_userKey, jsonString);
    } catch (e) {
      throw const CacheException('Failed to cache user.');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await hive.openBox(_userBoxName);
      await box.delete(_userKey);
    } catch (e) {
      throw const CacheException('Failed to clear cached user.');
    }
  }
}
