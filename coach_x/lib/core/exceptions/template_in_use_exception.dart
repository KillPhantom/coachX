/// 模板正在被使用的异常
class TemplateInUseException implements Exception {
  /// 引用该模板的计划数量
  final int planCount;

  const TemplateInUseException(this.planCount);

  @override
  String toString() => 'Template is in use by $planCount plan(s)';
}
