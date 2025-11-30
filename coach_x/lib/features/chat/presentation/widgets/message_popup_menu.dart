import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessagePopupMenu extends StatelessWidget {
  final Rect targetRect;
  final VoidCallback onQuote;
  final VoidCallback? onDelete; // Nullable, if null, delete option is hidden
  final VoidCallback onDismiss;

  const MessagePopupMenu({
    super.key,
    required this.targetRect,
    required this.onQuote,
    this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Simple layout logic: try above, if not enough space, go below
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Use intrinsic size calculation if possible or a reasonable estimate
    // Here we estimate slightly larger to be safe, but the content is dynamic
    const menuHeight = 60.0; 
    const menuWidth = 160.0; 
    const arrowHeight = 8.0;
    const verticalMargin = 4.0; // Small gap between bubble and arrow

    final topSpace = targetRect.top;

    // Decide whether to show above or below
    // Show above if there is enough space (menuHeight + arrowHeight + margin)
    bool showAbove = topSpace > (menuHeight + arrowHeight + verticalMargin + 50); // 50 padding/safe area

    double top;
    double left;
    
    // Horizontal centering relative to the message bubble
    left = targetRect.center.dx - (menuWidth / 2);
    
    // Clamp to screen edges with padding
    if (left < 16) left = 16;
    if (left + menuWidth > screenWidth - 16) left = screenWidth - 16 - menuWidth;

    if (showAbove) {
      // Position above the bubble
      top = targetRect.top - menuHeight - arrowHeight - verticalMargin;
    } else {
      // Position below the bubble
      top = targetRect.bottom + arrowHeight + verticalMargin;
    }

    // Arrow position: centered horizontally on the bubble
    final arrowLeft = targetRect.center.dx - 8; // 8 is half arrow width (16/2)
    
    // Arrow top position
    final arrowTop = showAbove 
        ? (targetRect.top - arrowHeight - verticalMargin) 
        : (targetRect.bottom + verticalMargin);

    return Stack(
      children: [
        // Dismiss barrier
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Menu content
        Positioned(
          top: top,
          left: left,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // If showing below, we need the spacer/arrow placeholder here? 
                // No, the arrow is drawn separately, but let's keep the logic simple.
                // The menu container is just the dark rounded box.
                Container(
                  // Ensure we have a minimum width for aesthetic consistency
                  constraints: const BoxConstraints(minWidth: menuWidth),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C4C4C),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          onDismiss();
                          onQuote();
                        },
                        behavior: HitTestBehavior.translucent,
                        child: const _MenuItem(
                          icon: CupertinoIcons.quote_bubble,
                          label: '引用', // Quote
                        ),
                      ),
                      if (onDelete != null) ...[
                        Container(
                          height: 24,
                          width: 0.5,
                          color: Colors.white30,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            onDismiss();
                            onDelete!();
                          },
                          behavior: HitTestBehavior.translucent,
                          child: const _MenuItem(
                            icon: CupertinoIcons.delete,
                            label: '删除', // Delete
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Arrow indicator
        Positioned(
          top: arrowTop,
          left: arrowLeft,
          child: CustomPaint(
            size: const Size(16, 8),
            painter: _ArrowPainter(
              color: const Color(0xFF4C4C4C),
              isUp: !showAbove, 
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool isUp;

  _ArrowPainter({required this.color, required this.isUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isUp) {
      // Pointing up (base at bottom)
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      // Pointing down (base at top)
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

