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
