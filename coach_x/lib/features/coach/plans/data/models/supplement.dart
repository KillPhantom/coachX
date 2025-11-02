/// 补剂模型
class Supplement {
  final String name;
  final String amount;

  const Supplement({
    required this.name,
    required this.amount,
  });

  /// 创建空的补剂
  factory Supplement.empty() {
    return const Supplement(
      name: '',
      amount: '',
    );
  }

  /// 从 JSON 创建
  factory Supplement.fromJson(Map<String, dynamic> json) {
    return Supplement(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }

  /// 复制并修改部分字段
  Supplement copyWith({
    String? name,
    String? amount,
  }) {
    return Supplement(
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplement &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          amount == other.amount;

  @override
  int get hashCode =>
      name.hashCode ^
      amount.hashCode;

  @override
  String toString() {
    return 'Supplement(name: $name, amount: $amount)';
  }
}

