"""
身体测量相关Cloud Functions处理器
"""
from firebase_functions import https_fn
from firebase_admin import firestore, storage
from utils import logger
from datetime import datetime


@https_fn.on_call()
def save_body_measurement(req: https_fn.CallableRequest):
    """
    保存身体测量记录

    请求参数:
        - record_date: 记录日期 (ISO 8601格式, 如 "2025-11-05")
        - weight: 体重值 (必填, > 0)
        - weight_unit: 体重单位 ('kg' 或 'lbs')
        - body_fat: 体脂率 (可选, 0-100)
        - photos: 照片URL列表 (可选, 最多3个)

    返回:
        - status: 状态码
        - data: 新创建的测量记录对象
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid

        # 获取参数
        record_date = req.data.get('record_date', '').strip()
        weight = req.data.get('weight')
        weight_unit = req.data.get('weight_unit', '').strip()
        body_fat = req.data.get('body_fat')
        photos = req.data.get('photos', [])

        # 验证必填参数
        if not record_date:
            raise https_fn.HttpsError('invalid-argument', '记录日期不能为空')

        if weight is None or weight <= 0:
            raise https_fn.HttpsError('invalid-argument', '体重必须大于0')

        if weight_unit not in ['kg', 'lbs']:
            raise https_fn.HttpsError('invalid-argument', '体重单位必须为 kg 或 lbs')

        # 验证可选参数
        if body_fat is not None:
            if not isinstance(body_fat, (int, float)):
                raise https_fn.HttpsError('invalid-argument', '体脂率必须为数字')
            if body_fat < 0 or body_fat > 100:
                raise https_fn.HttpsError('invalid-argument', '体脂率必须在0-100之间')

        # 验证照片列表
        if not isinstance(photos, list):
            raise https_fn.HttpsError('invalid-argument', '照片必须为列表')

        if len(photos) > 3:
            raise https_fn.HttpsError('invalid-argument', '最多上传3张照片')

        # 验证日期格式
        try:
            datetime.fromisoformat(record_date)
        except ValueError:
            raise https_fn.HttpsError('invalid-argument', '日期格式无效，应为ISO 8601格式')

        logger.info(f'保存身体测量记录: student_id={student_id}, date={record_date}, weight={weight}{weight_unit}')

        # 创建记录对象
        db = firestore.client()
        measurement_data = {
            'studentID': student_id,
            'recordDate': record_date,
            'weight': weight,
            'weightUnit': weight_unit,
            'bodyFat': body_fat,
            'photos': photos,
            'createdAt': firestore.SERVER_TIMESTAMP
        }

        # 保存到Firestore
        doc_ref = db.collection('bodyMeasure').document()
        doc_ref.set(measurement_data)

        # 获取创建后的文档（包含自动生成的timestamp）
        created_doc = doc_ref.get()
        created_data = created_doc.to_dict()
        created_data['id'] = doc_ref.id

        # 转换timestamp为毫秒
        if created_data.get('createdAt'):
            created_data['createdAt'] = int(created_data['createdAt'].timestamp() * 1000)

        logger.info(f'✅ 身体测量记录保存成功: id={doc_ref.id}')

        return {
            'status': 'success',
            'data': created_data
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 保存身体测量记录失败: {str(e)}', e)
        raise https_fn.HttpsError('internal', f'保存失败: {str(e)}')


@https_fn.on_call()
def fetch_body_measurements(req: https_fn.CallableRequest):
    """
    获取用户的身体测量历史记录

    请求参数:
        - start_date: 开始日期 (可选, ISO 8601格式)
        - end_date: 结束日期 (可选, ISO 8601格式)

    返回:
        - status: 状态码
        - data: { measurements: [...] }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid

        # 获取参数
        start_date = req.data.get('start_date', '').strip() if req.data.get('start_date') else None
        end_date = req.data.get('end_date', '').strip() if req.data.get('end_date') else None

        logger.info(f'获取身体测量记录: student_id={student_id}, start={start_date}, end={end_date}')

        # 构建查询
        db = firestore.client()
        query = db.collection('bodyMeasure').where('studentID', '==', student_id)

        # 添加日期范围过滤
        if start_date:
            query = query.where('recordDate', '>=', start_date)

        if end_date:
            query = query.where('recordDate', '<=', end_date)

        # 按日期降序排序
        query = query.order_by('recordDate', direction=firestore.Query.DESCENDING)

        # 执行查询
        docs = query.get()

        measurements = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id

            # 转换timestamp为毫秒
            if data.get('createdAt'):
                data['createdAt'] = int(data['createdAt'].timestamp() * 1000)

            measurements.append(data)

        logger.info(f'✅ 查询到 {len(measurements)} 条身体测量记录')

        return {
            'status': 'success',
            'data': {
                'measurements': measurements
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取身体测量记录失败: {str(e)}', e)
        raise https_fn.HttpsError('internal', f'获取失败: {str(e)}')


@https_fn.on_call()
def update_body_measurement(req: https_fn.CallableRequest):
    """
    更新身体测量记录

    请求参数:
        - measurement_id: 记录ID (必填)
        - weight: 体重值 (可选)
        - weight_unit: 体重单位 (可选)
        - body_fat: 体脂率 (可选)
        - photos: 照片URL列表 (可选)

    返回:
        - status: 状态码
        - data: 更新后的记录对象
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid

        # 获取参数
        measurement_id = req.data.get('measurement_id', '').strip()

        if not measurement_id:
            raise https_fn.HttpsError('invalid-argument', '记录ID不能为空')

        logger.info(f'更新身体测量记录: id={measurement_id}, student_id={student_id}')

        # 获取现有记录
        db = firestore.client()
        doc_ref = db.collection('bodyMeasure').document(measurement_id)
        doc = doc_ref.get()

        if not doc.exists:
            raise https_fn.HttpsError('not-found', '记录不存在')

        existing_data = doc.to_dict()

        # 验证所有权
        if existing_data.get('studentID') != student_id:
            raise https_fn.HttpsError('permission-denied', '无权限修改此记录')

        # 构建更新数据
        update_data = {}

        # 更新体重
        if 'weight' in req.data:
            weight = req.data['weight']
            if weight is None or weight <= 0:
                raise https_fn.HttpsError('invalid-argument', '体重必须大于0')
            update_data['weight'] = weight

        # 更新体重单位
        if 'weight_unit' in req.data:
            weight_unit = req.data['weight_unit'].strip()
            if weight_unit not in ['kg', 'lbs']:
                raise https_fn.HttpsError('invalid-argument', '体重单位必须为 kg 或 lbs')
            update_data['weightUnit'] = weight_unit

        # 更新体脂率
        if 'body_fat' in req.data:
            body_fat = req.data['body_fat']
            if body_fat is not None:
                if not isinstance(body_fat, (int, float)):
                    raise https_fn.HttpsError('invalid-argument', '体脂率必须为数字')
                if body_fat < 0 or body_fat > 100:
                    raise https_fn.HttpsError('invalid-argument', '体脂率必须在0-100之间')
            update_data['bodyFat'] = body_fat

        # 更新照片
        if 'photos' in req.data:
            photos = req.data['photos']
            if not isinstance(photos, list):
                raise https_fn.HttpsError('invalid-argument', '照片必须为列表')
            if len(photos) > 3:
                raise https_fn.HttpsError('invalid-argument', '最多上传3张照片')
            update_data['photos'] = photos

        # 如果没有任何更新
        if not update_data:
            raise https_fn.HttpsError('invalid-argument', '没有需要更新的字段')

        # 执行更新
        doc_ref.update(update_data)

        # 获取更新后的数据
        updated_doc = doc_ref.get()
        updated_data = updated_doc.to_dict()
        updated_data['id'] = measurement_id

        # 转换timestamp为毫秒
        if updated_data.get('createdAt'):
            updated_data['createdAt'] = int(updated_data['createdAt'].timestamp() * 1000)

        logger.info(f'✅ 身体测量记录更新成功: id={measurement_id}')

        return {
            'status': 'success',
            'data': updated_data
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 更新身体测量记录失败: {str(e)}', e)
        raise https_fn.HttpsError('internal', f'更新失败: {str(e)}')


@https_fn.on_call()
def delete_body_measurement(req: https_fn.CallableRequest):
    """
    删除身体测量记录

    请求参数:
        - measurement_id: 记录ID (必填)

    返回:
        - status: 状态码
        - message: 成功消息
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid

        # 获取参数
        measurement_id = req.data.get('measurement_id', '').strip()

        if not measurement_id:
            raise https_fn.HttpsError('invalid-argument', '记录ID不能为空')

        logger.info(f'删除身体测量记录: id={measurement_id}, student_id={student_id}')

        # 获取记录
        db = firestore.client()
        doc_ref = db.collection('bodyMeasure').document(measurement_id)
        doc = doc_ref.get()

        if not doc.exists:
            raise https_fn.HttpsError('not-found', '记录不存在')

        existing_data = doc.to_dict()

        # 验证所有权
        if existing_data.get('studentID') != student_id:
            raise https_fn.HttpsError('permission-denied', '无权限删除此记录')

        # 获取照片列表，准备删除
        photos = existing_data.get('photos', [])

        # 删除Firestore记录
        doc_ref.delete()

        # 删除关联的Storage照片
        if photos:
            try:
                bucket = storage.bucket()
                for photo_url in photos:
                    # 从URL提取文件路径
                    # URL格式: https://storage.googleapis.com/bucket-name/path/to/file
                    if 'storage.googleapis.com' in photo_url:
                        # 提取路径部分
                        path_start = photo_url.find('/o/') + 3
                        path_end = photo_url.find('?') if '?' in photo_url else len(photo_url)
                        file_path = photo_url[path_start:path_end]
                        # URL解码
                        import urllib.parse
                        file_path = urllib.parse.unquote(file_path)

                        blob = bucket.blob(file_path)
                        if blob.exists():
                            blob.delete()
                            logger.info(f'🗑️ 删除照片: {file_path}')
            except Exception as e:
                logger.warning(f'⚠️ 删除照片失败（忽略错误）: {str(e)}')

        logger.info(f'✅ 身体测量记录删除成功: id={measurement_id}')

        return {
            'status': 'success',
            'message': 'Measurement deleted successfully'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 删除身体测量记录失败: {str(e)}', e)
        raise https_fn.HttpsError('internal', f'删除失败: {str(e)}')
