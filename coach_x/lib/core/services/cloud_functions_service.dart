import 'package:cloud_functions/cloud_functions.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/core/services/auth_service.dart';

/// Cloud Functions服务
///
/// 封装对Firebase Cloud Functions的调用
class CloudFunctionsService {
  CloudFunctionsService._();

  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Cloud Functions Base URL (用于 SSE 直连)
  static String get baseUrl {
    // 🔧 开发模式：使用本地模拟器
    // 将这里改为 true 即可使用本地测试
    final bool useLocalEmulator = true;

    if (useLocalEmulator) {
      return 'http://127.0.0.1:5001/coachx-9d219/us-central1';
    }

    // 生产环境
    // ignore: dead_code
    return 'https://us-central1-coachx-9d219.cloudfunctions.net';
  }

  /// 调用Cloud Function
  ///
  /// [functionName] 函数名称
  /// [parameters] 参数
  /// 返回函数执行结果
  static Future<Map<String, dynamic>> call(
    String functionName, [
    Map<String, dynamic>? parameters,
  ]) async {
    try {
      AppLogger.info('调用Cloud Function: $functionName');

      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call(parameters);

      AppLogger.info('Cloud Function调用成功: $functionName');
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('Cloud Function调用失败: $functionName', e);
      throw _handleFunctionsException(e);
    } catch (e, stackTrace) {
      AppLogger.error('Cloud Function调用失败: $functionName', e, stackTrace);
      rethrow;
    }
  }

  // ==================== 用户管理 ====================

  /// 获取用户信息
  ///
  /// [userId] 用户ID（可选，默认当前用户）
  static Future<Map<String, dynamic>> fetchUserInfo([String? userId]) async {
    final params = userId != null ? {'user_id': userId} : null;
    return await call('fetch_user_info', params);
  }

  /// 更新用户信息
  ///
  /// [name] 用户名
  /// [avatarUrl] 头像URL
  /// [role] 角色
  /// [gender] 性别
  /// [bornDate] 出生日期（格式: "yyyy-MM-dd"）
  /// [height] 身高（cm）
  /// [initialWeight] 体重（kg）
  /// [coachId] 教练ID
  static Future<Map<String, dynamic>> updateUserInfo({
    String? name,
    String? avatarUrl,
    String? role,
    String? gender,
    String? bornDate,
    double? height,
    double? initialWeight,
    String? coachId,
  }) async {
    final params = <String, dynamic>{};
    if (name != null) params['name'] = name;
    if (avatarUrl != null) params['avatarUrl'] = avatarUrl;
    if (role != null) params['role'] = role;
    if (gender != null) params['gender'] = gender;
    if (bornDate != null) params['bornDate'] = bornDate;
    if (height != null) params['height'] = height;
    if (initialWeight != null) params['initialWeight'] = initialWeight;
    if (coachId != null) params['coachId'] = coachId;

    return await call('update_user_info', params);
  }

  /// 更新用户的 Active Plan
  ///
  /// [planType] 计划类型：'exercise', 'diet', 'supplement'
  /// [planId] 计划ID
  static Future<Map<String, dynamic>> updateActivePlan({
    required String planType,
    required String planId,
  }) async {
    return await call('update_active_plan', {
      'planType': planType,
      'planId': planId,
    });
  }

  // ==================== 邀请码管理 ====================

  /// 验证邀请码
  ///
  /// [code] 邀请码
  /// [confirm] 是否确认使用 (默认false)
  /// 返回验证结果
  static Future<Map<String, dynamic>> verifyInvitationCode(
    String code, {
    bool confirm = false,
  }) async {
    return await call('verify_invitation_code', {
      'code': code,
      'confirm': confirm,
    });
  }

  /// 生成邀请码（教练专用）
  ///
  /// [count] 生成数量
  /// [totalDays] 签约总时长
  /// [note] 备注
  /// 返回生成的邀请码列表
  static Future<Map<String, dynamic>> generateInvitationCodes({
    int count = 1,
    int totalDays = 180,
    String? note,
  }) async {
    final params = <String, dynamic>{'count': count, 'total_days': totalDays};
    if (note != null && note.isNotEmpty) {
      params['note'] = note;
    }
    return await call('generate_invitation_codes', params);
  }

  /// 获取邀请码列表
  ///
  /// 返回教练的所有邀请码
  static Future<Map<String, dynamic>> fetchInvitationCodes() async {
    return await call('fetch_invitation_codes');
  }

  // ==================== 学生管理 ====================

  /// 获取学生列表
  ///
  /// [pageSize] 每页数量
  /// [pageNumber] 页码
  /// [searchName] 搜索姓名
  /// [filterPlanId] 筛选计划ID
  static Future<Map<String, dynamic>> fetchStudents({
    required int pageSize,
    required int pageNumber,
    String? searchName,
    String? filterPlanId,
  }) async {
    final params = <String, dynamic>{
      'page_size': pageSize,
      'page_number': pageNumber,
    };
    if (searchName != null && searchName.isNotEmpty) {
      params['search_name'] = searchName;
    }
    if (filterPlanId != null && filterPlanId.isNotEmpty) {
      params['filter_plan_id'] = filterPlanId;
    }
    return await call('fetch_students', params);
  }

  /// 删除学生
  ///
  /// [studentId] 学生ID
  static Future<Map<String, dynamic>> deleteStudent(String studentId) async {
    return await call('delete_student', {'student_id': studentId});
  }

  /// 获取可用计划列表
  ///
  /// 返回教练的所有计划
  static Future<Map<String, dynamic>> fetchAvailablePlans() async {
    return await call('fetch_available_plans');
  }

  // ==================== AI 生成API ====================

  /// AI 生成训练计划
  ///
  /// [prompt] 用户输入的提示词（可选，如果有 params）
  /// [type] 生成类型：'full_plan', 'next_day', 'exercises', 'sets', 'optimize'
  /// [context] 可选，上下文信息
  /// [studentId] 可选，学生ID
  /// [params] 可选，结构化参数（优先使用）
  static Future<Map<String, dynamic>> generateAITrainingPlan({
    String? prompt,
    required String type,
    Map<String, dynamic>? context,
    String? studentId,
    Map<String, dynamic>? params,
  }) async {
    final requestParams = <String, dynamic>{'type': type};
    if (prompt != null && prompt.isNotEmpty) {
      requestParams['prompt'] = prompt;
    }
    if (context != null) {
      requestParams['context'] = context;
    }
    if (studentId != null) {
      requestParams['studentId'] = studentId;
    }
    if (params != null) {
      requestParams['params'] = params;
    }
    return await call('generate_ai_training_plan', requestParams);
  }

  /// 从图片导入训练计划
  ///
  /// [imageUrl] 图片的 Firebase Storage URL
  static Future<Map<String, dynamic>> importPlanFromImage({
    required String imageUrl,
  }) async {
    final params = <String, dynamic>{'image_url': imageUrl};
    return await call('import_plan_from_image', params);
  }

  /// 从图片导入补剂计划
  ///
  /// [imageUrl] 图片的 Firebase Storage URL
  static Future<Map<String, dynamic>> importSupplementPlanFromImage({
    required String imageUrl,
  }) async {
    final params = <String, dynamic>{'image_url': imageUrl};
    return await call('import_supplement_plan_from_image', params);
  }

  /// 从文本导入训练计划
  ///
  /// [textContent] 训练计划文本内容
  static Future<Map<String, dynamic>> importPlanFromText({
    required String textContent,
  }) async {
    final params = <String, dynamic>{'text_content': textContent};
    return await call('import_plan_from_text', params);
  }

  // ==================== 计划管理API ====================

  /// 创建训练计划
  ///
  /// [planData] 计划数据
  static Future<Map<String, dynamic>> createExercisePlan({
    required Map<String, dynamic> planData,
  }) async {
    return await call('exercise_plan', {
      'action': 'create',
      'planData': planData,
    });
  }

  /// 更新训练计划
  ///
  /// [planId] 计划ID
  /// [planData] 计划数据
  static Future<Map<String, dynamic>> updateExercisePlan({
    required String planId,
    required Map<String, dynamic> planData,
  }) async {
    return await call('exercise_plan', {
      'action': 'update',
      'planId': planId,
      'planData': planData,
    });
  }

  /// 获取训练计划详情
  ///
  /// [planId] 计划ID
  static Future<Map<String, dynamic>> getExercisePlanDetail({
    required String planId,
  }) async {
    return await call('exercise_plan', {'action': 'get', 'planId': planId});
  }

  /// 删除训练计划
  ///
  /// [planId] 计划ID
  static Future<Map<String, dynamic>> deleteExercisePlan({
    required String planId,
  }) async {
    return await call('exercise_plan', {'action': 'delete', 'planId': planId});
  }

  /// 复制训练计划
  ///
  /// [planId] 计划ID
  static Future<Map<String, dynamic>> copyExercisePlan({
    required String planId,
  }) async {
    return await call('exercise_plan', {'action': 'copy', 'planId': planId});
  }

  // ==================== 学生端API ====================

  /// 获取学生被分配的计划
  ///
  /// 学生专用，返回分配给当前学生的训练、饮食、补剂计划
  /// 每类计划只返回一个（最新分配的）
  static Future<Map<String, dynamic>> getStudentAssignedPlans() async {
    return await call('get_student_assigned_plans');
  }

  /// 获取学生所有计划
  ///
  /// 学生专用，返回学生的所有计划（包括教练分配的和自己创建的）
  /// 返回格式：
  /// {
  ///   'exercisePlans': [...],
  ///   'dietPlans': [...],
  ///   'supplementPlans': [...]
  /// }
  static Future<Map<String, dynamic>> getStudentAllPlans() async {
    return await call('get_student_all_plans');
  }

  /// 获取学生最新训练记录
  ///
  /// 用于确定今天应该是计划的第几天
  static Future<Map<String, dynamic>> fetchLatestTraining() async {
    return await call('fetch_latest_training');
  }

  /// 获取今日训练记录
  ///
  /// [date] 日期 (格式: "yyyy-MM-dd")
  /// 返回今日的完整训练记录（包含饮食、训练、补剂）
  static Future<Map<String, dynamic>> fetchTodayTraining(String date) async {
    return await call('fetch_today_training', {'date': date});
  }

  /// 保存/更新今日训练记录
  ///
  /// [trainingData] 训练记录数据
  /// 返回保存结果
  static Future<Map<String, dynamic>> upsertTodayTraining(
    Map<String, dynamic> trainingData,
  ) async {
    return await call('upsert_today_training', trainingData);
  }

  /// 获取本周首页统计数据
  ///
  /// 传递客户端当前日期以确保时区同步
  ///
  /// 返回:
  /// - 本周训练打卡状态（7天）
  /// - 体重变化统计（本周平均 vs 上周平均）
  /// - 卡路里摄入统计（本周总量 vs 上周总量）
  /// - Volume PR 统计（选一个动作示例）
  static Future<Map<String, dynamic>> fetchWeeklyHomeStats() async {
    // 获取客户端当前日期（用户本地时区）
    final now = DateTime.now();
    final currentDate =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    return await call('fetch_weekly_home_stats', {'current_date': currentDate});
  }

  // ==================== 动作库管理 ====================

  /// 批量创建动作模板
  ///
  /// [exerciseNames] 动作名称列表
  ///
  /// 返回 Map<exerciseName, templateId>
  static Future<Map<String, String>> createExerciseTemplatesBatch(
    List<String> exerciseNames,
  ) async {
    try {
      AppLogger.info('🔧 调用批量创建模板 API: ${exerciseNames.length} 个');

      final response = await call(
        'create_exercise_templates_batch',
        {
          'coach_id': AuthService.currentUserId,
          'exercise_names': exerciseNames,
        },
      );

      if (response['status'] == 'success') {
        // 使用 safeMapCast 安全处理 Firebase 返回的嵌套数据
        final data = safeMapCast(response['data'], 'data');
        if (data == null) {
          throw Exception('Response data is null or invalid');
        }

        final templateIdMapData = safeMapCast(data['template_id_map'], 'template_id_map');
        if (templateIdMapData == null) {
          throw Exception('template_id_map is null or invalid');
        }

        final templateIdMap = Map<String, String>.from(templateIdMapData);

        AppLogger.info('✅ 批量创建成功: ${templateIdMap.length} 个模板');
        return templateIdMap;
      } else {
        throw Exception(response['error'] ?? 'Unknown error');
      }
    } catch (e) {
      AppLogger.error('❌ 批量创建模板 API 调用失败', e);
      rethrow;
    }
  }

  // ==================== 异常处理 ====================

  /// 处理Firebase Functions异常
  static Exception _handleFunctionsException(FirebaseFunctionsException e) {
    String message;

    switch (e.code) {
      case 'unauthenticated':
        message = '用户未登录';
        break;
      case 'permission-denied':
        message = '权限不足';
        break;
      case 'not-found':
        message = '资源不存在';
        break;
      case 'invalid-argument':
        message = '参数无效';
        break;
      case 'deadline-exceeded':
        message = '请求超时';
        break;
      case 'unavailable':
        message = '服务暂时不可用';
        break;
      case 'internal':
        message = '服务器内部错误';
        break;
      default:
        message = e.message ?? '未知错误';
    }

    return Exception(message);
  }
}
