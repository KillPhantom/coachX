"""
学生训练记录相关Cloud Functions处理器
"""
from firebase_functions import https_fn
from firebase_admin import firestore
from google.cloud.firestore import SERVER_TIMESTAMP
from utils import logger, db_helper
from typing import Dict, Any, Tuple, Optional, List
from datetime import datetime, timedelta
import tempfile
import re


@https_fn.on_call()
def fetch_today_training(req: https_fn.CallableRequest):
    """
    获取学生指定日期的训练记录

    请求参数:
        - date: str, 日期格式 "yyyy-MM-dd"

    返回:
        {
            'status': 'success',
            'data': {
                'training': DailyTrainingModel | None
            }
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid
        date = req.data.get('date', '').strip()

        if not date:
            raise https_fn.HttpsError('invalid-argument', '日期不能为空')

        # 验证日期格式 (简单验证)
        if len(date) != 10 or date.count('-') != 2:
            raise https_fn.HttpsError(
                'invalid-argument',
                '日期格式错误，应为 yyyy-MM-dd'
            )

        logger.info(f'📖 获取训练记录 - 学生: {student_id}, 日期: {date}')

        # 查询 dailyTrainings collection
        db = firestore.client()
        trainings_query = db.collection('dailyTrainings') \
            .where('studentID', '==', student_id) \
            .where('date', '==', date) \
            .limit(1) \
            .get()

        # 查找匹配的记录
        training_data = None
        if trainings_query:
            for training_doc in trainings_query:
                training_data = training_doc.to_dict()
                training_data['id'] = training_doc.id
                logger.info(f'✅ 找到训练记录: ID={training_doc.id}')
                break

        if not training_data:
            logger.info(f'📖 未找到训练记录: {student_id} - {date}')

        return {
            'status': 'success',
            'data': training_data
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取训练记录失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def upsert_today_training(req: https_fn.CallableRequest):
    """
    创建或更新学生训练记录

    请求参数: 完整的DailyTrainingModel JSON
        - id: str (可选，如果为空则创建新记录)
        - studentID: str
        - coachID: str
        - date: str
        - planSelection: dict
        - diet: dict (可选)
        - exercises: list (可选)
        - supplements: list (可选)
        - completionStatus: str (可选)
        - isReviewed: bool (可选)

    返回:
        {
            'status': 'success',
            'data': {
                'id': document_id
            }
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        user_id = req.auth.uid
        training_data = dict(req.data)

        # 验证必需字段
        student_id = training_data.get('studentID', '').strip()
        coach_id = training_data.get('coachID', '').strip()
        date = training_data.get('date', '').strip()

        if not student_id or not coach_id or not date:
            raise https_fn.HttpsError(
                'invalid-argument',
                '缺少必需字段: studentID, coachID, date'
            )

        # 验证权限：只能操作自己的记录
        if student_id != user_id:
            raise https_fn.HttpsError(
                'permission-denied',
                '只能保存自己的训练记录'
            )

        logger.info(f'💾 保存训练记录 - 学生: {student_id}, 日期: {date}')

        # 获取 Firestore 实例
        db = firestore.client()

        # 查询是否已存在该日期的记录
        existing_query = db.collection('dailyTrainings') \
            .where('studentID', '==', student_id) \
            .where('date', '==', date) \
            .limit(1) \
            .get()

        doc_id = training_data.get('id', '').strip()
        doc_ref = None

        # 准备保存的数据（移除id字段，Firestore不需要）
        save_data = {k: v for k, v in training_data.items() if k != 'id'}

        # 如果存在记录，更新它
        if existing_query:
            for existing_doc in existing_query:
                doc_id = existing_doc.id
                doc_ref = existing_doc.reference
                logger.info(f'📝 更新已存在的记录: {doc_id}')
                doc_ref.update(save_data)
                break
        else:
            # 创建新记录
            if doc_id:
                # 如果提供了ID，使用指定ID创建
                doc_ref = db.collection('dailyTrainings').document(doc_id)
                doc_ref.set(save_data)
                logger.info(f'✨ 创建新记录（指定ID）: {doc_id}')
            else:
                # 自动生成ID
                doc_ref = db.collection('dailyTrainings').add(save_data)[1]
                doc_id = doc_ref.id
                logger.info(f'✨ 创建新记录（自动ID）: {doc_id}')

        logger.info(f'✅ 训练记录保存成功: {doc_id}')

        return {
            'status': 'success',
            'data': {
                'id': doc_id
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 保存训练记录失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


# ==================== 辅助函数 ====================


def get_week_range(date: datetime) -> Tuple[str, str]:
    """
    获取指定日期所在周的周一和周日日期

    参数:
        date: 任意日期

    返回:
        (week_start, week_end) 元组，格式 "yyyy-MM-dd"
    """
    # 计算周一（weekday=0 是周一）
    week_start = date - timedelta(days=date.weekday())
    # 计算周日
    week_end = week_start + timedelta(days=6)

    return (
        week_start.strftime('%Y-%m-%d'),
        week_end.strftime('%Y-%m-%d')
    )


def parse_weight_string(weight_str: str) -> Tuple[float, str]:
    """
    解析重量字符串，提取数值和单位

    参数:
        weight_str: 如 "100kg", "225lbs", "50"

    返回:
        (value: float, unit: str) 元组
    """
    if not weight_str:
        return (0.0, '')

    # 使用正则提取数字部分和单位部分
    match = re.match(r'([0-9.]+)\s*(kg|lbs|lb)?', weight_str.strip().lower())

    if match:
        value = float(match.group(1))
        unit = match.group(2) or ''
        # 统一 lb 为 lbs
        if unit == 'lb':
            unit = 'lbs'
        return (value, unit)

    return (0.0, '')


def parse_reps_string(reps_str: str) -> int:
    """
    解析次数字符串

    参数:
        reps_str: 如 "10", "8-12"

    返回:
        int (单值或范围平均值)
    """
    if not reps_str:
        return 0

    reps_str = reps_str.strip()

    # 检查是否为范围格式 "8-12"
    if '-' in reps_str:
        parts = reps_str.split('-')
        if len(parts) == 2:
            try:
                min_reps = int(parts[0])
                max_reps = int(parts[1])
                return (min_reps + max_reps) // 2
            except ValueError:
                return 0

    # 单个数字
    try:
        return int(reps_str)
    except ValueError:
        return 0


def calculate_volume(sets: List[Dict[str, Any]]) -> Tuple[float, str]:
    """
    计算训练量 (Volume = weight × reps × sets_count)

    参数:
        sets: TrainingSet[] 列表

    返回:
        (total_volume: float, unit: str) 元组
    """
    total_volume = 0.0
    unit = ''

    for set_data in sets:
        weight_str = set_data.get('weight', '')
        reps_str = set_data.get('reps', '')

        weight_value, weight_unit = parse_weight_string(weight_str)
        reps_value = parse_reps_string(reps_str)

        # 累加 volume
        total_volume += weight_value * reps_value

        # 记录单位（取第一个非空单位）
        if not unit and weight_unit:
            unit = weight_unit

    return (total_volume, unit)


# ==================== 主函数 ====================


@https_fn.on_call()
def fetch_weekly_home_stats(req: https_fn.CallableRequest):
    """
    获取学生本周首页统计数据

    请求参数:
        - current_date: str (可选), 客户端当前日期 "yyyy-MM-dd"，用于时区同步

    功能:
        1. 本周训练打卡状态（7天圆点）
        2. 体重变化统计（本周平均 vs 上周平均）
        3. 卡路里摄入统计（本周总量 vs 上周总量）
        4. Volume PR 统计（选一个动作示例）

    返回:
        {
            'status': 'success',
            'data': {
                'currentWeek': {
                    'startDate': '2025-01-13',
                    'endDate': '2025-01-19',
                    'trainings': [
                        {'date': '2025-01-13', 'hasRecord': True},
                        ...
                    ]
                },
                'stats': {
                    'weightChange': {...},
                    'caloriesChange': {...},
                    'volumePR': {...}
                }
            }
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid
        logger.info(f'📊 获取本周统计数据 - 学生ID: {student_id}')

        # 获取客户端当前日期（用户时区），如果未提供则使用服务器时间
        current_date_str = req.data.get('current_date', '').strip() if req.data else ''

        if current_date_str:
            try:
                today = datetime.strptime(current_date_str, '%Y-%m-%d')
                logger.info(f'使用客户端日期: {current_date_str}')
            except ValueError:
                logger.warning(f'客户端日期格式错误: {current_date_str}，使用服务器时间')
                today = datetime.now()
        else:
            today = datetime.now()
            logger.info(f'使用服务器时间: {today.strftime("%Y-%m-%d")}')

        # 计算本周和上周的日期范围
        this_week_start, this_week_end = get_week_range(today)
        last_week_start, last_week_end = get_week_range(
            today - timedelta(days=7)
        )

        logger.info(f'本周: {this_week_start} ~ {this_week_end}')
        logger.info(f'上周: {last_week_start} ~ {last_week_end}')

        db = firestore.client()

        # 查询本周的 dailyTrainings 记录
        this_week_trainings = db.collection('dailyTrainings') \
            .where('studentID', '==', student_id) \
            .where('date', '>=', this_week_start) \
            .where('date', '<=', this_week_end) \
            .get()

        # 查询上周的 dailyTrainings 记录
        last_week_trainings = db.collection('dailyTrainings') \
            .where('studentID', '==', student_id) \
            .where('date', '>=', last_week_start) \
            .where('date', '<=', last_week_end) \
            .get()

        # 查询本周的 bodyMeasure 记录
        this_week_measurements = db.collection('bodyMeasure') \
            .where('studentID', '==', student_id) \
            .where('recordDate', '>=', this_week_start) \
            .where('recordDate', '<=', this_week_end) \
            .get()

        # 查询上周的 bodyMeasure 记录
        last_week_measurements = db.collection('bodyMeasure') \
            .where('studentID', '==', student_id) \
            .where('recordDate', '>=', last_week_start) \
            .where('recordDate', '<=', last_week_end) \
            .get()

        # 转换为字典，方便处理
        this_week_trainings_dict = {}
        for doc in this_week_trainings:
            data = doc.to_dict()
            data['id'] = doc.id
            this_week_trainings_dict[data['date']] = data

        last_week_trainings_dict = {}
        for doc in last_week_trainings:
            data = doc.to_dict()
            data['id'] = doc.id
            last_week_trainings_dict[data['date']] = data

        this_week_measurements_list = [doc.to_dict() for doc in this_week_measurements]
        last_week_measurements_list = [doc.to_dict() for doc in last_week_measurements]

        logger.info(f'本周训练记录: {len(this_week_trainings_dict)}天')
        logger.info(f'上周训练记录: {len(last_week_trainings_dict)}天')
        logger.info(f'本周体重记录: {len(this_week_measurements_list)}条')
        logger.info(f'上周体重记录: {len(last_week_measurements_list)}条')

        # ==================== 计算统计数据 ====================

        # 1. 体重变化统计
        weight_change_stats = _calculate_weight_change(
            this_week_measurements_list,
            last_week_measurements_list
        )

        # 2. 卡路里变化统计
        calories_change_stats = _calculate_calories_change(
            this_week_trainings_dict,
            last_week_trainings_dict
        )

        # 3. Volume PR 统计
        volume_pr_stats = _calculate_volume_pr(
            this_week_trainings_dict,
            last_week_trainings_dict
        )

        # 4. 构建本周训练摘要（7天）
        trainings_summary = _build_trainings_summary(
            this_week_start,
            this_week_trainings_dict
        )

        # ==================== 构建返回数据 ====================

        return {
            'status': 'success',
            'data': {
                'currentWeek': {
                    'startDate': this_week_start,
                    'endDate': this_week_end,
                    'trainings': trainings_summary
                },
                'stats': {
                    'weightChange': weight_change_stats,
                    'caloriesChange': calories_change_stats,
                    'volumePR': volume_pr_stats
                }
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取本周统计数据失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


def _calculate_weight_change(
    this_week_measurements: List[Dict[str, Any]],
    last_week_measurements: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """计算体重变化统计"""
    has_data = len(this_week_measurements) > 0 or len(last_week_measurements) > 0

    if not has_data:
        return {
            'currentWeekAvg': None,
            'lastWeekAvg': None,
            'change': None,
            'unit': 'kg',
            'hasData': False
        }

    # 计算本周平均体重
    this_week_avg = None
    unit = 'kg'
    if this_week_measurements:
        total = sum(m.get('weight', 0) for m in this_week_measurements)
        this_week_avg = round(total / len(this_week_measurements), 1)
        unit = this_week_measurements[0].get('weightUnit', 'kg')

    # 计算上周平均体重
    last_week_avg = None
    if last_week_measurements:
        total = sum(m.get('weight', 0) for m in last_week_measurements)
        last_week_avg = round(total / len(last_week_measurements), 1)
        if not unit:
            unit = last_week_measurements[0].get('weightUnit', 'kg')

    # 计算变化量
    change = None
    if this_week_avg is not None and last_week_avg is not None:
        change = round(this_week_avg - last_week_avg, 1)

    return {
        'currentWeekAvg': this_week_avg,
        'lastWeekAvg': last_week_avg,
        'change': change,
        'unit': unit,
        'hasData': True
    }


def _calculate_calories_change(
    this_week_trainings: Dict[str, Dict[str, Any]],
    last_week_trainings: Dict[str, Dict[str, Any]]
) -> Dict[str, Any]:
    """计算卡路里变化统计"""
    # 计算本周总卡路里
    this_week_total = 0.0
    for training in this_week_trainings.values():
        diet = training.get('diet', {})
        if diet:
            macros = diet.get('macros', {})
            if macros:
                this_week_total += macros.get('calories', 0)

    # 计算上周总卡路里
    last_week_total = 0.0
    for training in last_week_trainings.values():
        diet = training.get('diet', {})
        if diet:
            macros = diet.get('macros', {})
            if macros:
                last_week_total += macros.get('calories', 0)

    has_data = this_week_total > 0 or last_week_total > 0

    if not has_data:
        return {
            'currentWeekTotal': None,
            'lastWeekTotal': None,
            'change': None,
            'hasData': False
        }

    # 计算变化量
    change = None
    if this_week_total > 0 and last_week_total > 0:
        change = round(this_week_total - last_week_total, 0)

    return {
        'currentWeekTotal': round(this_week_total, 0) if this_week_total > 0 else None,
        'lastWeekTotal': round(last_week_total, 0) if last_week_total > 0 else None,
        'change': change,
        'hasData': True
    }


def _calculate_volume_pr(
    this_week_trainings: Dict[str, Dict[str, Any]],
    last_week_trainings: Dict[str, Dict[str, Any]]
) -> Dict[str, Any]:
    """计算 Volume PR 统计（选一个动作示例）"""
    # 收集本周所有动作的 Volume
    this_week_volumes = {}
    for training in this_week_trainings.values():
        exercises = training.get('exercises', [])
        if exercises:
            for exercise in exercises:
                name = exercise.get('name', '')
                sets = exercise.get('sets', [])
                if name and sets:
                    volume, unit = calculate_volume(sets)
                    if name not in this_week_volumes:
                        this_week_volumes[name] = {'total': 0.0, 'unit': unit}
                    this_week_volumes[name]['total'] += volume

    # 收集上周所有动作的 Volume
    last_week_volumes = {}
    for training in last_week_trainings.values():
        exercises = training.get('exercises', [])
        if exercises:
            for exercise in exercises:
                name = exercise.get('name', '')
                sets = exercise.get('sets', [])
                if name and sets:
                    volume, unit = calculate_volume(sets)
                    if name not in last_week_volumes:
                        last_week_volumes[name] = {'total': 0.0, 'unit': unit}
                    last_week_volumes[name]['total'] += volume

    # 找到第一个在两周都出现的动作
    for exercise_name in this_week_volumes.keys():
        if exercise_name in last_week_volumes:
            this_week_vol = this_week_volumes[exercise_name]['total']
            last_week_vol = last_week_volumes[exercise_name]['total']
            unit = this_week_volumes[exercise_name]['unit']

            improvement = round(this_week_vol - last_week_vol, 0)

            return {
                'exerciseName': exercise_name,
                'currentWeekVolume': round(this_week_vol, 0),
                'lastWeekVolume': round(last_week_vol, 0),
                'improvement': improvement,
                'unit': unit,
                'hasData': True
            }

    # 没有找到匹配的动作
    return {
        'exerciseName': None,
        'currentWeekVolume': None,
        'lastWeekVolume': None,
        'improvement': None,
        'unit': 'kg',
        'hasData': False
    }


def _build_trainings_summary(
    week_start: str,
    trainings_dict: Dict[str, Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """构建本周训练摘要（7天，周一到周日）"""
    summary = []
    start_date = datetime.strptime(week_start, '%Y-%m-%d')

    for i in range(7):
        current_date = start_date + timedelta(days=i)
        date_str = current_date.strftime('%Y-%m-%d')
        has_record = date_str in trainings_dict

        summary.append({
            'date': date_str,
            'hasRecord': has_record
        })

    return summary


@https_fn.on_call()
def update_meal_record(req: https_fn.CallableRequest):
    """
    更新学生某日的餐次记录

    请求参数:
        - studentId: str, 学生ID (可选，默认使用当前用户)
        - date: str, 日期格式 "yyyy-MM-dd"
        - meal: dict, 餐次数据 {name, note, items, images}

    返回:
        {
            'status': 'success',
            'message': '餐次更新成功'
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        # 获取参数
        student_id = req.data.get('studentId', req.auth.uid)
        date = req.data.get('date', '').strip()
        meal_data = req.data.get('meal')

        # 验证参数
        if not date:
            raise https_fn.HttpsError('invalid-argument', '日期不能为空')

        if not meal_data or not isinstance(meal_data, dict):
            raise https_fn.HttpsError('invalid-argument', '餐次数据无效')

        if 'name' not in meal_data:
            raise https_fn.HttpsError('invalid-argument', '餐次名称不能为空')

        logger.info(f'🍽️ 更新餐次记录 - 学生: {student_id}, 日期: {date}, '
                   f'餐次: {meal_data.get("name")}')

        db = firestore.client()

        # 查找该日期的训练记录
        training_query = (
            db.collection('dailyTrainings')
            .where('studentID', '==', student_id)
            .where('date', '==', date)
            .limit(1)
        )

        training_docs = list(training_query.stream())

        if not training_docs:
            raise https_fn.HttpsError(
                'not-found',
                f'未找到日期 {date} 的训练记录'
            )

        training_doc = training_docs[0]
        training_ref = training_doc.reference
        training_data = training_doc.to_dict()

        # 获取现有的 diet 数据
        diet_data = training_data.get('diet', {})
        meals = diet_data.get('meals', [])

        # 查找并更新匹配的餐次
        meal_name = meal_data.get('name')
        meal_found = False

        for i, existing_meal in enumerate(meals):
            if existing_meal.get('name') == meal_name:
                # 更新餐次
                meals[i] = meal_data
                meal_found = True
                logger.info(f'✅ 找到并更新餐次: {meal_name}')
                break

        if not meal_found:
            # 如果没找到，添加新餐次
            meals.append(meal_data)
            logger.info(f'➕ 添加新餐次: {meal_name}')

        # 更新 Firestore
        training_ref.update({
            'diet.meals': meals,
            'updatedAt': SERVER_TIMESTAMP
        })

        logger.info(f'✅ 餐次记录更新成功 - {meal_name}')

        return {
            'status': 'success',
            'message': '餐次更新成功'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 更新餐次记录失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'更新餐次失败: {str(e)}')
