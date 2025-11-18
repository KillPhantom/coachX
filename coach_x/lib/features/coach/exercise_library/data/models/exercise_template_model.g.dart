// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_template_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseTemplateModelAdapter extends TypeAdapter<ExerciseTemplateModel> {
  @override
  final int typeId = 10;

  @override
  ExerciseTemplateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseTemplateModel(
      id: fields[0] as String,
      ownerId: fields[1] as String,
      name: fields[2] as String,
      tags: (fields[3] as List).cast<String>(),
      textGuidance: fields[5] as String?,
      imageUrls: (fields[6] as List?)?.cast<String>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      videoUrls: (fields[10] as List?)?.cast<String>(),
      thumbnailUrls: (fields[11] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseTemplateModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ownerId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.textGuidance)
      ..writeByte(6)
      ..write(obj.imageUrls)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.videoUrls)
      ..writeByte(11)
      ..write(obj.thumbnailUrls);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseTemplateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
