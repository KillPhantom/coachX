```python
#!/usr/bin/env python3
"""
上传nutrition-calculator skill到Claude API
运行此脚本获取skill_id，然后在Firebase环境变量中设置
"""

import os
import sys
from pathlib import Path
from anthropic import Anthropic
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

def upload_skill(skill_path: str) -> dict:
    """
    上传skill文件到Claude API
    
    Args:
        skill_path: skill文件的路径
        
    Returns:
        包含skill信息的字典
    """
    # 初始化Anthropic客户端
    api_key = os.environ.get('ANTHROPIC_API_KEY')
    
    if not api_key:
        print("❌ Error: ANTHROPIC_API_KEY not found in environment variables")
        print("Please set it in .env file or export it:")
        print("  export ANTHROPIC_API_KEY='your-api-key-here'")
        sys.exit(1)
    
    client = Anthropic(api_key=api_key)
    
    # 检查文件是否存在
    skill_file = Path(skill_path)
    if not skill_file.exists():
        print(f"❌ Error: Skill file not found at {skill_path}")
        sys.exit(1)
    
    print(f"📦 Uploading skill from: {skill_path}")
    print(f"📏 File size: {skill_file.stat().st_size / 1024:.2f} KB")
    
    try:
        # 读取skill文件
        with open(skill_path, 'rb') as f:
            skill_data = f.read()
        
        # 上传skill
        print("🚀 Uploading to Claude API...")
        
        skill = client.beta.skills.create(
            display_title="Nutrition Calculator v2.0",
            files=[
                (skill_file.name, skill_data)
            ],
            betas=["skills-2025-10-02"]
        )
        
        print("\n✅ Skill uploaded successfully!")
        print(f"📝 Skill ID: {skill.id}")
        print(f"📅 Created at: {skill.created_at}")
        
        # 提供Firebase配置命令
        print("\n" + "="*70)
        print("⚠️  IMPORTANT: Configure Firebase with this skill ID")
        print("="*70)
        print("\n1️⃣  For Firebase CLI (local development):")
        print(f"   export NUTRITION_SKILL_ID='{skill.id}'")
        
        print("\n2️⃣  For Firebase Functions config:")
        print(f"   firebase functions:config:set nutrition.skill_id='{skill.id}'")
        
        print("\n3️⃣  For Firebase environment variables (recommended):")
        print("   In Firebase Console → Functions → Environment Variables:")
        print(f"   NUTRITION_SKILL_ID = {skill.id}")
        
        print("\n4️⃣  Update your .env file:")
        print(f"   NUTRITION_SKILL_ID={skill.id}")
        
        print("\n" + "="*70)
        
        return {
            'id': skill.id,
            'created_at': skill.created_at,
            'display_title': "Nutrition Calculator v2.0"
        }
        
    except Exception as e:
        print(f"\n❌ Error uploading skill: {str(e)}")
        print(f"Error type: {type(e).__name__}")
        sys.exit(1)


def list_existing_skills():
    """列出已上传的skills"""
    api_key = os.environ.get('ANTHROPIC_API_KEY')
    
    if not api_key:
        print("❌ ANTHROPIC_API_KEY not set")
        return
    
    client = Anthropic(api_key=api_key)
    
    try:
        print("\n📋 Listing existing custom skills...")
        
        # 列出skills
        skills = client.beta.skills.list(
            betas=["skills-2025-10-02"]
        )
        
        custom_skills = [s for s in skills.data if getattr(s, 'type', 'custom') == 'custom']
        
        if not custom_skills:
            print("   No custom skills found")
            return
        
        print(f"   Found {len(custom_skills)} custom skill(s):\n")
        
        for skill in custom_skills:
            print(f"   • {skill.display_title or 'Untitled'}")
            print(f"     ID: {skill.id}")
            print(f"     Created: {skill.created_at}")
            print()
            
    except Exception as e:
        print(f"❌ Error listing skills: {str(e)}")


def main():
    """主函数"""
    print("="*70)
    print("🎯 Nutrition Calculator Skill Uploader")
    print("="*70)
    
    # 默认skill路径
    default_skill_path = "../nutrition-calculator.skill"
    
    # 检查命令行参数
    if len(sys.argv) > 1:
        skill_path = sys.argv[1]
    else:
        skill_path = default_skill_path
    
    # 检查是否需要列出现有skills
    if len(sys.argv) > 1 and sys.argv[1] == '--list':
        list_existing_skills()
        return
    
    # 上传skill
    result = upload_skill(skill_path)
    
    # 可选：列出所有skills
    list_existing_skills()
    
    print("\n✨ Done! Your skill is ready to use in Firebase Functions.")
    print("   Remember to deploy your functions after configuring the skill ID.")


if __name__ == "__main__":
    main()
```