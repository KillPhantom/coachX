/// 饮食偏好枚举
///
/// 用于饮食计划生成时描述用户的饮食偏好和限制
enum DietaryPreference {
  /// 素食（无肉类）
  vegetarian,

  /// 纯素（无动物产品）
  vegan,

  /// 碳循环（训练日高碳水，休息日低碳水）
  carbCycling,

  /// 间歇性断食
  intermittentFasting,

  /// 生酮饮食（极低碳水）
  keto,

  /// 高碳水饮食
  highCarb,
}

extension DietaryPreferenceExtension on DietaryPreference {
  /// 显示名称（中文）
  String get displayName {
    switch (this) {
      case DietaryPreference.vegetarian:
        return '素食';
      case DietaryPreference.vegan:
        return '纯素';
      case DietaryPreference.carbCycling:
        return '碳循环';
      case DietaryPreference.intermittentFasting:
        return '间歇性断食';
      case DietaryPreference.keto:
        return '生酮饮食';
      case DietaryPreference.highCarb:
        return '高碳水';
    }
  }

  /// 描述文本
  String get description {
    switch (this) {
      case DietaryPreference.vegetarian:
        return '不包含肉类';
      case DietaryPreference.vegan:
        return '不包含任何动物产品';
      case DietaryPreference.carbCycling:
        return '训练日高碳水，休息日低碳水';
      case DietaryPreference.intermittentFasting:
        return '限制进食时间窗口';
      case DietaryPreference.keto:
        return '极低碳水，高脂肪';
      case DietaryPreference.highCarb:
        return '高碳水比例';
    }
  }

  /// 转换为 API 参数值
  String get apiValue {
    switch (this) {
      case DietaryPreference.vegetarian:
        return 'vegetarian';
      case DietaryPreference.vegan:
        return 'vegan';
      case DietaryPreference.carbCycling:
        return 'carb_cycling';
      case DietaryPreference.intermittentFasting:
        return 'intermittent_fasting';
      case DietaryPreference.keto:
        return 'keto';
      case DietaryPreference.highCarb:
        return 'high_carb';
    }
  }

  /// 从 API 值解析
  static DietaryPreference? fromApiValue(String value) {
    switch (value) {
      case 'vegetarian':
        return DietaryPreference.vegetarian;
      case 'vegan':
        return DietaryPreference.vegan;
      case 'carb_cycling':
        return DietaryPreference.carbCycling;
      case 'intermittent_fasting':
        return DietaryPreference.intermittentFasting;
      case 'keto':
        return DietaryPreference.keto;
      case 'high_carb':
        return DietaryPreference.highCarb;
      default:
        return null;
    }
  }
}

/// 过敏原枚举
enum Allergen {
  /// 乳制品
  dairy,

  /// 坚果
  nuts,

  /// 麸质
  gluten,
}

extension AllergenExtension on Allergen {
  /// 显示名称（中文）
  String get displayName {
    switch (this) {
      case Allergen.dairy:
        return '乳制品';
      case Allergen.nuts:
        return '坚果';
      case Allergen.gluten:
        return '麸质';
    }
  }

  /// 转换为 API 参数值
  String get apiValue {
    switch (this) {
      case Allergen.dairy:
        return 'dairy';
      case Allergen.nuts:
        return 'nuts';
      case Allergen.gluten:
        return 'gluten';
    }
  }

  /// 从 API 值解析
  static Allergen? fromApiValue(String value) {
    switch (value) {
      case 'dairy':
        return Allergen.dairy;
      case 'nuts':
        return Allergen.nuts;
      case 'gluten':
        return Allergen.gluten;
      default:
        return null;
    }
  }
}
