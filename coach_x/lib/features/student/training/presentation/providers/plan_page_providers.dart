import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 计划页面标签类型
enum PlanTab { training, diet, supplements }

/// 当前选中的计划标签
final selectedPlanTabProvider = StateProvider<PlanTab>((ref) {
  return PlanTab.training;
});

/// 当前选中的部位筛选（用于训练计划）
/// null 表示显示所有部位
final selectedBodyPartProvider = StateProvider<String?>((ref) {
  return null;
});

/// Coach's Plan 展开状态
final coachPlanExpandedProvider = StateProvider<bool>((ref) {
  return true; // 默认展开
});

/// 当前选中的饮食计划日期
final selectedDietDayProvider = StateProvider<int>((ref) {
  return 1; // 默认第1天
});

/// 当前选中的补剂计划日期
final selectedSupplementDayProvider = StateProvider<int>((ref) {
  return 1; // 默认第1天
});
