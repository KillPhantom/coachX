"""
学生管理相关Cloud Functions处理器
"""
from firebase_functions import https_fn
from firebase_admin import firestore
from utils import logger, db_helper
from utils.param_parser import parse_int_param, parse_bool_param
from .models import StudentListItem, StudentPlanInfo
import math


@https_fn.on_call()
def fetch_students(req: https_fn.CallableRequest):
    """
    获取学生列表（含分页、搜索、筛选）
    
    请求参数:
        - page_size: 每页数量 (默认20)
        - page_number: 页码，从1开始 (默认1)
        - search_name: 搜索姓名 (可选)
        - filter_plan_id: 筛选训练计划ID (可选)
        - include_plans: 是否包含计划信息 (默认False，可提升性能)
    
    返回:
        - status: 状态码
        - data: 
            - students: 学生列表
            - total_count: 总学生数
            - has_more: 是否还有更多数据
            - current_page: 当前页码
            - total_pages: 总页数
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        coach_id = req.auth.uid

        # 验证教练身份
        user_doc = db_helper.get_document('users', coach_id)
        if not user_doc.exists:
            raise https_fn.HttpsError('not-found', '用户不存在')

        user_data = user_doc.to_dict()
        if user_data.get('role') != 'coach':
            raise https_fn.HttpsError('permission-denied', '只有教练可以查看学生列表')

        # 获取参数（处理 Protobuf 包装）
        page_size = parse_int_param(req.data.get('page_size'), 20)
        page_number = parse_int_param(req.data.get('page_number'), 1)
        search_name = req.data.get('search_name', '').strip()
        filter_plan_id = req.data.get('filter_plan_id', '').strip()
        include_plans = parse_bool_param(req.data.get('include_plans'), False)


        # 参数验证
        if page_size < 1 or page_size > 100:
            raise https_fn.HttpsError('invalid-argument', '每页数量必须在1-100之间')
        if page_number < 1:
            raise https_fn.HttpsError('invalid-argument', '页码必须大于0')

        logger.info(f'查询学生列表: coach_id={coach_id}, page={page_number}, size={page_size}, search={search_name}, filter={filter_plan_id}')
        
        # 构建查询
        db = firestore.client()
        query = db.collection('users') \
            .where('role', '==', 'student') \
            .where('coachId', '==', coach_id)
        
        # 添加搜索条件（前缀匹配）
        if search_name:
            query = query.order_by('name') \
                .start_at([search_name]) \
                .end_at([search_name + '\uf8ff'])
        else:
            # 默认按name排序（避免createdAt字段缺失或类型不一致导致的排序错误）
            query = query.order_by('name')
        
        # 获取所有匹配的学生（用于计算总数和筛选）
        all_students_docs = query.get()
        all_students = []
        
        for student_doc in all_students_docs:
            student_data = student_doc.to_dict()

            # 只有在需要时才查询计划信息（性能优化）
            exercise_plan = None
            diet_plan = None
            supplement_plan = None

            if include_plans or filter_plan_id:
                exercise_plan = _get_student_plan(db, student_doc.id, 'exercisePlans')
                diet_plan = _get_student_plan(db, student_doc.id, 'dietPlans')
                supplement_plan = _get_student_plan(db, student_doc.id, 'supplementPlans')

            logger.info(f"exercise_plan: {exercise_plan}")
            logger.info(f"diet_plan: {diet_plan}")
            logger.info(f"supplement_plan: {supplement_plan}")
            # 创建学生列表项
            student_item = StudentListItem(
                student_id=student_doc.id,
                name=student_data.get('name', ''),
                email=student_data.get('email', ''),
                avatar_url=student_data.get('avatarUrl'),
                coach_id=student_data.get('coachId'),
                exercise_plan=exercise_plan,
                diet_plan=diet_plan,
                supplement_plan=supplement_plan,
                created_at=student_data.get('createdAt')
            )

            # 应用计划筛选
            if filter_plan_id:
                # 检查学生是否有该计划
                has_plan = False
                if exercise_plan and exercise_plan.id == filter_plan_id:
                    has_plan = True
                if diet_plan and diet_plan.id == filter_plan_id:
                    has_plan = True
                if supplement_plan and supplement_plan.id == filter_plan_id:
                    has_plan = True

                if has_plan:
                    all_students.append(student_item)
            else:
                all_students.append(student_item)
        
        # 计算分页信息
        total_count = len(all_students)
        total_pages = math.ceil(total_count / page_size) if total_count > 0 else 1
        start_index = (page_number - 1) * page_size
        end_index = start_index + page_size
        has_more = end_index < total_count
        
        # 获取当前页的学生
        page_students = all_students[start_index:end_index]
        
        # 转换为字典格式
        students_data = [student.to_dict() for student in page_students]

        logger.info(f'查询学生列表成功: total={total_count}, page={page_number}, returned={len(students_data)}')
        
        return {
            'status': 'success',
            'data': {
                'students': students_data,
                'total_count': total_count,
                'has_more': has_more,
                'current_page': page_number,
                'total_pages': total_pages
            }
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'查询学生列表失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def delete_student(req: https_fn.CallableRequest):
    """
    删除学生（软删除）
    
    请求参数:
        - student_id: 学生ID
    
    返回:
        - status: 状态码
        - message: 消息
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        coach_id = req.auth.uid
        student_id = req.data.get('student_id', '').strip()
        
        if not student_id:
            raise https_fn.HttpsError('invalid-argument', '学生ID不能为空')
        
        # 验证教练身份
        user_doc = db_helper.get_document('users', coach_id)
        if not user_doc.exists or user_doc.to_dict().get('role') != 'coach':
            raise https_fn.HttpsError('permission-denied', '只有教练可以删除学生')
        
        # 获取学生信息并验证归属
        student_doc = db_helper.get_document('users', student_id)
        if not student_doc.exists:
            raise https_fn.HttpsError('not-found', '学生不存在')
        
        student_data = student_doc.to_dict()
        if student_data.get('coachId') != coach_id:
            raise https_fn.HttpsError('permission-denied', '该学生不属于您')
        
        # 软删除学生
        db_helper.update_document('users', student_id, {
            'isDeleted': True,
            'deletedAt': firestore.SERVER_TIMESTAMP
        })
        
        # 从所有计划中移除该学生
        db = firestore.client()
        _remove_student_from_plans(db, student_id, 'exercisePlans')
        _remove_student_from_plans(db, student_id, 'dietPlans')
        _remove_student_from_plans(db, student_id, 'supplementPlans')
        
        logger.info(f'学生删除成功: {student_id} by coach {coach_id}')
        
        return {
            'status': 'success',
            'message': '学生已删除'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'删除学生失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


# ==================== 辅助函数 ====================

def _get_student_plan(db, student_id: str, collection_name: str):
    """获取学生的计划信息"""
    try:
        plans = db.collection(collection_name) \
            .where('studentIds', 'array_contains', student_id) \
            .limit(1) \
            .get()
        
        if not plans:
            return None
        
        plan_doc = plans[0]
        plan_data = plan_doc.to_dict()
        
        # 确定计划类型
        plan_type = 'exercise' if collection_name == 'exercisePlans' else \
                    'diet' if collection_name == 'dietPlans' else \
                    'supplement'
        
        return StudentPlanInfo(
            plan_id=plan_doc.id,
            plan_name=plan_data.get('name', ''),
            plan_type=plan_type
        )
    except Exception as e:
        logger.error(f'获取学生计划失败: {collection_name}', e)
        return None


def _remove_student_from_plans(db, student_id: str, collection_name: str):
    """从所有计划中移除学生"""
    try:
        plans = db.collection(collection_name) \
            .where('studentIds', 'array_contains', student_id) \
            .get()

        batch = db.batch()
        for plan_doc in plans:
            batch.update(plan_doc.reference, {
                'studentIds': firestore.ArrayRemove([student_id])
            })

        if len(plans) > 0:
            batch.commit()
            logger.info(f'从{len(plans)}个{collection_name}中移除学生: {student_id}')
    except Exception as e:
        logger.error(f'从计划中移除学生失败: {collection_name}', e)


# ==================== 训练记录相关 ====================


@https_fn.on_call()
def fetch_latest_training(req: https_fn.CallableRequest):
    """
    获取学生最新一次的训练记录

    用于确定学生今天应该训练计划的第几天

    返回:
        {
            'status': 'success',
            'data': {
                'training': {
                    'id': str,
                    'date': str,
                    'planSelection': {
                        'exercisePlanId': str,
                        'exerciseDayNumber': int,
                        'dietPlanId': str,
                        'dietDayNumber': int,
                        'supplementPlanId': str,
                        'supplementDayNumber': int
                    },
                    ...
                } | None
            }
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid

        logger.info(f'📖 获取最新训练记录 - 学生ID: {student_id}')

        # 获取 Firestore 实例
        db = firestore.client()

        # 查询 dailyTrainings collection
        trainings_query = db.collection('dailyTrainings') \
            .where('studentID', '==', student_id) \
            .order_by('date', direction=firestore.Query.DESCENDING) \
            .limit(1) \
            .get()

        # 如果找到记录，返回第一个（最新的）
        training_data = None
        if trainings_query:
            for training_doc in trainings_query:
                training_data = training_doc.to_dict()
                training_data['id'] = training_doc.id
                logger.info(f'✅ 找到最新训练记录: 日期={training_data.get("date")}, ID={training_doc.id}')
                break

        if not training_data:
            logger.info(f'📖 学生无训练记录: {student_id}')

        return {
            'status': 'success',
            'data': {
                'training': training_data
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取最新训练记录失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def fetch_student_detail(req: https_fn.CallableRequest):
    """
    获取学生详情（教练端查看）

    请求参数:
        - student_id: 学生ID (必填)
        - time_range: 时间范围 ['1M', '3M', '6M', '1Y'] (可选，默认'3M')

    返回:
        - status: 状态码
        - data: 学生详情数据对象
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        coach_id = req.auth.uid
        student_id = req.data.get('student_id', '').strip()
        time_range = req.data.get('time_range', '3M').strip()

        # 参数验证
        if not student_id:
            raise https_fn.HttpsError('invalid-argument', '学生ID不能为空')

        if time_range not in ['1M', '3M', '6M', '1Y']:
            time_range = '3M'

        logger.info(f'获取学生详情: coach={coach_id}, student={student_id}, range={time_range}')

        # 验证教练身份
        coach_doc = db_helper.get_document('users', coach_id)
        if not coach_doc.exists or coach_doc.to_dict().get('role') != 'coach':
            raise https_fn.HttpsError('permission-denied', '只有教练可以查看学生详情')

        # 获取学生信息并验证归属
        student_doc = db_helper.get_document('users', student_id)
        if not student_doc.exists:
            raise https_fn.HttpsError('not-found', '学生不存在')

        student_data = student_doc.to_dict()
        if student_data.get('coachId') != coach_id:
            raise https_fn.HttpsError('permission-denied', '该学生不属于您')

        db = firestore.client()

        # 1. 获取基本信息
        basic_info = _get_basic_info(student_data, student_id, db)

        # 2. 获取学生计划
        plans = _get_student_plans(db, student_id)

        # 3. 计算训练统计
        stats = _calculate_training_stats(db, student_id, time_range)

        # 4. 获取体重趋势
        weight_trend = _get_weight_trend(db, student_id, student_data, time_range)

        # 5. 获取最近训练记录
        recent_trainings = _get_recent_trainings(db, student_id, limit=3)

        # 6. 生成AI摘要
        ai_summary = _generate_ai_summary(stats, weight_trend)

        result = {
            'basicInfo': basic_info,
            'plans': plans,
            'stats': stats,
            'aiSummary': ai_summary,
            'weightTrend': weight_trend,
            'recentTrainings': recent_trainings
        }

        logger.info(f'✅ 获取学生详情成功: {student_id}')

        return {
            'status': 'success',
            'data': result
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'获取学生详情失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


# ==================== 学生详情辅助函数 ====================

def _get_basic_info(student_data: dict, student_id: str, db):
    """获取学生基本信息"""
    from datetime import datetime

    # 计算年龄
    age = None
    born_date = student_data.get('bornDate')
    if born_date:
        try:
            if isinstance(born_date, str):
                birth_date = datetime.fromisoformat(born_date.replace('Z', '+00:00'))
            else:
                birth_date = born_date.toDate() if hasattr(born_date, 'toDate') else born_date

            today = datetime.now()
            age = today.year - birth_date.year
            if (today.month, today.day) < (birth_date.month, birth_date.day):
                age -= 1
        except Exception as e:
            logger.error(f'计算年龄失败: {e}')

    # 获取当前体重（从最新的bodyMeasure记录）
    current_weight = student_data.get('initialWeight')
    weight_unit = 'kg'
    try:
        latest_measurement = db.collection('bodyMeasure') \
            .where('studentID', '==', student_id) \
            .order_by('recordDate', direction=firestore.Query.DESCENDING) \
            .limit(1) \
            .get()

        if latest_measurement:
            for doc in latest_measurement:
                measurement_data = doc.to_dict()
                current_weight = measurement_data.get('weight')
                weight_unit = measurement_data.get('weightUnit', 'kg')
                break
    except Exception as e:
        logger.error(f'获取当前体重失败: {e}')

    return {
        'id': student_id,
        'name': student_data.get('name', ''),
        'email': student_data.get('email', ''),
        'avatarUrl': student_data.get('avatarUrl'),
        'gender': student_data.get('gender'),
        'age': age,
        'height': student_data.get('height'),
        'currentWeight': current_weight,
        'weightUnit': weight_unit,
        'coachId': student_data.get('coachId')
    }


def _get_student_plans(db, student_id: str):
    """获取学生计划信息"""
    exercise_plan = _get_plan_detail(db, student_id, 'exercisePlans')
    diet_plan = _get_plan_detail(db, student_id, 'dietPlans')
    supplement_plan = _get_plan_detail(db, student_id, 'supplementPlans')

    return {
        'exercisePlan': exercise_plan,
        'dietPlan': diet_plan,
        'supplementPlan': supplement_plan
    }


def _get_plan_detail(db, student_id: str, collection_name: str):
    """获取计划详细信息"""
    try:
        plans = db.collection(collection_name) \
            .where('studentIds', 'array_contains', student_id) \
            .limit(1) \
            .get()

        if not plans:
            return None

        for plan_doc in plans:
            plan_data = plan_doc.to_dict()
            return {
                'id': plan_doc.id,
                'name': plan_data.get('name', ''),
                'description': plan_data.get('description', '')
            }

        return None
    except Exception as e:
        logger.error(f'获取计划详情失败: {collection_name}', e)
        return None


def _calculate_training_stats(db, student_id: str, time_range: str):
    """计算训练统计数据"""
    from datetime import datetime, timedelta

    # 计算时间范围
    end_date = datetime.now()
    days_map = {'1M': 30, '3M': 90, '6M': 180, '1Y': 365}
    days = days_map.get(time_range, 90)
    start_date = end_date - timedelta(days=days)

    start_date_str = start_date.strftime('%Y-%m-%d')

    try:
        # 获取时间范围内的训练记录
        trainings = db.collection('dailyTrainings') \
            .where('studentID', '==', student_id) \
            .where('date', '>=', start_date_str) \
            .get()

        total_sessions = 0
        completed_sessions = 0
        total_volume = 0  # 总训练容量（kg）

        for training_doc in trainings:
            training_data = training_doc.to_dict()
            total_sessions += 1

            # 统计完成的训练
            if training_data.get('completionStatus') in ['completed', 'partial']:
                completed_sessions += 1

            # 计算训练容量
            exercises = training_data.get('exercises', [])
            for exercise in exercises:
                sets = exercise.get('sets', [])
                for set_data in sets:
                    try:
                        weight = float(set_data.get('weight', 0) or 0)
                        reps = float(set_data.get('reps', 0) or 0)
                        total_volume += weight * reps
                    except (ValueError, TypeError):
                        continue

        # 计算完成率
        adherence_rate = (completed_sessions / total_sessions * 100) if total_sessions > 0 else 0

        # 获取体重变化
        weight_change = _calculate_weight_change(db, student_id, start_date_str)

        return {
            'totalSessions': total_sessions,
            'weightChange': weight_change,
            'adherenceRate': round(adherence_rate, 1),
            'totalVolume': round(total_volume, 1)
        }

    except Exception as e:
        logger.error(f'计算训练统计失败: {e}')
        return {
            'totalSessions': 0,
            'weightChange': 0,
            'adherenceRate': 0,
            'totalVolume': 0
        }


def _calculate_weight_change(db, student_id: str, start_date_str: str):
    """计算体重变化"""
    try:
        # 获取起始体重
        start_measurements = db.collection('bodyMeasure') \
            .where('studentID', '==', student_id) \
            .where('recordDate', '>=', start_date_str) \
            .order_by('recordDate') \
            .limit(1) \
            .get()

        # 获取最新体重
        end_measurements = db.collection('bodyMeasure') \
            .where('studentID', '==', student_id) \
            .order_by('recordDate', direction=firestore.Query.DESCENDING) \
            .limit(1) \
            .get()

        start_weight = None
        end_weight = None

        for doc in start_measurements:
            start_weight = doc.to_dict().get('weight')
            break

        for doc in end_measurements:
            end_weight = doc.to_dict().get('weight')
            break

        if start_weight and end_weight:
            return round(end_weight - start_weight, 1)

        return 0

    except Exception as e:
        logger.error(f'计算体重变化失败: {e}')
        return 0


def _get_weight_trend(db, student_id: str, student_data: dict, time_range: str):
    """获取体重趋势数据"""
    from datetime import datetime, timedelta

    # 计算时间范围
    end_date = datetime.now()
    days_map = {'1M': 30, '3M': 90, '6M': 180, '1Y': 365}
    days = days_map.get(time_range, 90)
    start_date = end_date - timedelta(days=days)

    start_date_str = start_date.strftime('%Y-%m-%d')

    try:
        # 获取时间范围内的体重数据
        measurements = db.collection('bodyMeasure') \
            .where('studentID', '==', student_id) \
            .where('recordDate', '>=', start_date_str) \
            .order_by('recordDate') \
            .get()

        data_points = []
        for doc in measurements:
            data = doc.to_dict()
            data_points.append({
                'date': data.get('recordDate'),
                'weight': data.get('weight'),
                'timestamp': int(datetime.fromisoformat(data.get('recordDate')).timestamp() * 1000)
            })

        # 计算统计值
        starting = data_points[0]['weight'] if data_points else student_data.get('initialWeight')
        current = data_points[-1]['weight'] if data_points else student_data.get('initialWeight')
        change = (current - starting) if (starting and current) else 0
        target = student_data.get('targetWeight', starting)  # 假设有targetWeight字段

        return {
            'dataPoints': data_points,
            'starting': starting,
            'current': current,
            'change': round(change, 1) if change else 0,
            'target': target if target else starting
        }

    except Exception as e:
        logger.error(f'获取体重趋势失败: {e}')
        initial_weight = student_data.get('initialWeight', 0)
        return {
            'dataPoints': [],
            'starting': initial_weight,
            'current': initial_weight,
            'change': 0,
            'target': initial_weight
        }


def _get_recent_trainings(db, student_id: str, limit: int = 3):
    """获取最近的训练记录"""
    try:
        trainings = db.collection('dailyTrainings') \
            .where('studentID', '==', student_id) \
            .order_by('date', direction=firestore.Query.DESCENDING) \
            .limit(limit) \
            .get()

        recent_trainings = []
        for training_doc in trainings:
            training_data = training_doc.to_dict()
            exercises = training_data.get('exercises', [])

            # 计算视频数量
            video_count = 0
            for exercise in exercises:
                videos = exercise.get('medias', exercise.get('videos', []))
                video_count += len(videos)

            # 获取训练标题（从planSelection获取）
            title = 'Training Session'
            plan_selection = training_data.get('planSelection', {})
            if plan_selection and plan_selection.get('exercisePlanId'):
                # 可以从exercisePlans获取更详细的名称，这里简化处理
                day_num = plan_selection.get('exerciseDayNumber', 0)
                title = f'Day {day_num} Training'

            recent_trainings.append({
                'id': training_doc.id,
                'date': training_data.get('date', ''),
                'title': title,
                'exerciseCount': len(exercises),
                'videoCount': video_count,
                'duration': training_data.get('totalDuration', 0),
                'isReviewed': training_data.get('isReviewed', False)
            })

        return recent_trainings

    except Exception as e:
        logger.error(f'获取最近训练记录失败: {e}')
        return []


def _generate_ai_summary(stats: dict, weight_trend: dict):
    """生成AI进度摘要（当前为模板生成）"""
    # TODO: 未来可以集成真实的AI生成服务

    total_sessions = stats.get('totalSessions', 0)
    weight_change = stats.get('weightChange', 0)
    adherence = stats.get('adherenceRate', 0)
    volume = stats.get('totalVolume', 0)

    # 生成摘要文本
    weight_trend_text = f"down {abs(weight_change):.1f} kg" if weight_change < 0 else f"up {abs(weight_change):.1f} kg" if weight_change > 0 else "stable"
    adherence_level = "excellent" if adherence >= 90 else "good" if adherence >= 75 else "moderate"

    content = f"Student is showing {'excellent' if adherence >= 90 else 'good'} progress! "
    content += f"Completed {total_sessions} training sessions with {adherence:.0f}% adherence rate. "
    content += f"Weight is trending {weight_trend_text}. "
    content += f"Total training volume has reached {volume:.0f} kg. "
    content += f"Maintain the {adherence_level} consistency!"

    # 计算高亮数据
    volume_change_pct = "+15%" if volume > 0 else "0%"  # 简化计算

    return {
        'content': content,
        'highlights': {
            'trainingVolumeChange': volume_change_pct,
            'weightLoss': f"{weight_change:+.1f} kg",
            'avgStrength': "+0 kg",  # 需要更复杂的计算，暂时返回0
            'adherence': f"{adherence:.0f}%"
        }
    }


@https_fn.on_call()
def generate_student_ai_summary(req: https_fn.CallableRequest):
    """
    按需生成学生AI进度摘要（教练端）

    请求参数:
        - student_id: 学生ID (必填)
        - time_range: 时间范围 ['1M', '3M', '6M', '1Y'] (可选，默认'3M')

    返回:
        - status: 状态码
        - data: AI摘要数据对象 {content, highlights}
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        coach_id = req.auth.uid
        student_id = req.data.get('student_id', '').strip()
        time_range = req.data.get('time_range', '3M').strip()

        # 参数验证
        if not student_id:
            raise https_fn.HttpsError('invalid-argument', '学生ID不能为空')

        if time_range not in ['1M', '3M', '6M', '1Y']:
            time_range = '3M'

        logger.info(f'生成AI摘要: coach={coach_id}, student={student_id}, range={time_range}')

        # 验证教练身份
        coach_doc = db_helper.get_document('users', coach_id)
        if not coach_doc.exists or coach_doc.to_dict().get('role') != 'coach':
            raise https_fn.HttpsError('permission-denied', '只有教练可以生成AI摘要')

        # 获取学生信息并验证归属
        student_doc = db_helper.get_document('users', student_id)
        if not student_doc.exists:
            raise https_fn.HttpsError('not-found', '学生不存在')

        student_data = student_doc.to_dict()
        if student_data.get('coachId') != coach_id:
            raise https_fn.HttpsError('permission-denied', '该学生不属于您')

        db = firestore.client()

        # 1. 计算训练统计
        stats = _calculate_training_stats(db, student_id, time_range)

        # 2. 获取体重趋势
        weight_trend = _get_weight_trend(db, student_id, student_data, time_range)

        # 3. 生成AI摘要
        ai_summary = _generate_ai_summary(stats, weight_trend)

        logger.info(f'✅ 生成AI摘要成功: {student_id}')

        return {
            'status': 'success',
            'data': ai_summary
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'生成AI摘要失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')

