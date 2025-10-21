import 'package:coach_x/core/services/firestore_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';
import 'package:coach_x/features/auth/data/repositories/user_repository.dart';

/// 用户仓库实现
class UserRepositoryImpl implements UserRepository {
  static const String _collection = 'users';

  @override
  Future<void> createUser(UserModel user) async {
    try {
      await FirestoreService.setDocument(
        _collection,
        user.id,
        user.toFirestore(),
      );
      AppLogger.info('用户创建成功: ${user.id}');
    } catch (e, stackTrace) {
      AppLogger.error('创建用户失败: ${user.id}', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await FirestoreService.getDocument(_collection, userId);

      if (!doc.exists) {
        AppLogger.warning('用户不存在: $userId');
        return null;
      }

      return UserModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.error('获取用户失败: $userId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await FirestoreService.updateDocument(_collection, userId, data);
      AppLogger.info('用户更新成功: $userId');
    } catch (e, stackTrace) {
      AppLogger.error('更新用户失败: $userId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await FirestoreService.deleteDocument(_collection, userId);
      AppLogger.info('用户删除成功: $userId');
    } catch (e, stackTrace) {
      AppLogger.error('删除用户失败: $userId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<UserModel?> watchUser(String userId) {
    return FirestoreService.watchDocument(_collection, userId).map((doc) {
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromFirestore(doc);
    });
  }

  @override
  Future<bool> userExists(String userId) async {
    try {
      final doc = await FirestoreService.getDocument(_collection, userId);
      return doc.exists;
    } catch (e, stackTrace) {
      AppLogger.error('检查用户存在失败: $userId', e, stackTrace);
      return false;
    }
  }
}
