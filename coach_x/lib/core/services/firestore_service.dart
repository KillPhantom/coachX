import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_x/core/utils/logger.dart';

/// Firestore数据库服务
///
/// 封装Cloud Firestore的基础CRUD操作
class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 添加文档（自动生成ID）
  ///
  /// [collection] 集合名称
  /// [data] 文档数据
  /// 返回新文档的ID
  static Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      // 添加时间戳
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection(collection).add(data);
      AppLogger.info('文档添加成功: $collection/${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('添加文档失败: $collection', e, stackTrace);
      rethrow;
    }
  }

  /// 创建文档（指定ID）
  ///
  /// [collection] 集合名称
  /// [docId] 文档ID
  /// [data] 文档数据
  static Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      if (!merge) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(collection).doc(docId).set(data, SetOptions(merge: merge));
      AppLogger.info('文档设置成功: $collection/$docId');
    } catch (e, stackTrace) {
      AppLogger.error('设置文档失败: $collection/$docId', e, stackTrace);
      rethrow;
    }
  }

  /// 更新文档
  ///
  /// [collection] 集合名称
  /// [docId] 文档ID
  /// [data] 要更新的字段
  static Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(collection).doc(docId).update(data);
      AppLogger.info('文档更新成功: $collection/$docId');
    } catch (e, stackTrace) {
      AppLogger.error('更新文档失败: $collection/$docId', e, stackTrace);
      rethrow;
    }
  }

  /// 删除文档
  ///
  /// [collection] 集合名称
  /// [docId] 文档ID
  static Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      AppLogger.info('文档删除成功: $collection/$docId');
    } catch (e, stackTrace) {
      AppLogger.error('删除文档失败: $collection/$docId', e, stackTrace);
      rethrow;
    }
  }

  /// 获取单个文档
  ///
  /// [collection] 集合名称
  /// [docId] 文档ID
  /// 返回文档快照
  static Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      AppLogger.info('获取文档: $collection/$docId, 存在: ${doc.exists}');
      return doc;
    } catch (e, stackTrace) {
      AppLogger.error('获取文档失败: $collection/$docId', e, stackTrace);
      rethrow;
    }
  }

  /// 查询文档列表
  ///
  /// [collection] 集合名称
  /// [where] 查询条件列表 [字段名, 操作符, 值]
  /// [orderBy] 排序字段
  /// [descending] 是否降序
  /// [limit] 限制数量
  static Future<List<DocumentSnapshot>> queryDocuments(
    String collection, {
    List<List<dynamic>>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // 添加查询条件
      if (where != null) {
        for (final condition in where) {
          if (condition.length == 3) {
            query = query.where(
              condition[0] as String,
              isEqualTo: condition[1] == '==' ? condition[2] : null,
              isNotEqualTo: condition[1] == '!=' ? condition[2] : null,
              isLessThan: condition[1] == '<' ? condition[2] : null,
              isLessThanOrEqualTo: condition[1] == '<=' ? condition[2] : null,
              isGreaterThan: condition[1] == '>' ? condition[2] : null,
              isGreaterThanOrEqualTo: condition[1] == '>=' ? condition[2] : null,
              arrayContains: condition[1] == 'array-contains' ? condition[2] : null,
            );
          }
        }
      }

      // 添加排序
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // 添加限制
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      AppLogger.info('查询文档: $collection, 数量: ${snapshot.docs.length}');
      return snapshot.docs;
    } catch (e, stackTrace) {
      AppLogger.error('查询文档失败: $collection', e, stackTrace);
      rethrow;
    }
  }

  /// 监听单个文档变化
  ///
  /// [collection] 集合名称
  /// [docId] 文档ID
  /// 返回文档快照流
  static Stream<DocumentSnapshot> watchDocument(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  /// 监听集合变化
  ///
  /// [collection] 集合名称
  /// [where] 查询条件列表
  /// [orderBy] 排序字段
  /// [descending] 是否降序
  /// [limit] 限制数量
  static Stream<QuerySnapshot> watchCollection(
    String collection, {
    List<List<dynamic>>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // 添加查询条件
    if (where != null) {
      for (final condition in where) {
        if (condition.length == 3) {
          query = query.where(
            condition[0] as String,
            isEqualTo: condition[1] == '==' ? condition[2] : null,
            isNotEqualTo: condition[1] == '!=' ? condition[2] : null,
            isLessThan: condition[1] == '<' ? condition[2] : null,
            isLessThanOrEqualTo: condition[1] == '<=' ? condition[2] : null,
            isGreaterThan: condition[1] == '>' ? condition[2] : null,
            isGreaterThanOrEqualTo: condition[1] == '>=' ? condition[2] : null,
          );
        }
      }
    }

    // 添加排序
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // 添加限制
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  /// 批量写入操作
  ///
  /// [operations] 操作列表
  static Future<void> batchWrite(List<void Function(WriteBatch)> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        operation(batch);
      }

      await batch.commit();
      AppLogger.info('批量写入成功: ${operations.length}个操作');
    } catch (e, stackTrace) {
      AppLogger.error('批量写入失败', e, stackTrace);
      rethrow;
    }
  }

  /// 事务操作
  ///
  /// [transactionHandler] 事务处理函数
  static Future<T> runTransaction<T>(Future<T> Function(Transaction) transactionHandler) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } catch (e, stackTrace) {
      AppLogger.error('事务执行失败', e, stackTrace);
      rethrow;
    }
  }
}
