/// 语音录制状态
enum VoiceRecordStatus {
  /// 未开始录制
  idle,

  /// 正在录制
  recording,

  /// 录制完成
  completed,

  /// 录制被取消
  cancelled,
}

/// 语音录制状态模型
class VoiceRecordState {
  /// 录制状态
  final VoiceRecordStatus status;

  /// 录制时长（秒）
  final int duration;

  /// 录制文件路径
  final String? filePath;

  const VoiceRecordState({
    this.status = VoiceRecordStatus.idle,
    this.duration = 0,
    this.filePath,
  });

  /// 复制并修改部分字段
  VoiceRecordState copyWith({
    VoiceRecordStatus? status,
    int? duration,
    String? filePath,
  }) {
    return VoiceRecordState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
    );
  }

  /// 是否正在录制
  bool get isRecording => status == VoiceRecordStatus.recording;

  /// 是否已完成录制
  bool get isCompleted => status == VoiceRecordStatus.completed;

  /// 是否空闲状态
  bool get isIdle => status == VoiceRecordStatus.idle;

  @override
  String toString() {
    return 'VoiceRecordState(status: $status, duration: $duration, filePath: $filePath)';
  }
}
