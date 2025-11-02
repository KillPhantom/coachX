/// 单位转换工具类
///
/// 提供身高、体重等数据的单位转换功能
class UnitConverter {
  UnitConverter._(); // 私有构造函数，防止实例化

  // ==================== 身高转换 ====================

  /// 格式化身高
  ///
  /// [heightCm] 身高（厘米）
  /// [useMetric] 是否使用公制单位
  ///
  /// 返回格式:
  /// - 公制: "172 cm"
  /// - 英制: "5'7\""
  static String formatHeight(double? heightCm, {bool useMetric = false}) {
    if (heightCm == null || heightCm <= 0) return '--';

    if (useMetric) {
      return '${heightCm.toStringAsFixed(0)} cm';
    }

    // 转换为英寸
    final totalInches = heightCm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();

    return '$feet\'$inches"';
  }

  /// 厘米转英寸
  static double cmToInches(double cm) {
    return cm / 2.54;
  }

  /// 英寸转厘米
  static double inchesToCm(double inches) {
    return inches * 2.54;
  }

  /// 英尺和英寸转厘米
  static double feetAndInchesToCm(int feet, int inches) {
    final totalInches = (feet * 12 + inches).toDouble();
    return inchesToCm(totalInches);
  }

  // ==================== 体重转换 ====================

  /// 格式化体重
  ///
  /// [weightKg] 体重（公斤）
  /// [useMetric] 是否使用公制单位
  ///
  /// 返回格式:
  /// - 公制: "65.0 kg"
  /// - 英制: "143 lbs"
  static String formatWeight(double? weightKg, {bool useMetric = false}) {
    if (weightKg == null || weightKg <= 0) return '--';

    if (useMetric) {
      return '${weightKg.toStringAsFixed(1)} kg';
    }

    // 转换为磅
    final lbs = (weightKg * 2.20462).round();
    return '$lbs lbs';
  }

  /// 公斤转磅
  static double kgToLbs(double kg) {
    return kg * 2.20462;
  }

  /// 磅转公斤
  static double lbsToKg(double lbs) {
    return lbs / 2.20462;
  }

  // ==================== 年龄计算 ====================

  /// 计算年龄
  ///
  /// [bornDate] 出生日期
  ///
  /// 返回年龄（整数），如果出生日期为空则返回 null
  static int? calculateAge(DateTime? bornDate) {
    if (bornDate == null) return null;

    final now = DateTime.now();
    int age = now.year - bornDate.year;

    // 如果今年的生日还没到，年龄减1
    if (now.month < bornDate.month ||
        (now.month == bornDate.month && now.day < bornDate.day)) {
      age--;
    }

    return age;
  }

  /// 格式化年龄
  ///
  /// [bornDate] 出生日期
  ///
  /// 返回格式: "25" 或 "--"
  static String formatAge(DateTime? bornDate) {
    final age = calculateAge(bornDate);
    return age != null ? age.toString() : '--';
  }

  // ==================== 单位偏好判断 ====================

  /// 判断是否使用公制单位
  ///
  /// [preference] 单位偏好: 'metric' | 'imperial'
  static bool isMetric(String? preference) {
    return preference?.toLowerCase() == 'metric';
  }

  /// 获取单位偏好的显示名称
  ///
  /// [preference] 单位偏好: 'metric' | 'imperial'
  static String getPreferenceDisplayName(String? preference) {
    if (preference?.toLowerCase() == 'metric') {
      return 'Metric (cm, kg)';
    }
    return 'Imperial (ft, lbs)';
  }
}
