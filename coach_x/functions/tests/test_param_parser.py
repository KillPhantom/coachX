"""
测试 utils/param_parser.py 中的参数解析工具

主要测试 unwrap_protobuf_values 函数对嵌套数据结构的解包能力
"""
import sys
import os

# 添加 functions 目录到 Python 路径
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from utils.param_parser import (
    unwrap_protobuf_values,
    parse_int_param,
    parse_float_param,
    parse_bool_param,
    parse_string_param,
)


def test_unwrap_protobuf_int64_value():
    """测试解包 Int64Value"""
    # Protobuf Int64Value 格式
    data = {
        'count': {
            '@type': 'type.googleapis.com/google.protobuf.Int64Value',
            'value': '100'
        }
    }
    result = unwrap_protobuf_values(data)
    assert result == {'count': 100}, f"Expected {{'count': 100}}, got {result}"
    assert isinstance(result['count'], int), "Value should be int type"
    print("✅ 测试通过: unwrap_protobuf_int64_value")


def test_unwrap_protobuf_double_value():
    """测试解包 DoubleValue"""
    data = {
        'weight': {
            '@type': 'type.googleapis.com/google.protobuf.DoubleValue',
            'value': '72.5'
        }
    }
    result = unwrap_protobuf_values(data)
    assert result == {'weight': 72.5}, f"Expected {{'weight': 72.5}}, got {result}"
    assert isinstance(result['weight'], float), "Value should be float type"
    print("✅ 测试通过: unwrap_protobuf_double_value")


def test_unwrap_nested_plan_selection():
    """测试解包嵌套的 planSelection 对象（真实场景）"""
    data = {
        'id': 'training123',
        'studentID': 'student456',
        'date': '2025-11-30',
        'planSelection': {
            'exercisePlanId': 'plan789',
            'exerciseDayNumber': {
                '@type': 'type.googleapis.com/google.protobuf.Int64Value',
                'value': '2'
            },
            'dietPlanId': 'dietPlan123',
            'dietDayNumber': {
                '@type': 'type.googleapis.com/google.protobuf.Int64Value',
                'value': '3'
            },
            'supplementPlanId': 'suppPlan456',
            'supplementDayNumber': {
                '@type': 'type.googleapis.com/google.protobuf.Int64Value',
                'value': '1'
            }
        }
    }

    result = unwrap_protobuf_values(data)

    # 验证顶层字段未改变
    assert result['id'] == 'training123'
    assert result['studentID'] == 'student456'
    assert result['date'] == '2025-11-30'

    # 验证 planSelection 中的整数已解包
    assert result['planSelection']['exercisePlanId'] == 'plan789'
    assert result['planSelection']['exerciseDayNumber'] == 2
    assert isinstance(result['planSelection']['exerciseDayNumber'], int)

    assert result['planSelection']['dietDayNumber'] == 3
    assert isinstance(result['planSelection']['dietDayNumber'], int)

    assert result['planSelection']['supplementDayNumber'] == 1
    assert isinstance(result['planSelection']['supplementDayNumber'], int)

    print("✅ 测试通过: unwrap_nested_plan_selection")


def test_unwrap_array_with_protobuf_values():
    """测试解包数组中的 Protobuf 值"""
    data = {
        'exercises': [
            {
                'name': 'Squat',
                'reps': {
                    '@type': 'type.googleapis.com/google.protobuf.Int64Value',
                    'value': '10'
                },
                'weight': {
                    '@type': 'type.googleapis.com/google.protobuf.DoubleValue',
                    'value': '100.5'
                }
            },
            {
                'name': 'Bench Press',
                'reps': {
                    '@type': 'type.googleapis.com/google.protobuf.Int64Value',
                    'value': '8'
                },
                'weight': {
                    '@type': 'type.googleapis.com/google.protobuf.DoubleValue',
                    'value': '80.0'
                }
            }
        ]
    }

    result = unwrap_protobuf_values(data)

    # 验证数组中的每个对象都被正确解包
    assert result['exercises'][0]['name'] == 'Squat'
    assert result['exercises'][0]['reps'] == 10
    assert result['exercises'][0]['weight'] == 100.5

    assert result['exercises'][1]['name'] == 'Bench Press'
    assert result['exercises'][1]['reps'] == 8
    assert result['exercises'][1]['weight'] == 80.0

    print("✅ 测试通过: unwrap_array_with_protobuf_values")


def test_unwrap_mixed_data_structure():
    """测试复杂混合数据结构"""
    data = {
        'stringField': 'hello',
        'intField': 42,  # 原始整数（未包装）
        'wrappedInt': {
            '@type': 'type.googleapis.com/google.protobuf.Int64Value',
            'value': '99'
        },
        'nested': {
            'level1': {
                'level2': {
                    'deepInt': {
                        '@type': 'type.googleapis.com/google.protobuf.Int64Value',
                        'value': '777'
                    }
                }
            }
        },
        'arrayOfArrays': [
            [
                {'val': {'@type': 'type.googleapis.com/google.protobuf.Int64Value', 'value': '1'}},
                {'val': {'@type': 'type.googleapis.com/google.protobuf.Int64Value', 'value': '2'}}
            ]
        ],
        'nullField': None
    }

    result = unwrap_protobuf_values(data)

    # 验证各种类型的字段
    assert result['stringField'] == 'hello'
    assert result['intField'] == 42
    assert result['wrappedInt'] == 99
    assert result['nested']['level1']['level2']['deepInt'] == 777
    assert result['arrayOfArrays'][0][0]['val'] == 1
    assert result['arrayOfArrays'][0][1]['val'] == 2
    assert result['nullField'] is None

    print("✅ 测试通过: unwrap_mixed_data_structure")


def test_unwrap_empty_structures():
    """测试空数据结构"""
    assert unwrap_protobuf_values({}) == {}
    assert unwrap_protobuf_values([]) == []
    assert unwrap_protobuf_values(None) is None
    assert unwrap_protobuf_values({'empty': {}}) == {'empty': {}}
    print("✅ 测试通过: unwrap_empty_structures")


def test_unwrap_primitive_values():
    """测试原始值（不需要解包）"""
    assert unwrap_protobuf_values(42) == 42
    assert unwrap_protobuf_values(3.14) == 3.14
    assert unwrap_protobuf_values('hello') == 'hello'
    assert unwrap_protobuf_values(True) is True
    assert unwrap_protobuf_values(False) is False
    print("✅ 测试通过: unwrap_primitive_values")


def test_parse_int_param():
    """测试 parse_int_param 函数"""
    # 原始整数
    assert parse_int_param(10) == 10
    # Protobuf 包装
    assert parse_int_param({'value': '20', '@type': '...'}) == 20
    # 默认值
    assert parse_int_param(None, 30) == 30
    # 字符串转换
    assert parse_int_param('40') == 40
    print("✅ 测试通过: parse_int_param")


def test_parse_float_param():
    """测试 parse_float_param 函数"""
    assert parse_float_param(1.5) == 1.5
    assert parse_float_param({'value': '2.5', '@type': '...'}) == 2.5
    assert parse_float_param(None, 3.5) == 3.5
    print("✅ 测试通过: parse_float_param")


def run_all_tests():
    """运行所有测试"""
    print("\n🧪 开始运行 param_parser 单元测试...\n")

    tests = [
        test_unwrap_protobuf_int64_value,
        test_unwrap_protobuf_double_value,
        test_unwrap_nested_plan_selection,
        test_unwrap_array_with_protobuf_values,
        test_unwrap_mixed_data_structure,
        test_unwrap_empty_structures,
        test_unwrap_primitive_values,
        test_parse_int_param,
        test_parse_float_param,
    ]

    passed = 0
    failed = 0

    for test in tests:
        try:
            test()
            passed += 1
        except AssertionError as e:
            print(f"❌ 测试失败: {test.__name__}")
            print(f"   错误: {e}")
            failed += 1
        except Exception as e:
            print(f"❌ 测试异常: {test.__name__}")
            print(f"   异常: {e}")
            failed += 1

    print(f"\n{'='*50}")
    print(f"测试结果: {passed} 通过, {failed} 失败")
    print(f"{'='*50}\n")

    return failed == 0


if __name__ == '__main__':
    success = run_all_tests()
    sys.exit(0 if success else 1)
