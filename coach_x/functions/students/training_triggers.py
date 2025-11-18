"""
训练记录 Firestore Triggers

监听 dailyTrainings 文档的创建和更新，触发视频关键帧提取
"""
import os
import tempfile
from firebase_functions import firestore_fn
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from typing import Dict, List, Any
import sys
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from utils import logger
from video_processing import (
    download_video_from_url,
    extract_keyframes,
    upload_keyframe_to_storage,
    cleanup_temp_files
)




def _should_extract_keyframes(data: Dict[str, Any]) -> bool:
    """
    检查是否需要提取关键帧

    条件:
    1. coachID 字段非空
    2. exercises 数组存在且非空
    3. 至少一个 exercise 包含 videos 且没有 keyframes

    Args:
        data: dailyTraining 文档数据

    Returns:
        True 如果需要提取，False 否则
    """
    try:
        # 检查 coachID
        coach_id = data.get('coachID', '').strip()
        if not coach_id:
            logger.info('ℹ️ 无 coachID，跳过关键帧提取')
            return False

        # 检查 exercises
        exercises = data.get('exercises', [])
        if not exercises or not isinstance(exercises, list):
            logger.info('ℹ️ 无 exercises 数据，跳过关键帧提取')
            return False

        # 检查是否有需要处理的视频
        for exercise in exercises:
            videos = exercise.get('videos', [])
            keyframes = exercise.get('keyframes', [])

            # 如果有视频但没有关键帧，需要提取
            if videos and not keyframes:
                logger.info(f'✅ 发现需要提取关键帧的视频: {exercise.get("name", "未知动作")}')
                return True

        logger.info('ℹ️ 所有视频已有关键帧或无视频，跳过处理')
        return False

    except Exception as e:
        logger.error(f'❌ 检查关键帧提取条件失败: {str(e)}')
        return False


def _process_training_videos(training_id: str, exercises: List[Dict[str, Any]]) -> None:
    """
    处理训练视频，提取并上传关键帧

    Args:
        training_id: 训练记录 ID
        exercises: exercises 数组
    """
    db = firestore.client()
    doc_ref = db.collection('dailyTrainings').document(training_id)

    temp_files_to_cleanup = []

    try:
        # 遍历每个 exercise
        for exercise_index, exercise in enumerate(exercises):
            videos = exercise.get('videos', [])
            keyframes = exercise.get('keyframes', [])

            # 跳过已有关键帧或无视频的 exercise
            if not videos or keyframes:
                continue

            exercise_name = exercise.get('name', f'Exercise {exercise_index}')
            logger.info(f'🎬 处理动作视频: {exercise_name} (索引 {exercise_index})')

            # 只处理第一个视频（如果有多个视频，可以遍历）
            video_url = videos[0]

            try:
                # 1. 下载视频
                video_ext = video_url.split('.')[-1].split('?')[0]  # 获取文件扩展名
                temp_video = tempfile.NamedTemporaryFile(
                    suffix=f'.{video_ext}',
                    delete=False
                )
                temp_video.close()
                temp_files_to_cleanup.append(temp_video.name)

                download_video_from_url(video_url, temp_video.name)

                # 2. 提取关键帧（带时间戳）
                keyframes_with_ts = extract_keyframes(temp_video.name, max_frames=5)

                # 收集需要清理的文件路径
                for kf in keyframes_with_ts:
                    temp_files_to_cleanup.append(kf['path'])

                # 获取关键帧所在目录（用于后续清理）
                if keyframes_with_ts:
                    keyframe_dir = os.path.dirname(keyframes_with_ts[0]['path'])
                    temp_files_to_cleanup.append(keyframe_dir)

                # 3. 上传关键帧到 Storage
                keyframe_data = []
                for frame_index, keyframe_info in enumerate(keyframes_with_ts):
                    try:
                        result = upload_keyframe_to_storage(
                            keyframe_info['path'],
                            training_id,
                            exercise_index,
                            frame_index,
                            keyframe_info['timestamp']
                        )
                        keyframe_data.append(result)
                    except Exception as e:
                        logger.error(f'❌ 上传关键帧失败 (frame {frame_index}): {str(e)}')
                        # 继续处理其他关键帧

                # 4. 更新 Firestore 文档
                if keyframe_data:
                    # 使用字段路径更新特定 exercise 的 keyframes
                    field_path = f'exercises.{exercise_index}.keyframes'
                    doc_ref.update({field_path: keyframe_data})
                    logger.info(f'✅ 已更新关键帧数据: {len(keyframe_data)} 个')

            except Exception as e:
                logger.error(f'❌ 处理视频失败 ({exercise_name}): {str(e)}')
                # 继续处理下一个 exercise

    except Exception as e:
        logger.error(f'❌ 处理训练视频失败: {str(e)}', exc_info=True)

    finally:
        # 清理临时文件
        if temp_files_to_cleanup:
            cleanup_temp_files(temp_files_to_cleanup)
