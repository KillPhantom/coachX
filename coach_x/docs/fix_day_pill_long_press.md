# 修复 DayPill 长按删除功能

## 问题描述
Training Plan 编辑页面中，DayPill 长按无法删除训练日。

## 根本原因
`editing_view.dart:144` 中 `onDayLongPress: null` 被写死，导致长按事件无法传递。

## 影响范围
- `lib/features/coach/plans/presentation/widgets/create_plan/editing_view.dart`

## 修复方案

### 方案选择
参考 `create_diet_plan_page.dart` 的实现，在长按时显示操作菜单（包含删除选项）。

由于 `EditingView` 已经有 `onDeleteDay` 回调，最简方案是直接在 `editing_view.dart` 内部处理长按事件，调用现有的删除逻辑。

### 修改文件
仅修改 1 个文件：`editing_view.dart`

---

## 实施检查清单

1. [ ] 在 `_EditingViewState` 中添加 `_showDayOptionsMenu` 方法，显示包含"删除"选项的 ActionSheet
2. [ ] 修改 `DayPillScrollView` 的 `onDayLongPress` 参数，从 `null` 改为调用 `_showDayOptionsMenu`
3. [ ] 测试：长按 DayPill 应显示删除确认菜单，确认后删除该训练日

---

## 代码变更详情

### 1. 添加 `_showDayOptionsMenu` 方法

位置：`_EditingViewState` 类内，`_scrollToHighlightedCard` 方法之后

```dart
/// 显示 Day 操作菜单（长按触发）
void _showDayOptionsMenu(BuildContext context, int dayIndex, String dayName) {
  final l10n = AppLocalizations.of(context)!;

  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext popupContext) => CupertinoActionSheet(
      title: Text(dayName),
      actions: <CupertinoActionSheetAction>[
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(popupContext);
            widget.onDeleteDay(dayIndex);
          },
          child: Text(l10n.delete),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(popupContext),
        child: Text(l10n.cancel),
      ),
    ),
  );
}
```

### 2. 修改 `DayPillScrollView` 调用

位置：`editing_view.dart:144`

修改前：
```dart
onDayLongPress: null, // Day options menu handled by parent
```

修改后：
```dart
onDayLongPress: (index, dayName) => _showDayOptionsMenu(context, index, dayName),
```

---

## 验证步骤

1. 启动 App，进入 Training Plan 创建/编辑页面
2. 添加多个训练日
3. 长按任意 DayPill
4. 验证弹出 ActionSheet 包含"删除"选项
5. 点击"删除"，验证弹出确认对话框
6. 确认删除后，验证该训练日被移除

---

## 风险评估
- **风险等级**: 低
- **影响范围**: 仅 Training Plan 编辑页面
- **回滚方案**: 将 `onDayLongPress` 改回 `null`
