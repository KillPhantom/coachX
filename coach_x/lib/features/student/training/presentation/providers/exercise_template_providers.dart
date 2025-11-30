import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/exercise_library/data/models/exercise_template_model.dart';

/// 根据 templateId 加载 ExerciseTemplate
final exerciseTemplateProvider =
    StreamProvider.family<ExerciseTemplateModel?, String>((
      ref,
      templateId,
    ) {
      return FirebaseFirestore.instance
          .collection('exerciseTemplates')
          .doc(templateId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return ExerciseTemplateModel.fromFirestore(doc);
          })
          .handleError((e) {
            // 加载失败时返回 null
            return null;
          });
    });
