// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_list_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentListItemModelAdapter extends TypeAdapter<StudentListItemModel> {
  @override
  final int typeId = 20;

  @override
  StudentListItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentListItemModel(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      avatarUrl: fields[3] as String?,
      coachId: fields[4] as String,
      exercisePlan: fields[5] as StudentPlanInfo?,
      dietPlan: fields[6] as StudentPlanInfo?,
      supplementPlan: fields[7] as StudentPlanInfo?,
      createdAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StudentListItemModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.coachId)
      ..writeByte(5)
      ..write(obj.exercisePlan)
      ..writeByte(6)
      ..write(obj.dietPlan)
      ..writeByte(7)
      ..write(obj.supplementPlan)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentListItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
