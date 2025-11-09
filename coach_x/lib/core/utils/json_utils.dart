/// JSON 解析工具函数
///
/// 提供安全的类型转换，避免从 Firebase Cloud Functions 返回的数据类型不匹配问题

/// 安全地将 dynamic 转换为 Map<String, dynamic>
///
/// 从 Firebase Cloud Functions 返回的嵌套 Map 对象的运行时类型可能不是严格的
/// Map<String, dynamic>，而是普通的 Map。这个函数会自动处理类型转换。
///
/// [data] 要转换的数据
/// [fieldName] 字段名称（用于错误信息）
///
/// 返回：
/// - 如果 data 为 null，返回 null
/// - 如果 data 已经是 Map<String, dynamic>，直接返回
/// - 如果 data 是 Map，转换为 Map<String, dynamic>
/// - 否则返回 null
///
/// 示例：
/// ```dart
/// final planData = safeMapCast(json['exercisePlan']);
/// if (planData != null) {
///   return ExercisePlanModel.fromJson(planData);
/// }
/// ```
Map<String, dynamic>? safeMapCast(dynamic data, [String? fieldName]) {
  if (data == null) return null;

  // 已经是正确的类型，直接返回
  if (data is Map<String, dynamic>) {
    return data;
  }

  // 是 Map 但不是 Map<String, dynamic>，进行转换
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  // 不是 Map 类型，记录警告并返回 null
  final field = fieldName != null ? ' for field "$fieldName"' : '';
  print('⚠️ Warning: Expected Map but got ${data.runtimeType}$field');
  return null;
}

/// 安全地将 dynamic List 转换为 List<Map<String, dynamic>>
///
/// [data] 要转换的数据
/// [fieldName] 字段名称（用于错误信息）
///
/// 返回：
/// - 如果 data 为 null，返回空列表
/// - 如果 data 是 List，转换其中的每个元素为 Map<String, dynamic>
/// - 否则返回空列表
///
/// 示例：
/// ```dart
/// final daysData = safeMapListCast(json['days']);
/// final days = daysData.map((d) => ExerciseDay.fromJson(d)).toList();
/// ```
List<Map<String, dynamic>> safeMapListCast(dynamic data, [String? fieldName]) {
  if (data == null) return [];

  if (data is! List) {
    final field = fieldName != null ? ' for field "$fieldName"' : '';
    print('⚠️ Warning: Expected List but got ${data.runtimeType}$field');
    return [];
  }

  return data
      .map((item) => safeMapCast(item))
      .whereType<Map<String, dynamic>>()
      .toList();
}

/// 安全地将 dynamic 转换为 List<String>
///
/// [data] 要转换的数据
/// [fieldName] 字段名称（用于错误信息）
///
/// 返回：
/// - 如果 data 为 null，返回空列表
/// - 如果 data 是 List，转换为 List<String>
/// - 否则返回空列表
List<String> safeStringListCast(dynamic data, [String? fieldName]) {
  if (data == null) return [];

  if (data is! List) {
    final field = fieldName != null ? ' for field "$fieldName"' : '';
    print('⚠️ Warning: Expected List but got ${data.runtimeType}$field');
    return [];
  }

  return data.map((e) => e.toString()).toList();
}

/// 安全地将 dynamic 转换为 int
///
/// Firebase 有时会将数字作为字符串返回，这个函数会自动处理转换
///
/// [data] 要转换的数据
/// [defaultValue] 默认值（如果转换失败）
/// [fieldName] 字段名称（用于错误信息）
///
/// 返回：
/// - 如果 data 为 null，返回 null
/// - 如果 data 已经是 int，直接返回
/// - 如果 data 是 String，尝试解析为 int
/// - 如果 data 是 double，转换为 int
/// - 否则返回 defaultValue 或 null
///
/// 示例：
/// ```dart
/// final timestamp = safeIntCast(json['createdAt'], 0, 'createdAt');
/// final count = safeIntCast(json['count']); // 可以为 null
/// ```
int? safeIntCast(dynamic data, [int? defaultValue, String? fieldName]) {
  if (data == null) return defaultValue;

  // 已经是 int，直接返回
  if (data is int) return data;

  // 是 double，转换为 int
  if (data is double) return data.toInt();

  // 是 String，尝试解析
  if (data is String) {
    // 首先尝试直接解析为数字
    final parsed = int.tryParse(data);
    if (parsed != null) return parsed;

    // 尝试解析为日期字符串（如 "Sun, 02 Nov 2025 21:52:15 GMT"）
    try {
      final dateTime = DateTime.parse(data);
      return dateTime.millisecondsSinceEpoch;
    } catch (_) {
      // 不是有效的日期字符串
    }

    final field = fieldName != null ? ' for field "$fieldName"' : '';
    print('⚠️ Warning: Cannot parse "$data" as int$field');
    return defaultValue;
  }

  // 其他类型
  final field = fieldName != null ? ' for field "$fieldName"' : '';
  print('⚠️ Warning: Expected int but got ${data.runtimeType}$field');
  return defaultValue;
}

/// 安全地将 dynamic 转换为 double
///
/// [data] 要转换的数据
/// [defaultValue] 默认值（如果转换失败）
/// [fieldName] 字段名称（用于错误信息）
///
/// 返回：
/// - 如果 data 为 null，返回 null
/// - 如果 data 已经是 double，直接返回
/// - 如果 data 是 int，转换为 double
/// - 如果 data 是 String，尝试解析为 double
/// - 否则返回 defaultValue 或 null
double? safeDoubleCast(
  dynamic data, [
  double? defaultValue,
  String? fieldName,
]) {
  if (data == null) return defaultValue;

  // 已经是 double，直接返回
  if (data is double) return data;

  // 是 int，转换为 double
  if (data is int) return data.toDouble();

  // 是 String，尝试解析
  if (data is String) {
    final parsed = double.tryParse(data);
    if (parsed != null) return parsed;

    final field = fieldName != null ? ' for field "$fieldName"' : '';
    print('⚠️ Warning: Cannot parse "$data" as double$field');
    return defaultValue;
  }

  // 其他类型
  final field = fieldName != null ? ' for field "$fieldName"' : '';
  print('⚠️ Warning: Expected double but got ${data.runtimeType}$field');
  return defaultValue;
}
