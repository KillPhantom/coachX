/// 补剂模型
class Supplement {
  final String name;
  final String amount;
  final String? note;

  const Supplement({
    required this.name,
    required this.amount,
    this.note,
  });

  /// 创建空的补剂
  factory Supplement.empty() {
    return const Supplement(name: '', amount: '');
  }

  /// 从 JSON 创建
  factory Supplement.fromJson(Map<String, dynamic> json) {
    return Supplement(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      note: json['note'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'name': name, 'amount': amount, 'note': note};
  }

  /// 复制并修改部分字段
  Supplement copyWith({String? name, String? amount, String? note}) {
    return Supplement(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplement &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          amount == other.amount &&
          note == other.note;

  @override
  int get hashCode => name.hashCode ^ amount.hashCode ^ note.hashCode;

  @override
  String toString() {
    return 'Supplement(name: $name, amount: $amount, note: $note)';
  }
}
