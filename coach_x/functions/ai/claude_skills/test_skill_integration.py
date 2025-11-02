#!/usr/bin/env python3
"""
Claude Skills 集成测试脚本

测试 Skill 自动管理和营养计算功能
"""

import os
import sys
import json
from pathlib import Path

# 添加 functions 目录到 Python 路径
functions_dir = Path(__file__).parent.parent.parent
sys.path.insert(0, str(functions_dir))

from ai.claude_skills.skill_manager import (
    verify_skill,
    get_or_create_nutrition_skill,
)
from ai.claude_skills.skill_caller import call_nutrition_calculator_skill


def test_get_or_create_skill():
    """测试获取或创建 Skill"""
    print("=" * 70)
    print("测试 1: 获取或创建 Nutrition Calculator Skill")
    print("=" * 70)

    try:
        skill_id = get_or_create_nutrition_skill()
        print(f"\n✅ 成功获取 Skill ID: {skill_id}")
        return skill_id
    except Exception as e:
        print(f"\n❌ 失败: {str(e)}")
        return None


def test_verify_skill(skill_id: str):
    """测试验证 Skill"""
    print("\n" + "=" * 70)
    print("测试 2: 验证 Skill 是否存在")
    print("=" * 70)

    try:
        result = verify_skill(skill_id)

        if result.get('exists'):
            print(f"\n✅ Skill 验证成功:")
            print(f"   - Display Title: {result.get('display_title')}")
            print(f"   - Created: {result.get('created_at')}")
            print(f"   - Updated: {result.get('updated_at')}")
        else:
            print(f"\n❌ Skill 不存在: {result.get('error')}")

        return result.get('exists', False)
    except Exception as e:
        print(f"\n❌ 验证失败: {str(e)}")
        return False


def test_nutrition_calculation():
    """测试营养计算"""
    print("\n" + "=" * 70)
    print("测试 3: 完整营养计算流程")
    print("=" * 70)

    # 测试数据
    test_params = {
        "weight_kg": 70,
        "height_cm": 175,
        "age": 30,
        "gender": "male",
        "activity_level": "moderately_active",
        "goal": "muscle_gain",
        "body_fat_percentage": 15,
        "meal_count": 4,
        "plan_duration_days": 7,
        "dietary_preferences": ["high_protein"],
    }

    print("\n📊 测试参数:")
    print(json.dumps(test_params, indent=2, ensure_ascii=False))

    try:
        print("\n🚀 调用营养计算 Skill...")
        result = call_nutrition_calculator_skill(test_params)

        if result.get('success'):
            print("\n✅ 营养计算成功!")

            data = result.get('data', {})

            # 显示关键数据
            print(f"\n📈 计算结果:")
            print(f"   - BMR: {data.get('bmr_kcal')} kcal")
            print(f"   - TDEE: {data.get('tdee_kcal')} kcal")
            print(f"   - 目标热量: {data.get('target_calories_kcal')} kcal")

            if 'macros' in data:
                macros = data['macros']
                print(f"\n🥗 宏量营养素:")
                print(f"   - 蛋白质: {macros.get('protein', {})} g")
                print(f"   - 脂肪: {macros.get('fat', {})} g")
                print(f"   - 碳水: {macros.get('carbohydrates', {})} g")

            if 'diet_plan_recommendation' in data:
                print(f"\n📋 饮食计划已生成")
                diet_plan = data['diet_plan_recommendation']

                # 显示计划概要
                if isinstance(diet_plan, dict):
                    days = diet_plan.get('days', [])
                    print(f"   - 计划天数: {len(days)} 天")

                    if days:
                        first_day = days[0]
                        meals = first_day.get('meals', [])
                        print(f"   - 每日餐数: {len(meals)} 餐")

                        if meals:
                            total_foods = sum(len(meal.get('foods', [])) for meal in meals)
                            print(f"   - 每日食物种类: {total_foods} 种")

            return True
        else:
            error = result.get('error', 'Unknown error')
            print(f"\n❌ 营养计算失败: {error}")
            return False

    except Exception as e:
        print(f"\n❌ 测试失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


def check_environment():
    """检查环境配置"""
    print("=" * 70)
    print("环境检查")
    print("=" * 70)

    # 检查 ANTHROPIC_API_KEY
    api_key = os.environ.get('ANTHROPIC_API_KEY')

    if api_key:
        print(f"✅ ANTHROPIC_API_KEY: 已设置 ({api_key[:10]}...)")
    else:
        print("❌ ANTHROPIC_API_KEY: 未设置")
        print("\n请设置环境变量:")
        print("  export ANTHROPIC_API_KEY='your-api-key-here'")
        print("\n或创建 .env 文件:")
        print("  echo 'ANTHROPIC_API_KEY=your-api-key-here' > .env")
        print("  export $(cat .env | xargs)")
        return False

    # 检查 skill 文件
    skill_file = Path(__file__).parent / 'diet_plan_calculation' / 'nutrition-calculator.skill'

    if skill_file.exists():
        print(f"✅ Skill 文件: 存在 ({skill_file.stat().st_size / 1024:.2f} KB)")
    else:
        print(f"❌ Skill 文件: 不存在 ({skill_file})")
        return False

    return True


def main():
    """主测试流程"""
    print("\n🎯 Claude Skills 集成测试")
    print("\n")

    # 1. 环境检查
    if not check_environment():
        print("\n❌ 环境检查失败，请先配置环境")
        sys.exit(1)

    # 2. 获取或创建 Skill
    skill_id = test_get_or_create_skill()

    if not skill_id:
        print("\n❌ 无法获取 Skill ID，测试终止")
        sys.exit(1)

    # 3. 验证 Skill
    if not test_verify_skill(skill_id):
        print("\n⚠️ Skill 验证失败，但继续测试...")

    # 4. 测试营养计算
    success = test_nutrition_calculation()

    # 总结
    print("\n" + "=" * 70)
    print("测试总结")
    print("=" * 70)

    if success:
        print("\n✅ 所有测试通过！")
        print("\n💡 接下来可以:")
        print("   1. 集成到 Firebase Functions")
        print("   2. 部署到生产环境")
        print("   3. 在客户端调用 API")
    else:
        print("\n❌ 测试失败，请检查错误信息")
        sys.exit(1)


if __name__ == "__main__":
    main()
