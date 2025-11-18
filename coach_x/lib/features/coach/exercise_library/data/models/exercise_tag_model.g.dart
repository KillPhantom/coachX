// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_tag_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseTagModelAdapter extends TypeAdapter<ExerciseTagModel> {
  @override
  final int typeId = 11;

  @override
  ExerciseTagModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseTagModel(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseTagModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseTagModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
