import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/enums/ai_status.dart';
import 'package:coach_x/features/coach/plans/data/models/ai/ai_generation_response.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_training_day.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_generation_params.dart';
import 'package:coach_x/features/coach/plans/data/models/import_result.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_import_result.dart';
import 'package:coach_x/features/coach/plans/data/models/ai_stream_event.dart';
import 'package:coach_x/features/coach/plans/data/models/edit_stream_event.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cloud_functions_service.dart';

/// AI 服务
///
/// 提供 AI 生成训练计划的功能
class AIService {
  AIService._();

  /// 生成完整训练计划
  ///
  /// [prompt] 用户输入的需求描述
  /// [studentId] 可选，为特定学生定制
  /// 返回 AI 生成的响应
  static Future<AIGenerationResponse> generateFullPlan({
    required String prompt,
    String? studentId,
  }) async {
    try {
      AppLogger.info(
        '🤖 AI生成完整计划 - Prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...',
      );

      final result = await CloudFunctionsService.generateAITrainingPlan(
        prompt: prompt,
        type: 'full_plan',
        studentId: studentId,
      );

      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null && data['plan'] != null) {
          try {
            final plan = ExercisePlanModel.fromJson(
              data['plan'] as Map<String, dynamic>,
            );
            AppLogger.info('✅ 完整计划生成成功 - ${plan.totalDays} 个训练日');

            return AIGenerationResponse(
              status: AIGenerationStatus.success,
              plan: plan,
            );
          } catch (e) {
            AppLogger.error('❌ 解析计划数据失败', e);
            return AIGenerationResponse(
              status: AIGenerationStatus.error,
              error: '数据解析失败: $e',
            );
          }
        }
      }

      final error = result['error'] as String? ?? '生成失败';
      AppLogger.warning('⚠️ AI生成失败: $error');

      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: error,
      );
    } catch (e) {
      AppLogger.error('❌ AI服务错误', e);
      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: '服务错误: $e',
      );
    }
  }

  /// 推荐下一个训练日
  ///
  /// [existingDays] 已有的训练日列表
  /// [goal] 训练目标
  /// 返回推荐的训练日列表
  static Future<AIGenerationResponse> suggestNextDay({
    required List<ExerciseTrainingDay> existingDays,
    required String goal,
  }) async {
    try {
      AppLogger.info('🤖 AI推荐下一个训练日 - 已有: ${existingDays.length} 天');

      final context = {
        'days': existingDays.map((day) => day.toJson()).toList(),
      };

      final result = await CloudFunctionsService.generateAITrainingPlan(
        prompt: goal,
        type: 'next_day',
        context: context,
      );

      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null && data['days'] != null) {
          try {
            final daysJson = data['days'] as List<dynamic>;
            final days = daysJson
                .map(
                  (json) => ExerciseTrainingDay.fromJson(
                    json as Map<String, dynamic>,
                  ),
                )
                .toList();

            AppLogger.info('✅ 训练日推荐成功 - ${days.length} 个');

            return AIGenerationResponse(
              status: AIGenerationStatus.success,
              days: days,
            );
          } catch (e) {
            AppLogger.error('❌ 解析训练日数据失败', e);
            return AIGenerationResponse(
              status: AIGenerationStatus.error,
              error: '数据解析失败: $e',
            );
          }
        }
      }

      final error = result['error'] as String? ?? '推荐失败';
      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: error,
      );
    } catch (e) {
      AppLogger.error('❌ AI服务错误', e);
      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: '服务错误: $e',
      );
    }
  }

  /// 推荐动作
  ///
  /// [dayType] 训练日类型（如 "Leg Day"）
  /// [existingExercises] 已有的动作列表
  /// 返回推荐的动作列表
  static Future<AIGenerationResponse> suggestExercises({
    required String dayType,
    List<Exercise> existingExercises = const [],
  }) async {
    try {
      AppLogger.info('🤖 AI推荐动作 - 类型: $dayType');

      final context = {
        'exercises': existingExercises.map((ex) => ex.toJson()).toList(),
      };

      final result = await CloudFunctionsService.generateAITrainingPlan(
        prompt: dayType,
        type: 'exercises',
        context: context,
      );

      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null && data['exercises'] != null) {
          try {
            final exercisesJson = data['exercises'] as List<dynamic>;
            final exercises = exercisesJson
                .map((json) => Exercise.fromJson(json as Map<String, dynamic>))
                .toList();

            AppLogger.info('✅ 动作推荐成功 - ${exercises.length} 个');

            return AIGenerationResponse(
              status: AIGenerationStatus.success,
              exercises: exercises,
            );
          } catch (e) {
            AppLogger.error('❌ 解析动作数据失败', e);
            return AIGenerationResponse(
              status: AIGenerationStatus.error,
              error: '数据解析失败: $e',
            );
          }
        }
      }

      final error = result['error'] as String? ?? '推荐失败';
      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: error,
      );
    } catch (e) {
      AppLogger.error('❌ AI服务错误', e);
      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: '服务错误: $e',
      );
    }
  }

  /// 推荐 Sets 配置
  ///
  /// [exerciseName] 动作名称
  /// [userLevel] 用户水平（初级/中级/高级）
  /// 返回推荐的 Sets 列表
  static Future<AIGenerationResponse> suggestSets({
    required String exerciseName,
    String userLevel = '中级',
  }) async {
    try {
      AppLogger.info('🤖 AI推荐Sets - 动作: $exerciseName');

      final context = {'userLevel': userLevel};

      final result = await CloudFunctionsService.generateAITrainingPlan(
        prompt: exerciseName,
        type: 'sets',
        context: context,
      );

      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null && data['sets'] != null) {
          try {
            final setsJson = data['sets'] as List<dynamic>;
            final sets = setsJson
                .map(
                  (json) => TrainingSet.fromJson(json as Map<String, dynamic>),
                )
                .toList();

            AppLogger.info('✅ Sets推荐成功 - ${sets.length} 组');

            return AIGenerationResponse(
              status: AIGenerationStatus.success,
              sets: sets,
            );
          } catch (e) {
            AppLogger.error('❌ 解析Sets数据失败', e);
            return AIGenerationResponse(
              status: AIGenerationStatus.error,
              error: '数据解析失败: $e',
            );
          }
        }
      }

      final error = result['error'] as String? ?? '推荐失败';
      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: error,
      );
    } catch (e) {
      AppLogger.error('❌ AI服务错误', e);
      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: '服务错误: $e',
      );
    }
  }

  /// 从图片导入训练计划
  ///
  /// [imageUrl] 图片的 Firebase Storage URL
  /// 返回导入结果（包含计划和置信度）
  static Future<ImportResult> importPlanFromImage({
    required String imageUrl,
  }) async {
    try {
      AppLogger.info('📷 从图片导入训练计划');
      AppLogger.info('图片 URL: $imageUrl');

      final result = await CloudFunctionsService.importPlanFromImage(
        imageUrl: imageUrl,
      );

      // 解析结果
      final importResult = ImportResult.fromJson(result);

      if (importResult.isSuccess) {
        AppLogger.info(
          '✅ 图片导入成功 - 置信度: ${(importResult.confidence * 100).toStringAsFixed(0)}%',
        );
        if (importResult.hasWarnings) {
          AppLogger.warning('⚠️ 警告: ${importResult.warnings.join(", ")}');
        }
      } else {
        AppLogger.warning('⚠️ 图片导入失败: ${importResult.errorMessage}');
      }

      return importResult;
    } catch (e) {
      AppLogger.error('❌ 图片导入异常', e);
      return ImportResult.failure(errorMessage: '图片导入失败: $e');
    }
  }

  /// 从图片导入补剂计划
  ///
  /// [imageUrl] 图片的 Firebase Storage URL
  /// 返回导入结果（包含补剂计划和置信度）
  static Future<SupplementImportResult> importSupplementPlanFromImage({
    required String imageUrl,
  }) async {
    try {
      AppLogger.info('📷 从图片导入补剂计划');
      AppLogger.info('图片 URL: $imageUrl');

      final result = await CloudFunctionsService.importSupplementPlanFromImage(
        imageUrl: imageUrl,
      );

      // 解析结果
      final importResult = SupplementImportResult.fromJson(result);

      if (importResult.isSuccess) {
        AppLogger.info(
          '✅ 图片导入成功 - 置信度: ${(importResult.confidence * 100).toStringAsFixed(0)}%',
        );
        if (importResult.hasWarnings) {
          AppLogger.warning('⚠️ 警告: ${importResult.warnings.join(", ")}');
        }
      } else {
        AppLogger.warning('⚠️ 图片导入失败: ${importResult.errorMessage}');
      }

      return importResult;
    } catch (e) {
      AppLogger.error('❌ 补剂计划图片导入异常', e);
      return SupplementImportResult.failure(errorMessage: '图片导入失败: $e');
    }
  }

  /// 基于结构化参数生成训练计划
  ///
  /// [params] 结构化参数对象
  /// 返回 AI 生成的完整训练计划
  static Future<AIGenerationResponse> generatePlanFromParams({
    required PlanGenerationParams params,
  }) async {
    try {
      AppLogger.info('🤖 基于结构化参数生成训练计划');
      AppLogger.info('参数: ${params.toString()}');

      // 验证参数
      if (!params.isValid) {
        final errors = params.validationErrors;
        AppLogger.warning('⚠️ 参数验证失败: ${errors.join(", ")}');
        return AIGenerationResponse(
          status: AIGenerationStatus.error,
          error: '参数验证失败: ${errors.first}',
        );
      }

      final result = await CloudFunctionsService.generateAITrainingPlan(
        prompt: '', // 使用参数，不需要 prompt
        type: 'full_plan',
        params: params.toJson(),
      );

      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null && data['plan'] != null) {
          try {
            final plan = ExercisePlanModel.fromJson(
              data['plan'] as Map<String, dynamic>,
            );
            AppLogger.info('✅ 结构化参数生成成功 - ${plan.totalDays} 个训练日');

            return AIGenerationResponse(
              status: AIGenerationStatus.success,
              plan: plan,
            );
          } catch (e) {
            AppLogger.error('❌ 解析计划数据失败', e);
            return AIGenerationResponse(
              status: AIGenerationStatus.error,
              error: '数据解析失败: $e',
            );
          }
        }
      }

      final error = result['error'] as String? ?? '生成失败';
      AppLogger.warning('⚠️ AI生成失败: $error');

      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: error,
      );
    } catch (e) {
      AppLogger.error('❌ AI服务错误', e);
      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: '服务错误: $e',
      );
    }
  }

  /// 流式生成训练计划
  ///
  /// 使用 SSE 接收实时生成进度
  /// [params] 结构化参数对象
  /// 返回 Stream，实时 yield 生成事件
  static Stream<AIStreamEvent> generatePlanStreaming({
    required PlanGenerationParams params,
  }) async* {
    try {
      AppLogger.info('🔄 开始流式生成训练计划');
      AppLogger.info('参数: ${params.toString()}');

      // 验证参数
      if (!params.isValid) {
        final errors = params.validationErrors;
        AppLogger.warning('⚠️ 参数验证失败: ${errors.join(", ")}');
        yield AIStreamEvent(type: 'error', error: '参数验证失败: ${errors.first}');
        return;
      }

      // 构建请求 URL
      final url = Uri.parse(
        '${CloudFunctionsService.baseUrl}/stream_training_plan',
      );

      // 发起 HTTP POST 请求
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(params.toJson());

      AppLogger.info('发送流式请求到: $url');

      // 发送请求并获取流式响应
      final response = await request.send();

      if (response.statusCode != 200) {
        AppLogger.error('❌ 请求失败: ${response.statusCode}');
        yield AIStreamEvent(
          type: 'error',
          error: '请求失败: HTTP ${response.statusCode}',
        );
        return;
      }

      AppLogger.info('✅ SSE 连接建立');

      // 读取 SSE 流
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        // 按行分割
        final lines = chunk.split('\n');

        for (final line in lines) {
          // SSE 格式：data: {...}
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data.isEmpty) continue;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final event = AIStreamEvent.fromJson(json);

              AppLogger.debug('收到事件: ${event.type}');
              yield event;

              // 如果是完成或错误，结束流
              if (event.isComplete || event.isError) {
                return;
              }
            } catch (e) {
              AppLogger.warning('解析 SSE 数据失败: $e');
              // 继续处理下一个事件
            }
          }
        }
      }

      AppLogger.info('✅ SSE 流结束');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 流式生成异常', e, stackTrace);
      yield AIStreamEvent(type: 'error', error: '生成失败: $e');
    }
  }

  /// 优化训练计划
  ///
  /// [currentPlan] 当前计划
  /// 返回优化建议和优化后的计划
  static Future<AIGenerationResponse> optimizePlan({
    required ExercisePlanModel currentPlan,
  }) async {
    try {
      AppLogger.info('🤖 AI优化计划 - ID: ${currentPlan.id}');

      final context = {'plan': currentPlan.toJson()};

      final result = await CloudFunctionsService.generateAITrainingPlan(
        prompt: '',
        type: 'optimize',
        context: context,
      );

      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null) {
          try {
            ExercisePlanModel? optimizedPlan;
            if (data['optimizedPlan'] != null) {
              optimizedPlan = ExercisePlanModel.fromJson(
                data['optimizedPlan'] as Map<String, dynamic>,
              );
            }

            AppLogger.info('✅ 计划优化成功');

            return AIGenerationResponse(
              status: AIGenerationStatus.success,
              plan: optimizedPlan,
            );
          } catch (e) {
            AppLogger.error('❌ 解析优化数据失败', e);
            return AIGenerationResponse(
              status: AIGenerationStatus.error,
              error: '数据解析失败: $e',
            );
          }
        }
      }

      final error = result['error'] as String? ?? '优化失败';
      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: error,
      );
    } catch (e) {
      AppLogger.error('❌ AI服务错误', e);
      return AIGenerationResponse(
        status: AIGenerationStatus.error,
        error: '服务错误: $e',
      );
    }
  }

  /// 对话式编辑训练计划（流式）
  ///
  /// [planId] 计划ID
  /// [userMessage] 用户的修改请求
  /// [currentPlan] 当前完整计划
  /// 返回 Stream，实时 yield 编辑事件
  static Stream<EditStreamEvent> editPlanConversation({
    required String planId,
    required String userMessage,
    required ExercisePlanModel currentPlan,
  }) async* {
    try {
      AppLogger.info('🔄 开始对话式编辑训练计划');
      AppLogger.info(
        '用户请求: ${userMessage.substring(0, userMessage.length > 50 ? 50 : userMessage.length)}...',
      );

      // 获取当前用户ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('❌ 用户未登录');
        yield EditStreamEvent(type: 'error', error: '用户未登录');
        return;
      }

      // 构建请求 URL
      final url = Uri.parse(
        '${CloudFunctionsService.baseUrl}/edit_plan_conversation',
      );

      // 发起 HTTP POST 请求
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'user_id': user.uid,
        'plan_id': planId,
        'user_message': userMessage,
        'current_plan': currentPlan.toJson(),
      });

      AppLogger.info('发送编辑请求到: $url');

      // 发送请求并获取流式响应
      final response = await request.send();

      if (response.statusCode != 200) {
        AppLogger.error('❌ 请求失败: ${response.statusCode}');
        yield EditStreamEvent(
          type: 'error',
          error: '请求失败: HTTP ${response.statusCode}',
        );
        return;
      }

      AppLogger.info('✅ SSE 连接建立');

      // 读取 SSE 流
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        // 按行分割
        final lines = chunk.split('\n');

        for (final line in lines) {
          // SSE 格式：data: {...}
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data.isEmpty) continue;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final event = EditStreamEvent.fromJson(json);

              AppLogger.debug('收到事件: ${event.type}');
              yield event;

              // 如果是完成或错误，结束流
              if (event.isComplete || event.isError) {
                return;
              }
            } catch (e) {
              AppLogger.warning('解析 SSE 数据失败: $e');
              // 继续处理下一个事件
            }
          }
        }
      }

      AppLogger.info('✅ SSE 流结束');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 对话式编辑异常', e, stackTrace);
      yield EditStreamEvent(type: 'error', error: '编辑失败: $e');
    }
  }

  /// AI 获取食物营养信息
  ///
  /// [foodName] 食物名称
  /// 返回每100g食物的营养数据
  static Future<Macros> getFoodMacros(String foodName) async {
    try {
      AppLogger.info('🥗 AI获取食物营养信息: $foodName');

      final result = await CloudFunctionsService.call('get_food_macros', {
        'food_name': foodName,
      });

      if (result['status'] == 'success') {
        final data = result['data'];

        // 安全地转换为 Map<String, dynamic>
        final macrosData = data is Map
            ? Map<String, dynamic>.from(data as Map)
            : <String, dynamic>{};

        final macros = Macros.fromJson(macrosData);
        AppLogger.info('✅ 营养信息获取成功: $macros');
        return macros;
      } else {
        AppLogger.warning('⚠️ AI无法获取营养信息: ${result['message']}');
        // 返回默认值
        return Macros.zero();
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 获取食物营养信息失败', e, stackTrace);
      // 发生错误时返回默认值，不阻塞用户流程
      return Macros.zero();
    }
  }

  /// 使用 Claude Skill 生成完整饮食计划
  ///
  /// [params] 饮食计划生成参数
  /// 返回饮食计划数据（包含 name, description, days）
  static Future<Map<String, dynamic>> generateDietPlanWithSkill({
    required Map<String, dynamic> params,
  }) async {
    try {
      AppLogger.info('🍽️ AI生成饮食计划（Skill模式）');
      AppLogger.debug('参数: $params');

      final result = await CloudFunctionsService.call(
        'generate_diet_plan_with_skill',
        params,
      );

      if (result['status'] == 'success') {
        final data = result['data'];
        final dietPlan = data['diet_plan'];

        AppLogger.info('✅ 饮食计划生成成功');
        AppLogger.debug('BMR: ${data['bmr_kcal']}, TDEE: ${data['tdee_kcal']}');

        // 返回完整的饮食计划数据
        return {
          'name': dietPlan['name'] ?? '饮食计划',
          'description': dietPlan['description'] ?? '',
          'days': dietPlan['days'] ?? [],
        };
      } else {
        final error = result['message'] ?? '生成失败';
        AppLogger.error('❌ 饮食计划生成失败: $error');
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 生成饮食计划异常', e, stackTrace);
      rethrow;
    }
  }

  /// 对话式编辑饮食计划（流式）
  ///
  /// [planId] 计划ID
  /// [userMessage] 用户的修改请求
  /// [currentPlan] 当前完整饮食计划
  /// 返回 Stream，实时 yield 编辑事件
  static Stream<EditStreamEvent> editDietPlanConversation({
    required String planId,
    required String userMessage,
    required dynamic currentPlan, // DietPlanModel
  }) async* {
    try {
      AppLogger.info('🔄 开始对话式编辑饮食计划');
      AppLogger.info(
        '用户请求: ${userMessage.substring(0, userMessage.length > 50 ? 50 : userMessage.length)}...',
      );

      // 获取当前用户ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('❌ 用户未登录');
        yield EditStreamEvent(type: 'error', error: '用户未登录');
        return;
      }

      // 构建请求 URL
      final url = Uri.parse(
        '${CloudFunctionsService.baseUrl}/edit_diet_plan_conversation',
      );

      // 发起 HTTP POST 请求
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'user_id': user.uid,
        'plan_id': planId,
        'user_message': userMessage,
        'current_plan': currentPlan.toJson(),
      });

      AppLogger.info('发送编辑请求到: $url');

      // 发送请求并获取流式响应
      final response = await request.send();

      if (response.statusCode != 200) {
        AppLogger.error('❌ 请求失败: ${response.statusCode}');
        yield EditStreamEvent(
          type: 'error',
          error: '请求失败: HTTP ${response.statusCode}',
        );
        return;
      }

      AppLogger.info('✅ SSE 连接建立');

      // 读取 SSE 流
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        // 按行分割
        final lines = chunk.split('\n');

        for (final line in lines) {
          // SSE 格式：data: {...}
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data.isEmpty) continue;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;

              // 🆕 详细日志：显示接收到的原始数据
              AppLogger.debug('📦 原始 JSON 数据: ${json.toString()}');

              final event = EditStreamEvent.fromJson(json);

              AppLogger.debug('收到事件: ${event.type}, hasData=${event.data != null}, hasContent=${event.content != null}');

              // 🆕 如果有 data 字段，打印其 keys
              if (event.data != null) {
                AppLogger.debug('事件 data 包含的 keys: ${event.data!.keys.join(", ")}');
              }

              yield event;

              // 如果是完成或错误，结束流
              if (event.isComplete || event.isError) {
                return;
              }
            } catch (e) {
              AppLogger.warning('解析 SSE 数据失败: $e, 原始行: ${line.substring(0, line.length > 100 ? 100 : line.length)}');
              // 继续处理下一个事件
            }
          }
        }
      }

      AppLogger.info('✅ SSE 流结束');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 对话式编辑饮食计划异常', e, stackTrace);
      yield EditStreamEvent(type: 'error', error: '编辑失败: $e');
    }
  }

  /// AI 生成补剂计划对话（流式）
  ///
  /// [userMessage] 用户的请求消息
  /// [trainingPlanId] 训练计划ID（可选）
  /// [dietPlanId] 饮食计划ID（可选）
  /// [conversationHistory] 对话历史
  /// 返回 Stream，实时 yield 生成事件
  static Stream<dynamic> generateSupplementPlanConversation({
    required String userMessage,
    String? trainingPlanId,
    String? dietPlanId,
    List<Map<String, dynamic>> conversationHistory = const [],
  }) async* {
    try {
      AppLogger.info('🔄 开始AI生成补剂计划对话');
      AppLogger.info(
        '用户请求: ${userMessage.substring(0, userMessage.length > 50 ? 50 : userMessage.length)}...',
      );

      // 获取当前用户ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('❌ 用户未登录');
        yield {'type': 'error', 'error': '用户未登录'};
        return;
      }

      // 构建请求 URL
      final url = Uri.parse(
        '${CloudFunctionsService.baseUrl}/generate_supplement_plan_conversation',
      );

      // 发起 HTTP POST 请求
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'user_id': user.uid,
        'user_message': userMessage,
        'training_plan_id': trainingPlanId,
        'diet_plan_id': dietPlanId,
        'conversation_history': conversationHistory,
      });

      AppLogger.info('发送补剂计划生成请求到: $url');

      // 发送请求并获取流式响应
      final response = await request.send();

      if (response.statusCode != 200) {
        AppLogger.error('❌ 请求失败: ${response.statusCode}');
        yield {
          'type': 'error',
          'error': '请求失败: HTTP ${response.statusCode}',
        };
        return;
      }

      AppLogger.info('✅ SSE 连接建立');

      // 读取 SSE 流
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        // 按行分割
        final lines = chunk.split('\n');

        for (final line in lines) {
          // SSE 格式：data: {...}
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data.isEmpty) continue;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;

              AppLogger.debug('收到补剂计划事件: ${json['type']}');
              yield json;

              // 如果是完成或错误，结束流
              if (json['type'] == 'complete' || json['type'] == 'error') {
                return;
              }
            } catch (e) {
              AppLogger.warning('解析 SSE 数据失败: $e');
              // 继续处理下一个事件
            }
          }
        }
      }

      AppLogger.info('✅ SSE 流结束');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 补剂计划生成异常', e, stackTrace);
      yield {'type': 'error', 'error': '生成失败: $e'};
    }
  }
}
