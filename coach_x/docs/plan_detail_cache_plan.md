# Plan 详情缓存实施计划

## 目标
为三类计划（Exercise、Diet、Supplement）的详情页面添加本地缓存，消除编辑模式下的加载延迟。

---

## 技术方案

### 缓存策略
- **存储方式**: JSON 格式存储于 Hive（复用现有 `plans_cache` Box）
- **缓存键格式**: `plan_detail_{planType}_{planId}`
  - 例: `plan_detail_exercise_abc123`
  - 例: `plan_detail_diet_xyz789`
  - 例: `plan_detail_supplement_def456`
- **有效期**: 7天（与列表缓存一致）

### 缓存失效时机
| 操作 | 失效范围 |
|------|---------|
| 更新计划 (savePlan) | 该计划的详情缓存 |
| 删除计划 | 该计划的详情缓存 |
| 7天过期 | 自动失效 |

---

## 实施清单

### 1. 扩展 PlansCacheService (plans_cache_service.dart)

1. 添加 `getCachedPlanDetail(String planId, String planType)` 方法
2. 添加 `cachePlanDetail(String planId, String planType, Map<String, dynamic> planJson)` 方法
3. 添加 `invalidatePlanDetail(String planId, String planType)` 方法

### 2. 修改 PlanRepositoryImpl (plan_repository_impl.dart)

4. 在 `getPlanDetail()` 中添加缓存读取逻辑（缓存命中直接返回）
5. 在 `getPlanDetail()` 中添加缓存写入逻辑（Cloud Function 返回后缓存）
6. 在 `updatePlan()` 中调用 `invalidatePlanDetail()` 失效缓存

### 3. 修改 DietPlanRepository (diet_plan_repository.dart)

7. 在 `getPlan()` 中添加缓存读取逻辑
8. 在 `getPlan()` 中添加缓存写入逻辑
9. 在 `updatePlan()` 中调用 `invalidatePlanDetail()` 失效缓存

### 4. 修改 SupplementPlanRepository (supplement_plan_repository.dart)

10. 在 `getPlan()` 中添加缓存读取逻辑
11. 在 `getPlan()` 中添加缓存写入逻辑
12. 在 `updatePlan()` 中调用 `invalidatePlanDetail()` 失效缓存

---

## 数据流

```
编辑计划页面 loadPlan(planId)
        ↓
   Repository.getPlanDetail(planId)
        ↓
   ┌─ 缓存命中? ─┐
   │            │
  Yes          No
   │            │
   ↓            ↓
返回缓存    调用 Cloud Function
              ↓
          写入缓存
              ↓
          返回数据
```

```
保存计划 savePlan()
        ↓
   Repository.updatePlan(plan)
        ↓
   Cloud Function 成功
        ↓
   invalidatePlanDetail(planId, planType)
        ↓
   invalidateListCache(planType)
```

---

## 文件修改清单

| 文件 | 修改内容 |
|------|---------|
| `lib/features/coach/plans/data/cache/plans_cache_service.dart` | 添加详情缓存方法 |
| `lib/features/coach/plans/data/repositories/plan_repository_impl.dart` | 训练计划详情缓存集成 |
| `lib/features/coach/plans/data/repositories/diet_plan_repository.dart` | 饮食计划详情缓存集成 |
| `lib/features/coach/plans/data/repositories/supplement_plan_repository.dart` | 补剂计划详情缓存集成 |

---

## 预期效果

| 场景 | 缓存前 | 缓存后 |
|------|--------|--------|
| 首次编辑计划 | ~600-1200ms | ~600-1200ms (无变化) |
| 再次编辑同一计划 | ~600-1200ms | ~50-100ms (**10倍提升**) |
| 编辑后再次进入 | ~600-1200ms | ~600-1200ms (缓存已失效，重新加载) |

---

**文档版本**: v1.0
**创建日期**: 2025-12-01
