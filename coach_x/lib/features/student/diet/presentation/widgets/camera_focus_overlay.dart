import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 相机取景框覆盖层
///
/// 显示半透明遮罩和中心透明矩形取景框
class CameraFocusOverlay extends StatelessWidget {
  final String hintText;

  const CameraFocusOverlay({super.key, this.hintText = '将食物置于框内'});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final focusRectWidth = size.width * 0.9;
    final focusRectHeight = size.height * 0.5;

    return Stack(
      children: [
        // 半透明遮罩
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _FocusOverlayPainter(
            focusRect: Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: focusRectWidth,
              height: focusRectHeight,
            ),
          ),
        ),

        // 提示文字（移到取景框内部顶部，避免和导航栏重叠）
        Positioned(
          top: size.height / 2 - focusRectHeight / 2 + 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingL,
                vertical: AppDimensions.spacingS,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Text(
                hintText,
                style: AppTextStyles.callout.copyWith(
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ),

        // 取景框边角装饰
        Positioned.fill(
          child: Center(
            child: SizedBox(
              width: focusRectWidth,
              height: focusRectHeight,
              child: CustomPaint(painter: _CornersPainter()),
            ),
          ),
        ),
      ],
    );
  }
}

/// 绘制半透明遮罩和透明取景框
class _FocusOverlayPainter extends CustomPainter {
  final Rect focusRect;

  _FocusOverlayPainter({required this.focusRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CupertinoColors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // 绘制整个遮罩
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          focusRect,
          const Radius.circular(AppDimensions.radiusL),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 绘制取景框边角
class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // 左上角
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // 右上角
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // 左下角
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );

    // 右下角
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
