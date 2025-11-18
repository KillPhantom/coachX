import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../exercise_library/data/models/exercise_template_model.dart';
import '../../../exercise_library/presentation/providers/exercise_library_providers.dart';

/// 搜索动作模板的 Provider
///
/// 根据查询字符串过滤动作库中的模板
final exerciseTemplateSearchProvider =
    Provider.family<List<ExerciseTemplateModel>, String>((ref, query) {
      if (query.isEmpty) {
        return [];
      }

      final templates = ref.watch(exerciseTemplatesProvider);
      final lowerQuery = query.toLowerCase();

      return templates
          .where((template) {
            // 按名称搜索
            if (template.name.toLowerCase().contains(lowerQuery)) {
              return true;
            }

            // 按标签搜索
            for (final tag in template.tags) {
              if (tag.toLowerCase().contains(lowerQuery)) {
                return true;
              }
            }

            return false;
          })
          .take(5)
          .toList(); // 限制返回 5 个结果
    });
