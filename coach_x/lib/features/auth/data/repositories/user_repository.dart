import 'package:coach_x/features/auth/data/models/user_model.dart';

/// 用户仓库接口
abstract class UserRepository {
  /// 创建用户
  Future<void> createUser(UserModel user);

  /// 获取用户信息
  Future<UserModel?> getUser(String userId);

  /// 更新用户信息
  Future<void> updateUser(String userId, Map<String, dynamic> data);

  /// 删除用户
  Future<void> deleteUser(String userId);

  /// 监听用户信息变化
  Stream<UserModel?> watchUser(String userId);

  /// 检查用户是否存在
  Future<bool> userExists(String userId);
}

