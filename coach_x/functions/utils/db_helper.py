"""
Firestore数据库通用操作模块
"""
from firebase_admin import firestore

def get_firestore_client():
    """获取Firestore客户端"""
    return firestore.client()

def create_document(collection: str, doc_id: str, data: dict):
    """创建文档"""
    db = get_firestore_client()
    data['createdAt'] = firestore.SERVER_TIMESTAMP
    data['updatedAt'] = firestore.SERVER_TIMESTAMP
    db.collection(collection).document(doc_id).set(data)

def update_document(collection: str, doc_id: str, data: dict):
    """更新文档"""
    db = get_firestore_client()
    data['updatedAt'] = firestore.SERVER_TIMESTAMP
    db.collection(collection).document(doc_id).update(data)

def get_document(collection: str, doc_id: str):
    """获取文档"""
    db = get_firestore_client()
    return db.collection(collection).document(doc_id).get()

def delete_document(collection: str, doc_id: str):
    """删除文档"""
    db = get_firestore_client()
    db.collection(collection).document(doc_id).delete()

def query_documents(collection: str, filters: list = None, limit: int = None):
    """查询文档"""
    db = get_firestore_client()
    query = db.collection(collection)
    
    if filters:
        for filter_item in filters:
            field, operator, value = filter_item
            query = query.where(field, operator, value)
    
    if limit:
        query = query.limit(limit)
    
    return query.get()

