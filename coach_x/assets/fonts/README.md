# Lexend 字体文件

## 需要下载的字体文件

请从 Google Fonts 下载 Lexend 字体：
https://fonts.google.com/specimen/Lexend

## 需要的字体文件和字重

1. `Lexend-Regular.ttf` (weight: 400)
2. `Lexend-Medium.ttf` (weight: 500)
3. `Lexend-SemiBold.ttf` (weight: 600)
4. `Lexend-Bold.ttf` (weight: 700)
5. `Lexend-Black.ttf` (weight: 900)

## 下载步骤

1. 访问 https://fonts.google.com/specimen/Lexend
2. 点击 "Download family" 按钮
3. 解压下载的zip文件
4. 在 `static/` 目录中找到对应字重的ttf文件
5. 将以上5个文件复制到当前目录

## 临时方案：使用系统默认字体

✅ **当前配置已启用系统默认字体**

如果暂时无法下载字体文件，应用已配置为使用系统默认字体：
- **iOS**: SF Pro (San Francisco)
- **Android**: Roboto
- **Web**: 系统默认无衬线字体

### 已完成的配置

1. ✅ `pubspec.yaml` - fonts 配置已注释（第118-130行）
2. ✅ `lib/core/theme/app_text_styles.dart` - `_fontFamily` 设置为 `null`