// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_cache_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoCacheMetadataAdapter extends TypeAdapter<VideoCacheMetadata> {
  @override
  final int typeId = 36;

  @override
  VideoCacheMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoCacheMetadata(
      videoUrl: fields[0] as String,
      localPath: fields[1] as String,
      trainingId: fields[2] as String,
      fileSize: fields[3] as int,
      cachedAt: fields[4] as DateTime,
      expiresAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VideoCacheMetadata obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.videoUrl)
      ..writeByte(1)
      ..write(obj.localPath)
      ..writeByte(2)
      ..write(obj.trainingId)
      ..writeByte(3)
      ..write(obj.fileSize)
      ..writeByte(4)
      ..write(obj.cachedAt)
      ..writeByte(5)
      ..write(obj.expiresAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoCacheMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
