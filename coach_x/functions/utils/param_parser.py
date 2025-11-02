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
