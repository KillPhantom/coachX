"""
参数解析工具
处理 Firebase Cloud Functions 2nd gen 的 Protobuf 参数包装问题
"""
from typing import Any, Optional, Union


def parse_int_param(value: Any, default: Optional[int] = None) -> Optional[int]:
    """
    解析整数参数，处理 Protobuf Int64Value 包装格式

    Args:
        value: 参数值，可能是 int、dict（Protobuf格式）或 None
        default: 默认值

    Returns:
        解析后的整数值，或默认值

    Examples:
        >>> parse_int_param(20)
        20
        >>> parse_int_param({'value': '100', '@type': '...'})
        100
        >>> parse_int_param(None, 10)
        10
    """
    if value is None:
        return default

    # 如果已经是整数，直接返回
    if isinstance(value, int):
        return value

    # 处理 Protobuf Int64Value 格式: {'value': '123', '@type': '...'}
    if isinstance(value, dict) and 'value' in value:
        try:
            return int(value['value'])
        except (ValueError, TypeError):
            return default

    # 尝试直接转换
    try:
        return int(value)
    except (ValueError, TypeError):
        return default


def parse_float_param(value: Any, default: Optional[float] = None) -> Optional[float]:
    """
    解析浮点数参数，处理 Protobuf DoubleValue 包装格式

    Args:
        value: 参数值，可能是 float、dict（Protobuf格式）或 None
        default: 默认值

    Returns:
        解析后的浮点数值，或默认值
    """
    if value is None:
        return default

    # 如果已经是浮点数或整数，直接返回
    if isinstance(value, (float, int)):
        return float(value)

    # 处理 Protobuf DoubleValue 格式
    if isinstance(value, dict) and 'value' in value:
        try:
            return float(value['value'])
        except (ValueError, TypeError):
            return default

    # 尝试直接转换
    try:
        return float(value)
    except (ValueError, TypeError):
        return default


def parse_bool_param(value: Any, default: Optional[bool] = None) -> Optional[bool]:
    """
    解析布尔参数（为API一致性提供）

    Args:
        value: 参数值
        default: 默认值

    Returns:
        布尔值，或默认值
    """
    if value is None:
        return default

    # 布尔值通常不会被 Protobuf 包装，但保持一致性
    if isinstance(value, bool):
        return value

    # 处理可能的包装格式
    if isinstance(value, dict) and 'value' in value:
        return bool(value['value'])

    # 字符串转布尔
    if isinstance(value, str):
        return value.lower() in ('true', '1', 'yes')

    return bool(value)


def parse_string_param(value: Any, default: Optional[str] = None) -> Optional[str]:
    """
    解析字符串参数

    Args:
        value: 参数值
        default: 默认值

    Returns:
        字符串值，或默认值
    """
    if value is None:
        return default

    if isinstance(value, str):
        return value

    # 处理可能的包装格式
    if isinstance(value, dict) and 'value' in value:
        return str(value['value'])

    return str(value)


def unwrap_protobuf_values(data: Any) -> Any:
    """
    递归解包 Protobuf 包装的值

    Firebase Cloud Functions 2nd gen 使用 gRPC/Protobuf 传输数据时，
    会自动将整数和浮点数包装为 Protobuf wrapper types:
    - int -> Int64Value: {'@type': 'type.googleapis.com/google.protobuf.Int64Value', 'value': '123'}
    - float -> DoubleValue: {'@type': 'type.googleapis.com/google.protobuf.DoubleValue', 'value': '1.23'}

    此函数递归遍历数据结构，将所有 Protobuf 包装值解包为原始 Python 类型。

    Args:
        data: 可能包含 Protobuf 包装值的数据（dict, list, 或原始值）

    Returns:
        解包后的数据，类型与输入相同（dict, list, 或原始值）

    Examples:
        >>> unwrap_protobuf_values({'count': {'@type': '...Int64Value', 'value': '10'}})
        {'count': 10}

        >>> unwrap_protobuf_values({
        ...     'planSelection': {
        ...         'exerciseDayNumber': {'@type': '...Int64Value', 'value': '2'},
        ...         'dietDayNumber': {'@type': '...Int64Value', 'value': '3'}
        ...     }
        ... })
        {'planSelection': {'exerciseDayNumber': 2, 'dietDayNumber': 3}}

        >>> unwrap_protobuf_values([
        ...     {'id': 1, 'weight': {'@type': '...DoubleValue', 'value': '100.5'}}
        ... ])
        [{'id': 1, 'weight': 100.5}]
    """
    # 如果是 None，直接返回
    if data is None:
        return None

    # 检测 Protobuf 包装格式
    if isinstance(data, dict):
        # 检查是否是 Protobuf wrapper type
        if '@type' in data and 'value' in data:
            type_url = data.get('@type', '')
            value = data.get('value')

            # Int64Value
            if 'Int64Value' in type_url:
                try:
                    return int(value)
                except (ValueError, TypeError):
                    return value

            # DoubleValue
            if 'DoubleValue' in type_url:
                try:
                    return float(value)
                except (ValueError, TypeError):
                    return value

            # FloatValue
            if 'FloatValue' in type_url:
                try:
                    return float(value)
                except (ValueError, TypeError):
                    return value

            # 其他未知包装类型，返回 value 字段
            return value

        # 普通字典，递归处理每个值
        return {key: unwrap_protobuf_values(val) for key, val in data.items()}

    # 列表，递归处理每个元素
    if isinstance(data, list):
        return [unwrap_protobuf_values(item) for item in data]

    # 原始类型（int, float, str, bool），直接返回
    return data
